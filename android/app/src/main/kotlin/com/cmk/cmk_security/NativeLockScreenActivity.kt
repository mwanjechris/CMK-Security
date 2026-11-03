package com.cmk.cmk_security

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.GridLayout
import android.widget.LinearLayout
import android.widget.Space
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import java.security.MessageDigest

class NativeLockScreenActivity : AppCompatActivity() {

    companion object {
        const val PREFS_NAME = "cmk_security_lock"
        const val KEY_LOCK_TYPE = "lock_type"
        const val KEY_LOCK_HASH = "lock_hash"
        const val EXTRA_LOCKED_PACKAGE = "locked_package"

        fun start(context: Context, lockedPackage: String) {
            val intent = Intent(context, NativeLockScreenActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                addFlags(Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS)
                putExtra(EXTRA_LOCKED_PACKAGE, lockedPackage)
            }
            context.startActivity(intent)
        }
    }

    private val enteredPin = StringBuilder()
    private lateinit var lockType: String
    private lateinit var lockHash: String
    private lateinit var lockedPackage: String
    private lateinit var dotViews: List<View>
    private lateinit var statusLabel: TextView

    private val PIN_LENGTH = 4

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Read lock credentials from native prefs
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        lockType = prefs.getString(KEY_LOCK_TYPE, "pin") ?: "pin"
        lockHash = prefs.getString(KEY_LOCK_HASH, "") ?: ""
        lockedPackage = intent.getStringExtra(EXTRA_LOCKED_PACKAGE) ?: ""

        if (lockHash.isEmpty()) {
            finish()
            return
        }

