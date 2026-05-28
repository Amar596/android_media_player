package com.example.media_player_port

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ActivityInfo
import android.content.res.Configuration
import android.os.Build
import android.os.BatteryManager
import android.os.Environment
import android.os.StatFs
import android.provider.Settings
import android.util.DisplayMetrics
import android.util.Log
import android.view.WindowManager
import android.net.Uri
import android.hardware.display.DisplayManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import org.json.JSONObject
import java.net.NetworkInterface
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.CopyOnWriteArrayList
import org.json.JSONArray
import java.io.File
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.app.AlarmManager
import android.app.PendingIntent
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager



class MainActivity : FlutterActivity() {
    private val BRIGHTNESS_CHANNEL = "com.example.app/brightness"
    private val SYSTEM_CHANNEL = "com.example.app/system"
    private val PERMISSIONS_CHANNEL = "com.example.app/permissions"
    private val ORIENTATION_CHANNEL = "com.example.app/orientation"
    private val SYSTEM_INFO_CHANNEL = "com.example.app/system_info"
    private val METHOD_CHANNEL = "port_control"
    private val EVENT_CHANNEL = "com.example.media_player_port/monitoring_events"
    private val CHANNEL = "com.example.media_player/screen"
    private val USB_CHANNEL = "usb_detection"
    private val USB_EVENT_CHANNEL = "usb_detection_events"

    companion object {
        private const val PREFS_NAME = "WaulyMonitorPrefs"
        private const val KEY_EVENT_HISTORY = "event_history"
        private const val METHOD_CHANNEL = "port_control"   
    }
    
    // Custom TAG for logging
    private val TAG = "MainActivity"
    private var isExiting = false

    //private var isRestarting = false
    
    // Method channels
    private lateinit var methodChannel: MethodChannel
    
    // Event channel handlers
    private var eventSink: EventChannel.EventSink? = null
    private var usbEventSink: EventChannel.EventSink? = null
    
    // Message history
    private val messageHistory = CopyOnWriteArrayList<Map<String, Any>>()
    private val maxHistorySize = 100

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Setup all method channels
        setupBrightnessChannel(flutterEngine)
        setupSystemChannel(flutterEngine)
        setupPermissionsChannel(flutterEngine)
        setupOrientationChannel(flutterEngine)
        setupSystemInfoChannel(flutterEngine)
        setupMethodChannel(flutterEngine)
        setupEventChannel(flutterEngine)
        setupScreenChannel(flutterEngine)
        setupUsbChannel(flutterEngine)
        setupMethodChannel(flutterEngine)
        
        // Register Broadcast Receivers
        registerBroadcastReceivers()

