package com.onnetwork.hrms.app

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Draw behind the status and navigation bars on every Android
        // version, as Android 15 and later already require. Not
        // androidx's enableEdgeToEdge(): it sets the bars' colours through
        // Window.setStatusBarColor and setNavigationBarColor, which Android
        // 15 deprecates. The bars are made clear from Dart instead.
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // The app's version and ID, and the way to its store page, for the
        // update check and the profile.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "railway_hrms/app_info")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "info" -> {
                        val info = packageManager.getPackageInfo(packageName, 0)
                        val build = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                            info.longVersionCode
                        } else {
                            @Suppress("DEPRECATION")
                            info.versionCode.toLong()
                        }
                        result.success(
                            mapOf(
                                "version" to (info.versionName ?: ""),
                                "build" to build.toString(),
                                "id" to packageName,
                            ),
                        )
                    }
                    "openStore" -> result.success(openStore(call.argument<String>("url")))
                    else -> result.notImplemented()
                }
            }
        // Reports and other files the app makes, saved to Downloads.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "railway_hrms/downloads")
            .setMethodCallHandler { call, result ->
                val uri = call.argument<String>("uri") ?: ""
                val mime = call.argument<String>("mime") ?: "application/octet-stream"
                when (call.method) {
                    "save" -> {
                        val name = call.argument<String>("name") ?: "file"
                        val bytes = call.argument<ByteArray>("bytes") ?: ByteArray(0)
                        // Off the main thread: it writes the file.
                        Thread {
                            try {
                                val saved = Downloads.save(this, name, mime, bytes)
                                runOnUiThread { result.success(saved) }
                            } catch (e: Downloads.NeedsPermission) {
                                runOnUiThread { result.error("permission", e.message, null) }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("failed", e.message, null) }
                            }
                        }.start()
                    }
                    "open" -> result.success(Downloads.open(this, uri, mime))
                    "share" -> result.success(
                        Downloads.share(this, uri, mime, call.argument<String>("title") ?: ""),
                    )
                    else -> result.notImplemented()
                }
            }
        // How fast the screen runs for the app: a phone that can't draw
        // the app at 90 or 120 frames a second asks for a steady 60.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "railway_hrms/display")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "preferRefreshRate" -> result.success(
                        preferRefreshRate((call.argument<Double>("rate") ?: 0.0).toFloat()),
                    )
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "railway_hrms/device_integrity")
            .setMethodCallHandler { call, result ->
                if (call.method != "check") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                // Off the main thread: it runs getprop and which.
                Thread {
                    try {
                        val report = DeviceIntegrity.check(applicationContext)
                        runOnUiThread { result.success(report) }
                    } catch (e: Exception) {
                        runOnUiThread { result.error("failed", e.message, null) }
                    }
                }.start()
            }
    }

    /**
     * Runs the screen, while the app is in front, in its mode closest to
     * [rate] frames a second at the same resolution; 0 hands the choice
     * back to the system. False where the screen has no such choice.
     */
    private fun preferRefreshRate(rate: Float): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return false
        val display = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            display
        } else {
            @Suppress("DEPRECATION")
            windowManager.defaultDisplay
        } ?: return false
        val params = window.attributes
        if (rate <= 0f) {
            params.preferredDisplayModeId = 0
            params.preferredRefreshRate = 0f
        } else {
            val current = display.mode
            val mode = display.supportedModes
                .filter {
                    it.physicalWidth == current.physicalWidth &&
                        it.physicalHeight == current.physicalHeight
                }
                .minByOrNull { kotlin.math.abs(it.refreshRate - rate) }
                ?: return false
            params.preferredDisplayModeId = mode.modeId
            params.preferredRefreshRate = mode.refreshRate
        }
        window.attributes = params
        return true
    }

    /** Opens [url], or the app's Play Store page; false if nothing could. */
    private fun openStore(url: String?): Boolean {
        val tries = listOfNotNull(
            url,
            "market://details?id=$packageName",
            "https://play.google.com/store/apps/details?id=$packageName",
        )
        for (each in tries) {
            try {
                startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(each)))
                return true
            } catch (e: ActivityNotFoundException) {
                // Try the next way.
            }
        }
        return false
    }
}
