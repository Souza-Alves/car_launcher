import 'package:flutter/material.dart';

import '../models/home_tile.dart';
import '../services/location_service.dart';
import '../services/media_controller.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import '../widgets/home_tile_button.dart';
import '../widgets/status_bar.dart';
import 'now_playing_screen.dart';
import 'speedometer_screen.dart';
import 'weather_screen.dart';

/// Chevrolet MyLink–style home: a top status bar over a paginated grid of large
/// rounded tiles. Tiles either launch installed apps or open internal screens
/// (media, speedometer, weather).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationService _locationService = LocationService();
  final WeatherService _weatherService = WeatherService();
  final MediaController _mediaController = MediaController();
  final PageController _pageController = PageController();

  static const int _columns = 4;
  static const int _rows = 2;
  static const int _perPage = _columns * _rows;

  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Request location permission once up front; widgets share the result.
    _locationService.ensurePermission();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<HomeTile> _buildTiles() {
    return [
      HomeTile(
        label: 'Telefone',
        icon: Icons.phone_rounded,
        gradient: const [Color(0xFF43E97B), Color(0xFF38F9D7)],
        androidPackage: 'com.android.dialer',
        fallbackUrl: 'tel:',
      ),
      HomeTile(
        label: 'Navegação',
        icon: Icons.map_rounded,
        gradient: const [Color(0xFF4DA3FF), Color(0xFF1E63D6)],
        androidPackage: 'com.google.android.apps.maps',
        fallbackUrl:
            'https://play.google.com/store/apps/details?id=com.google.android.apps.maps',
      ),
      HomeTile(
        label: 'Mídia',
        icon: Icons.library_music_rounded,
        gradient: const [Color(0xFFFF6A88), Color(0xFFFF99AC)],
        screenBuilder: (_) =>
            NowPlayingScreen(mediaController: _mediaController),
      ),
      HomeTile(
        label: 'Spotify',
        icon: Icons.music_note_rounded,
        gradient: const [Color(0xFF1DB954), Color(0xFF169C46)],
        androidPackage: 'com.spotify.music',
        fallbackUrl:
            'https://play.google.com/store/apps/details?id=com.spotify.music',
      ),
      HomeTile(
        label: 'Waze',
        icon: Icons.navigation_rounded,
        gradient: const [Color(0xFF33CCFF), Color(0xFF0E8BD6)],
        androidPackage: 'com.waze',
        fallbackUrl: 'https://play.google.com/store/apps/details?id=com.waze',
      ),
      HomeTile(
        label: 'YouTube',
        icon: Icons.smart_display_rounded,
        gradient: const [Color(0xFFFF5858), Color(0xFFD60000)],
        androidPackage: 'com.google.android.youtube',
        fallbackUrl:
            'https://play.google.com/store/apps/details?id=com.google.android.youtube',
      ),
      HomeTile(
        label: 'Velocímetro',
        icon: Icons.speed_rounded,
        gradient: const [Color(0xFF7F7FD5), Color(0xFF4A4AE0)],
        screenBuilder: (_) =>
            SpeedometerScreen(locationService: _locationService),
      ),
      HomeTile(
        label: 'Clima',
        icon: Icons.cloud_rounded,
        gradient: const [Color(0xFFFFB75E), Color(0xFFED8F03)],
        screenBuilder: (_) => WeatherScreen(
          locationService: _locationService,
          weatherService: _weatherService,
        ),
      ),
      // Projection: launch the head unit's Android Auto / CarPlay host app.
      HomeTile(
        label: 'Android Auto',
        icon: Icons.android_rounded,
        gradient: const [Color(0xFF3DDC84), Color(0xFF1FA463)],
        androidPackage: 'com.google.android.projection.gearhead',
        fallbackUrl:
            'https://play.google.com/store/apps/details?id=com.google.android.projection.gearhead',
      ),
      // CarPlay via the ZLink / CarlinKit companion app. The package id varies
      // by head-unit firmware, so try the common ones in order.
      HomeTile(
        label: 'CarPlay',
        icon: Icons.directions_car_filled_rounded,
        gradient: const [Color(0xFF8E9EAB), Color(0xFF5B6770)],
        androidPackages: const [
          'com.zjinnova.zlink',
          'com.carlinkit.zlink',
          'cn.manstep.phonemirrorBox',
          'com.carlinkit.airplay',
        ],
        fallbackUrl: 'https://play.google.com/store/search?q=zlink&c=apps',
      ),
      HomeTile(
        label: 'Câmera',
        icon: Icons.photo_camera_rounded,
        gradient: const [Color(0xFF606C88), Color(0xFF3F4C6B)],
        androidPackage: 'com.android.camera2',
        fallbackUrl: 'https://play.google.com/store/search?q=camera&c=apps',
      ),
      HomeTile(
        label: 'Ajustes',
        icon: Icons.settings_rounded,
        gradient: const [Color(0xFF9AA5B1), Color(0xFF6B7682)],
        androidPackage: 'com.android.settings',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tiles = _buildTiles();
    final pageCount = (tiles.length / _perPage).ceil();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              StatusBar(
                locationService: _locationService,
                weatherService: _weatherService,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: pageCount,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  itemBuilder: (context, page) {
                    final start = page * _perPage;
                    final end = (start + _perPage).clamp(0, tiles.length);
                    final pageTiles = tiles.sublist(start, end);
                    return GridView.count(
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: _columns,
                      mainAxisSpacing: 18,
                      crossAxisSpacing: 18,
                      childAspectRatio: 0.85,
                      children: [
                        for (final tile in pageTiles)
                          HomeTileButton(tile: tile),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              _PageDots(count: pageCount, current: _currentPage),
            ],
          ),
        ),
      ),
    );
  }
}

/// MyLink-style page indicator dots.
class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == current ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == current
                  ? AppTheme.accent
                  : Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
