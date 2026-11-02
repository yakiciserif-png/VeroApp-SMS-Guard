package com.veroapp.smsguard

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

/**
 * [ADIM 5D] Optional On-Device Accessibility Link Guard for Instant Messaging Apps.
 *
 * Strictly 100% Offline:
 * - Inspects visible URL patterns inside supported messaging apps (WhatsApp, Telegram, Messenger)
 *   only when explicitly enabled by the user in Android Accessibility Settings.
 * - Never stores, logs, or transmits message text or personal identifiers.
 * - Emits high-priority local warning notification via [TrustNotificationHelper] if a known
 *   phishing or malware (.apk / .exe) URL is detected.
 */
class VeroLinkAccessibilityService : AccessibilityService() {

    private var lastInspectedSignature: Int = 0
    private var lastInspectTimestampMs: Long = 0L

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        val pkg = event.packageName?.toString() ?: return
        if (pkg != "com.whatsapp" &&
            pkg != "org.telegram.messenger" &&
            pkg != "com.facebook.orca"
        ) {
            return
        }

        val now = System.currentTimeMillis()
        if (now - lastInspectTimestampMs < 750L) return

        try {
            val texts = mutableListOf<String>()
            event.text.forEach { seq ->
                if (!seq.isNullOrBlank()) {
                    texts.add(seq.toString())
                }
            }

            val rootNode = rootInActiveWindow
            if (rootNode != null) {
                collectUrlCandidateText(rootNode, texts, depth = 0)
                @Suppress("DEPRECATION")
                rootNode.recycle()
            }

            if (texts.isEmpty()) return
            val combined = texts.joinToString(" ")
            val sig = combined.hashCode()
            if (sig == lastInspectedSignature) return
            lastInspectedSignature = sig
            lastInspectTimestampMs = now

            if (!containsUrlLikeToken(combined)) return

            val decision = TrustFilterEngine.classify(
                text = combined,
                sender = pkg
            )

            if (decision.category == "spam" && decision.score >= 0.75) {
                TrustNotificationListener.bufferExternalMessage(
                    context = applicationContext,
                    text = combined,
                    sender = "Link Guard ($pkg)",
                    packageName = pkg,
                    dismissed = false,
                    category = decision.category,
                    source = decision.source
                )
            }
        } catch (_: Throwable) {
            // Silent fail-safe: never crash the accessibility pipeline or log PII.
        }
    }

    override fun onInterrupt() {
        // No-op: stateless on-device scanner.
    }

    private fun collectUrlCandidateText(
        node: AccessibilityNodeInfo?,
        out: MutableList<String>,
        depth: Int
    ) {
        if (node == null || depth > 8 || out.size >= 16) return
        val nodeText = node.text?.toString()
        if (!nodeText.isNullOrBlank() && containsUrlLikeToken(nodeText)) {
            out.add(nodeText)
        }
        val count = node.childCount
        for (i in 0 until count) {
            if (out.size >= 16) break
            val child = node.getChild(i) ?: continue
            collectUrlCandidateText(child, out, depth + 1)
            @Suppress("DEPRECATION")
            child.recycle()
        }
    }

    private fun containsUrlLikeToken(text: String): Boolean {
        val lower = text.lowercase()
        return lower.contains("http://") ||
            lower.contains("https://") ||
            lower.contains("bit.ly/") ||
            lower.contains("tinyurl.com/") ||
            lower.contains("t.co/") ||
            lower.contains(".xyz") ||
            lower.contains(".top") ||
            lower.contains(".click") ||
            lower.contains(".apk")
    }
}
