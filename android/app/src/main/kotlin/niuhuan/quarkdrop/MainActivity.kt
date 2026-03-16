package niuhuan.quarkdrop

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val platformChannelName = "quarkdrop/platform_paths"

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
    }
}
