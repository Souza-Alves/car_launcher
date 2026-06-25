package com.souzaalves.car_launcher.carplay

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.view.Surface
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.Timer
import java.util.TimerTask

/**
 * Orchestrates a CarPlay session: USB transport ([CarlinkitTransport]) + H.264
 * decoder ([CarPlayDecoder]) + Flutter channels. Exposes:
 *   - MethodChannel "car_launcher/carplay": start, stop, touch
 *   - EventChannel  "car_launcher/carplay/events": status updates to the UI
 */
class CarPlayController(
    private val context: Context,
    messenger: BinaryMessenger,
) : CarlinkitTransport.Listener,
    CarPlayVideoView.SurfaceProvider,
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {

    companion object {
        const val METHOD_CHANNEL = "car_launcher/carplay"
        const val EVENT_CHANNEL = "car_launcher/carplay/events"
        private const val HEARTBEAT_MS = 2000L
    }

    private val main = Handler(Looper.getMainLooper())
    private val methodChannel = MethodChannel(messenger, METHOD_CHANNEL).also {
        it.setMethodCallHandler(this)
    }
    private val eventChannel = EventChannel(messenger, EVENT_CHANNEL).also {
        it.setStreamHandler(this)
    }

    private var eventSink: EventChannel.EventSink? = null
    private var transport: CarlinkitTransport? = null
    private var decoder: CarPlayDecoder? = null
    private val audioPlayer = CarPlayAudioPlayer()
    private val micRecorder = CarPlayMicRecorder(context) { pcm, length ->
        transport?.write(CarPlayProtocol.micAudio(pcm, length))
    }
    private var heartbeat: Timer? = null

    private var surface: Surface? = null
    private var width = 800
    private var height = 480
    private var fps = 30
    private var dpi = 160

    // --- PlatformView factory wiring ---

    val viewFactory: CarPlayVideoView.Factory = CarPlayVideoView.Factory(this)

    // --- MethodChannel ---

    override fun onMethodCall(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> {
                width = call.argument<Int>("width") ?: width
                height = call.argument<Int>("height") ?: height
                fps = call.argument<Int>("fps") ?: fps
                dpi = call.argument<Int>("dpi") ?: dpi
                start()
                result.success(true)
            }
            "stop" -> {
                stop()
                result.success(true)
            }
            "touch" -> {
                val action = when (call.argument<String>("action")) {
                    "down" -> CarPlayProtocol.TOUCH_DOWN
                    "move" -> CarPlayProtocol.TOUCH_MOVE
                    "up" -> CarPlayProtocol.TOUCH_UP
                    else -> null
                }
                val x = (call.argument<Double>("x") ?: 0.0).toFloat()
                val y = (call.argument<Double>("y") ?: 0.0).toFloat()
                if (action != null) {
                    transport?.write(CarPlayProtocol.touch(action, x, y))
                }
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    // --- EventChannel ---

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun emit(status: String, message: String? = null) {
        main.post {
            eventSink?.success(
                buildMap<String, Any> {
                    put("status", status)
                    if (message != null) put("message", message)
                },
            )
        }
    }

    // --- Session lifecycle ---

    private fun start() {
        stop()
        decoder = CarPlayDecoder(width, height)
        surface?.let { decoder?.start(it) }
        emit("connecting")
        val t = CarlinkitTransport(context, this)
        transport = t
        t.start()
    }

    private fun stop() {
        heartbeat?.cancel()
        heartbeat = null
        micRecorder.stop()
        audioPlayer.stop()
        transport?.stop()
        transport = null
        decoder?.stop()
        decoder = null
    }

    fun dispose() {
        stop()
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    private fun handshake() {
        val t = transport ?: return
        t.write(CarPlayProtocol.open(width, height, fps))
        t.write(CarPlayProtocol.sendInt(CarPlayProtocol.FILE_DPI, dpi))
        t.write(CarPlayProtocol.sendBool(CarPlayProtocol.FILE_NIGHT_MODE, false))
        t.write(CarPlayProtocol.sendBool(CarPlayProtocol.FILE_HAND_DRIVE_MODE, false))
        t.write(CarPlayProtocol.sendBool(CarPlayProtocol.FILE_CHARGE_MODE, true))
        t.write(CarPlayProtocol.sendString(CarPlayProtocol.FILE_BOX_NAME, "Car Launcher"))
        t.write(CarPlayProtocol.boxSettings())
        t.write(CarPlayProtocol.command(CarPlayProtocol.CMD_WIFI_ENABLE))
        t.write(CarPlayProtocol.command(CarPlayProtocol.CMD_MIC))
        t.write(CarPlayProtocol.command(CarPlayProtocol.CMD_AUDIO_TRANSFER_OFF))
        startHeartbeat()
    }

    private fun startHeartbeat() {
        heartbeat?.cancel()
        heartbeat = Timer("carplay-heartbeat").also {
            it.scheduleAtFixedRate(object : TimerTask() {
                override fun run() {
                    transport?.write(CarPlayProtocol.heartbeat())
                }
            }, HEARTBEAT_MS, HEARTBEAT_MS)
        }
    }

    // --- CarlinkitTransport.Listener ---

    override fun onConnected() {
        emit("dongleConnected")
        handshake()
    }

    override fun onMessage(type: Int, payload: ByteArray) {
        when (type) {
            CarPlayProtocol.TYPE_VIDEO_DATA -> {
                CarPlayProtocol.videoPayloadToH264(payload)?.let { decoder?.decode(it) }
            }
            CarPlayProtocol.TYPE_AUDIO_DATA -> handleAudio(payload)
            CarPlayProtocol.TYPE_PLUGGED -> emit("phoneConnected")
            CarPlayProtocol.TYPE_UNPLUGGED -> {
                micRecorder.stop()
                audioPlayer.stop()
                emit("phoneDisconnected")
            }
        }
    }

    private fun handleAudio(payload: ByteArray) {
        val packet = CarPlayProtocol.parseAudio(payload) ?: return
        when (packet.command) {
            CarPlayProtocol.AUDIO_SIRI_START,
            CarPlayProtocol.AUDIO_PHONECALL_START -> micRecorder.start()
            CarPlayProtocol.AUDIO_SIRI_STOP,
            CarPlayProtocol.AUDIO_PHONECALL_STOP -> micRecorder.stop()
            null -> packet.pcm?.let { audioPlayer.play(packet.decodeType, it) }
            else -> Unit
        }
    }

    override fun onError(message: String) {
        emit("error", message)
    }

    override fun onClosed() {
        emit("closed")
    }

    // --- CarPlayVideoView.SurfaceProvider ---

    override fun onSurfaceAvailable(surface: Surface) {
        this.surface = surface
        decoder?.start(surface)
    }

    override fun onSurfaceDestroyed() {
        this.surface = null
        decoder?.stop()
    }
}
