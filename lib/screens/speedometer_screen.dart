import 'package:flutter/material.dart';

import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/speedometer_card.dart';
import '../widgets/screen_scaffold.dart';

/// Full-screen GPS speedometer (opened from the home grid).
class SpeedometerScreen extends StatelessWidget {
  const SpeedometerScreen({super.key, required this.locationService});

  final LocationService locationService;

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Velocímetro',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration:
                  AppTheme.cardDecoration(color: AppTheme.surfaceHigh),
              child: SpeedometerCard(locationService: locationService),
            ),
          ),
        ),
      ),
    );
  }
}
