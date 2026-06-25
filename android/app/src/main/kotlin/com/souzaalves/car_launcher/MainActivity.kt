package com.souzaalves.car_launcher

import android.media.AudioManager
import android.os.SystemClock
import android.view.KeyEvent
import com.souzaalves.car_launcher.carplay.CarPlayController
import com.souzaalves.car_launcher.carplay.CarPlayVideoView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channel = "car_launcher/media"
    private var carPlayController: CarPlayController? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, channel).setMethodCallHandler { call, result ->
            val keyCode = when (call.method) {
                "playPause" -> KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE
                "next" -> KeyEvent.KEYCODE_MEDIA_NEXT
                "previous" -> KeyEvent.KEYCODE_MEDIA_PREVIOUS
                else -> null
            }
            if (keyCode == null) {
                result.notImplemented()
            } else {
                dispatchMediaKey(keyCode)
                result.success(true)
            }
        }

        val controller = CarPlayController(applicationContext, messenger)
        carPlayController = controller
        flutterEngine.platformViewsController.registry.registerViewFactory(
            CarPlayVideoView.VIEW_TYPE,
            controller.viewFactory,
        )
    }

    override fun onDestroy() {
        carPlayController?.dispose()
        carPlayController = null
        super.onDestroy()
    }

    /// Sends a media key press to whichever app currently holds media focus.
    private fun dispatchMediaKey(keyCode: Int) {
        val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
        val eventTime = SystemClock.uptimeMillis()
        audioManager.dispatchMediaKeyEvent(
            KeyEvent(eventTime, eventTime, KeyEvent.ACTION_DOWN, keyCode, 0)
        )
        audioManager.dispatchMediaKeyEvent(
            KeyEvent(eventTime, eventTime, KeyEvent.ACTION_UP, keyCode, 0)
        )
    }
}
