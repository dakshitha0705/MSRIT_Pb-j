package com.dakshitha.battery_barter

import android.Manifest
import android.content.ContentUris
import android.content.Intent
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.os.Bundle
import android.provider.MediaStore
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val SPEECH_CHANNEL = "com.dakshitha.battery_barter/speech"
    private val MUSIC_CHANNEL  = "com.dakshitha.battery_barter/music"
    private val RECORD_AUDIO_PERMISSION_CODE = 101
    private val READ_MEDIA_PERMISSION_CODE   = 102

    private var speechRecognizer: SpeechRecognizer? = null
    private var speechChannel: MethodChannel? = null
    private var pendingSpeechResult: MethodChannel.Result? = null
    private var pendingMusicResult: MethodChannel.Result? = null
    private var isListening = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── Speech channel ──────────────────────────
        speechChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SPEECH_CHANNEL)
        speechChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isAvailable" -> result.success(true)
                "startListening" -> {
                    if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO)
                        == PackageManager.PERMISSION_GRANTED) {
                        startListening(result)
                    } else {
                        pendingSpeechResult = result
                        ActivityCompat.requestPermissions(this,
                            arrayOf(Manifest.permission.RECORD_AUDIO),
                            RECORD_AUDIO_PERMISSION_CODE)
                    }
                }
                "stopListening" -> stopListening(result)
                else -> result.notImplemented()
            }
        }

        // ── Music channel ───────────────────────────
        val musicChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MUSIC_CHANNEL)
        musicChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getSongs" -> {
                    val permission = if (android.os.Build.VERSION.SDK_INT >= 33)
                        Manifest.permission.READ_MEDIA_AUDIO
                    else
                        Manifest.permission.READ_EXTERNAL_STORAGE

                    if (ContextCompat.checkSelfPermission(this, permission)
                        == PackageManager.PERMISSION_GRANTED) {
                        result.success(querySongs())
                    } else {
                        pendingMusicResult = result
                        ActivityCompat.requestPermissions(this,
                            arrayOf(permission), READ_MEDIA_PERMISSION_CODE)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun querySongs(): List<Map<String, Any>> {
        val songs = mutableListOf<Map<String, Any>>()
        val uri   = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.DATA,
        )
        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0 AND ${MediaStore.Audio.Media.DURATION} > 30000"
        val cursor: Cursor? = contentResolver.query(
            uri, projection, selection, null,
            "${MediaStore.Audio.Media.TITLE} ASC")

        cursor?.use {
            val idCol       = it.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val titleCol    = it.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val artistCol   = it.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val albumCol    = it.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
            val durationCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
            val dataCol     = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)

            while (it.moveToNext()) {
                val id = it.getLong(idCol)
                songs.add(mapOf(
                    "id"       to id,
                    "title"    to (it.getString(titleCol) ?: "Unknown"),
                    "artist"   to (it.getString(artistCol) ?: "Unknown Artist"),
                    "album"    to (it.getString(albumCol) ?: ""),
                    "duration" to it.getLong(durationCol),
                    "path"     to (it.getString(dataCol) ?: ""),
                ))
            }
        }
        return songs
    }

    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<out String>, grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        when (requestCode) {
            RECORD_AUDIO_PERMISSION_CODE -> {
                if (grantResults.isNotEmpty() &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    pendingSpeechResult?.let { startListening(it) }
                } else {
                    pendingSpeechResult?.error("PERMISSION_DENIED", "Mic denied", null)
                    speechChannel?.invokeMethod("onError", "permission_denied")
                }
                pendingSpeechResult = null
            }
            READ_MEDIA_PERMISSION_CODE -> {
                if (grantResults.isNotEmpty() &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    pendingMusicResult?.success(querySongs())
                } else {
                    pendingMusicResult?.success(emptyList<Map<String, Any>>())
                }
                pendingMusicResult = null
            }
        }
    }

    // ── Speech recognition ──────────────────────────
    private fun startListening(result: MethodChannel.Result) {
        isListening = true
        speechRecognizer?.destroy()
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
        speechRecognizer?.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) {
                speechChannel?.invokeMethod("onStatus", "listening")
            }
            override fun onBeginningOfSpeech() {
                speechChannel?.invokeMethod("onStatus", "speaking")
            }
            override fun onRmsChanged(rmsdB: Float) {
                val level = ((rmsdB + 2f) / 12f * 10f).coerceIn(0f, 10f)
                speechChannel?.invokeMethod("onSoundLevel", level.toDouble())
            }
            override fun onPartialResults(partialResults: Bundle?) {
                val matches = partialResults
                    ?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                if (!matches.isNullOrEmpty())
                    speechChannel?.invokeMethod("onPartial", matches[0])
            }
            override fun onResults(results: Bundle?) {
                val matches = results
                    ?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                if (!matches.isNullOrEmpty() && matches[0].isNotEmpty())
                    speechChannel?.invokeMethod("onResult", matches[0])
                if (isListening) startListeningIntent()
            }
            override fun onError(error: Int) {
                when (error) {
                    SpeechRecognizer.ERROR_NO_MATCH,
                    SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> {
                        if (isListening) startListeningIntent()
                    }
                    SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> {
                        speechRecognizer?.destroy()
                        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this@MainActivity)
                        speechRecognizer?.setRecognitionListener(this)
                        if (isListening) startListeningIntent()
                    }
                    else -> speechChannel?.invokeMethod("onError", "error_$error")
                }
            }
            override fun onEndOfSpeech() {
                speechChannel?.invokeMethod("onStatus", "processing")
            }
            override fun onBufferReceived(buffer: ByteArray?) {}
            override fun onEvent(eventType: Int, params: Bundle?) {}
        })
        startListeningIntent()
        result.success(true)
    }

    private fun startListeningIntent() {
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, "en-IN")
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 2000L)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, 2000L)
        }
        try { speechRecognizer?.startListening(intent) } catch (e: Exception) {}
    }

    private fun stopListening(result: MethodChannel.Result) {
        isListening = false
        try {
            speechRecognizer?.stopListening()
            speechRecognizer?.destroy()
            speechRecognizer = null
        } catch (e: Exception) {}
        speechChannel?.invokeMethod("onStatus", "stopped")
        result.success(true)
    }

    override fun onDestroy() {
        isListening = false
        try { speechRecognizer?.destroy() } catch (e: Exception) {}
        super.onDestroy()
    }
}