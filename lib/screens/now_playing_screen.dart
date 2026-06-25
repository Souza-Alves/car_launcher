import 'package:flutter/material.dart';

import '../services/media_controller.dart';
import '../widgets/media_card.dart';
import '../widgets/screen_scaffold.dart';

/// Full-screen media / now-playing controls (opened from the home grid).
class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key, required this.mediaController});

  final MediaController mediaController;

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Mídia',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: MediaCard(mediaController: mediaController),
        ),
      ),
    );
  }
}
