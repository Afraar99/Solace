/*
 *
 *  * Copyright (c) 2024 Mindful (https://github.com/akaMrNagar/Mindful)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'package:flutter/material.dart';

/// Royal-orange accents scoped to the dashboard preview theme.
abstract final class DashboardPalette {
  static const Color ember = Color(0xFFB84312);
  static const Color royal = Color(0xFFE46B18);
  static const Color apricot = Color(0xFFF2A65A);
  static const Color champagne = Color(0xFFF7D9B8);
  static const Color warmInk = Color(0xFF1C120C);
  static const Color warmIvory = Color(0xFFFFF7F0);

  static const seed = Color(0xFFE87722);

  static LinearGradient ambient({required bool isDark}) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [
                Color(0xFF24160F),
                Color(0xFF16100C),
                Color(0xFF1A100C),
              ]
            : const [
                Color(0xFFFFF4EA),
                Color(0xFFFFF9F4),
                Color(0xFFFFF1E4),
              ],
        stops: const [0.0, 0.45, 1.0],
      );

  static LinearGradient heroWash({required bool isDark}) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                royal.withValues(alpha: 0.34),
                ember.withValues(alpha: 0.18),
                Colors.transparent,
              ]
            : [
                apricot.withValues(alpha: 0.42),
                royal.withValues(alpha: 0.18),
                champagne.withValues(alpha: 0.08),
              ],
      );

  static LinearGradient panelFace({required bool isDark}) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                Colors.white.withValues(alpha: 0.08),
                royal.withValues(alpha: 0.10),
                Colors.white.withValues(alpha: 0.03),
              ]
            : [
                Colors.white.withValues(alpha: 0.86),
                champagne.withValues(alpha: 0.55),
                Colors.white.withValues(alpha: 0.72),
              ],
      );
}
