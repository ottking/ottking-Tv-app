package com.ottking.app

import android.content.Context
import android.app.UiModeManager
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.view.WindowManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.ottking.app/device_info"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ভিডিও প্লেব্যাকের সময় স্ক্রিন অন রাখার ফ্ল্যাগ
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        // ফ্লাটার মেথড চ্যানেল হ্যান্ডেলার
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "isAndroidTV") {
                result.success(checkIsTvReal())
            } else {
                result.notImplemented()
            }
        }
    }

    private fun checkIsTvReal(): Boolean {
        // ১. স্ট্যান্ডার্ড অফিশিয়াল চেক (UiModeManager)
        val uiModeManager = getSystemService(Context.UI_MODE_SERVICE) as UiModeManager
        if (uiModeManager.currentModeType == Configuration.UI_MODE_TYPE_TELEVISION) {
            return true
        }

        // ২. সিস্টেম ফিচার চেক (Leanback লঞ্চার অথবা Amazon Fire TV ইন্টারফেস)
        if (packageManager.hasSystemFeature(PackageManager.FEATURE_LEANBACK) ||
            packageManager.hasSystemFeature("amazon.hardware.fire_tv")) {
            return true
        }

        // ৩. কাস্টম/লোকাল টিভি বক্স ফিক্স (ডিভাইসের মডেল/রিলিজ বা টাচস্ক্রিন এবসেন্স চেক)
        // বেশিরভাগ খাঁটি অ্যান্ড্রয়েড টিভিতে কোনো টাচস্ক্রিন থাকে না
        val hasNoTouchScreen = !packageManager.hasSystemFeature(PackageManager.FEATURE_TOUCHSCREEN)
        
        // কিছু কাস্টম বক্সে বা ওএসে "box" বা "tv" শব্দটা হার্ডওয়্যার বা মডেলে লুকিয়ে থাকে
        val isTvHardware = Build.HARDWARE.lowercase().contains("tv") || 
                           Build.MODEL.lowercase().contains("tv") || 
                           Build.MODEL.lowercase().contains("box")

        if (hasNoTouchScreen && isTvHardware) {
            return true
        }

        return false
    }
}
