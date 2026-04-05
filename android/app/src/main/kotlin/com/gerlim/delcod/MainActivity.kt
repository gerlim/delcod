package com.gerlim.delcod

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            APP_UPDATE_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "launchInstaller" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath.isNullOrBlank()) {
                        result.success(
                            mapOf(
                                "status" to "failed",
                                "message" to "Arquivo da atualizacao nao informado.",
                            ),
                        )
                        return@setMethodCallHandler
                    }

                    result.success(launchInstaller(filePath))
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun launchInstaller(filePath: String): Map<String, String> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            !packageManager.canRequestPackageInstalls()
        ) {
            openUnknownAppsSettings()
            return mapOf(
                "status" to "permissionDenied",
                "message" to "Permita a instalacao de apps desconhecidos para continuar.",
            )
        }

        val apkFile = File(filePath)
        if (!apkFile.exists()) {
            return mapOf(
                "status" to "failed",
                "message" to "Arquivo da atualizacao nao encontrado no dispositivo.",
            )
        }

        val apkUri = FileProvider.getUriForFile(
            this,
            "$packageName.app_update_provider",
            apkFile,
        )
        val installIntent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(apkUri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        return try {
            startActivity(installIntent)
            mapOf("status" to "readyToInstall")
        } catch (_: ActivityNotFoundException) {
            mapOf(
                "status" to "failed",
                "message" to "Nao foi possivel abrir o instalador do Android.",
            )
        }
    }

    private fun openUnknownAppsSettings() {
        val intent = Intent(
            android.provider.Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
            Uri.parse("package:$packageName"),
        ).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        startActivity(intent)
    }

    companion object {
        private const val APP_UPDATE_CHANNEL = "com.gerlim.delcod/app_update"
    }
}
