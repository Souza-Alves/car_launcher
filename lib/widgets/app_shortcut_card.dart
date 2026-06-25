import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/launcher_app.dart';
import '../theme/app_theme.dart';

/// Large tappable tile that launches an installed app, falling back to a URL
/// (Play Store / browser) when the app is not present.
class AppShortcutCard extends StatelessWidget {
  const AppShortcutCard({super.key, required this.app, this.onTap});

  final LauncherApp app;
  final VoidCallback? onTap;

  Future<void> _launch(BuildContext context) async {
    if (onTap != null) {
      onTap!();
      return;
    }

    final opened = await LaunchApp.openApp(
      androidPackageName: app.androidPackage,
      openStore: false,
    );

    // `openApp` returns a non-positive value when the app is not installed.
    if (opened > 0) {
      return;
    }

    final fallback = app.fallbackUrl;
    if (fallback != null && fallback.isNotEmpty) {
      final uri = Uri.parse(fallback);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${app.label} não está instalado')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _launch(context),
        child: Container(
          decoration: AppTheme.cardDecoration(),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: app.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(app.icon, color: app.color, size: 36),
              ),
              const SizedBox(height: 12),
              Text(
                app.label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
