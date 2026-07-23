/*
 *
 *  * Copyright (c) 2024 Solace
 *
 */

import 'package:flutter/material.dart';
import 'package:mindful/ui/transitions/default_page_transition_builder.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Solace visual identity — solid dark surfaces with burgundy accents.
class AppTheme {
  static const Color solaceBurgundy = Color(0xFF8B1E3F);
  static const Color solaceBurgundyLight = Color(0xFFC23A5E);
  static const Color solaceInk = Color(0xFF0E1218);
  static const Color solaceSurface = Color(0xFF151A22);
  static const Color solaceElevated = Color(0xFF1C2330);
  static const Color solaceBlueGrey = Color(0xFF1A2230);

  /// Kept for compatibility with older settings color names.
  static const Color solaceTeal = Color(0xFF2DD4BF);
  static const Color solaceIndigo = Color(0xFF6366F1);

  static const _kSeedColor = solaceBurgundy;

  static final _kShimmerEffect = ShimmerEffect(
    highlightColor: Colors.white.withValues(alpha: 0.08),
    baseColor: Colors.white.withValues(alpha: 0.03),
  );

  static const _kPageTransitionTheme = PageTransitionsTheme(
    builders: {TargetPlatform.android: DefaultPageTransitionsBuilder()},
  );

  static final materialColors = <String, MaterialColor>{
    'Burgundy': const MaterialColor(0xFF8B1E3F, {
      50: Color(0xFFF8E8EE),
      100: Color(0xFFEBC5D1),
      200: Color(0xFFD98EAA),
      300: Color(0xFFC23A5E),
      400: Color(0xFFA8284C),
      500: Color(0xFF8B1E3F),
      600: Color(0xFF741834),
      700: Color(0xFF5C1229),
      800: Color(0xFF450D1F),
      900: Color(0xFF2E0814),
    }),
    'Teal': Colors.teal,
    'Indigo': Colors.indigo,
    'Cyan': Colors.cyan,
    'Blue': Colors.blue,
    'Deep Purple': Colors.deepPurple,
    'Green': Colors.green,
    'Blue Grey': Colors.blueGrey,
    'Grey': Colors.grey,
    'Red': Colors.red,
    'Pink': Colors.pink,
    'Purple': Colors.purple,
  };

  static ColorScheme _darkScheme({Color? seedColor, required bool isAmoled}) {
    final base = ColorScheme.fromSeed(
      seedColor: seedColor ?? _kSeedColor,
      brightness: Brightness.dark,
    );

    final surface = isAmoled ? Colors.black : solaceSurface;
    final container = isAmoled ? const Color(0xFF10141A) : solaceElevated;

    return base.copyWith(
      surface: surface,
      surfaceContainerLowest: isAmoled ? Colors.black : solaceInk,
      surfaceContainerLow: container,
      surfaceContainer: container,
      surfaceContainerHigh: const Color(0xFF242C3A),
      surfaceContainerHighest: const Color(0xFF2C3545),
      primary: solaceBurgundyLight,
      onPrimary: Colors.white,
      secondary: solaceBurgundy,
      onSecondary: Colors.white,
      tertiary: const Color(0xFF9CA3AF),
      outline: Colors.white.withValues(alpha: 0.10),
      outlineVariant: Colors.white.withValues(alpha: 0.05),
    );
  }

  static ThemeData darkTheme({Color? seedColor, required bool isAmoled}) {
    final scheme = _darkScheme(seedColor: seedColor, isAmoled: isAmoled);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surfaceContainerLowest,
      pageTransitionsTheme: _kPageTransitionTheme,
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.5)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outline.withValues(alpha: 0.35),
        thickness: 0.6,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: scheme.onSurface,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      extensions: [SkeletonizerConfigData.dark(effect: _kShimmerEffect)],
    );
  }

  static ThemeData lightTheme({Color? seedColor}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor ?? _kSeedColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      pageTransitionsTheme: _kPageTransitionTheme,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      extensions: [SkeletonizerConfigData(effect: _kShimmerEffect)],
    );
  }
}
