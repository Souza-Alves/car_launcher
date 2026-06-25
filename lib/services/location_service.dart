import 'package:geolocator/geolocator.dart';

/// Thin wrapper around `geolocator` that handles permissions and exposes a
/// continuous position stream used by the speedometer and weather widgets.
class LocationService {
  /// Ensures location services are enabled and permission is granted.
  ///
  /// Returns `true` when the app can read the device position.
  Future<bool> ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Continuous, high-accuracy position updates suitable for live speed.
  Stream<Position> positionStream() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );
    return Geolocator.getPositionStream(locationSettings: settings);
  }

  /// One-shot best-effort current position (used to seed the weather lookup).
  Future<Position?> currentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
    } catch (_) {
      return null;
    }
  }
}
