package com.cmk.cmk_security

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.PointF
import android.util.AttributeSet
import android.view.MotionEvent
import android.view.View
import kotlin.math.sqrt

class PatternLockView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null
) : View(context, attrs) {

    var onPatternComplete: ((List<Int>) -> Unit)? = null

    private val GRID = 3
    private val dots = Array(GRID * GRID) { PointF() }
    private val selectedDots = mutableListOf<Int>()
    private var currentTouch: PointF? = null
    private var hasError = false

    private val dotPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#444466")
        style = Paint.Style.FILL
    }
    private val selectedDotPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#6C63FF")
        style = Paint.Style.FILL
    }
    private val errorDotPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#FF4757")
        style = Paint.Style.FILL
    }
    private val linePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#6C63FF")
        style = Paint.Style.STROKE
        strokeWidth = 6f
        strokeCap = Paint.Cap.ROUND
    }
    private val errorLinePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#FF4757")
        style = Paint.Style.STROKE
        strokeWidth = 6f
        strokeCap = Paint.Cap.ROUND
    }
    private val ringPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#6C63FF")
        style = Paint.Style.STROKE
        strokeWidth = 3f
    }

    override fun onSizeChanged(w: Int, h: Int, oldW: Int, oldH: Int) {
        super.onSizeChanged(w, h, oldW, oldH)
        val cellW = w.toFloat() / GRID
        val cellH = h.toFloat() / GRID
        for (i in dots.indices) {
            val col = i % GRID
            val row = i / GRID
            dots[i] = PointF(cellW * col + cellW / 2f, cellH * row + cellH / 2f)
        }
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)

        val active = if (hasError) errorLinePaint else linePaint
        val activeDot = if (hasError) errorDotPaint else selectedDotPaint

        // Draw connecting lines between selected dots
        for (i in 0 until selectedDots.size - 1) {
            val a = dots[selectedDots[i]]
            val b = dots[selectedDots[i + 1]]
            canvas.drawLine(a.x, a.y, b.x, b.y, active)
        }
        // Line to current touch
        if (selectedDots.isNotEmpty() && currentTouch != null) {
            val last = dots[selectedDots.last()]
            canvas.drawLine(last.x, last.y, currentTouch!!.x, currentTouch!!.y, active)
        }

        // Draw all dots
        for (i in dots.indices) {
            val p = dots[i]
            val isSelected = selectedDots.contains(i)
            val r = if (isSelected) 20f else 14f
            canvas.drawCircle(p.x, p.y, r, if (isSelected) activeDot else dotPaint)
            if (isSelected) {
                canvas.drawCircle(p.x, p.y, r + 8f, if (hasError) errorLinePaint else ringPaint)
            }
        }
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        when (event.action) {
            MotionEvent.ACTION_DOWN, MotionEvent.ACTION_MOVE -> {
                val hit = hitTest(event.x, event.y)
                if (hit != null && !selectedDots.contains(hit)) {
                    selectedDots.add(hit)
                    invalidate()
                }
                currentTouch = PointF(event.x, event.y)
                invalidate()
            }
            MotionEvent.ACTION_UP -> {
                currentTouch = null
                invalidate()
                if (selectedDots.size >= 4) {
                    onPatternComplete?.invoke(selectedDots.toList())
                } else if (selectedDots.isNotEmpty()) {
                    showError()
                    postDelayed({ clearPattern() }, 600)
                }
            }
        }
        return true
    }

    private fun hitTest(x: Float, y: Float): Int? {
        for (i in dots.indices) {
            val d = dots[i]
            val dist = sqrt(((x - d.x) * (x - d.x) + (y - d.y) * (y - d.y)).toDouble()).toFloat()
            if (dist < 40f) return i
        }
        return null
    }

    fun clearPattern() {
        selectedDots.clear()
        currentTouch = null
        hasError = false
        invalidate()
    }

    fun showError() {
        hasError = true
        invalidate()
    }
}
