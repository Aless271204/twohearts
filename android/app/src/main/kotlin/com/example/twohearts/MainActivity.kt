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
        tts = TextToSpeech(this) { status -> runOnUiThread {
            val voice = tts?.voices?.filter { it.locale.language == "es" && !it.isNetworkConnectionRequired }
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
                    if (!ready || text.isEmpty() || text.length > 500 || speaking != null) result.error("voice", "Voz no disponible", null)
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
