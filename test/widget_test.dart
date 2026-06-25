import 'package:car_launcher/models/launcher_app.dart';
import 'package:car_launcher/widgets/app_shortcut_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppShortcutCard renders its label and icon', (tester) async {
    const app = LauncherApp(
      label: 'Maps',
      icon: Icons.map_rounded,
      color: Colors.green,
      androidPackage: 'com.google.android.apps.maps',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppShortcutCard(app: app)),
      ),
    );

    expect(find.text('Maps'), findsOneWidget);
    expect(find.byIcon(Icons.map_rounded), findsOneWidget);
  });

  test('default shortcut set includes the requested apps', () {
    final packages = defaultApps.map((a) => a.androidPackage).toList();
    expect(packages, contains('com.google.android.apps.maps')); // Maps
    expect(packages, contains('com.waze')); // Waze
    expect(packages, contains('com.spotify.music')); // Spotify
  });
}
