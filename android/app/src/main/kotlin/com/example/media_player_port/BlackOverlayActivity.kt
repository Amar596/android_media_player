package com.example.media_player_port

import android.os.Bundle
import android.view.View
import android.view.WindowManager
import androidx.appcompat.app.AppCompatActivity

class BlackOverlayActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Make it fullscreen and hide system UI
        window.decorView.systemUiVisibility = (
            View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
            View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
            View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
            View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
            View.SYSTEM_UI_FLAG_FULLSCREEN or
            View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
        )
        
        // Keep screen on
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        
        // Simple black view
        val blackView = android.widget.FrameLayout(this)
        blackView.setBackgroundColor(android.graphics.Color.BLACK)
        setContentView(blackView)
        
        // Add a tap listener to close
        blackView.setOnClickListener {
            finish()
        }
    }
    
    override fun onBackPressed() {
        // Close on back button
        super.onBackPressed()
        finish()
    }
}