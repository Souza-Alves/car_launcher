import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:flutter/material.dart';

import '../services/media_controller.dart';
import '../theme/app_theme.dart';

/// Now-playing / media control block (inspired by Car Launcher PRO).
///
/// The transport buttons dispatch system media keys via [MediaController], so
/// they control whichever player currently holds audio focus. Tapping the album
/// art opens Spotify.
class MediaCard extends StatefulWidget {
  const MediaCard({super.key, required this.mediaController});

  final MediaController mediaController;

  @override
  State<MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<MediaCard> {
  bool _isPlaying = false;

  Future<void> _openSpotify() async {
    await LaunchApp.openApp(
      androidPackageName: 'com.spotify.music',
      openStore: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _openSpotify,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.accent, AppTheme.accentAlt],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.music_note_rounded,
                      color: Colors.white, size: 36),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tocando agora',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Controle de mídia',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ControlButton(
                icon: Icons.skip_previous_rounded,
                onTap: widget.mediaController.previous,
              ),
              _ControlButton(
                icon: _isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                primary: true,
                onTap: () {
                  widget.mediaController.playPause();
                  setState(() => _isPlaying = !_isPlaying);
                },
              ),
              _ControlButton(
                icon: Icons.skip_next_rounded,
                onTap: widget.mediaController.next,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final size = primary ? 64.0 : 52.0;
    return Material(
      color: primary ? AppTheme.accent : AppTheme.surfaceHigh,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            color: primary ? AppTheme.background : AppTheme.textPrimary,
            size: primary ? 36 : 28,
          ),
        ),
      ),
    );
  }
}
