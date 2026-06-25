import 'package:flutter/material.dart';

import '../services/location_service.dart';
import '../services/weather_service.dart';
import '../widgets/screen_scaffold.dart';
import '../widgets/weather_card.dart';

/// Full-screen weather detail (opened from the home grid).
class WeatherScreen extends StatelessWidget {
  const WeatherScreen({
    super.key,
    required this.locationService,
    required this.weatherService,
  });

  final LocationService locationService;
  final WeatherService weatherService;

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Clima',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: WeatherCard(
            locationService: locationService,
            weatherService: weatherService,
          ),
        ),
      ),
    );
  }
}
