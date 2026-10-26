package com.veroapp.smsguard

import android.app.Service
import android.content.Intent
import android.os.IBinder

/**
 * [ADIM 6] Mandatory Service for Android Default SMS App eligibility.
 * Handles `android.intent.action.RESPOND_VIA_MESSAGE` for quick incoming call responses.
 */
class HeadlessSmsSendService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null
}
