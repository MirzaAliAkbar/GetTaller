package com.grayonix.GetTaller

import android.content.Context
import android.content.res.Configuration
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    // Store the original density to prevent Samsung's display zoom from
    // overriding the app's density.
    private var originalDensityDpi: Int = 0

    // Capture the original density before the framework applies any override
    // configuration. This runs earlier than onCreate() — applyOverrideConfiguration()
    // is invoked during attachBaseContext(), so if we captured the value in
    // onCreate() the guard in applyOverrideConfiguration() would always see 0
    // and the density fix would silently do nothing.
    override fun attachBaseContext(newBase: Context) {
        originalDensityDpi = newBase.resources.configuration.densityDpi
        super.attachBaseContext(newBase)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        // Fix Samsung zoom/scaling issue on all devices:
        // 1. Use SHORT_EDGES layout mode so the app renders edge-to-edge in the
        //    display cutout area without stretching or zooming.
        // 2. Samsung devices can override the app's density in their display settings,
        //    causing zoom/stretch. We restore our own density in
        //    applyOverrideConfiguration() below.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val attrs = window?.attributes
            attrs?.layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
            window?.attributes = attrs
        }

        super.onCreate(savedInstanceState)
    }

    // Override onConfigurationChanged to handle Samsung's display scaling changes
    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)

        // Re-apply cutout mode on configuration changes (Samsung can reset this)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val attrs = window?.attributes
            attrs?.layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
            window?.attributes = attrs
        }
    }

    // Override applyOverrideConfiguration to prevent Samsung's display zoom
    // from changing the app's density. Samsung devices can override the density
    // in their display settings, which causes the app to appear zoomed in.
    override fun applyOverrideConfiguration(overrideConfiguration: Configuration?) {
        if (overrideConfiguration != null && originalDensityDpi != 0) {
            // Force the app to use its original density, ignoring Samsung's
            // display zoom override.
            overrideConfiguration.densityDpi = originalDensityDpi
        }
        super.applyOverrideConfiguration(overrideConfiguration)
    }
}
