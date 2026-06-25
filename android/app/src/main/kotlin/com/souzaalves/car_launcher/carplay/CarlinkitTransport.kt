package com.souzaalves.car_launcher.carplay

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbDeviceConnection
import android.hardware.usb.UsbEndpoint
import android.hardware.usb.UsbInterface
import android.hardware.usb.UsbManager
import android.os.Build
import android.util.Log
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.concurrent.thread

/**
 * Opens a CarlinKit dongle over USB host, claims its bulk interface and runs a
 * background read loop that hands decoded message frames to [listener]. The
 * dongle does the proprietary Apple/Google authentication; we just exchange the
 * CarlinKit framed messages with it.
 */
class CarlinkitTransport(
    private val context: Context,
    private val listener: Listener,
) {
    interface Listener {
        fun onConnected()
        fun onMessage(type: Int, payload: ByteArray)
        fun onError(message: String)
        fun onClosed()
    }

    companion object {
        private const val TAG = "CarlinkitTransport"
        private const val ACTION_USB_PERMISSION = "com.souzaalves.car_launcher.USB_PERMISSION"
        private const val VENDOR_ID = 0x1314
        private val PRODUCT_IDS = setOf(0x1520, 0x1521, 0x1522, 0x1523)
        private const val READ_TIMEOUT_MS = 2000
    }

    private val usbManager: UsbManager =
        context.getSystemService(Context.USB_SERVICE) as UsbManager

    @Volatile
    private var running = false
    private var connection: UsbDeviceConnection? = null
    private var usbInterface: UsbInterface? = null
    private var endpointIn: UsbEndpoint? = null
    private var endpointOut: UsbEndpoint? = null
    private var readThread: Thread? = null
    private var permissionReceiver: BroadcastReceiver? = null

    fun isCarlinkit(device: UsbDevice): Boolean =
        device.vendorId == VENDOR_ID && PRODUCT_IDS.contains(device.productId)

    fun findDongle(): UsbDevice? =
        usbManager.deviceList.values.firstOrNull { isCarlinkit(it) }

    /** Locates the dongle, requesting USB permission if necessary. */
    fun start() {
        val device = findDongle()
        if (device == null) {
            listener.onError("Dongle CarlinKit não encontrado no barramento USB")
            return
        }
        if (usbManager.hasPermission(device)) {
            openDevice(device)
        } else {
            requestPermission(device)
        }
    }

    private fun requestPermission(device: UsbDevice) {
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_MUTABLE
        } else {
            0
        }
        val intent = PendingIntent.getBroadcast(
            context, 0, Intent(ACTION_USB_PERMISSION), flags,
        )
        permissionReceiver = object : BroadcastReceiver() {
            override fun onReceive(ctx: Context, received: Intent) {
                if (received.action != ACTION_USB_PERMISSION) return
                unregisterPermissionReceiver()
                val granted = received.getBooleanExtra(
                    UsbManager.EXTRA_PERMISSION_GRANTED, false,
                )
                if (granted) {
                    openDevice(device)
                } else {
                    listener.onError("Permissão de USB negada para o dongle")
                }
            }
        }
        val filter = IntentFilter(ACTION_USB_PERMISSION)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(permissionReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            context.registerReceiver(permissionReceiver, filter)
        }
        usbManager.requestPermission(device, intent)
    }

    private fun unregisterPermissionReceiver() {
        permissionReceiver?.let {
            runCatching { context.unregisterReceiver(it) }
            permissionReceiver = null
        }
    }

    private fun openDevice(device: UsbDevice) {
        val iface = (0 until device.interfaceCount)
            .map { device.getInterface(it) }
            .firstOrNull { hasBulkPair(it) }
        if (iface == null) {
            listener.onError("Interface bulk não encontrada no dongle")
            return
        }
        var inEp: UsbEndpoint? = null
        var outEp: UsbEndpoint? = null
        for (i in 0 until iface.endpointCount) {
            val ep = iface.getEndpoint(i)
            if (ep.type != UsbConstants.USB_ENDPOINT_XFER_BULK) continue
            if (ep.direction == UsbConstants.USB_DIR_IN) inEp = ep else outEp = ep
        }
        val conn = usbManager.openDevice(device)
        if (conn == null || inEp == null || outEp == null || !conn.claimInterface(iface, true)) {
            conn?.close()
            listener.onError("Falha ao abrir/claim do dispositivo USB")
            return
        }
        connection = conn
        usbInterface = iface
        endpointIn = inEp
        endpointOut = outEp
        running = true
        listener.onConnected()
        readThread = thread(name = "carlinkit-read") { readLoop() }
    }

    private fun hasBulkPair(iface: UsbInterface): Boolean {
        var bulkIn = false
        var bulkOut = false
        for (i in 0 until iface.endpointCount) {
            val ep = iface.getEndpoint(i)
            if (ep.type != UsbConstants.USB_ENDPOINT_XFER_BULK) continue
            if (ep.direction == UsbConstants.USB_DIR_IN) bulkIn = true else bulkOut = true
        }
        return bulkIn && bulkOut
    }

    /** Writes a pre-framed message to the dongle. Thread-safe enough for our use. */
    @Synchronized
    fun write(frame: ByteArray): Boolean {
        val conn = connection ?: return false
        val ep = endpointOut ?: return false
        var offset = 0
        while (offset < frame.size) {
            val chunk = minOf(ep.maxPacketSize.takeIf { it > 0 } ?: frame.size, frame.size - offset)
            val sent = conn.bulkTransfer(ep, frame.copyOfRange(offset, offset + chunk), chunk, READ_TIMEOUT_MS)
            if (sent < 0) return false
            offset += sent
        }
        return true
    }

    private fun readLoop() {
        val conn = connection ?: return
        val ep = endpointIn ?: return
        val headerBuf = ByteArray(CarPlayProtocol.HEADER_SIZE)
        while (running) {
            try {
                if (!readFully(conn, ep, headerBuf, CarPlayProtocol.HEADER_SIZE)) continue
                val header = ByteBuffer.wrap(headerBuf).order(ByteOrder.LITTLE_ENDIAN)
                val magic = header.int
                if (magic != CarPlayProtocol.MAGIC) {
                    Log.w(TAG, "Magic inesperado: ${Integer.toHexString(magic)}")
                    continue
                }
                val length = header.int
                val type = header.int
                // header.int  // ~type checksum, ignored
                val payload = if (length > 0) ByteArray(length) else ByteArray(0)
                if (length > 0 && !readFully(conn, ep, payload, length)) continue
                listener.onMessage(type, payload)
            } catch (e: Exception) {
                if (running) listener.onError("Erro de leitura USB: ${e.message}")
                break
            }
        }
    }

    /** Reads exactly [length] bytes, retrying on partial/timed-out bulk reads. */
    private fun readFully(
        conn: UsbDeviceConnection,
        ep: UsbEndpoint,
        out: ByteArray,
        length: Int,
    ): Boolean {
        var read = 0
        val temp = ByteArray(maxOf(ep.maxPacketSize, length))
        while (read < length && running) {
            val n = conn.bulkTransfer(ep, temp, length - read, READ_TIMEOUT_MS)
            if (n < 0) return read > 0 && read == length
            if (n == 0) continue
            System.arraycopy(temp, 0, out, read, n)
            read += n
        }
        return read == length
    }

    fun stop() {
        running = false
        unregisterPermissionReceiver()
        readThread?.let { runCatching { it.join(500) } }
        readThread = null
        usbInterface?.let { iface -> runCatching { connection?.releaseInterface(iface) } }
        runCatching { connection?.close() }
        connection = null
        usbInterface = null
        endpointIn = null
        endpointOut = null
        listener.onClosed()
    }
}
