package com.trustlens.trustlens_mobile

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony

/**
 * FAZ 4: Real-Time SMS Interceptor (`SMS_RECEIVED` & `SMS_DELIVER` with priority=999).
 *
 * Executes entirely offline in < 5 ms (0.005 s) without spinning up a FlutterEngine
 * or Dart VM, preserving battery life while immediately classifying incoming SMS
 * via [TrustFilterEngine] (FAZ 2 Normalization + FAZ 3 6D Semantic Intent Engine).
 */
class TrustSmsReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return
        val action = intent.action ?: return
        if (action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION &&
            action != Telephony.Sms.Intents.SMS_DELIVER_ACTION
        ) {
            return
        }

        val startNs = System.nanoTime()
        try {
            // Ensure engine configuration is loaded into memory once (zero-disk-read on hot path)
            TrustNotificationListener.ensureConfigLoaded(context.applicationContext)

            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            if (messages.isNullOrEmpty()) return

            // Group multi-part SMS segments by sender address
            val grouped = linkedMapOf<String, StringBuilder>()
            for (sms in messages) {
                val sender = sms?.displayOriginatingAddress ?: sms?.originatingAddress ?: ""
                val body = sms?.displayMessageBody ?: sms?.messageBody ?: ""
                if (body.isNotEmpty()) {
                    grouped.getOrPut(sender) { StringBuilder() }.append(body)
                }
            }

            for ((rawSender, bodyBuilder) in grouped) {
                val fullText = bodyBuilder.toString().trim()
                if (fullText.isEmpty()) continue
                val sender = rawSender.ifBlank { null }

                val decision = TrustFilterEngine.classify(fullText, sender)
                val elapsedMs = (System.nanoTime() - startNs) / 1_000_000.0
                TrustFilterEngine.lastDecisionLatencyMs = elapsedMs

                var suppressed = false
                if (decision.category == "spam" && TrustFilterEngine.autoDismiss) {
                    try {
                        if (isOrderedBroadcast) {
                            abortBroadcast()
                            suppressed = true
                        }
                    } catch (_: Exception) {
                        // Graceful degradation on non-ordered broadcasts on newer Android OEMs
                    }
                }

                // Persist to local pending queue so Flutter UI & History display it with X-Ray details
                TrustNotificationListener.bufferExternalMessage(
                    context = context.applicationContext,
                    text = fullText,
                    sender = sender,
                    packageName = "android.provider.Telephony.SMS",
                    dismissed = suppressed,
                    category = decision.category,
                    source = decision.source
                )
            }
        } catch (e: Exception) {
            // Crash-free guarantee: never crash the system broadcast receiver
            e.printStackTrace()
        }
    }
}
