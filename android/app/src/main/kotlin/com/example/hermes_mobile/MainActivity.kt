package com.example.hermes_mobile

import android.app.Activity
import android.content.Intent
import android.provider.DocumentsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private var saveResult: MethodChannel.Result? = null
    private var saveSource: File? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "hermes_mobile/files")
            .setMethodCallHandler { call, result ->
                if (call.method != "save") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (saveResult != null) {
                    result.error("busy", "Há um salvamento em andamento.", null)
                    return@setMethodCallHandler
                }
                try {
                    val source = File(call.argument<String>("path") ?: "").canonicalFile
                    // Somente temporários privados criados pelo app.
                    val privateRoots = listOf(cacheDir.canonicalFile, codeCacheDir.canonicalFile)
                    require(privateRoots.any { source.path.startsWith(it.path + File.separator) })
                    require(source.parentFile?.name?.startsWith("hermes-download-") == true)
                    require(source.isFile)
                    val name = (call.argument<String>("name") ?: "arquivo")
                        .replace(Regex("[\\\\/\\p{Cntrl}]"), "_")
                    val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = call.argument<String>("mimeType") ?: "application/octet-stream"
                        putExtra(Intent.EXTRA_TITLE, name)
                    }
                    saveSource = source
                    saveResult = result
                    startActivityForResult(intent, 104)
                } catch (_: Exception) {
                    saveSource = null
                    saveResult = null
                    result.error("save_failed", "Não foi possível escolher o destino.", null)
                }
            }
    }

    @Deprecated("Android activity result callback used by FlutterActivity")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != 104) return
        val result = saveResult ?: return
        val source = saveSource
        val destination = data?.data
        if (resultCode != Activity.RESULT_OK || destination == null || source == null) {
            saveResult = null
            saveSource = null
            result.success(false)
            return
        }
        Thread {
            var saved = false
            try {
                val output = contentResolver.openOutputStream(destination, "w")
                    ?: throw IllegalStateException()
                output.use { target -> source.inputStream().use { it.copyTo(target) } }
                saved = true
            } catch (_: Exception) {
                // O documento recém-criado não pode ficar como download parcial.
                try { DocumentsContract.deleteDocument(contentResolver, destination) }
                catch (_: Exception) { }
            }
            runOnUiThread {
                saveResult = null
                saveSource = null
                if (saved) result.success(true)
                else result.error("save_failed", "Não foi possível salvar o arquivo.", null)
            }
        }.start()
    }
}
