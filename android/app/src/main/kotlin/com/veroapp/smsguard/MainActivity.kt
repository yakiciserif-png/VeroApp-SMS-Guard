package com.veroapp.smsguard

import android.Manifest
import android.app.role.RoleManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import android.provider.Telephony
import android.text.TextUtils
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.veroapp.smsguard/native"
    private val REQ_SMS_PERMISSIONS = 4001
    private val REQ_SPAM_ROLE = 4002
    private val REQ_CALL_SCREENING_ROLE = 4003

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "isNotificationAccessGranted" -> {
                        result.success(isNotificationServiceEnabled())
                    }
                    "openNotificationAccessSettings" -> {
                        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    }
                    "getSystemHooksStatus" -> {
                        result.success(
                            mapOf(
                                "notificationAccess" to isNotificationServiceEnabled(),
                                "smsPermissionGranted" to isSmsPermissionGranted(),
                                "isDefaultSmsRoleHeld" to isDefaultSmsRoleHeld(),
                                "isCallScreeningRoleHeld" to isCallScreeningRoleHeld(),
                                "lastInterceptLatencyMs" to TrustFilterEngine.lastDecisionLatencyMs
                            )
                        )
                    }
                    "requestSmsPermissions" -> {
                        requestSmsPermissionsSafely()
                        result.success(isSmsPermissionGranted())
                    }
                    "requestSpamRole" -> {
                        val launched = requestDefaultSpamRoleSafely()
                        result.success(launched)
                    }
                    "isCallScreeningRoleHeld" -> {
                        result.success(isCallScreeningRoleHeld())
                    }
                    "requestCallScreeningRole" -> {
                        val launched = requestCallScreeningRoleSafely()
                        result.success(launched)
                    }
                    "syncFilterConfig" -> {
                        val configJson = call.arguments as? String
                        if (configJson != null) {
                            TrustNotificationListener.saveConfig(applicationContext, configJson)
                            result.success(true)
                        } else {
                            result.error("INVALID_ARGS", "Config JSON missing", null)
                        }
                    }
                    "evaluateAccelerator" -> {
                        val startNs = System.nanoTime()
                        val args = call.arguments as? Map<*, *>
                        val text = args?.get("text") as? String ?: ""
                        val sender = args?.get("sender") as? String
                        val decision = TrustFilterEngine.classify(text, sender)
                        val elapsedMs = (System.nanoTime() - startNs) / 1_000_000.0
                        TrustFilterEngine.lastDecisionLatencyMs = elapsedMs
                        result.success(
                            mapOf(
                                "score" to decision.score,
                                "isSpam" to if (decision.category == "spam") 1.0 else 0.0,
                                "isTransaction" to if (decision.category == "transaction") 1.0 else 0.0,
                                "latencyMs" to elapsedMs
                            )
                        )
                    }
                    "fetchPendingMessages" -> {
                        val messages = TrustNotificationListener.getPendingMessages(applicationContext)
                        result.success(messages)
                    }
                    "isDefaultSmsApp" -> {
                        result.success(isDefaultSmsRoleHeld())
                    }
                    "requestDefaultSmsRole" -> {
                        val launched = requestDefaultSpamRoleSafely()
                        result.success(launched)
                    }
                    "syncBlockedNumbers" -> {
                        val numbers = (call.arguments as? List<*>)?.filterIsInstance<String>()?.toSet() ?: emptySet()
                        val prefs = getSharedPreferences("vero_call_screening", Context.MODE_PRIVATE)
                        prefs.edit().putStringSet("blocked_numbers", numbers).apply()
                        result.success(true)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            } catch (e: Exception) {
                // Graceful degradation: never crash the host activity
                result.success(null)
            }
        }

        // Dedicated telecom channel for SMS service and call screening
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.veroapp.smsguard/telecom").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "isDefaultSmsApp" -> result.success(isDefaultSmsRoleHeld())
                    "requestDefaultSmsRole" -> result.success(requestDefaultSpamRoleSafely())
                    "isCallScreeningRoleHeld" -> result.success(isCallScreeningRoleHeld())
                    "requestCallScreeningRole" -> result.success(requestCallScreeningRoleSafely())
                    "syncBlockedNumbers" -> {
                        val numbers = (call.arguments as? List<*>)?.filterIsInstance<String>()?.toSet() ?: emptySet()
                        val prefs = getSharedPreferences("vero_call_screening", Context.MODE_PRIVATE)
                        prefs.edit().putStringSet("blocked_numbers", numbers).apply()
                        result.success(true)
                    }
                    "sendSms" -> result.success(true)
                    else -> result.notImplemented()
                }
            } catch (_: Exception) {
                result.success(null)
            }
        }
    }

    private fun isSmsPermissionGranted(): Boolean {
        return try {
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.RECEIVE_SMS
            ) == PackageManager.PERMISSION_GRANTED
        } catch (_: Exception) {
            false
        }
    }

    private fun requestSmsPermissionsSafely() {
        try {
            val perms = mutableListOf(
                Manifest.permission.RECEIVE_SMS,
                Manifest.permission.READ_SMS
            )
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                perms.add(Manifest.permission.POST_NOTIFICATIONS)
            }
            ActivityCompat.requestPermissions(this, perms.toTypedArray(), REQ_SMS_PERMISSIONS)
        } catch (_: Exception) {
            // Fallback to application details settings if OEM blocks runtime prompt
            try {
                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = android.net.Uri.fromParts("package", packageName, null)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(intent)
            } catch (_: Exception) {}
        }
    }

    private fun isDefaultSmsRoleHeld(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val roleManager = getSystemService(Context.ROLE_SERVICE) as? RoleManager
                if (roleManager != null && roleManager.isRoleAvailable(RoleManager.ROLE_SMS)) {
                    return roleManager.isRoleHeld(RoleManager.ROLE_SMS)
                }
            }
            val defaultPkg = Telephony.Sms.getDefaultSmsPackage(this)
            defaultPkg == packageName
        } catch (_: Exception) {
            false
        }
    }

    private fun requestDefaultSpamRoleSafely(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val roleManager = getSystemService(Context.ROLE_SERVICE) as? RoleManager
                if (roleManager != null && roleManager.isRoleAvailable(RoleManager.ROLE_SMS)) {
                    if (!roleManager.isRoleHeld(RoleManager.ROLE_SMS)) {
                        val intent = roleManager.createRequestRoleIntent(RoleManager.ROLE_SMS)
                        startActivityForResult(intent, REQ_SPAM_ROLE)
                        return true
                    }
                    return true
                }
            }
            val intent = Intent(Telephony.Sms.Intents.ACTION_CHANGE_DEFAULT).apply {
                putExtra(Telephony.Sms.Intents.EXTRA_PACKAGE_NAME, packageName)
            }
            startActivityForResult(intent, REQ_SPAM_ROLE)
            true
        } catch (_: Exception) {
            try {
                val fallback = Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(fallback)
                true
            } catch (_: Exception) {
                false
            }
        }
    }

    private fun isCallScreeningRoleHeld(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val roleManager = getSystemService(Context.ROLE_SERVICE) as? RoleManager
                if (roleManager != null && roleManager.isRoleAvailable(RoleManager.ROLE_CALL_SCREENING)) {
                    return roleManager.isRoleHeld(RoleManager.ROLE_CALL_SCREENING)
                }
            }
            false
        } catch (_: Exception) {
            false
        }
    }

    private fun requestCallScreeningRoleSafely(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val roleManager = getSystemService(Context.ROLE_SERVICE) as? RoleManager
                if (roleManager != null && roleManager.isRoleAvailable(RoleManager.ROLE_CALL_SCREENING)) {
                    if (!roleManager.isRoleHeld(RoleManager.ROLE_CALL_SCREENING)) {
                        val intent = roleManager.createRequestRoleIntent(RoleManager.ROLE_CALL_SCREENING)
                        startActivityForResult(intent, REQ_CALL_SCREENING_ROLE)
                        return true
                    }
                    return true
                }
            }
            false
        } catch (_: Exception) {
            false
        }
    }

    private fun isNotificationServiceEnabled(): Boolean {
        val pkgName = packageName
        val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
        if (!TextUtils.isEmpty(flat)) {
            val names = flat.split(":").toTypedArray()
            for (name in names) {
                val cn = ComponentName.unflattenFromString(name)
                if (cn != null && TextUtils.equals(pkgName, cn.packageName)) {
                    return true
                }
            }
        }
        return false
    }
}
