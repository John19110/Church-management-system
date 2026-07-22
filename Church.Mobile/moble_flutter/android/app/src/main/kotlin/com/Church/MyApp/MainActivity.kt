package com.Church.MyApp

import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Default instant splash is light. Dark only if the user chose app dark mode.
        setTheme(
            if (ChurchApplication.wantsDarkLaunchSplash(this)) R.style.LaunchThemeDark
            else R.style.LaunchTheme,
        )
        installSplashScreen()
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setThemeMode" -> {
                    val mode = call.arguments as? String ?: "light"
                    ChurchApplication.persistAndApply(applicationContext, mode)
                    result.success(null)
                }
                "getThemeMode" -> {
                    result.success(ChurchApplication.readThemeMode(applicationContext))
                }
                else -> result.notImplemented()
            }
        }
    }

    companion object {
        private const val CHANNEL = "com.Church.MyApp/splash_theme"
    }
}