        // Window flags to show over lock screen and other apps
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
        @Suppress("DEPRECATION")
        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
        )
        window.statusBarColor = Color.parseColor("#0A0A0F")
        window.navigationBarColor = Color.parseColor("#0A0A0F")

        when (lockType) {
            "pin" -> buildPinScreen()
            "pattern" -> buildPatternScreen()
            "biometric" -> buildBiometricScreen()
            else -> buildPinScreen()
        }
    }

    // ── Block back button ─────────────────────────────────────
    override fun onBackPressed() {
        // Move the locked app to back so CMK Security appears, or go to home
        val homeIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(homeIntent)
    }

    // ── Auth success ──────────────────────────────────────────
    private fun onAuthSuccess() {
        AppMonitorService.sessionUnlock(lockedPackage)
        finish()
    }

    // ──────────────────────────────────────────────────────────
    // PIN Screen
    // ──────────────────────────────────────────────────────────
    private fun buildPinScreen() {
        val root = buildRootLayout()
        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }

        content.addView(makeShieldHeader())
        content.addView(vspace(32))

        statusLabel = TextView(this).apply {
            text = "Enter PIN"
            textSize = 16f
            setTextColor(Color.parseColor("#AAAACC"))
            gravity = Gravity.CENTER
        }
        content.addView(statusLabel)
        content.addView(vspace(32))

        // PIN dots
        val dotsRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
        }
        dotViews = List(PIN_LENGTH) { makeDot(false) }
        dotViews.forEach { dotsRow.addView(it) }
        content.addView(dotsRow)
        content.addView(vspace(48))

        // Number grid
        content.addView(buildNumpad())

        root.addView(content)
        setContentView(root)
    }

    private fun buildNumpad(): GridLayout {
        val grid = GridLayout(this).apply {
            columnCount = 3
            rowCount = 4
            // GridLayout doesn't support gravity; centering is handled by parent LinearLayout
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).also { it.gravity = Gravity.CENTER_HORIZONTAL }
        }
        val digits = listOf("1","2","3","4","5","6","7","8","9","","0","⌫")
        digits.forEachIndexed { idx, d ->
            if (d == "") {
                grid.addView(View(this).apply {
                    layoutParams = GridLayout.LayoutParams().apply {
                        width = dp(80); height = dp(80)
                        setMargins(dp(8), dp(8), dp(8), dp(8))
                    }
                })
            } else {
                grid.addView(makeNumpadButton(d) { handlePinKey(d) })
            }
        }
        return grid
    }

    private fun handlePinKey(key: String) {
        if (key == "⌫") {
            if (enteredPin.isNotEmpty()) {
                enteredPin.deleteCharAt(enteredPin.length - 1)
                updateDots()
            }
            return
        }
        if (enteredPin.length >= PIN_LENGTH) return
        enteredPin.append(key)
        updateDots()
        if (enteredPin.length == PIN_LENGTH) {
            validatePin()
        }
    }

    private fun validatePin() {
        val hash = sha256(enteredPin.toString())
        if (hash == lockHash) {
            onAuthSuccess()
        } else {
            shakeAndReset()
        }
    }

    private fun updateDots() {
        dotViews.forEachIndexed { i, dot ->
            dot.setBackgroundColor(
                if (i < enteredPin.length) Color.parseColor("#6C63FF")
                else Color.parseColor("#333355")
            )
        }
    }

    private fun makeDot(filled: Boolean): View {
        val size = dp(18)
        return View(this).apply {
            setBackgroundColor(if (filled) Color.parseColor("#6C63FF") else Color.parseColor("#333355"))
            val lp = LinearLayout.LayoutParams(size, size)
            lp.setMargins(dp(10), 0, dp(10), 0)
            layoutParams = lp
            // Round it with a clipping path
            post { clipToOutline = true }
            background = ContextCompat.getDrawable(context, android.R.drawable.btn_radio)
                ?: background
        }
    }

    // ──────────────────────────────────────────────────────────
    // Pattern Screen
    // ──────────────────────────────────────────────────────────
    private fun buildPatternScreen() {
        val root = buildRootLayout()
        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }

        content.addView(makeShieldHeader())
        content.addView(vspace(24))

        statusLabel = TextView(this).apply {
            text = "Draw pattern to unlock"
            textSize = 16f
            setTextColor(Color.parseColor("#AAAACC"))
            gravity = Gravity.CENTER
        }
        content.addView(statusLabel)
        content.addView(vspace(32))

        val patternView = PatternLockView(this).apply {
            val size = resources.displayMetrics.widthPixels - dp(80)
            layoutParams = LinearLayout.LayoutParams(size, size).also {
                it.gravity = Gravity.CENTER_HORIZONTAL
            }
            onPatternComplete = { pattern ->
                val key = pattern.joinToString("-")
                val hash = sha256(key)
                if (hash == lockHash) {
                    onAuthSuccess()
                } else {
                    statusLabel.text = "Wrong pattern. Try again."
                    statusLabel.setTextColor(Color.parseColor("#FF4757"))
                    shakeView(this)
                    Handler(Looper.getMainLooper()).postDelayed({
                        statusLabel.text = "Draw pattern to unlock"
                        statusLabel.setTextColor(Color.parseColor("#AAAACC"))
                        this.clearPattern()
                    }, 600)
                }
            }
        }
        content.addView(patternView)
        content.addView(vspace(16))
        content.addView(TextView(this).apply {
            text = "Connect 4+ dots"
            textSize = 12f
            setTextColor(Color.parseColor("#555577"))
            gravity = Gravity.CENTER
        })

        root.addView(content)
        setContentView(root)
    }

    // ──────────────────────────────────────────────────────────
    // Biometric Screen
    // ──────────────────────────────────────────────────────────
    private fun buildBiometricScreen() {
        val root = buildRootLayout()
        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }

        content.addView(makeShieldHeader())
        content.addView(vspace(32))

        statusLabel = TextView(this).apply {
            text = "Touch the fingerprint sensor"
            textSize = 16f
            setTextColor(Color.parseColor("#AAAACC"))
            gravity = Gravity.CENTER
        }
        content.addView(statusLabel)
        content.addView(vspace(32))

        // Fingerprint icon button
        val fingerprintBtn = TextView(this).apply {
            text = "👆"
            textSize = 64f
            gravity = Gravity.CENTER
            isClickable = true
            isFocusable = true
            setOnClickListener { showBiometricPrompt() }
        }
        content.addView(fingerprintBtn)

        root.addView(content)
        setContentView(root)
        showBiometricPrompt()
    }

    private fun showBiometricPrompt() {
        val executor = ContextCompat.getMainExecutor(this)
        val callback = object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                onAuthSuccess()
            }
            override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                if (errorCode != BiometricPrompt.ERROR_USER_CANCELED &&
                    errorCode != BiometricPrompt.ERROR_NEGATIVE_BUTTON) {
                    statusLabel.text = "Authentication failed. Try again."
                    statusLabel.setTextColor(Color.parseColor("#FF4757"))
                }
            }
            override fun onAuthenticationFailed() {
                statusLabel.text = "Not recognized. Try again."
                statusLabel.setTextColor(Color.parseColor("#FFD32A"))
            }
        }

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("CMK Security")
            .setSubtitle("Authenticate to access locked app")
            .setNegativeButtonText("Cancel")
            .setAllowedAuthenticators(
                BiometricManager.Authenticators.BIOMETRIC_STRONG or
                BiometricManager.Authenticators.BIOMETRIC_WEAK
            )
            .build()

        BiometricPrompt(this, executor, callback).authenticate(promptInfo)
    }

    // ──────────────────────────────────────────────────────────
    // Helpers
    // ──────────────────────────────────────────────────────────
    private fun shakeAndReset() {
        statusLabel.text = "Wrong PIN"
        statusLabel.setTextColor(Color.parseColor("#FF4757"))
        vibrate()
        shakeView(statusLabel)
        Handler(Looper.getMainLooper()).postDelayed({
            enteredPin.clear()
            updateDots()
            statusLabel.text = "Enter PIN"
            statusLabel.setTextColor(Color.parseColor("#AAAACC"))
        }, 600)
    }

    private fun shakeView(view: View) {
        view.animate()
            .translationX(-16f).setDuration(50)
            .withEndAction {
                view.animate().translationX(16f).setDuration(50)
                    .withEndAction {
                        view.animate().translationX(-12f).setDuration(50)
                            .withEndAction {
                                view.animate().translationX(0f).setDuration(50).start()
                            }.start()
                    }.start()
            }.start()
    }

    private fun vibrate() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vm = getSystemService(VibratorManager::class.java)
            vm?.defaultVibrator?.vibrate(VibrationEffect.createOneShot(200, VibrationEffect.DEFAULT_AMPLITUDE))
        } else {
            @Suppress("DEPRECATION")
            val v = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                v?.vibrate(VibrationEffect.createOneShot(200, VibrationEffect.DEFAULT_AMPLITUDE))
            } else {
                @Suppress("DEPRECATION")
                v?.vibrate(200)
            }
        }
    }

    private fun sha256(input: String): String {
        val digest = MessageDigest.getInstance("SHA-256")
        val bytes = digest.digest(input.toByteArray(Charsets.UTF_8))
        return bytes.joinToString("") { "%02x".format(it) }
    }

    private fun buildRootLayout(): FrameLayout {
        return FrameLayout(this).apply {
            setBackgroundColor(Color.parseColor("#0A0A0F"))
        }
    }

    private fun makeShieldHeader(): LinearLayout {
        val col = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
        }
        col.addView(TextView(this).apply {
            text = "🔒"
            textSize = 52f
            gravity = Gravity.CENTER
        })
        col.addView(vspace(12))
        col.addView(TextView(this).apply {
            text = "CMK Security"
            textSize = 22f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        })
        return col
    }

    private fun makeNumpadButton(label: String, action: () -> Unit): View {
        return TextView(this).apply {
            text = label
            textSize = if (label == "⌫") 20f else 24f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#1A1A2E"))
            isClickable = true
            isFocusable = true
            setOnClickListener { action() }
            val lp = GridLayout.LayoutParams().apply {
                width = dp(80); height = dp(80)
                setMargins(dp(8), dp(8), dp(8), dp(8))
            }
            layoutParams = lp
            // Circular background
            background = roundedRippleDrawable()
        }
    }

    private fun roundedRippleDrawable(): android.graphics.drawable.Drawable {
        val shape = android.graphics.drawable.GradientDrawable().apply {
            shape = android.graphics.drawable.GradientDrawable.OVAL
            setColor(Color.parseColor("#1A1A2E"))
        }
        return android.graphics.drawable.RippleDrawable(
            android.content.res.ColorStateList.valueOf(Color.parseColor("#6C63FF")),
            shape,
            null
        )
    }

    private fun vspace(heightDp: Int): Space {
        return Space(this).apply {
            minimumHeight = dp(heightDp)
        }
    }

    private fun dp(value: Int): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            value.toFloat(),
            resources.displayMetrics
        ).toInt()
    }
}
