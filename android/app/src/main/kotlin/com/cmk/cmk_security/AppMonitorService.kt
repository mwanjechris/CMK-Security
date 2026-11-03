package com.cmk.cmk_security

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
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
        private const val CHECK_INTERVAL_MS = 400L
        // Session: once the user authenticates, allow access for this duration
        private const val SESSION_DURATION_MS = 5 * 60 * 1000L  // 5 minutes

        @Volatile private var sessionUnlockedPackage: String? = null
        @Volatile private var sessionUnlockTime = 0L
        @Volatile private var lastForeground: String? = null

        fun sessionUnlock(pkg: String) {
            sessionUnlockedPackage = pkg
            sessionUnlockTime = System.currentTimeMillis()
            Log.d(TAG, "Session unlocked: $pkg")
        }

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
            Log.d(TAG, "Locked apps updated: $packages")
        }

        fun getLockedApps(context: Context): Set<String> {
            val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
            return prefs.getStringSet(PREF_KEY, emptySet()) ?: emptySet()
        }
    }

    private val handler = Handler(Looper.getMainLooper())
    private var lockCooldown = mutableMapOf<String, Long>()

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

        // When user switched away from the session-unlocked app, clear the session
        if (lastForeground != foregroundPkg && sessionUnlockedPackage == lastForeground) {
            Log.d(TAG, "App changed, clearing session for $sessionUnlockedPackage")
            sessionUnlockedPackage = null
            sessionUnlockTime = 0L
        }
        lastForeground = foregroundPkg

        val lockedApps = getLockedApps(this)
        if (foregroundPkg !in lockedApps) return

        // Check session unlock (still valid within window)
        val now = System.currentTimeMillis()
        if (sessionUnlockedPackage == foregroundPkg && now - sessionUnlockTime < SESSION_DURATION_MS) {
            return
        }

        // Debounce: don't spam lock screens
        val lastLock = lockCooldown[foregroundPkg] ?: 0L
        if (now - lastLock < 2000L) return

        lockCooldown[foregroundPkg] = now
        Log.d(TAG, "Locked app in foreground: $foregroundPkg — showing lock screen")
        NativeLockScreenActivity.start(this, foregroundPkg)
    }

    private fun getForegroundApp(): String? {
        return try {
            val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val now = System.currentTimeMillis()
            val stats = usm.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                now - 30000L,
                now
            )
            stats?.maxByOrNull { it.lastTimeUsed }?.packageName
        } catch (e: Exception) {
            Log.e(TAG, "Error getting foreground app: ${e.message}")
            null
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "CMK Security",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Protecting your locked apps"
                setShowBadge(false)
            }
            getSystemService(NotificationManager::class.java)?.createNotificationChannel(channel)
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
            .setContentText("App protection active")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentIntent(pi)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
}
