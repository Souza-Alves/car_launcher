package com.souzaalves.car_launcher.carplay

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.util.Log

/**
 * Plays PCM audio streamed from the phone via [AudioTrack]. The CarlinKit stream
 * can switch sample rate/channels on the fly (media vs. navigation vs. Siri), so
 * the track is rebuilt whenever the format changes.
 */
class CarPlayAudioPlayer {
    companion object {
        private const val TAG = "CarPlayAudioPlayer"
    }

    private var track: AudioTrack? = null
    private var currentDecodeType = -1

    @Synchronized
    fun play(decodeType: Int, pcm: ByteArray) {
        if (decodeType != currentDecodeType) {
            reconfigure(decodeType)
        }
        val t = track ?: return
        runCatching { t.write(pcm, 0, pcm.size) }
    }

    private fun reconfigure(decodeType: Int) {
        stop()
        val (sampleRate, channels, bytesPerSample) = CarPlayProtocol.audioFormat(decodeType)
        val channelMask = if (channels == 1) {
            AudioFormat.CHANNEL_OUT_MONO
        } else {
            AudioFormat.CHANNEL_OUT_STEREO
        }
        val minBuf = AudioTrack.getMinBufferSize(
            sampleRate, channelMask, AudioFormat.ENCODING_PCM_16BIT,
        )
        val bufferSize = if (minBuf > 0) minBuf * 2 else sampleRate * channels * bytesPerSample
        try {
            val newTrack = AudioTrack(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build(),
                AudioFormat.Builder()
                    .setSampleRate(sampleRate)
                    .setChannelMask(channelMask)
                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                    .build(),
                bufferSize,
                AudioTrack.MODE_STREAM,
                AudioManager.AUDIO_SESSION_ID_GENERATE,
            )
            newTrack.play()
            track = newTrack
            currentDecodeType = decodeType
        } catch (e: Exception) {
            Log.e(TAG, "Falha ao configurar AudioTrack: ${e.message}")
            track = null
            currentDecodeType = -1
        }
    }

    @Synchronized
    fun stop() {
        track?.let {
            runCatching { it.pause() }
            runCatching { it.flush() }
            runCatching { it.stop() }
            runCatching { it.release() }
        }
        track = null
        currentDecodeType = -1
    }
}
