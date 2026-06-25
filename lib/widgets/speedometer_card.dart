import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/location_service.dart';
import '../theme/app_theme.dart';

/// GPS-based circular speedometer gauge (inspired by AutoLauncher/MotorCar).
///
/// Subscribes to the position stream and renders the current speed in km/h on a
/// sweeping arc gauge. Shows a clear status message when GPS is unavailable.
class SpeedometerCard extends StatefulWidget {
  const SpeedometerCard({super.key, required this.locationService});

  final LocationService locationService;

  /// Top of the gauge scale, in km/h.
  static const double maxSpeed = 180;

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
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(color: AppTheme.surfaceHigh),
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: CustomPaint(
            painter: _GaugePainter(
              value: _hasFix ? _speedKmh : 0,
              maxValue: SpeedometerCard.maxSpeed,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _hasFix ? _speedKmh.toStringAsFixed(0) : '--',
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'km/h',
                    style:
                        TextStyle(fontSize: 15, color: AppTheme.textSecondary),
                  ),
                  if (!_hasFix) ...[
                    const SizedBox(height: 6),
                    Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints a 270° sweep gauge with a track, a value arc and tick marks.
class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.value, required this.maxValue});

  final double value;
  final double maxValue;

  static const double _startAngle = math.pi * 0.75; // 135°
  static const double _sweepAngle = math.pi * 1.5; // 270°

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.09;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.width - stroke) / 2;
    final arcRect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..color = Colors.white.withValues(alpha: 0.08);
    canvas.drawArc(arcRect, _startAngle, _sweepAngle, false, trackPaint);

    final fraction = (value / maxValue).clamp(0.0, 1.0);
    final valuePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..shader = const SweepGradient(
        startAngle: _startAngle,
        endAngle: _startAngle + _sweepAngle,
        colors: [AppTheme.accentAlt, AppTheme.accent],
      ).createShader(arcRect);
    canvas.drawArc(arcRect, _startAngle, _sweepAngle * fraction, false,
        valuePaint);

    // Tick marks around the scale.
    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 2;
    const ticks = 9;
    for (var i = 0; i <= ticks; i++) {
      final angle = _startAngle + _sweepAngle * (i / ticks);
      final outer = center +
          Offset(math.cos(angle), math.sin(angle)) * (radius - stroke / 2);
      final inner = center +
          Offset(math.cos(angle), math.sin(angle)) *
              (radius - stroke / 2 - size.width * 0.05);
      canvas.drawLine(inner, outer, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.maxValue != maxValue;
}
