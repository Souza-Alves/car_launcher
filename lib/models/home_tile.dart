import 'package:flutter/material.dart';

/// A single tile on the MyLink-style home grid.
///
/// A tile either launches an external app ([androidPackage]) or opens an
/// internal screen ([screenBuilder]). Exactly one should be provided.
class HomeTile {
  const HomeTile({
    required this.label,
    required this.icon,
    required this.gradient,
    this.androidPackage,
    this.fallbackUrl,
    this.screenBuilder,
  });

  final String label;
  final IconData icon;
  final List<Color> gradient;
  final String? androidPackage;
  final String? fallbackUrl;
  final WidgetBuilder? screenBuilder;
}
