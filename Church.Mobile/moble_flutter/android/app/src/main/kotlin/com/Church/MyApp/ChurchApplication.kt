package com.Church.MyApp

import android.app.Application
import android.content.Context
import androidx.appcompat.app.AppCompatDelegate

/**
 * Syncs Flutter ThemeMode with AppCompat night mode.
 * Instant launch splash defaults to light; dark splash only when mode is explicitly "dark".
 */
class ChurchApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        applyStoredThemeMode(this)
    }

    companion object {
        const val SPLASH_PREFS = "ChurchSplashPrefs"
        const val KEY_THEME_MODE = "theme_mode"
        private const val FLUTTER_PREFS = "FlutterSharedPreferences"
        private const val FLUTTER_THEME_KEY = "flutter.app_theme_mode"

        fun applyStoredThemeMode(context: Context) {
            val mode = readThemeMode(context)
            AppCompatDelegate.setDefaultNightMode(nightModeFor(mode))
        }

        fun persistAndApply(context: Context, mode: String) {
            context.getSharedPreferences(SPLASH_PREFS, Context.MODE_PRIVATE)
                .edit()
                .putString(KEY_THEME_MODE, mode)
                .commit()
            AppCompatDelegate.setDefaultNightMode(nightModeFor(mode))
        }

        fun readThemeMode(context: Context): String {
            val splashPrefs = context.getSharedPreferences(SPLASH_PREFS, Context.MODE_PRIVATE)
            splashPrefs.getString(KEY_THEME_MODE, null)?.let { return normalize(it) }

            val flutterPrefs = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
            flutterPrefs.getString(FLUTTER_THEME_KEY, null)?.let { return normalize(it) }

            return "light"
        }

        private fun normalize(raw: String): String {
            val v = raw.trim().removeSurrounding("\"")
            return when (v) {
                "dark", "light", "system" -> v
                else -> "light"
            }
        }

        private fun nightModeFor(mode: String): Int = when (mode) {
            "dark" -> AppCompatDelegate.MODE_NIGHT_YES
            "system" -> AppCompatDelegate.MODE_NIGHT_FOLLOW_SYSTEM
            else -> AppCompatDelegate.MODE_NIGHT_NO
        }

        /** Dark launch splash only for explicit app dark mode — not system night. */
        fun wantsDarkLaunchSplash(context: Context): Boolean =
            readThemeMode(context) == "dark"
    }
}
