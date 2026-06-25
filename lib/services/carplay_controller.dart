import 'package:flutter/services.dart';

/// High-level CarPlay session state surfaced to the UI.
enum CarPlayStatus {
  idle,
  connecting,
  dongleConnected,
  phoneConnected,
  phoneDisconnected,
  closed,
  error,
}

class CarPlayEvent {
  const CarPlayEvent(this.status, [this.message]);

  final CarPlayStatus status;
  final String? message;

  static CarPlayEvent fromMap(Map<dynamic, dynamic> map) {
    final status = switch (map['status'] as String?) {
      'connecting' => CarPlayStatus.connecting,
      'dongleConnected' => CarPlayStatus.dongleConnected,
      'phoneConnected' => CarPlayStatus.phoneConnected,
      'phoneDisconnected' => CarPlayStatus.phoneDisconnected,
      'closed' => CarPlayStatus.closed,
      'error' => CarPlayStatus.error,
      _ => CarPlayStatus.idle,
    };
    return CarPlayEvent(status, map['message'] as String?);
  }
}

/// Talks to the native CarPlay receiver ([CarPlayController] on Android) over a
/// method channel (commands) and event channel (status updates). The native
/// side handles the CarlinKit USB dongle, H.264 decode and rendering.
class CarPlayController {
  static const MethodChannel _method = MethodChannel('car_launcher/carplay');
  static const EventChannel _events =
      EventChannel('car_launcher/carplay/events');

  Stream<CarPlayEvent> get events => _events
      .receiveBroadcastStream()
      .map((e) => CarPlayEvent.fromMap(e as Map<dynamic, dynamic>));

  Future<void> start({
    required int width,
    required int height,
    int fps = 30,
    int dpi = 160,
  }) async {
    await _method.invokeMethod<bool>('start', {
      'width': width,
      'height': height,
      'fps': fps,
      'dpi': dpi,
    });
  }

  Future<void> stop() async {
    await _method.invokeMethod<bool>('stop');
  }

  Future<void> touch(String action, double x, double y) async {
    await _method.invokeMethod<bool>('touch', {
      'action': action,
      'x': x.clamp(0.0, 1.0),
      'y': y.clamp(0.0, 1.0),
    });
  }
}
