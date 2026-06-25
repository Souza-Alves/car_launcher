import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/location_service.dart';
import '../theme/app_theme.dart';

/// GPS-based speedometer. Subscribes to the position stream and renders the
/// current speed in km/h. Shows a clear status message when GPS is unavailable.
class SpeedometerCard extends StatefulWidget {
  const SpeedometerCard({super.key, required this.locationService});

  final LocationService locationService;

  @override
  State<SpeedometerCard> createState() => _SpeedometerCardState();
}

class _SpeedometerCardState extends State<SpeedometerCard> {
  StreamSubscription<Position>? _subscription;
  double _speedKmh = 0;
  bool _hasFix = false;
  String _status = 'Aguardando GPS...';

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final granted = await widget.locationService.ensurePermission();
    if (!granted) {
      if (mounted) {
        setState(() => _status = 'GPS sem permissão');
      }
      return;
    }

    _subscription = widget.locationService.positionStream().listen(
      (position) {
        if (!mounted) return;
        // geolocator reports speed in m/s; convert to km/h and clamp noise.
        final kmh = (position.speed * 3.6).clamp(0, 360).toDouble();
        setState(() {
          _speedKmh = kmh;
          _hasFix = true;
        });
      },
      onError: (_) {
        if (mounted) {
          setState(() => _status = 'Erro de GPS');
        }
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: AppTheme.cardDecoration(color: AppTheme.surfaceHigh),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.speed_rounded, color: AppTheme.accentAlt, size: 28),
          const SizedBox(height: 4),
          Text(
            _hasFix ? _speedKmh.toStringAsFixed(0) : '--',
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w700,
              height: 1,
              color: AppTheme.textPrimary,
            ),
          ),
          const Text(
            'km/h',
            style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
          ),
          if (!_hasFix) ...[
            const SizedBox(height: 6),
            Text(
              _status,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
