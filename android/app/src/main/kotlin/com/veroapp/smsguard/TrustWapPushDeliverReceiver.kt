package com.veroapp.smsguard

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony

/**
 * [ADIM 6] Mandatory BroadcastReceiver for Android Default SMS App eligibility.
 * Handles `android.provider.Telephony.WAP_PUSH_DELIVER` (MMS) intents.
 */
class TrustWapPushDeliverReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        // Safe offline stub for incoming WAP Push MMS
    }
}
