package niuhuan.quarkdrop

import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val platformChannelName = "quarkdrop/platform_paths"
    private val backgroundChannelName = "quarkdrop/background"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, platformChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPlatformPaths" -> {
                        val configDir = File(filesDir, "quarkdrop")
                        if (!configDir.exists()) {
                            configDir.mkdirs()
                        }
                        val displayName =
                            applicationInfo.loadLabel(packageManager)?.toString()?.trim()
                                ?.takeIf { it.isNotEmpty() } ?: "QuarkDrop"
                        result.success(
                            mapOf(
                                "configDir" to configDir.absolutePath,
                                "downloadDir" to null,
                                "displayName" to displayName,
                                "requiresDownloadPicker" to true,
                            )
                        )
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, backgroundChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isIgnoringBatteryOptimizations" -> {
                        val pm = getSystemService(POWER_SERVICE) as PowerManager
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    }
                    "requestIgnoreBatteryOptimizations" -> {
                        val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                        intent.data = Uri.parse("package:$packageName")
                        startActivity(intent)
                        result.success(true)
                    }
                    "openAppSettings" -> {
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                        intent.data = Uri.parse("package:$packageName")
                        startActivity(intent)
                        result.success(true)
                    }
                    "getKeepScreenOn" -> {
                        val flags = window.attributes.flags
                        result.success(flags and WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON != 0)
                    }
                    "setKeepScreenOn" -> {
                        val value = call.arguments as? Boolean ?: false
                        runOnUiThread {
                            if (value) {
                                window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                            } else {
                                window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                            }
                        }
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
