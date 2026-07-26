/*
 *
 *  * Copyright (c) 2024 Solace
 *
 */

import 'package:flutter/material.dart';
import 'package:mindful/core/extensions/ext_num.dart';
import 'package:mindful/ui/common/styled_text.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.imgArtPath,
    required this.title,
    required this.description,
    this.bottomPadding = 24,
  });

  final String imgArtPath;
  final String title;
  final String description;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        /// Scales with the space actually available, so small and large
        /// screens (and large font sizes) never overflow.
        final artSize = (constraints.maxHeight * 0.42)
            .clamp(120.0, MediaQuery.sizeOf(context).width);

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - bottomPadding)
                  .clamp(0.0, double.infinity),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                8.vBox,

                /// Illustration
                Center(
                  child: SizedBox(
                    height: artSize,
                    width: artSize,
                    child: Image.asset(imgArtPath, fit: BoxFit.contain),
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StyledText(
                      title,
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    4.vBox,
                    StyledText(
                      description,
                      fontSize: 16,
                      height: 1.4,
                      color: Theme.of(context).hintColor,
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
