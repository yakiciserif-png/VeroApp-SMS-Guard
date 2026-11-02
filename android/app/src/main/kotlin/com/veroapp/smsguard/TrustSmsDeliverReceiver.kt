package com.veroapp.smsguard

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony

/**
 * [ADIM 6] Mandatory BroadcastReceiver for Android Default SMS App eligibility.
 * Handles `android.provider.Telephony.SMS_DELIVER` intents directly from the telecom framework.
 */
class TrustSmsDeliverReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == Telephony.Sms.Intents.SMS_DELIVER_ACTION) {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            if (messages != null && context != null) {
                for (sms in messages) {
                    val body = sms.displayMessageBody ?: ""
                    val sender = sms.displayOriginatingAddress ?: ""
                    TrustFilterEngine.classify(body, sender)
                }
            }
        }
    }
}
