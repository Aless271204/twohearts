package com.example.twohearts

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import java.util.Locale
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.ContentValues
import android.provider.MediaStore
import org.json.JSONObject
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat

class MainActivity : FlutterFragmentActivity() {
    private var tts: TextToSpeech? = null
    private var ready = false
    private var initialized = false
    private val preparations = mutableListOf<MethodChannel.Result>()
    private var speaking: MethodChannel.Result? = null
    private var dictating: MethodChannel.Result? = null
    private var recognizer: SpeechRecognizer? = null

    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        MethodChannel(engine.dartExecutor.binaryMessenger,"nido/reminders").setMethodCallHandler { call,result ->
            when(call.method){
                "configure" -> {NidoReminders.configure(this,call.argument<Boolean>("daily")==true,call.argument<Boolean>("moods")==true,call.argument<Int>("hour")?:19,call.argument<Int>("minute")?:0);result.success(true)}
                "mood" -> {NidoReminders.mood(this,JSONObject(call.arguments as? Map<*,*> ?: emptyMap<String,Any>()));result.success(true)}
                else -> result.notImplemented()
            }
        }
        MethodChannel(engine.dartExecutor.binaryMessenger, "nido/art").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "configureWidget" -> {
                        val url = call.argument<String>("url").orEmpty()
                        val key = call.argument<String>("apiKey").orEmpty()
                        val token = call.argument<String>("token").orEmpty()
                        val user = call.argument<String>("user").orEmpty()
                        if (!url.startsWith("https://") || !Regex("[a-f0-9]{64}").matches(token)) result.error("widget", "Configuración no válida", null)
                        else { PartnerWidget.configure(this, url, key, token, user); result.success(true) }
                    }
                    "updateNote" -> { PartnerWidget.store(this, JSONObject(call.arguments as? Map<*, *> ?: emptyMap<String,Any>())); result.success(true) }
                    "openWidgetSettings" -> { startActivity(Intent(this,NidoWidgetSettingsActivity::class.java));result.success(true) }
                    "updateCoupleStats" -> { val data=JSONObject(call.arguments as? Map<*, *> ?: emptyMap<String,Any>()); data.optJSONArray("quote_members")?.let { PartnerWidget.prefs(this).edit().putString("quote_members",it.toString()).apply() }; PartnerWidget.prefs(this).edit().putString("couple_stats", JSONObject(call.arguments as? Map<*, *> ?: emptyMap<String,Any>()).toString()).apply(); PartnerWidget.redraw(this); result.success(true) }
                    "clearWidget" -> { PartnerWidget.clear(this); result.success(true) }
                    "pinWidget" -> {
                        val manager = AppWidgetManager.getInstance(this)
                        val provider = if (call.argument<Boolean>("history") == true) NidoCoupleWidgetProvider::class.java else NidoPartnerWidgetProvider::class.java
                        result.success(if (Build.VERSION.SDK_INT >= 26 && manager.isRequestPinAppWidgetSupported) manager.requestPinAppWidget(ComponentName(this,provider),null,null) else false)
                    }
                    "savePng" -> {
                        val bytes = call.argument<ByteArray>("bytes") ?: throw IllegalArgumentException("PNG vacío")
                        if (bytes.size > 2_000_000) throw IllegalArgumentException("Imagen demasiado grande")
                        if (Build.VERSION.SDK_INT < 29 && checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
                            result.error("storage", "Usa Compartir PNG para guardar en este teléfono", null)
                        } else {
                            val values = ContentValues().apply {
                                put(MediaStore.Images.Media.DISPLAY_NAME, "NIDO-${System.currentTimeMillis()}.png")
                                put(MediaStore.Images.Media.MIME_TYPE, "image/png")
                                if (Build.VERSION.SDK_INT >= 29) { put(MediaStore.Images.Media.RELATIVE_PATH,"Pictures/NIDO"); put(MediaStore.Images.Media.IS_PENDING,1) }
                            }
                            val uri = contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI,values) ?: throw IllegalStateException("No se pudo guardar")
                            try {
                                contentResolver.openOutputStream(uri)?.use { it.write(bytes) } ?: throw IllegalStateException("Sin almacenamiento")
                                if (Build.VERSION.SDK_INT >= 29) contentResolver.update(uri, ContentValues().apply {put(MediaStore.Images.Media.IS_PENDING,0)},null,null)
                                result.success(uri.toString())
                            } catch (e:Exception) { contentResolver.delete(uri,null,null); throw e }
                        }
                    }
                    else -> result.notImplemented()
                }
            } catch (_: Exception) { result.error("art", "No se pudo completar esta acción", null) }
        }
        MethodChannel(engine.dartExecutor.binaryMessenger, "nido/game_display").setMethodCallHandler { call, result ->
            if (call.method == "fullscreen") {
                val controller = WindowCompat.getInsetsController(window, window.decorView)
                controller.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                if (call.arguments == true) controller.hide(WindowInsetsCompat.Type.systemBars())
                else controller.show(WindowInsetsCompat.Type.systemBars())
                result.success(null)
            } else result.notImplemented()
        }
        tts = TextToSpeech(this) { status -> runOnUiThread {
            val voice = tts?.voices?.filter { it.locale.language == "es" && !it.isNetworkConnectionRequired && !it.features.contains(TextToSpeech.Engine.KEY_FEATURE_NOT_INSTALLED) }
                ?.sortedWith(compareBy({ if (it.name == "es-es-x-eef-local") 0 else 1 }, { it.name }))?.firstOrNull()
            ready = status == TextToSpeech.SUCCESS && voice != null
            if (ready) { tts?.voice = voice; tts?.setPitch(1.35f); tts?.setSpeechRate(.9f) }
            initialized = true
            preparations.forEach { it.success(ready) }; preparations.clear()
        } }
        tts?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
            override fun onStart(id: String?) {}
            override fun onDone(id: String?) { runOnUiThread { speaking?.success(true); speaking = null } }
            @Deprecated("Android compatibility")
            override fun onError(id: String?) { runOnUiThread { speaking?.error("voice", "No se pudo sintetizar el mensaje", null); speaking = null } }
        })
        MethodChannel(engine.dartExecutor.binaryMessenger, "nido/pet_voice").setMethodCallHandler { call, result ->
            when (call.method) {
                "prepare" -> if (initialized) result.success(ready) else preparations.add(result)
                "speak" -> {
                    val text = call.argument<String>("text")?.trim().orEmpty()
                    if (!ready || text.isEmpty() || text.codePointCount(0, text.length) > 500 || speaking != null) result.error("voice", "Voz no disponible", null)
                    else {
                        speaking = result
                        if (tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "pip-message") == TextToSpeech.ERROR) {
                            speaking = null; result.error("voice", "No se pudo iniciar la voz", null)
                        }
                    }
                }
                "dictate" -> {
                    if (dictating != null) result.error("busy", "Ya estás dictando", null)
                    else if (Build.VERSION.SDK_INT < 31 || !SpeechRecognizer.isOnDeviceRecognitionAvailable(this)) result.error("dictation", "Dictado local no disponible; escribe el mensaje", null)
                    else {
                        dictating = result
                        if (checkSelfPermission(Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) startDictation()
                        else requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), 812)
                    }
                }
                "stop" -> { stopVoice(); result.success(true) }
                else -> result.notImplemented()
            }
        }
    }
    private fun finishDictation(text: String? = null) {
        val pending = dictating; dictating = null
        if (text != null) pending?.success(text.take(500)) else pending?.error("dictation", "No se pudo reconocer el mensaje", null)
        recognizer?.destroy(); recognizer = null
    }
    private fun startDictation() {
        if (Build.VERSION.SDK_INT < 31) { finishDictation(); return }
        try {
            recognizer = SpeechRecognizer.createOnDeviceSpeechRecognizer(this)
            recognizer?.setRecognitionListener(object : RecognitionListener {
                override fun onReadyForSpeech(params: Bundle?) {}
                override fun onBeginningOfSpeech() {}
                override fun onRmsChanged(rmsdB: Float) {}
                override fun onBufferReceived(buffer: ByteArray?) {}
                override fun onEndOfSpeech() {}
                override fun onError(error: Int) { finishDictation() }
                override fun onResults(results: Bundle?) { finishDictation(results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()) }
                override fun onPartialResults(partialResults: Bundle?) {}
                override fun onEvent(eventType: Int, params: Bundle?) {}
            })
            recognizer?.startListening(Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                putExtra(RecognizerIntent.EXTRA_LANGUAGE, "es-ES")
                putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, true)
                putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
            })
        } catch (_: Exception) { finishDictation() }
    }
    override fun onRequestPermissionsResult(code: Int, permissions: Array<out String>, results: IntArray) {
        super.onRequestPermissionsResult(code, permissions, results)
        if (code == 812) { if (results.firstOrNull() == PackageManager.PERMISSION_GRANTED) startDictation() else finishDictation() }
    }
    private fun stopVoice() {
        tts?.stop(); speaking?.error("stopped", "Voz detenida", null); speaking = null
        recognizer?.cancel(); if (dictating != null) finishDictation()
    }
    override fun onStop() { stopVoice(); super.onStop() }
    override fun onDestroy() { stopVoice(); tts?.shutdown(); super.onDestroy() }
}
