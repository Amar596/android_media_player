package com.example.media_player_port

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.app.ActivityManager

// class WaulyBroadcastReceiver : BroadcastReceiver() {
//     override fun onReceive(context: Context, intent: Intent) {
//         Log.d("WaulyReceiver", "🔔 Manifest receiver received broadcast!")
//         Log.d("WaulyReceiver", "Action: ${intent.action}")
        
//         val message = intent.getStringExtra("crash_text") ?: "No message"
//         Log.d("WaulyReceiver", "Message: $message")
        
//         // Forward to MainActivity if needed
//         val forwardIntent = Intent(context, MainActivity::class.java).apply {
//             action = intent.action
//             putExtras(intent.extras ?: Bundle())
//             addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
//         }
//         context.startActivity(forwardIntent)
//     }
// }

class WaulyBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val message = intent.getStringExtra("crash_text") ?: "No message"
        
        // Check if app is in foreground
        if (isAppInForeground(context)) {
            // App is visible, send to activity
            sendToActivity(context, message)
        } else {
            // App is in background, just save for later
            saveForLater(context, message)
        }
    }
    
    private fun isAppInForeground(context: Context): Boolean {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val appProcesses = activityManager.runningAppProcesses ?: return false
        
        return appProcesses.any { process ->
            process.processName == context.packageName && 
            process.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND
        }
    }
    
    private fun sendToActivity(context: Context, message: String) {
        val intent = Intent("com.example.UPDATE_EVENT").apply {
            putExtra("message", message)
        }
        // Use LocalBroadcastManager or send to running activity
        context.sendBroadcast(intent)
    }
    
    private fun saveForLater(context: Context, message: String) {
        val prefs = context.getSharedPreferences("WaulyMonitorPrefs", Context.MODE_PRIVATE)
        prefs.edit().putString("pending_message", message).apply()
    }
}