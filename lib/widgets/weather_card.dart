import 'dart:async';

import 'package:flutter/material.dart';

import '../services/location_service.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';

/// Current weather block. Resolves the device location, queries Open-Meteo and
/// refreshes periodically.
class WeatherCard extends StatefulWidget {
  const WeatherCard({
    super.key,
    required this.locationService,
    required this.weatherService,
  });

  final LocationService locationService;
  final WeatherService weatherService;

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  Timer? _timer;
  WeatherData? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(minutes: 15), (_) => _refresh());
  }

  Future<void> _refresh() async {
    final granted = await widget.locationService.ensurePermission();
    if (!granted) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Sem localização';
        });
      }
      return;
    }

    final position = await widget.locationService.currentPosition();
    if (position == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Sem GPS';
        });
      }
      return;
    }

    final data = await widget.weatherService.fetch(
      position.latitude,
      position.longitude,
    );
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
      _error = data == null ? 'Indisponível' : null;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: AppTheme.cardDecoration(),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 16),
          Text('Carregando clima...',
              style: TextStyle(color: AppTheme.textSecondary)),
        ],
      );
    }

    final data = _data;
    if (data == null) {
      return Row(
        children: [
          const Icon(Icons.cloud_off_rounded,
              color: AppTheme.textSecondary, size: 40),
          const SizedBox(width: 16),
          Text(
            _error ?? 'Clima indisponível',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 18),
          ),
        ],
      );
    }

    final info = _describe(data.weatherCode, data.isDay);
    return Row(
      children: [
        Icon(info.icon, color: info.color, size: 56),
        const SizedBox(width: 18),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${data.temperatureC.toStringAsFixed(0)}°C',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              info.label,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Maps WMO weather codes to an icon, color and pt-BR label.
  _WeatherInfo _describe(int code, bool isDay) {
    if (code == 0) {
      return isDay
          ? const _WeatherInfo(Icons.wb_sunny_rounded, Color(0xFFFFC23D), 'Céu limpo')
          : const _WeatherInfo(Icons.nightlight_round, Color(0xFFB0B8FF), 'Noite limpa');
    }
    if (code >= 1 && code <= 3) {
      return const _WeatherInfo(
          Icons.cloud_rounded, Color(0xFF9AA5B1), 'Parcialmente nublado');
    }
    if (code == 45 || code == 48) {
      return const _WeatherInfo(Icons.foggy, Color(0xFF9AA5B1), 'Névoa');
    }
    if (code >= 51 && code <= 57) {
      return const _WeatherInfo(
          Icons.grain_rounded, Color(0xFF4DA3FF), 'Garoa');
    }
    if (code >= 61 && code <= 67) {
      return const _WeatherInfo(
          Icons.umbrella_rounded, Color(0xFF4DA3FF), 'Chuva');
    }
    if (code >= 71 && code <= 77) {
      return const _WeatherInfo(
          Icons.ac_unit_rounded, Color(0xFF8FD3FF), 'Neve');
    }
    if (code >= 80 && code <= 82) {
      return const _WeatherInfo(
          Icons.umbrella_rounded, Color(0xFF4DA3FF), 'Pancadas de chuva');
    }
    if (code >= 85 && code <= 86) {
      return const _WeatherInfo(
          Icons.ac_unit_rounded, Color(0xFF8FD3FF), 'Neve');
    }
    if (code >= 95) {
      return const _WeatherInfo(
          Icons.thunderstorm_rounded, Color(0xFFFFC23D), 'Tempestade');
    }
    return const _WeatherInfo(
        Icons.cloud_rounded, Color(0xFF9AA5B1), 'Nublado');
  }
}

class _WeatherInfo {
  const _WeatherInfo(this.icon, this.color, this.label);
  final IconData icon;
  final Color color;
  final String label;
}
