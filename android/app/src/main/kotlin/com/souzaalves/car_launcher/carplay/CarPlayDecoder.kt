package com.souzaalves.car_launcher.carplay

import android.media.MediaCodec
import android.media.MediaFormat
import android.util.Log
import android.view.Surface

/**
 * Wraps a [MediaCodec] H.264 decoder that renders directly to a [Surface]. SPS/PPS
 * arrive in-band in the CarPlay stream, so we just feed Annex-B access units.
 */
class CarPlayDecoder(
    private val width: Int,
    private val height: Int,
) {
    companion object {
        private const val TAG = "CarPlayDecoder"
        private const val MIME = MediaFormat.MIMETYPE_VIDEO_AVC
        private const val DEQUEUE_TIMEOUT_US = 10_000L
    }

    private var codec: MediaCodec? = null
    private val bufferInfo = MediaCodec.BufferInfo()

    @Synchronized
    fun start(surface: Surface) {
        stop()
        try {
            val format = MediaFormat.createVideoFormat(MIME, width, height)
            val decoder = MediaCodec.createDecoderByType(MIME)
            decoder.configure(format, surface, null, 0)
            decoder.start()
            codec = decoder
        } catch (e: Exception) {
            Log.e(TAG, "Falha ao iniciar o decoder: ${e.message}")
            codec = null
        }
    }

    @Synchronized
    fun decode(data: ByteArray) {
        val decoder = codec ?: return
        try {
            val inIndex = decoder.dequeueInputBuffer(DEQUEUE_TIMEOUT_US)
            if (inIndex >= 0) {
                val inputBuffer = decoder.getInputBuffer(inIndex)
                inputBuffer?.clear()
                inputBuffer?.put(data)
                decoder.queueInputBuffer(inIndex, 0, data.size, 0, 0)
            }
            var outIndex = decoder.dequeueOutputBuffer(bufferInfo, 0)
            while (outIndex >= 0) {
                decoder.releaseOutputBuffer(outIndex, true)
                outIndex = decoder.dequeueOutputBuffer(bufferInfo, 0)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Falha ao decodificar frame: ${e.message}")
        }
    }

    @Synchronized
    fun stop() {
        codec?.let {
            runCatching { it.stop() }
            runCatching { it.release() }
        }
        codec = null
    }
}
