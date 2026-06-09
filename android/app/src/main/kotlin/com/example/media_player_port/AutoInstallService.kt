package com.example.media_player_port

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

class AutoInstallService : AccessibilityService() {

    companion object {
        private const val TAG = "AutoInstallService"
        var instance: AutoInstallService? = null
        private var hasClickedInstall = false
        private var hasClickedOpen = false
        private var hasClickedUpdate = false

        fun autoClickInstall() {
            instance?.let {
                Log.d(TAG, "Auto-click install triggered")
                it.performInstallClick()
            } ?: Log.e(TAG, "AutoInstallService instance is null")
        }

        fun resetFlags() {
            hasClickedInstall = false
            hasClickedOpen = false
            hasClickedUpdate = false
            Log.d(TAG, "Flags reset: install=$hasClickedInstall, open=$hasClickedOpen, update=$hasClickedUpdate")
        }

        fun autoClickUpdateButton(buttonText: String) {
            instance?.let {
                Log.d(TAG, "Auto-click update button: $buttonText")
                it.clickUpdateButton(buttonText)
            }
        }

        fun checkForUpdateDialog(): Boolean {
            return instance?.findUpdateDialog() ?: false
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.d(TAG, "✅ AutoInstallService connected")

        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPES_ALL_MASK
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                    AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
            notificationTimeout = 100
        }
        setServiceInfo(info)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        event ?: return
        val packageName = event.packageName?.toString() ?: ""

        Log.d(TAG, "Event: ${event.eventType}, Package: $packageName")

        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED,
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                val isInstaller = packageName.contains("packageinstaller") ||
                        packageName == "com.android.packageinstaller" ||
                        packageName == "com.google.android.packageinstaller"

                if (isInstaller) {
                    Log.d(TAG, "📦 Installer window: $packageName")
                    Handler(Looper.getMainLooper()).postDelayed({
                        if (!hasClickedInstall) {
                            checkForInstallDialog()
                        } else if (!hasClickedOpen) {
                            Handler(Looper.getMainLooper()).postDelayed({
                                findAndClickOpenButton()
                            }, 1500)
                        }
                    }, 500)
                } else {
                    // Check install/update dialogs for all other windows
                    checkForInstallDialog()
                    checkAndClickUpdateDialog()
                }

                // Check for installation complete screens
                val className = event.className?.toString() ?: ""
                if (className.contains("InstallSuccess") ||
                    className.contains("InstallFinished") ||
                    className.contains("AppInstalled")
                ) {
                    Log.d(TAG, "🎉 Installation complete screen detected!")
                    Handler(Looper.getMainLooper()).postDelayed({
                        if (hasClickedInstall && !hasClickedOpen) {
                            findAndClickOpenButton()
                        }
                    }, 1000)
                }
            }

            AccessibilityEvent.TYPE_VIEW_CLICKED -> Log.d(TAG, "View clicked")
            else -> Log.d(TAG, "Unhandled event type: ${event.eventType}")
        }
    }

    // ── Install dialog ────────────────────────────────────────────────────────

    private fun checkForInstallDialog() {
        if (hasClickedInstall) return
        val root = rootInActiveWindow ?: return
        findAndClickInstallButton(root)
    }

    private fun findAndClickInstallButton(node: AccessibilityNodeInfo): Boolean {
        val installTexts = listOf("INSTALL", "Install", "install", "OK", "Yes", "Continue")

        for (text in installTexts) {
            val nodes = node.findAccessibilityNodeInfosByText(text)
            for (installNode in nodes) {
                if (installNode.isClickable) {
                    Log.d(TAG, "Found install button: $text")
                    installNode.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                    hasClickedInstall = true
                    return true
                }
            }
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            if (findAndClickInstallButton(child)) return true
        }

        return false
    }

    // ── Open button (post-install) ────────────────────────────────────────────

    private fun findAndClickOpenButton() {
        val root = rootInActiveWindow ?: return
        val openTexts = listOf("OPEN", "Open", "DONE", "Done", "Launch")

        for (text in openTexts) {
            val nodes = root.findAccessibilityNodeInfosByText(text)
            for (node in nodes) {
                if (node.isClickable) {
                    Log.d(TAG, "Found open/done button: $text")
                    node.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                    hasClickedOpen = true
                    return
                }
            }
        }
    }

    // ── Update dialog ─────────────────────────────────────────────────────────

    private fun checkAndClickUpdateDialog() {
        if (hasClickedUpdate) return
        val root = rootInActiveWindow ?: return
        findAndClickUpdateButton(root)
    }

    private fun findUpdateDialog(): Boolean {
        val root = rootInActiveWindow ?: return false
        val updateTexts = listOf("Update", "New version", "Update available", "Download", "Install update")

        for (text in updateTexts) {
            val nodes = root.findAccessibilityNodeInfosByText(text)
            if (nodes.isNotEmpty()) {
                Log.d(TAG, "Update dialog detected with text: $text")
                return true
            }
        }
        return false
    }

    private fun findAndClickUpdateButton(node: AccessibilityNodeInfo): Boolean {
        val updateTexts = listOf("Update", "Update Now", "Update now", "Download", "Install", "Install update")

        for (text in updateTexts) {
            val nodes = node.findAccessibilityNodeInfosByText(text)
            for (updateNode in nodes) {
                if (updateNode.isClickable) {
                    Log.d(TAG, "Found and clicking update button: $text")
                    updateNode.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                    hasClickedUpdate = true
                    return true
                }
            }
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            if (findAndClickUpdateButton(child)) return true
        }

        return false
    }

    // ── Public helpers ────────────────────────────────────────────────────────

    private fun performInstallClick() {
        val root = rootInActiveWindow ?: return
        findAndClickInstallButton(root)
    }

    private fun clickUpdateButton(buttonText: String) {
        val root = rootInActiveWindow ?: return
        val nodes = root.findAccessibilityNodeInfosByText(buttonText)
        for (node in nodes) {
            if (node.isClickable) {
                Log.d(TAG, "Clicking update button: $buttonText")
                node.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                hasClickedUpdate = true
                break
            }
        }
    }

    fun forceCheckForDialog() {
        Log.d(TAG, "Force checking for dialog")
        checkAndClickUpdateDialog()
    }

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    override fun onInterrupt() {
        Log.d(TAG, "AutoInstallService interrupted")
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        Log.d(TAG, "AutoInstallService destroyed")
    }
}