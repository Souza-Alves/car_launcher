import 'package:flutter/material.dart';

/// A shortcut shown on the home grid.
///
/// [androidPackage] is the package launched on tap. [fallbackUrl] is opened
/// (browser or Play Store) when the app is not installed on the device.
class LauncherApp {
  const LauncherApp({
    required this.label,
    required this.icon,
    required this.color,
    required this.androidPackage,
    this.fallbackUrl,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String androidPackage;
  final String? fallbackUrl;
}

/// Default set of shortcuts requested for the launcher.
const List<LauncherApp> defaultApps = <LauncherApp>[
  LauncherApp(
    label: 'Maps',
    icon: Icons.map_rounded,
    color: Color(0xFF34A853),
    androidPackage: 'com.google.android.apps.maps',
    fallbackUrl:
        'https://play.google.com/store/apps/details?id=com.google.android.apps.maps',
  ),
  LauncherApp(
    label: 'Waze',
    icon: Icons.navigation_rounded,
    color: Color(0xFF33CCFF),
    androidPackage: 'com.waze',
    fallbackUrl: 'https://play.google.com/store/apps/details?id=com.waze',
  ),
  LauncherApp(
    label: 'Spotify',
    icon: Icons.music_note_rounded,
    color: Color(0xFF1DB954),
    androidPackage: 'com.spotify.music',
    fallbackUrl:
        'https://play.google.com/store/apps/details?id=com.spotify.music',
  ),
  LauncherApp(
    label: 'YouTube',
    icon: Icons.smart_display_rounded,
    color: Color(0xFFFF0000),
    androidPackage: 'com.google.android.youtube',
    fallbackUrl:
        'https://play.google.com/store/apps/details?id=com.google.android.youtube',
  ),
  LauncherApp(
    label: 'Telefone',
    icon: Icons.phone_rounded,
    color: Color(0xFF4DA3FF),
    androidPackage: 'com.android.dialer',
    fallbackUrl: 'tel:',
  ),
  LauncherApp(
    label: 'Ajustes',
    icon: Icons.settings_rounded,
    color: Color(0xFF9AA5B1),
    androidPackage: 'com.android.settings',
  ),
];
