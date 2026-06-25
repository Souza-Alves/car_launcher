import 'package:flutter/material.dart';

import '../models/launcher_app.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shortcut_card.dart';
import '../widgets/clock_card.dart';
import '../widgets/speedometer_card.dart';
import '../widgets/weather_card.dart';

/// Main launcher dashboard. Landscape, block-based layout split into an
/// information column (clock + weather + speed) and an app shortcut grid.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationService _locationService = LocationService();
  final WeatherService _weatherService = WeatherService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left information column.
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    const ClockCard(),
                    const SizedBox(height: 16),
                    WeatherCard(
                      locationService: _locationService,
                      weatherService: _weatherService,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SpeedometerCard(
                        locationService: _locationService,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Right app shortcut grid.
              Expanded(
                flex: 7,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.cardDecoration(color: AppTheme.background),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 12),
                        child: Text(
                          'Atalhos',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 1.1,
                          ),
                          itemCount: defaultApps.length,
                          itemBuilder: (context, index) =>
                              AppShortcutCard(app: defaultApps[index]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
