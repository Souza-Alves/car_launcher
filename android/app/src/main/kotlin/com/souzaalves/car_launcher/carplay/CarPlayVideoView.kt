package com.souzaalves.car_launcher.carplay

import android.content.Context
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.View
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/**
 * Flutter PlatformView hosting a [SurfaceView] that the CarPlay video decoder
 * renders into. Surface availability is reported to a shared [SurfaceProvider]
 * so [CarPlayController] can (re)create the decoder at the right time.
 */
class CarPlayVideoView(
    context: Context,
    private val provider: SurfaceProvider,
) : PlatformView, SurfaceHolder.Callback {

    private val surfaceView = SurfaceView(context)

    init {
        surfaceView.holder.addCallback(this)
    }

    override fun getView(): View = surfaceView

    override fun dispose() {
        surfaceView.holder.removeCallback(this)
    }

    override fun surfaceCreated(holder: SurfaceHolder) {
        provider.onSurfaceAvailable(holder.surface)
    }

    override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
        provider.onSurfaceAvailable(holder.surface)
    }

    override fun surfaceDestroyed(holder: SurfaceHolder) {
        provider.onSurfaceDestroyed()
    }

    /** Bridge so the controller learns when the render Surface is (un)available. */
    interface SurfaceProvider {
        fun onSurfaceAvailable(surface: android.view.Surface)
        fun onSurfaceDestroyed()
    }

    class Factory(
        private val provider: SurfaceProvider,
    ) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
        override fun create(context: Context, viewId: Int, args: Any?): PlatformView =
            CarPlayVideoView(context, provider)
    }

    companion object {
        const val VIEW_TYPE = "car_launcher/carplay_video"

        @Suppress("unused")
        fun register(messenger: BinaryMessenger) {
            // Reserved for future per-view channels.
        }
    }
}
