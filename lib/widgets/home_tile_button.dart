import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/home_tile.dart';
import '../theme/app_theme.dart';

/// Large rounded "squircle" tile used on the MyLink-style home grid.
class HomeTileButton extends StatelessWidget {
  const HomeTileButton({super.key, required this.tile});

  final HomeTile tile;

  Future<void> _onTap(BuildContext context) async {
    final builder = tile.screenBuilder;
    if (builder != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: builder));
      return;
    }

    final package = tile.androidPackage;
    if (package == null || package.isEmpty) return;

    final opened =
        await LaunchApp.openApp(androidPackageName: package, openStore: false);
    if (opened > 0) return;

    final fallback = tile.fallbackUrl;
    if (fallback != null && fallback.isNotEmpty) {
      final uri = Uri.parse(fallback);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tile.label} não está instalado')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: Material(
              borderRadius: BorderRadius.circular(28),
              clipBehavior: Clip.antiAlias,
              color: Colors.transparent,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: tile.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: InkWell(
                  onTap: () => _onTap(context),
                  child: Center(
                    child: Icon(tile.icon, color: Colors.white, size: 44),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          tile.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
