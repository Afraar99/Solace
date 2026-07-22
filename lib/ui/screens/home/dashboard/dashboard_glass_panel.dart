/*
 *
 *  * Copyright (c) 2024 Mindful (https://github.com/akaMrNagar/Mindful)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'dart:ui';

import 'package:flutter/material.dart';

/// Soft glass panel used on the dashboard for a calmer, less cluttered look.
class DashboardGlassPanel extends StatelessWidget {
  const DashboardGlassPanel({
    super.key,
    required this.child,
    this.margin = EdgeInsets.zero,
    this.padding = EdgeInsets.zero,
    this.borderRadius,
    this.onPressed,
  });

  final Widget child;
  final EdgeInsets margin;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(22);

    final panel = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.surface.withValues(alpha: isDark ? 0.42 : 0.62),
                scheme.surfaceContainerHighest
                    .withValues(alpha: isDark ? 0.28 : 0.45),
              ],
            ),
            border: Border.all(
              color: scheme.onSurface.withValues(alpha: isDark ? 0.08 : 0.06),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: onPressed == null
                ? Padding(padding: padding, child: child)
                : InkWell(
                    onTap: onPressed,
                    borderRadius: radius,
                    splashFactory: InkSparkle.splashFactory,
                    child: Padding(padding: padding, child: child),
                  ),
          ),
        ),
      ),
    );

    return Padding(padding: margin, child: panel);
  }
}
