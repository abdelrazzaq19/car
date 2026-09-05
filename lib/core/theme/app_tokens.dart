import 'package:flutter/material.dart';

/// Design tokens.
///
/// Every spacing, radius, duration and brand colour used by the UI lives here,
/// so a change lands in one place rather than being hunted down across screens.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
}

abstract final class AppDuration {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 600);
}

abstract final class AppColors {
  /// Seed for the Material 3 colour scheme. A deep automotive blue reads as
  /// premium in both themes and keeps enough contrast for the price accents.
  static const Color seed = Color(0xFF1B4DE4);

  /// Semantic accents that sit outside the generated scheme.
  static const Color success = Color(0xFF178A5A);
  static const Color warning = Color(0xFFB25E02);
}

/// Minimum tap target required for accessibility.
const double kMinTapTarget = 48;
