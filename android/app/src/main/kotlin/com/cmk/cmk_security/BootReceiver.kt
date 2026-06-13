package com.cmk.cmk_security

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON"
        ) {
            val lockedApps = AppMonitorService.getLockedApps(context)
            if (lockedApps.isNotEmpty()) {
                AppMonitorService.start(context, lockedApps.toList())
            }
        }
    }
}
