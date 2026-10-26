package com.veroapp.smsguard

import android.os.Build
import android.telecom.Call
import android.telecom.CallScreeningService
import androidx.annotation.RequiresApi

/**
 * [ADIM 3] Android 10+ (API 29+) CallScreeningService implementation.
 *
 * Intercepts incoming calls at the OS telecom framework level before ringing.
 * Completely eliminates the need for intrusive READ_CALL_LOG / WRITE_CALL_LOG permissions.
 *
 * If incoming number matches offline verified spam/scam signatures, rejects the call
 * and suppresses the ringing notification while keeping normal call log intact.
 */
@RequiresApi(Build.VERSION_CODES.Q)
class VeroCallScreeningService : CallScreeningService() {

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
        val clean = number.replace(Regex("[^0-9+]"), "")

        // High-risk international toll/Wangiri prefixes
        val scamPrefixes = listOf("+63", "+62", "+234", "+212", "+359", "+370", "+375", "+880", "+254", "+91", "+92")
        for (prefix in scamPrefixes) {
            if (clean.startsWith(prefix)) return true
        }

        // Unverified high-risk 0850 telemarketing blocks
        if (clean.startsWith("+90850") || clean.startsWith("0850")) {
            val sub = if (clean.startsWith("+90850")) clean.substring(6) else clean.substring(4)
            if (sub.startsWith("532") || sub.startsWith("480") || sub.startsWith("901") || sub.startsWith("840")) {
                return true
            }
        }

        // 0212 9xx / 0216 9xx robocall PBX blocks
        if (Regex("^(90|0)?21[26]9\\d{6}$").matches(clean)) {
            return true
        }

        return false
    }
}
