import 'package:flutter/services.dart';

/// Dispatches media key events to the system so the controls drive whatever
/// player currently holds audio focus (Spotify, YouTube Music, etc.).
class MediaController {
  static const MethodChannel _channel = MethodChannel('car_launcher/media');

  Future<void> playPause() => _invoke('playPause');
  Future<void> next() => _invoke('next');
  Future<void> previous() => _invoke('previous');

  Future<void> _invoke(String method) async {
    try {
      await _channel.invokeMethod<bool>(method);
    } on PlatformException {
      // Media key dispatch is best-effort; ignore platform failures.
    } on MissingPluginException {
      // Channel unavailable (e.g. running on an unsupported platform).
    }
  }
}
