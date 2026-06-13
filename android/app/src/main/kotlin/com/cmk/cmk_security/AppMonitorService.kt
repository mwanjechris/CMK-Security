package com.cmk.cmk_security

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat

class AppMonitorService : Service() {

    companion object {
        private const val TAG = "AppMonitorService"
        private const val CHANNEL_ID = "cmk_security_monitor"
        private const val NOTIFICATION_ID = 1001
        private const val PREF_NAME = "cmk_locked_apps"
        private const val PREF_KEY = "locked_packages"
        private const val CHECK_INTERVAL_MS = 500L

        fun start(context: Context, lockedPackages: List<String>) {
            saveLockedApps(context, lockedPackages)
            val intent = Intent(context, AppMonitorService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, AppMonitorService::class.java))
        }

        fun updateLockedApps(context: Context, lockedPackages: List<String>) {
            saveLockedApps(context, lockedPackages)
        }

        private fun saveLockedApps(context: Context, packages: List<String>) {
            val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
            prefs.edit().putStringSet(PREF_KEY, packages.toSet()).apply()
        }

        fun getLockedApps(context: Context): Set<String> {
            val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
            return prefs.getStringSet(PREF_KEY, emptySet()) ?: emptySet()
        }
    }

    private val handler = Handler(Looper.getMainLooper())
    private var lastLockedPackage: String? = null
    private var lastDetectionTime = 0L

    private val monitorRunnable = object : Runnable {
        override fun run() {
            checkForegroundApp()
            handler.postDelayed(this, CHECK_INTERVAL_MS)
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildNotification())
        handler.post(monitorRunnable)
        Log.d(TAG, "AppMonitorService started")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacks(monitorRunnable)
        Log.d(TAG, "AppMonitorService stopped")
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun checkForegroundApp() {
        val foregroundPkg = getForegroundApp() ?: return
        if (foregroundPkg == packageName) return

        val lockedApps = getLockedApps(this)
        if (foregroundPkg in lockedApps) {
            val now = System.currentTimeMillis()
            // Debounce: don't re-trigger if same app locked < 3s ago
            if (foregroundPkg == lastLockedPackage && now - lastDetectionTime < 3000) return

            lastLockedPackage = foregroundPkg
            lastDetectionTime = now
            Log.d(TAG, "Locked app detected: $foregroundPkg")
            showLockScreen(foregroundPkg)
        } else {
            lastLockedPackage = null
        }
    }

    private fun getForegroundApp(): String? {
        return try {
            val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val now = System.currentTimeMillis()
            val stats = usm.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                now - 10000,
                now
            )
            stats?.maxByOrNull { it.lastTimeUsed }?.packageName
        } catch (e: Exception) {
            Log.e(TAG, "Error getting foreground app", e)
            null
        }
    }

    private fun showLockScreen(lockedPackage: String) {
        val intent = Intent(this, LockOverlayActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra("locked_package", lockedPackage)
        }
        startActivity(intent)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "CMK Security Monitor",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Monitoring locked apps"
                setShowBadge(false)
            }
            val nm = getSystemService(NotificationManager::class.java)
            nm.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        val pi = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("CMK Security")
            .setContentText("Protecting your apps")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentIntent(pi)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
}