        Log.d(TAG, "✅ Flutter Engine configured")
    }

    private val usbReceiver = object : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        when (intent?.action) {
            UsbManager.ACTION_USB_DEVICE_ATTACHED -> {
                val device =
                    intent.getParcelableExtra<UsbDevice>(
                        UsbManager.EXTRA_DEVICE
                    )
                val deviceName =
                    device?.deviceName ?: "Unknown USB"
                Log.d(TAG, "USB ATTACHED: $deviceName")
                usbEventSink?.success(
                    mapOf(
                        "event" to "USB_ATTACHED",
                        "deviceName" to deviceName
                    )
                )
            }

            UsbManager.ACTION_USB_DEVICE_DETACHED -> {
                val device =
                    intent.getParcelableExtra<UsbDevice>(
                        UsbManager.EXTRA_DEVICE
                    )
                val deviceName =
                    device?.deviceName ?: "Unknown USB"
                Log.d(TAG, "USB DETACHED: $deviceName")
                usbEventSink?.success(
                    mapOf(
                        "event" to "USB_DETACHED",
                        "deviceName" to deviceName
                    )
                )
            }
        }
    }
}

    // SYSTEM INFO METHODS
    private fun getTotalRAM(): String {
        return try {
            val memoryInfo = android.app.ActivityManager.MemoryInfo()
            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
            activityManager.getMemoryInfo(memoryInfo)
            val totalMem = memoryInfo.totalMem
            val totalMemGB = totalMem / (1024.0 * 1024.0 * 1024.0)
            String.format("%.1f GB", totalMemGB)
        } catch (e: Exception) {
            e.printStackTrace()
            "Unknown"
        }
    }

    private fun getTotalStorage(): String {
        return try {
            val stat = StatFs(Environment.getDataDirectory().path)
            val bytesAvailable: Long = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
                stat.blockSizeLong * stat.availableBlocksLong
            } else {
                @Suppress("DEPRECATION")
                (stat.blockSize * stat.availableBlocks).toLong()
            }
            val totalGB = bytesAvailable / (1024.0 * 1024.0 * 1024.0)
            String.format("%.1f GB", totalGB)
        } catch (e: Exception) {
            e.printStackTrace()
            "Unknown"
        }
    }

    private fun getMacAddress(interfaceName: String?): String {
        return try {
            val interfaces = NetworkInterface.getNetworkInterfaces()
            while (interfaces.hasMoreElements()) {
                val networkInterface = interfaces.nextElement() as NetworkInterface
                if (interfaceName == null || networkInterface.name == interfaceName) {
                    val macBytes = networkInterface.hardwareAddress ?: continue
                    val macBuilder = StringBuilder()
                    for (i in macBytes.indices) {
                        macBuilder.append(String.format("%02X", macBytes[i]))
                        if (i < macBytes.size - 1) {
                            macBuilder.append(':')
                        }
                    }
                    val mac = macBuilder.toString()
                    if (mac != "00:00:00:00:00:00" && mac != "02:00:00:00:00:00") {
                        return mac
                    }
                }
            }
            "Not Available"
        } catch (e: Exception) {
            e.printStackTrace()
            "Not Available"
        }
    }

    private fun getDisplaySize(): String {
        return try {
            val windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
            val metrics = DisplayMetrics()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val display = windowManager.defaultDisplay
                display?.getMetrics(metrics)
            } else {
                @Suppress("DEPRECATION")
                windowManager.defaultDisplay.getMetrics(metrics)
            }
            "${metrics.widthPixels} x ${metrics.heightPixels}"
        } catch (e: Exception) {
            e.printStackTrace()
            "Unknown"
        }
    }

    private fun getDisplayDensity(): String {
        return try {
            val windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
            val metrics = DisplayMetrics()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val display = windowManager.defaultDisplay
                display?.getMetrics(metrics)
            } else {
                @Suppress("DEPRECATION")
                windowManager.defaultDisplay.getMetrics(metrics)
            }
            "${metrics.densityDpi} dpi"
        } catch (e: Exception) {
            e.printStackTrace()
            "Unknown"
        }
    }

    private fun getBatteryLevel(): Int {
        return try {
            val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
            batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        } catch (e: Exception) {
            e.printStackTrace()
            -1
        }
    }

    private fun getCurrentBrightness(): Float {
        return try {
            Settings.System.getInt(contentResolver, Settings.System.SCREEN_BRIGHTNESS) / 255.0f
        } catch (e: Settings.SettingNotFoundException) {
            e.printStackTrace()
            0.5f
        }
    }

    private fun setScreenBrightness(brightness: Double): Boolean {
        return try {
            val window = window ?: return false
            val layoutParams = window.attributes
            layoutParams.screenBrightness = brightness.toFloat()
            window.attributes = layoutParams
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun openBrightnessSettings() {
        val intent = Intent(Settings.ACTION_DISPLAY_SETTINGS)
        startActivity(intent)
    }

    private fun checkWriteSettingsPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.System.canWrite(this)
        } else {
            true
        }
    }

    private fun requestWriteSettingsPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!Settings.System.canWrite(this)) {
                val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS)
                intent.data = Uri.parse("package:$packageName")
                startActivity(intent)
            }
        }
    }

    // Orientation methods
    private fun setPortraitOrientation(): Boolean {
        return try {
            requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB) {
                recreate()
            }
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun setLandscapeOrientation(): Boolean {
        return try {
            requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB) {
                recreate()
            }
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun setAutoOrientation(): Boolean {
        return try {
            requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB) {
                recreate()
            }
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun getCurrentOrientation(): String {
        return when (resources.configuration.orientation) {
            Configuration.ORIENTATION_PORTRAIT -> "portrait"
            Configuration.ORIENTATION_LANDSCAPE -> "landscape"
            else -> "auto"
        }
    }

    private fun forceOrientation(orientation: Int): Boolean {
        return try {
            requestedOrientation = orientation
            val configuration = resources.configuration
            if (orientation == ActivityInfo.SCREEN_ORIENTATION_PORTRAIT) {
                configuration.orientation = Configuration.ORIENTATION_PORTRAIT
            } else if (orientation == ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE) {
                configuration.orientation = Configuration.ORIENTATION_LANDSCAPE
            }
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB) {
                recreate()
            }
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun setupBrightnessChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BRIGHTNESS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getBrightness" -> {
                        val brightness = getCurrentBrightness()
                        result.success(brightness.toDouble())
                    }
                    "setBrightness" -> {
                        val brightness = call.argument<Double>("brightness") ?: 0.5
                        val success = setScreenBrightness(brightness)
                        result.success(success)
                    }
                    "isBrightnessAvailable" -> {
                        result.success(true)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }

    private fun setupSystemChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SYSTEM_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openBrightnessSettings" -> {
                        openBrightnessSettings()
                        result.success(true)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }

    private fun setupPermissionsChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSIONS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkWriteSettingsPermission" -> {
                        val hasPermission = checkWriteSettingsPermission()
                        result.success(hasPermission)
                    }
                    "requestWriteSettingsPermission" -> {
                        requestWriteSettingsPermission()
                        result.success(true)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }

    private fun setupOrientationChannel(flutterEngine: FlutterEngine) {
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ORIENTATION_CHANNEL)
        .setMethodCallHandler { call, result ->
            when (call.method) {

                "setOrientation" -> {
                    val orientation = call.argument<Int>("orientation") ?: 1
                    Log.d("ROTATION", "Setting orientation to: $orientation")
                    requestedOrientation = orientation
                    Log.d("ROTATION", "requestedOrientation set: $requestedOrientation")
                    result.success(true)
                }

                "getDeviceInfo" -> {
                    val config = resources.configuration
                    val isTV =
                        packageManager.hasSystemFeature("android.hardware.type.television") ||
                        packageManager.hasSystemFeature("android.software.leanback")
                    val info = mapOf(
                        "isTV"                 to isTV,
                        "currentOrientation"   to config.orientation,
                        "requestedOrientation" to requestedOrientation,
                    )
                    Log.d("ROTATION", "requestedOrientation set: $requestedOrientation")
                    result.success(info)
                }

                else -> result.notImplemented()
            }
        }
    }
    

    private fun setupMethodChannel(flutterEngine: FlutterEngine) {
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
        methodChannel.setMethodCallHandler { call, result ->
            Log.d(TAG, "📞 Method called: ${call.method}")
            when (call.method) {
                "getWaulyStatus"     -> result.success(getWaulyStatus())
                "loadMessageHistory" -> result.success(loadMessageHistory())
                "saveMessageHistory" -> {
                    saveMessageHistory(call.argument("history"))
                    result.success(null)
                }
                "clearWaulyData"  -> { clearWaulyData(); result.success(null) }
                "testConnection"  -> testConnection(result)
                "sendSelfTest"    -> sendSelfTest(result)
                "getEvents"       -> result.success(getEvents())
                "getSystemInfo"   -> result.success(getSystemInfo())
                "getDeviceStatus" -> result.success(getDeviceStatus())
                "ping"            -> result.success("pong from Android")

                "getRegisteredMethods" -> {
                    val methods = listOf(
                        "getWaulyStatus", "loadMessageHistory", "saveMessageHistory",
                        "clearWaulyData", "testConnection", "sendSelfTest", "getEvents",
                        "getSystemInfo", "getDeviceStatus", "ping", "getStorageInfo"
                    )
                    result.success(methods)
                }

                // ✅ ADD THIS
                "getStorageInfo"  -> {
                    Log.d(TAG, "📦 getStorageInfo called via METHOD_CHANNEL")
                    try {
                        val storageResults = mutableListOf<Map<String, Any>>()

                        // Internal
                        val intStat   = StatFs(Environment.getDataDirectory().path)
                        val intTotal  = intStat.blockCountLong * intStat.blockSizeLong
                        val intFree   = intStat.availableBlocksLong * intStat.blockSizeLong
                        storageResults.add(mapOf(
                            "label" to "Internal",
                            "total" to intTotal,
                            "free"  to intFree,
                            "used"  to (intTotal - intFree),
                            "path"  to Environment.getDataDirectory().path
                        ))

                        // External / USB
                        getExternalFilesDirs(null)
                            .filterNotNull()
                            .forEachIndexed { index, dir ->
                                try {
                                    val stat  = StatFs(dir.path)
                                    val total = stat.blockCountLong * stat.blockSizeLong
                                    val free  = stat.availableBlocksLong * stat.blockSizeLong
                                    if (total > 0) {
                                        storageResults.add(mapOf(
                                            "label" to if (index == 0) "SD Card"
                                                    else "USB Drive $index",
                                            "total" to total,
                                            "free"  to free,
                                            "used"  to (total - free),
                                            "path"  to dir.path
                                        ))
                                    }
                                } catch (e: Exception) {
                                    Log.e(TAG, "External storage error: ${e.message}")
                                }
                            }

                        Log.d(TAG, "📦 Returning ${storageResults.size} items")
                        result.success(storageResults)
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ getStorageInfo error: ${e.message}")
                        result.error("STORAGE_ERROR", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }


    private fun setupEventChannel(flutterEngine: FlutterEngine) {
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                    Log.d(TAG, "🎧 Event channel listening started")
                    eventSink = sink
                    
                    // Send last 10 messages from history when listener attaches
                    sendRecentMessages()
                }

                override fun onCancel(arguments: Any?) {
                    Log.d(TAG, "🎧 Event channel listening cancelled")
                    eventSink = null
                }
            }
        )
    }

    private fun setupUsbChannel(flutterEngine: FlutterEngine) {
    MethodChannel(
        flutterEngine.dartExecutor.binaryMessenger,
        USB_CHANNEL
    ).setMethodCallHandler { call, result ->

        when (call.method) {

            "getPlatformVersion" -> {
                result.success("Android")
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    EventChannel(
        flutterEngine.dartExecutor.binaryMessenger,
        USB_EVENT_CHANNEL
    ).setStreamHandler(object : EventChannel.StreamHandler {
        override fun onListen(
            arguments: Any?,
            events: EventChannel.EventSink?
        ) {
            usbEventSink = events
            val filter = IntentFilter()
            filter.addAction(
                UsbManager.ACTION_USB_DEVICE_ATTACHED
            )
            filter.addAction(
                UsbManager.ACTION_USB_DEVICE_DETACHED
            )
            registerReceiver(usbReceiver, filter)
            Log.d(TAG, "USB Receiver Registered")
        }

        override fun onCancel(arguments: Any?) {
            try {
                unregisterReceiver(usbReceiver)
            } catch (e: Exception) {
                Log.e(TAG, "USB Receiver unregister error")
            }
            usbEventSink = null
        }
    })
    }

    // Update the waulyBroadcastReceiver in MainActivity to have more prominent logging
    private val waulyBroadcastReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            
            if (intent == null) {
                Log.e(TAG, "❌❌❌ Intent is null")
                return
            }
            
            val action = intent.action ?: "null"
            Log.e(TAG, "📋📋📋 Action: $action")
            
            // Log all extras
            val bundle = intent.extras
            if (bundle != null) {
                Log.e(TAG, "📋 Extras (${bundle.size()} items):")
                bundle.keySet().forEach { key ->
                    val value = bundle.get(key)
                    Log.e(TAG, "  🔑 $key = $value")
                }
            } else {
                Log.e(TAG, "📋 No extras")
            }
            
            // Handle the message
            if (action == "com.signalr.TESTCRASH_CRASH_EVENT") {
                handleWaulyMessage(intent)
            }
        }
    }

    private fun setupScreenChannel(flutterEngine: FlutterEngine) {
    Log.d(TAG, "🔧 Setting up Screen Channel...")
    
    try {
        val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.media_player/screen")
        
        methodChannel.setMethodCallHandler { call, result ->
            Log.d(TAG, "📱 Screen channel method called: ${call.method}")
            
            try {
                when (call.method) {
                    "turnOffScreen" -> {
                        Log.d(TAG, "➡️ Handling turnOffScreen")
                        turnOffScreen(result)
                    }
                    "isScreenOn" -> {
                        Log.d(TAG, "➡️ Handling isScreenOn")
                        isScreenOn(result)
                    }
                    "hasOverlayPermission" -> {
                        Log.d(TAG, "➡️ Handling hasOverlayPermission")
                        hasOverlayPermission(result)
                    }
                    "requestOverlayPermission" -> {
                        Log.d(TAG, "➡️ Handling requestOverlayPermission")
                        requestOverlayPermission(result)
                    }
                    "showBlackOverlay" -> {
                        Log.d(TAG, "➡️ Handling showBlackOverlay")
                        showBlackOverlay(result)
                    }
                    "test" -> {
                        Log.d(TAG, "✅ Test method called successfully")
                        result.success(true)  // Make sure this returns success
                    }
                    else -> {
                        Log.d(TAG, "❌ Unknown method: ${call.method}")
                        result.notImplemented()
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "💥 Error handling ${call.method}: ${e.message}")
                e.printStackTrace()
                result.error("ERROR", e.message, null)
            }
        }
        
        Log.d(TAG, "✅ Screen Channel setup complete")
        
        // Immediately test if the channel is working
        Handler(Looper.getMainLooper()).postDelayed({
            testScreenChannel()
        }, 2000)
        
    } catch (e: Exception) {
        Log.e(TAG, "❌ Failed to setup screen channel: ${e.message}")
        e.printStackTrace()
    }
    }

   private fun testScreenChannel() {
    Log.d(TAG, "🧪 Testing screen channel from native side...")
    // This is just to verify the channel is registered
    }

    // Add these new methods for permission handling
    private fun hasOverlayPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            result.success(Settings.canDrawOverlays(this))
        } else {
            result.success(true) // Older versions don't need this permission
        }
    }

    // Add this to your MainActivity.kt
    private fun sendCecPowerOff(result: MethodChannel.Result) {
        try {
            // This requires system-level access - won't work for regular apps
            val hdmiControlService = getSystemService("hdmi_control") as? Any
            if (hdmiControlService != null) {
                // Use reflection to call CEC methods (requires system privileges)
                val method = hdmiControlService.javaClass.getMethod("sendStandby", Int::class.java)
                method.invoke(hdmiControlService, 0)
                result.success(true)
            } else {
                result.error("CEC_UNAVAILABLE", "HDMI-CEC not available", null)
            }
        } catch (e: Exception) {
            result.error("CEC_ERROR", e.message, null)
        }
    }

    private fun startScreenSaver(result: MethodChannel.Result) {
        try {
            // This just dims/blank the screen temporarily
            val window = window
            val params = window.attributes
            params.screenBrightness = 0.01f  // Minimum brightness
            window.attributes = params
            
            // Hide all content
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            
            result.success(true)
        } catch (e: Exception) {
            result.error("SCREENSAVER_ERROR", e.message, null)
        }
    }

    private fun showBlackOverlay(result: MethodChannel.Result) {
        try {
            // Create a transparent activity or dialog
            val intent = Intent(this, BlackOverlayActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or 
                        Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("OVERLAY_ERROR", e.message, null)
        }
    }

    private fun requestOverlayPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!Settings.canDrawOverlays(this)) {
                val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
                intent.data = Uri.parse("package:$packageName")
                startActivity(intent)
                result.success(true)
            } else {
                result.success(false) // Already have permission
            }
        } else {
            result.success(false) // Not needed
        }
    }

    // Update handleWaulyMessage to log when it's called
    private fun handleWaulyMessage(intent: Intent) {
        Log.d(TAG, "📨 handleWaulyMessage CALLED!")
        
        val timestamp = getCurrentTimestamp()
        val message = intent.getStringExtra("crash_text") ?: "No message"
        
        //Log.d(TAG, "📨 Message content: $message")

        // Extract last active time if present in the message
        var lastActiveTime = timestamp
        if (message.contains("Last Active:")) {
            val pattern = "Last Active: (\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}\\.\\d{3})".toRegex()
            val matchResult = pattern.find(message)
            lastActiveTime = matchResult?.groupValues?.get(1) ?: timestamp
        }
    
        // Store in SharedPreferences for later use
        val sharedPref = getSharedPreferences("WaulyMonitorPrefs", Context.MODE_PRIVATE)
        sharedPref.edit().putString("last_active_time", lastActiveTime).apply()

        // FILTER OUT background events
        if (message.contains("BACKGROUND") || message.contains("ALIVE")) {
        Log.d(TAG, "⏭️ Filtering out unwanted event: $message")
        return  // Don't process this message
        }
        
            // Determine message type based on content
            val type = when {
                message.contains("RUNNING") -> "running"
                message.contains("STARTED") -> "started"
                message.contains("STOPPED") -> "stopped"
                message.contains("HEARTBEAT") -> "heartbeat"
                message.contains("TEST") -> "test"
                message.contains("CRASH") -> "crash"
                else -> "info"
            }
        
        val eventData = mapOf(
            "type" to type,
            "message" to message,
            "timestamp" to timestamp,
            "lastActiveTime" to lastActiveTime
        )
        
        addToHistory(eventData)
        sendToFlutter(eventData)
        
        Log.d(TAG, "✅ Wauly message handled: $type - ${message.take(50)}...")
    }

    private fun handleWaulyMessageWithType(intent: Intent, type: String) {
        val timestamp = getCurrentTimestamp()
        val message = intent.getStringExtra("message") ?: "Wauly $type event"
        val extras = extractExtras(intent)
        
        val eventData = mapOf(
            "type" to type,
            "message" to message,
            "timestamp" to timestamp,
            "extras" to extras
        )
        
        addToHistory(eventData)
        sendToFlutter(eventData)
        
        Log.d(TAG, "📨 Wauly message handled: $type - $message")
    }

    private fun handleGenericBroadcast(intent: Intent) {
        val action = intent.action ?: return
        val timestamp = getCurrentTimestamp()
        val extras = extractExtras(intent)
        
        val eventData = mapOf(
            "type" to "broadcast",
            "message" to "Broadcast: $action",
            "timestamp" to timestamp,
            "extras" to extras
        )
        
        addToHistory(eventData)
        sendToFlutter(eventData)
    }

    private fun extractExtras(intent: Intent): Map<String, Any> {
        val extras = mutableMapOf<String, Any>()
        intent.extras?.keySet()?.forEach { key ->
            intent.extras?.get(key)?.let { value ->
                extras[key] = value.toString()
            }
        }
        return extras
    }

    private fun registerBroadcastReceivers() {
        try {
            Log.d(TAG, "=== REGISTERING BROADCAST RECEIVERS ===")
            
            val filter = IntentFilter().apply {
                // Add ONLY the action that's actually being sent
                addAction("com.signalr.TESTCRASH_CRASH_EVENT")
            }
            
            // Log the filter
            Log.d(TAG, "📋 IntentFilter actions:")
            filter.actionsIterator().forEach { action ->
                Log.d(TAG, "  📋 $action")
            }
            
            // Register with RECEIVER_EXPORTED to receive from other apps
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(waulyBroadcastReceiver, filter, Context.RECEIVER_EXPORTED)
                Log.d(TAG, "✅ Registered with RECEIVER_EXPORTED (API 33+)")
            } else {
                // Pre-API 33
                registerReceiver(waulyBroadcastReceiver, filter)
                Log.d(TAG, "✅ Registered with legacy method (API < 33)")
            }
            
            // Also add a manifest receiver as backup
            Log.d(TAG, "======================================")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to register receivers: ${e.message}")
            e.printStackTrace()
        }

        // Add verification
        verifyReceiverRegistration()
    }

    // Add this to verify the receiver is actually registered
    private fun verifyReceiverRegistration() {
        try {
            val pm = packageManager
            val intent = Intent("com.signalr.TESTCRASH_CRASH_EVENT")
            val receivers = pm.queryBroadcastReceivers(intent, 0)
            
            Log.d(TAG, "=== RECEIVER VERIFICATION ===")
            Log.d(TAG, "Receivers for com.signalr.TESTCRASH_CRASH_EVENT:")
            if (receivers.isEmpty()) {
                Log.d(TAG, "❌ No receivers found - check manifest declaration")
            } else {
                receivers.forEach { info ->
                    Log.d(TAG, "✅ ${info.activityInfo.packageName}/${info.activityInfo.name}")
                    Log.d(TAG, "   Permission: ${info.activityInfo.permission}")
                }
            }
            
            // Check if our receiver is in the list
            val ourReceiver = receivers.any { 
                it.activityInfo.packageName == packageName 
            }
            Log.d(TAG, "Our receiver registered: $ourReceiver")
            Log.d(TAG, "=============================")
        } catch (e: Exception) {
            Log.e(TAG, "Verification failed: ${e.message}")
        }
    }

    private fun registerWaulyReceiver() {
        try {
            val filter = IntentFilter().apply {
                addAction("com.signalr.TESTCRASH_CRASH_EVENT")
            }
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(waulyBroadcastReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                registerReceiver(waulyBroadcastReceiver, filter)
            }
            
            Log.d(TAG, "✅ Wauly broadcast receiver registered")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to register Wauly receiver: ${e.message}")
        }
    }

    private fun sendToFlutter(event: Map<String, Any>) {
        try {
            eventSink?.success(event)
            //Log.d(TAG, "📤 Event sent to Flutter: ${event["type"]}")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to send event to Flutter: ${e.message}")
        }
    }

    private fun sendRecentMessages() {
        val recentMessages = messageHistory.take(10)
        recentMessages.forEach { message ->
            sendToFlutter(message)
        }
    }

    private fun getWaulyStatus(): Map<String, Any> {
        val lastMessage = messageHistory.firstOrNull()
        
        return mapOf(
            "lastMessage" to (lastMessage?.get("message") ?: "No messages"),
            "lastMessageTime" to (lastMessage?.get("timestamp") ?: getCurrentTimestamp()),
            "lastActiveTime" to getLastActiveTime(),
            "appStatus" to determineAppStatus(),
            "messageCount" to messageHistory.size
        )
    }

    private fun getLastActiveTime(): String {
    val sharedPref = getSharedPreferences("WaulyMonitorPrefs", Context.MODE_PRIVATE)
    return sharedPref.getString("last_active_time", "N/A") ?: "N/A" 
    }

    private fun determineAppStatus(): String {
        val lastMessage = messageHistory.firstOrNull()
        val type = lastMessage?.get("type") as? String ?: return "UNKNOWN"

        return when (type) {
            "started" -> "STARTED"  // Explicitly show when it started
            "alive", "heartbeat", "running" -> "RUNNING"
            "stopped" -> "STOPPED"
            "background" -> "BACKGROUND"
            "test" -> "TESTING"
            "error" -> "ERROR"
            else -> "UNKNOWN"
        }
    }

    private fun loadMessageHistory(): String {
        return try {
            val history = messageHistory.map { event ->
                mapOf(
                    "message" to (event["message"] ?: ""),
                    "timestamp" to (event["timestamp"] ?: ""),
                    "type" to (event["type"] ?: "info")
                )
            }
            JSONObject(mapOf("history" to history)).toString()
        } catch (e: Exception) {
            "[]"
        }
    }

    private fun saveMessageHistory(historyJson: String?) {
        // Implement if you want to persist history
        Log.d(TAG, "💾 Saving message history")
    }

    private fun clearWaulyData() {
        messageHistory.clear()
        Log.d(TAG, "🧹 Cleared all wauly data")
    }

    private fun testConnection(result: Result) {
        val response = mapOf(
            "success" to true,
            "timestamp" to getCurrentTimestamp(),
            "message" to "Connection test successful",
            "listening" to (eventSink != null)
        )
        result.success(response)
    }

    private fun sendSelfTest(result: Result) {
        // Generate test events
        val testEvents = listOf(
            mapOf(
                "type" to "test",
                "message" to "Self-test started",
                "timestamp" to getCurrentTimestamp()
            ),
            mapOf(
                "type" to "alive",
                "message" to "Wauly service is alive",
                "timestamp" to getCurrentTimestamp()
            ),
            mapOf(
                "type" to "heartbeat",
                "message" to "Heartbeat received",
                "timestamp" to getCurrentTimestamp()
            )
        )
        
        testEvents.forEach { event ->
            addToHistory(event)
            sendToFlutter(event)
        }
        
        result.success(testEvents)
    }

    private fun getEvents(): List<Map<String, Any>> {
        return messageHistory.take(50)
    }

    private fun getSystemInfo(): Map<String, Any> {
        return mapOf(
            "model" to Build.MODEL,
            "manufacturer" to Build.MANUFACTURER,
            "version" to Build.VERSION.RELEASE,
            "sdk" to Build.VERSION.SDK_INT
        )
    }

    private fun getDeviceStatus(): Map<String, Any> {
        return mapOf(
            "isListening" to (eventSink != null),
            "messageCount" to messageHistory.size,
            "lastEvent" to (messageHistory.firstOrNull() ?: emptyMap<String, Any>())
        )
    }

    private fun getCurrentTimestamp(): String {
        val sdf = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())
        return sdf.format(Date())
    }

    override fun onDestroy() {
        Log.d(TAG, "💥 Activity destroyed, isExiting: $isExiting")
        
        // Unregister broadcast receiver
        try {
            unregisterReceiver(waulyBroadcastReceiver)
        } catch (e: Exception) {
            Log.e(TAG, "Error unregistering receiver: ${e.message}")
        }
        
        // Final cleanup
        releaseAllResources()
        
        super.onDestroy()
    }

    private fun checkBroadcastCapability() {
        try {
            // Log all intent filters your app is registered for
            val pm = packageManager
            val intent = Intent("com.signalr.TESTCRASH_CRASH_EVENT")
            val resolveInfo = pm.queryBroadcastReceivers(intent, 0)
            
            Log.d(TAG, "=== BROADCAST DIAGNOSTICS ===")
            Log.d(TAG, "Receivers registered for com.signalr.TESTCRASH_CRASH_EVENT:")
            if (resolveInfo.isEmpty()) {
                Log.d(TAG, "  ❌ None found - your app is NOT registered for this action")
            } else {
                resolveInfo.forEach { info ->
                    Log.d(TAG, "  ✅ ${info.activityInfo.packageName}/${info.activityInfo.name}")
                }
            }
            
            // Check if your app is in the list
            val ourPackage = packageName
            val isRegistered = resolveInfo.any { it.activityInfo.packageName == ourPackage }
            Log.d(TAG, "Our package ($ourPackage) registered: $isRegistered")
            
            // Check manifest receiver declarations - SIMPLIFIED VERSION
            Log.d(TAG, "Checking manifest receivers:")
            try {
                // Use queryBroadcastReceivers again to get the filter info
                val receiverInfo = pm.queryBroadcastReceivers(intent, 0)
                if (receiverInfo.isNotEmpty()) {
                    receiverInfo.forEach { info ->
                        if (info.activityInfo.packageName == ourPackage) {
                            Log.d(TAG, "  📱 Receiver: ${info.activityInfo.name}")
                            Log.d(TAG, "    ✅ Registered for TESTCRASH_CRASH_EVENT (via query)")
                        }
                    }
                } else {
                    Log.d(TAG, "  No manifest receivers found via query")
                }
            } catch (e: Exception) {
                Log.e(TAG, "  Error checking manifest receivers: ${e.message}")
            }
            
            Log.d(TAG, "=============================")
        } catch (e: Exception) {
            Log.e(TAG, "Error checking broadcast capability: ${e.message}")
        }
    }

    // Add this method to send a test broadcast from within your app
    private fun sendSelfTestBroadcast() {
        try {
            Log.d(TAG, "=== SENDING SELF-TEST BROADCAST ===")
            val intent = Intent("com.signalr.TESTCRASH_CRASH_EVENT").apply {
                putExtra("crash_text", "SELF-TEST from Media Player at ${getCurrentTimestamp()}")
                `package` = packageName  // Target only our own app
            }
            
            // Send as ordered broadcast to see if any receiver responds
            sendOrderedBroadcast(intent, null, object : BroadcastReceiver() {
                override fun onReceive(context: Context?, intent: Intent?) {
                    val resultCode = resultCode
                    val resultData = resultData
                    Log.d(TAG, "📬 Ordered broadcast result - Code: $resultCode, Data: $resultData")
                }
            }, null, 0, null, null)
            
            Log.d(TAG, "✅ Self-test broadcast sent")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to send self-test broadcast: ${e.message}")
        }
    }

    // Add this method to save history
    private fun saveHistoryToPrefs() {
        try {
            val sharedPref = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val editor = sharedPref.edit()
            
            // Convert history to JSON string
            val historyList = messageHistory.map { event ->
                JSONObject(event as Map<*, *>).toString()
            }
            
            val historyJson = JSONArray(historyList).toString()
            editor.putString(KEY_EVENT_HISTORY, historyJson)
            editor.apply()
            
            Log.d(TAG, "💾 History saved to SharedPreferences")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to save history: ${e.message}")
        }
    }

    // Add this method to load history
    private fun loadHistoryFromPrefs() {
        try {
            val sharedPref = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val historyJson = sharedPref.getString(KEY_EVENT_HISTORY, null)
            
            if (historyJson != null) {
                val historyArray = JSONArray(historyJson)
                messageHistory.clear()
                
                for (i in 0 until historyArray.length()) {
                    val eventJson = historyArray.getString(i)
                    val event = JSONObject(eventJson)
                    
                    val eventMap = mapOf(
                        "type" to event.getString("type"),
                        "message" to event.getString("message"),
                        "timestamp" to event.getString("timestamp"),
                        "lastActiveTime" to (event.optString("lastActiveTime") ?: "")
                    )
                    messageHistory.add(eventMap)
                }
                
                Log.d(TAG, "📂 Loaded ${messageHistory.size} events from SharedPreferences")
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to load history: ${e.message}")
        }
    }
    
    private fun addToHistory(event: Map<String, Any>) {
        messageHistory.add(0, event)
        
        // Keep only last 100 messages
        while (messageHistory.size > maxHistorySize) {
            messageHistory.removeAt(messageHistory.size - 1)
        }
        
        // Save to SharedPreferences whenever history changes
        saveHistoryToPrefs()
    }

    private fun saveHistoryToFile() {
        try {
            val historyList = messageHistory.map { event ->
                mapOf(
                    "type" to (event["type"] ?: ""),
                    "message" to (event["message"] ?: ""),
                    "timestamp" to (event["timestamp"] ?: ""),
                    "lastActiveTime" to (event["lastActiveTime"] ?: "")
                )
            }
            
            val json = JSONObject(mapOf("history" to historyList)).toString()
            
            val file = File(filesDir, "wauly_history.json")
            file.writeText(json)
            
            Log.d(TAG, "💾 History saved to file: ${file.absolutePath}")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to save history to file: ${e.message}")
        }
    }

    private fun loadHistoryFromFile() {
        try {
            val file = File(filesDir, "wauly_history.json")
            if (file.exists()) {
                val json = file.readText()
                val jsonObject = JSONObject(json)
                
                if (jsonObject.has("history")) {
                    val historyArray = jsonObject.getJSONArray("history")
                    messageHistory.clear()
                    
                    for (i in 0 until historyArray.length()) {
                        val eventJson = historyArray.getJSONObject(i)
                        val eventMap = mapOf(
                            "type" to eventJson.getString("type"),
                            "message" to eventJson.getString("message"),
                            "timestamp" to eventJson.getString("timestamp"),
                            "lastActiveTime" to (eventJson.optString("lastActiveTime") ?: "")
                        )
                        messageHistory.add(eventMap)
                    }
                    
                    Log.d(TAG, "📂 Loaded ${messageHistory.size} events from file")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to load history from file: ${e.message}")
        }
    }

    private fun turnOffScreen(result: MethodChannel.Result) {
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            
            // For Android 6.0+ (API 23+), we need special permission
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (Settings.canDrawOverlays(this)) {
                    // Use PowerManager to turn off screen
                    if (powerManager.isInteractive) {
                        // This requires DEVICE_POWER permission which normal apps don't have
                        // Alternative: Use wake lock to simulate screen off
                        val wakeLock = powerManager.newWakeLock(
                            PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK,
                            "MediaPlayer:ScreenOff"
                        )
                        wakeLock.acquire()
                        // Release after delay
                        android.os.Handler(mainLooper).postDelayed({
                            if (wakeLock.isHeld) {
                                wakeLock.release()
                            }
                        }, 5000)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                } else {
                    result.error("PERMISSION_DENIED", "Overlay permission required", null)
                }
            } else {
                // For older Android versions
                if (powerManager.isScreenOn) {
                    // Use reflection or other methods
                    result.success(false)
                }
            }
        } catch (e: Exception) {
            result.error("TURN_OFF_ERROR", e.message, null)
        }
    }

    private fun isScreenOn(result: MethodChannel.Result) {
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT_WATCH) {
                result.success(powerManager.isInteractive)
            } else {
                @Suppress("DEPRECATION")
                result.success(powerManager.isScreenOn)
            }
        } catch (e: Exception) {
            result.success(true)
        }
    }

    override fun onBackPressed() {
    Log.d(TAG, "🔙 Back pressed - exiting app")
    isExiting = true
    
    // Clean up
    try {
        unregisterReceiver(waulyBroadcastReceiver)
    } catch (e: Exception) {
        // Ignore
    }
    
    eventSink = null
    saveHistoryToPrefs()
    
    // Finish all activities
    finishAffinity()
    }

    override fun onResume() {
    super.onResume()
    // Reset exit flag when app comes to foreground
    isExiting = false
    }

   override fun finish() {
    Log.d(TAG, "🏁 Finishing activity")
    
    // Release all resources
    releaseAllResources()
    
    super.finish()
    }  


    private fun cleanupBeforeExit() {
    Log.d(TAG, "🧹 Cleaning up before exit")
    
    // Unregister receivers
    try {
        unregisterReceiver(waulyBroadcastReceiver)
    } catch (e: Exception) {
        Log.e(TAG, "Error unregistering receiver: ${e.message}")
    }
    
    // Clear event sink
    eventSink = null
    
    // Save data
    saveHistoryToPrefs()
    
    // Stop any running handlers
    // mainHandler.removeCallbacksAndMessages(null)
    }

    private fun releaseAllResources() {
    Log.d(TAG, "🔄 Releasing all resources")
    
    // Clear method channel handlers
    try {
        // If you have any method channels stored as properties, set them to null
        // methodChannel.setMethodCallHandler(null)
    } catch (e: Exception) {
        // Ignore
    }
    
    // Clear event sink
    eventSink = null
    
    // Force garbage collection hint
    System.gc()
    }
}