package com.cmk.cmk_security

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.AdaptiveIconDrawable
import android.graphics.drawable.BitmapDrawable
import android.net.Uri
import android.os.Build
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.cmk.cmk_security/app_lock"

    override fun onResume() {
        super.onResume()
        // Restart monitor service on app resume if there are locked apps
        val locked = AppMonitorService.getLockedApps(this)
        if (locked.isNotEmpty()) {
            AppMonitorService.start(this, locked.toList())
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> {
                    try {
                        result.success(getInstalledApps())
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "getAppIcon" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName == null) { result.error("NULL_ARG", "packageName is null", null); return@setMethodCallHandler }
                    result.success(getAppIconBytes(packageName))
                }
                "launchApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName == null) { result.error("NULL_ARG", "packageName is null", null); return@setMethodCallHandler }
                    val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
                    if (launchIntent != null) {
                        startActivity(launchIntent)
                        result.success(true)
                    } else {
                        result.error("NOT_FOUND", "App not found: $packageName", null)
                    }
                }
                "hasUsagePermission" -> result.success(hasUsageStatsPermission())
                "requestUsagePermission" -> {
                    startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                    result.success(null)
                }
                "hasOverlayPermission" -> result.success(Settings.canDrawOverlays(this))
                "requestOverlayPermission" -> {
                    startActivity(Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:$packageName")
                    ))
                    result.success(null)
                }
                "startMonitorService" -> {
                    val packages = call.argument<List<String>>("packages") ?: emptyList()
                    AppMonitorService.start(this, packages)
                    result.success(true)
                }
                "stopMonitorService" -> {
                    AppMonitorService.stop(this)
                    result.success(true)
                }
                "updateLockedApps" -> {
                    val packages = call.argument<List<String>>("packages") ?: emptyList()
                    AppMonitorService.updateLockedApps(this, packages)
                    result.success(true)
                }
                // Called from Flutter after PIN/pattern is configured
                "setLockCredentials" -> {
                    val lockType = call.argument<String>("lockType") ?: ""
                    val hash = call.argument<String>("hash") ?: ""
                    val prefs = getSharedPreferences(
                        NativeLockScreenActivity.PREFS_NAME, Context.MODE_PRIVATE
                    )
                    prefs.edit()
                        .putString(NativeLockScreenActivity.KEY_LOCK_TYPE, lockType)
                        .putString(NativeLockScreenActivity.KEY_LOCK_HASH, hash)
                        .apply()
                    result.success(true)
                }
                // Called from Flutter after successful auth (session unlock)
                "notifyAuthSuccess" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    if (packageName.isNotEmpty()) {
                        AppMonitorService.sessionUnlock(packageName)
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getInstalledApps(): List<HashMap<String, Any?>> {
        val pm = packageManager
        val apps = pm.getInstalledApplications(PackageManager.GET_META_DATA)
        return apps
            .filter { it.flags and ApplicationInfo.FLAG_SYSTEM == 0 || it.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP != 0 }
            .filter { pm.getLaunchIntentForPackage(it.packageName) != null }
            .filter { it.packageName != this.packageName }
            .map { info ->
                hashMapOf<String, Any?>(
                    "packageName" to info.packageName,
                    "appName" to pm.getApplicationLabel(info).toString(),
                    "icon" to getAppIconBytes(info.packageName)
                )
            }
    }

    private fun getAppIconBytes(packageName: String): ByteArray? {
        return try {
            val drawable = packageManager.getApplicationIcon(packageName)
            val bitmap: Bitmap = when {
                drawable is BitmapDrawable -> drawable.bitmap
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && drawable is AdaptiveIconDrawable -> {
                    val bmp = Bitmap.createBitmap(108, 108, Bitmap.Config.ARGB_8888)
                    val canvas = Canvas(bmp)
                    drawable.setBounds(0, 0, canvas.width, canvas.height)
                    drawable.draw(canvas)
                    bmp
                }
                else -> {
                    val bmp = Bitmap.createBitmap(
                        drawable.intrinsicWidth.coerceAtLeast(1),
                        drawable.intrinsicHeight.coerceAtLeast(1),
                        Bitmap.Config.ARGB_8888
                    )
                    val canvas = Canvas(bmp)
                    drawable.setBounds(0, 0, canvas.width, canvas.height)
                    drawable.draw(canvas)
                    bmp
                }
            }
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 80, stream)
            stream.toByteArray()
        } catch (e: Exception) {
            null
        }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }
}
