package com.veroapp.smsguard

import android.content.Context
import android.os.Build
import android.telecom.Call
import android.telecom.CallScreeningService
import androidx.annotation.RequiresApi

/**
 * Android 10+ (API 29+) CallScreeningService implementation.
 *
 * Intercepts incoming calls at the OS telecom framework level before ringing.
 * Completely eliminates the need for intrusive READ_CALL_LOG / WRITE_CALL_LOG permissions.
 *
 * If incoming number matches offline verified spam/scam signatures or synced custom
 * blocked numbers from VeroApp, rejects the call and suppresses the notification.
 */
@RequiresApi(Build.VERSION_CODES.Q)
class VeroCallScreeningService : CallScreeningService() {

    private val verifiedWhitelist = setOf(
        "4440000", "908502200000", "08502200000", "908507240724", "08507240724",
        "4440333", "4442525", "4440444", "908502220724", "08502220724",
        "4449999", "4442552", "182"
    )

    override fun onScreenCall(callDetails: Call.Details) {
        val handle = callDetails.handle
        val rawNumber = handle?.schemeSpecificPart ?: ""

        val isSpam = isSpamNumber(rawNumber)

        if (isSpam) {
            val response = CallResponse.Builder()
                .setDisallowCall(true)
                .setRejectCall(true)
                .setSkipCallLog(false)
                .setSkipNotification(true)
                .build()
            respondToCall(callDetails, response)
        } else {
            val response = CallResponse.Builder()
                .setDisallowCall(false)
                .setRejectCall(false)
                .build()
            respondToCall(callDetails, response)
        }
    }

    private fun isSpamNumber(number: String): Boolean {
        if (number.isBlank()) return false
        val digitsOnly = number.replace(Regex("[^0-9]"), "")
        if (digitsOnly.isBlank()) return false

        // Check verified corporate whitelist (legitimate banks, couriers, MHRS)
        for (safe in verifiedWhitelist) {
            val safeDigits = safe.replace(Regex("[^0-9]"), "")
            if (digitsOnly == safeDigits || digitsOnly.endsWith(safeDigits)) {
                return false
            }
        }

        // 1. Check synced custom blocked list from SharedPreferences
        try {
            val prefs = getSharedPreferences("vero_call_screening", Context.MODE_PRIVATE)
            val customBlocked = prefs.getStringSet("blocked_numbers", emptySet()) ?: emptySet()
            for (blocked in customBlocked) {
                val cleanBlocked = blocked.replace(Regex("[^0-9]"), "")
                if (cleanBlocked.isNotBlank() && (digitsOnly == cleanBlocked || digitsOnly.endsWith(cleanBlocked) || cleanBlocked.endsWith(digitsOnly))) {
                    return true
                }
            }
        } catch (_: Exception) {}

        // 2. High-risk international toll/Wangiri prefixes
        val intlPrefixes = listOf("63", "62", "234", "212", "359", "370", "375", "880", "254", "91", "92")
        for (prefix in intlPrefixes) {
            if (digitsOnly.startsWith(prefix) && digitsOnly.length >= 10) return true
        }

        // 3. ALL Unverified 0850 / +90 850 / 850 lines!
        if (digitsOnly.startsWith("90850") || digitsOnly.startsWith("0850") || digitsOnly.startsWith("850")) {
            return true
        }

        // 4. 0212 9xx / 0216 9xx robocall PBX blocks
        if (Regex("^(90|0)?21[26]9\\d{6}$").matches(digitsOnly)) {
            return true
        }

        return false
    }
}
