package com.souzaalves.car_launcher.carplay

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.util.Log
import androidx.core.content.ContextCompat
import kotlin.concurrent.thread

/**
 * Captures microphone PCM (16 kHz mono 16-bit) and hands it to [onData] so the
 * controller can forward it to the phone — used for Siri and phone calls.
 */
class CarPlayMicRecorder(
    private val context: Context,
    private val onData: (ByteArray, Int) -> Unit,
) {
    companion object {
        private const val TAG = "CarPlayMicRecorder"
        private const val SAMPLE_RATE = 16000
    }

    @Volatile
    private var recording = false
    private var recordThread: Thread? = null

    fun hasPermission(): Boolean = ContextCompat.checkSelfPermission(
        context, Manifest.permission.RECORD_AUDIO,
    ) == PackageManager.PERMISSION_GRANTED

    @SuppressLint("MissingPermission")
    fun start() {
        if (recording || !hasPermission()) {
            if (!hasPermission()) Log.w(TAG, "Sem permissão RECORD_AUDIO; mic ignorado")
            return
        }
        val minBuf = AudioRecord.getMinBufferSize(
            SAMPLE_RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT,
        )
        if (minBuf <= 0) return
        val recorder = try {
            AudioRecord(
                MediaRecorder.AudioSource.VOICE_RECOGNITION,
                SAMPLE_RATE,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                minBuf * 2,
            )
        } catch (e: Exception) {
            Log.e(TAG, "Falha ao criar AudioRecord: ${e.message}")
            return
        }
        if (recorder.state != AudioRecord.STATE_INITIALIZED) {
            recorder.release()
            return
        }
        recording = true
        recordThread = thread(name = "carplay-mic") {
            val buffer = ByteArray(minBuf)
            runCatching { recorder.startRecording() }
            while (recording) {
                val n = recorder.read(buffer, 0, buffer.size)
                if (n > 0) onData(buffer, n)
            }
            runCatching { recorder.stop() }
            runCatching { recorder.release() }
        }
    }

    fun stop() {
        recording = false
        recordThread?.let { runCatching { it.join(300) } }
        recordThread = null
    }
}
