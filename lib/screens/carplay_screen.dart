import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/carplay_controller.dart';
import '../theme/app_theme.dart';

/// Full-screen CarPlay receiver. Renders the dongle's H.264 video in a native
/// PlatformView and forwards touches back to the iPhone via [CarPlayController].
class CarPlayScreen extends StatefulWidget {
  const CarPlayScreen({super.key});

  @override
  State<CarPlayScreen> createState() => _CarPlayScreenState();
}

class _CarPlayScreenState extends State<CarPlayScreen> {
  final CarPlayController _controller = CarPlayController();
  StreamSubscription<CarPlayEvent>? _sub;
  CarPlayEvent _event = const CarPlayEvent(CarPlayStatus.idle);
  Size _viewSize = Size.zero;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _sub = _controller.events.listen(
      (e) => setState(() => _event = e),
      onError: (Object e) => setState(
        () => _event = CarPlayEvent(CarPlayStatus.error, e.toString()),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final media = MediaQuery.of(context);
    final dpr = media.devicePixelRatio;
    final size = media.size;
    // Mic is needed for Siri / phone calls; best-effort, harmless if denied.
    Permission.microphone.request();
    _controller.start(
      width: (size.width * dpr).round(),
      height: (size.height * dpr).round(),
      dpi: (160 * dpr).round(),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.stop();
    super.dispose();
  }

  void _sendTouch(String action, Offset local) {
    if (_viewSize.width <= 0 || _viewSize.height <= 0) return;
    _controller.touch(
      action,
      local.dx / _viewSize.width,
      local.dy / _viewSize.height,
    );
  }

  bool get _isLive => _event.status == CarPlayStatus.phoneConnected;

  String get _statusText => switch (_event.status) {
        CarPlayStatus.idle => 'Iniciando…',
        CarPlayStatus.connecting => 'Procurando o dongle CarlinKit…',
        CarPlayStatus.dongleConnected =>
          'Dongle conectado. Conecte o iPhone (USB ou Wi-Fi) e toque em "Confiar".',
        CarPlayStatus.phoneConnected => 'Conectado',
        CarPlayStatus.phoneDisconnected => 'iPhone desconectado.',
        CarPlayStatus.closed => 'Sessão encerrada.',
        CarPlayStatus.error => _event.message ?? 'Erro na conexão CarPlay.',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _viewSize = constraints.biggest;
                  return Listener(
                    onPointerDown: (e) => _sendTouch('down', e.localPosition),
                    onPointerMove: (e) => _sendTouch('move', e.localPosition),
                    onPointerUp: (e) => _sendTouch('up', e.localPosition),
                    child: const _CarPlayVideoView(),
                  );
                },
              ),
            ),
            if (!_isLive)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.85),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _event.status == CarPlayStatus.error
                            ? Icons.usb_off_rounded
                            : Icons.directions_car_filled_rounded,
                        color: AppTheme.accent,
                        size: 64,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _statusText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              top: 8,
              left: 8,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Native render surface for the decoded CarPlay video.
class _CarPlayVideoView extends StatelessWidget {
  const _CarPlayVideoView();

  static const String _viewType = 'car_launcher/carplay_video';

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).platform != TargetPlatform.android) {
      return const ColoredBox(color: Colors.black);
    }
    return const AndroidView(
      viewType: _viewType,
      creationParams: null,
      creationParamsCodec: StandardMessageCodec(),
    );
  }
}
