package com.veroapp.smsguard

import android.app.Notification
import android.content.Context
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import org.json.JSONArray
import org.json.JSONObject

class TrustNotificationListener : NotificationListenerService() {

    companion object {
        private const val PREFS_NAME = "veroapp_native_prefs"
        private const val KEY_PENDING_MESSAGES = "pending_messages"
        private const val KEY_CONFIG = "filter_config"
        private const val MAX_PENDING = 200

        @Volatile
        private var configInitialized = false

        fun ensureConfigLoaded(context: Context) {
            if (configInitialized) return
            synchronized(this) {
                if (configInitialized) return
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val savedConfig = prefs.getString(KEY_CONFIG, null)
                if (savedConfig != null) {
                    TrustFilterEngine.updateConfig(savedConfig)
                }
                configInitialized = true
            }
        }

        fun getPendingMessages(context: Context): List<Map<String, Any?>> {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val json = prefs.getString(KEY_PENDING_MESSAGES, "[]") ?: "[]"
            val list = mutableListOf<Map<String, Any?>>()
            try {
                val arr = JSONArray(json)
                for (i in 0 until arr.length()) {
                    val obj = arr.getJSONObject(i)
                    val map = mutableMapOf<String, Any?>()
                    val keys = obj.keys()
                    while (keys.hasNext()) {
                        val k = keys.next()
                        map[k] = obj.get(k)
                    }
                    list.add(map)
                }
                // Clear pending once retrieved
                prefs.edit().putString(KEY_PENDING_MESSAGES, "[]").apply()
            } catch (e: Exception) {
                e.printStackTrace()
            }
            return list
        }

        fun saveConfig(context: Context, configJson: String) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().putString(KEY_CONFIG, configJson).apply()
            TrustFilterEngine.updateConfig(configJson)
            configInitialized = true
        }

        fun bufferExternalMessage(
            context: Context,
            text: String,
            sender: String?,
            packageName: String?,
            dismissed: Boolean,
            category: String,
            source: String
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val json = prefs.getString(KEY_PENDING_MESSAGES, "[]") ?: "[]"
            try {
                val arr = JSONArray(json)
                // Deduplicate if TrustSmsReceiver and NotificationListener both saw the same SMS within 3 seconds
                val now = System.currentTimeMillis()
                if (arr.length() > 0) {
                    val last = arr.getJSONObject(arr.length() - 1)
                    val lastText = last.optString("text", "")
                    val lastTime = last.optLong("timestamp", 0L)
                    if (lastText == text && (now - lastTime) < 3000L) {
                        return
                    }
                }

                val obj = JSONObject().apply {
                    put("text", text)
                    put("sender", sender)
                    put("package", packageName)
                    put("dismissed", dismissed)
                    put("category", category)
                    put("source", source)
                    put("timestamp", now)
                }
                arr.put(obj)

                while (arr.length() > MAX_PENDING) {
                    arr.remove(0)
                }

                prefs.edit().putString(KEY_PENDING_MESSAGES, arr.toString()).apply()
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        ensureConfigLoaded(applicationContext)
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return

        val pkg = sbn.packageName ?: return
        if (pkg == packageName) return // Ignore self

        val extras = sbn.notification.extras ?: return
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
            ?: extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()
            ?: ""

        if (text.isBlank()) return

        val startNs = System.nanoTime()
        val sender = if (title.isNotBlank()) title else null
        val decision = TrustFilterEngine.classify(text, sender)
        TrustFilterEngine.lastDecisionLatencyMs = (System.nanoTime() - startNs) / 1_000_000.0

        var dismissed = false
        if (decision.category == "spam" && TrustFilterEngine.autoDismiss) {
            try {
                cancelNotification(sbn.key)
                dismissed = true
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        bufferExternalMessage(
            context = applicationContext,
            text = text,
            sender = sender,
            packageName = pkg,
            dismissed = dismissed,
            category = decision.category,
            source = decision.source
        )
    }
}
