import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/location_service.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';

/// Top status bar in the MyLink style: title on the left, live temperature and
/// clock on the right. Self-contained (ticks its own clock and polls weather).
class StatusBar extends StatefulWidget {
  const StatusBar({
    super.key,
    required this.locationService,
    required this.weatherService,
  });

  final LocationService locationService;
  final WeatherService weatherService;

  @override
  State<StatusBar> createState() => _StatusBarState();
}

class _StatusBarState extends State<StatusBar> {
  Timer? _clockTimer;
  Timer? _weatherTimer;
  DateTime _now = DateTime.now();
  String? _temperature;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _loadWeather();
    _weatherTimer =
        Timer.periodic(const Duration(minutes: 15), (_) => _loadWeather());
  }

  Future<void> _loadWeather() async {
    final granted = await widget.locationService.ensurePermission();
    if (!granted) return;
    final position = await widget.locationService.currentPosition();
    if (position == null) return;
    final data = await widget.weatherService
        .fetch(position.latitude, position.longitude);
    if (!mounted || data == null) return;
    setState(() => _temperature = '${data.temperatureC.toStringAsFixed(0)}°C');
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _weatherTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(_now);
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_car_rounded,
              color: AppTheme.accent, size: 24),
          const SizedBox(width: 10),
          const Text(
            'MyDrive',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          if (_temperature != null) ...[
            const Icon(Icons.thermostat_rounded,
                color: AppTheme.textSecondary, size: 20),
            const SizedBox(width: 4),
            Text(
              _temperature!,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 18),
          ],
          const Icon(Icons.wifi_rounded,
              color: AppTheme.textSecondary, size: 20),
          const SizedBox(width: 18),
          Text(
            time,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
