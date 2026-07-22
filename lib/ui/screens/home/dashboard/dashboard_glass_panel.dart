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
import 'package:mindful/ui/screens/home/dashboard/dashboard_palette.dart';

/// Soft glass panel used on the dashboard — warm, minimal, orange-tinted.
class DashboardGlassPanel extends StatelessWidget {
  const DashboardGlassPanel({
    super.key,
    required this.child,
    this.margin = EdgeInsets.zero,
    this.padding = EdgeInsets.zero,
    this.borderRadius,
    this.onPressed,
    this.emphasized = false,
  });

  final Widget child;
  final EdgeInsets margin;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;
  final VoidCallback? onPressed;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(24);

    final panel = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: emphasized
                ? DashboardPalette.heroWash(isDark: isDark)
                : DashboardPalette.panelFace(isDark: isDark),
            border: Border.all(
              color: DashboardPalette.royal.withValues(
                alpha: isDark
                    ? (emphasized ? 0.28 : 0.14)
                    : (emphasized ? 0.22 : 0.10),
              ),
              width: emphasized ? 1.1 : 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: DashboardPalette.ember.withValues(
                  alpha: isDark ? 0.18 : 0.08,
                ),
                blurRadius: emphasized ? 28 : 16,
                offset: const Offset(0, 10),
                spreadRadius: -8,
              ),
            ],
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
