import 'package:flutter/material.dart';

/// A single tile on the MyLink-style home grid.
///
/// A tile either launches an external app ([androidPackage] /
/// [androidPackages]) or opens an internal screen ([screenBuilder]).
class HomeTile {
  const HomeTile({
    required this.label,
    required this.icon,
    required this.gradient,
    this.androidPackage,
    this.androidPackages = const [],
    this.fallbackUrl,
    this.screenBuilder,
  });

  final String label;
  final IconData icon;
  final List<Color> gradient;
  final String? androidPackage;

  /// Candidate package names tried in order until one is installed. Useful for
  /// apps that ship under different package IDs across head-unit firmwares
  /// (e.g. the ZLink / CarlinKit CarPlay companion app).
  final List<String> androidPackages;
  final String? fallbackUrl;
  final WidgetBuilder? screenBuilder;

  /// All package names to try, in order ([androidPackage] first).
  List<String> get candidatePackages => [
        if (androidPackage != null && androidPackage!.isNotEmpty)
          androidPackage!,
        ...androidPackages,
      ];
}
