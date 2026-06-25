package com.souzaalves.car_launcher.carplay

import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.charset.StandardCharsets

/**
 * CarlinKit dongle USB protocol (compatible with the open `node-carplay`
 * implementation). Every message is a 16-byte little-endian header followed by
 * an optional payload:
 *
 *   magic (u32 = 0x55AA55AA) | length (u32) | type (u32) | ~type (u32)
 *
 * This file only encodes/decodes frames; the USB transport and decoding live in
 * [CarlinkitTransport] and [CarPlayDecoder].
 */
object CarPlayProtocol {
    const val MAGIC = 0x55AA55AA
    const val HEADER_SIZE = 16

    // Incoming + outgoing message types.
    const val TYPE_OPEN = 0x01
    const val TYPE_PLUGGED = 0x02
    const val TYPE_PHASE = 0x03
    const val TYPE_UNPLUGGED = 0x04
    const val TYPE_TOUCH = 0x05
    const val TYPE_VIDEO_DATA = 0x06
    const val TYPE_AUDIO_DATA = 0x07
    const val TYPE_COMMAND = 0x08
    const val TYPE_BLUETOOTH_ADDRESS = 0x0a
    const val TYPE_BLUETOOTH_PIN = 0x0c
    const val TYPE_BLUETOOTH_DEVICE_NAME = 0x0d
    const val TYPE_WIFI_DEVICE_NAME = 0x0e
    const val TYPE_DISCONNECT_PHONE = 0x0f
    const val TYPE_BLUETOOTH_PAIRED_LIST = 0x12
    const val TYPE_MANUFACTURER_INFO = 0x14
    const val TYPE_CLOSE_DONGLE = 0x15
    const val TYPE_MULTI_TOUCH = 0x17
    const val TYPE_BOX_SETTINGS = 0x19
    const val TYPE_MEDIA_DATA = 0x2a
    const val TYPE_SEND_FILE = 0x99
    const val TYPE_HEARTBEAT = 0xaa
    const val TYPE_SOFTWARE_VERSION = 0xcc

    // Command values used inside a TYPE_COMMAND message (single u32 payload).
    const val CMD_WIFI_ENABLE = 1000
    const val CMD_MIC = 7
    const val CMD_BOX_MIC = 15
    const val CMD_ENABLE_NIGHT_MODE = 16
    const val CMD_DISABLE_NIGHT_MODE = 17
    const val CMD_AUDIO_TRANSFER_ON = 22
    const val CMD_AUDIO_TRANSFER_OFF = 23
    const val CMD_FRAME = 12

    // Touch actions.
    const val TOUCH_DOWN = 14
    const val TOUCH_MOVE = 15
    const val TOUCH_UP = 16

    // CarlinKit config "files" written during the handshake.
    const val FILE_DPI = "/tmp/screen_dpi"
    const val FILE_NIGHT_MODE = "/tmp/night_mode"
    const val FILE_HAND_DRIVE_MODE = "/tmp/hand_drive_mode"
    const val FILE_CHARGE_MODE = "/tmp/charge_mode"
    const val FILE_BOX_NAME = "/etc/box_name"

    private fun le(capacity: Int): ByteBuffer =
        ByteBuffer.allocate(capacity).order(ByteOrder.LITTLE_ENDIAN)

    /** Builds a full message (header + payload) ready to be sent over USB. */
    fun frame(type: Int, payload: ByteArray = ByteArray(0)): ByteArray {
        val buf = le(HEADER_SIZE + payload.size)
        buf.putInt(MAGIC)
        buf.putInt(payload.size)
        buf.putInt(type)
        buf.putInt((type.inv()))
        buf.put(payload)
        return buf.array()
    }

    /** SendOpen — negotiates resolution/fps with the dongle. */
    fun open(width: Int, height: Int, fps: Int): ByteArray {
        val p = le(28)
        p.putInt(width)
        p.putInt(height)
        p.putInt(fps)
        p.putInt(5)        // format
        p.putInt(49152)    // packetMax
        p.putInt(2)        // iBoxVersion
        p.putInt(2)        // phoneWorkMode
        return frame(TYPE_OPEN, p.array())
    }

    /** SendFile — writes a virtual config file on the dongle. */
    fun sendFile(name: String, content: ByteArray): ByteArray {
        val nameBytes = (name + "\u0000").toByteArray(StandardCharsets.US_ASCII)
        val p = le(4 + nameBytes.size + 4 + content.size)
        p.putInt(nameBytes.size)
        p.put(nameBytes)
        p.putInt(content.size)
        p.put(content)
        return frame(TYPE_SEND_FILE, p.array())
    }

    fun sendInt(name: String, value: Int): ByteArray {
        val c = le(4)
        c.putInt(value)
        return sendFile(name, c.array())
    }

    fun sendBool(name: String, value: Boolean): ByteArray =
        sendInt(name, if (value) 1 else 0)

    fun sendString(name: String, value: String): ByteArray =
        sendFile(name, value.toByteArray(StandardCharsets.UTF_8))

    /** SendBoxSettings — JSON of misc tuning parameters. */
    fun boxSettings(mediaDelay: Int = 300): ByteArray {
        val json = "{\"mediaDelay\":$mediaDelay}"
        return frame(TYPE_BOX_SETTINGS, json.toByteArray(StandardCharsets.UTF_8))
    }

    fun command(value: Int): ByteArray {
        val p = le(4)
        p.putInt(value)
        return frame(TYPE_COMMAND, p.array())
    }

    fun heartbeat(): ByteArray = frame(TYPE_HEARTBEAT)

    /** SendTouch — normalized coordinates in [0,1]. */
    fun touch(action: Int, x: Float, y: Float): ByteArray {
        val p = le(16)
        p.putInt(action)
        p.putInt((10000 * x).toInt())
        p.putInt((10000 * y).toInt())
        p.putInt(0)
        return frame(TYPE_TOUCH, p.array())
    }

    /** Strips the 20-byte sub-header from a VideoData payload, leaving H.264. */
    fun videoPayloadToH264(payload: ByteArray): ByteArray? {
        if (payload.size <= 20) return null
        return payload.copyOfRange(20, payload.size)
    }
}
