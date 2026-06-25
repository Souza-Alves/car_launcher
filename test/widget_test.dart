import 'package:car_launcher/models/home_tile.dart';
import 'package:car_launcher/widgets/home_tile_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HomeTileButton renders its label and icon', (tester) async {
    const tile = HomeTile(
      label: 'Navegação',
      icon: Icons.map_rounded,
      gradient: [Colors.blue, Colors.indigo],
      androidPackage: 'com.google.android.apps.maps',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HomeTileButton(tile: tile)),
      ),
    );

    expect(find.text('Navegação'), findsOneWidget);
    expect(find.byIcon(Icons.map_rounded), findsOneWidget);
  });

  test('HomeTile exposes either an app package or an internal screen', () {
    const appTile = HomeTile(
      label: 'Spotify',
      icon: Icons.music_note_rounded,
      gradient: [Colors.green, Colors.teal],
      androidPackage: 'com.spotify.music',
    );
    final screenTile = HomeTile(
      label: 'Clima',
      icon: Icons.cloud_rounded,
      gradient: const [Colors.orange, Colors.deepOrange],
      screenBuilder: (_) => const SizedBox.shrink(),
    );

    expect(appTile.androidPackage, isNotNull);
    expect(appTile.screenBuilder, isNull);
    expect(screenTile.screenBuilder, isNotNull);
    expect(screenTile.androidPackage, isNull);
  });
}
