/*
 *
 *  * Copyright (c) 2024 Solace
 *
 */

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mindful/config/app_constants.dart';
import 'package:mindful/core/extensions/ext_num.dart';
import 'package:mindful/core/extensions/ext_widget.dart';
import 'package:mindful/core/services/method_channel_service.dart';
import 'package:mindful/ui/common/rounded_container.dart';
import 'package:mindful/ui/common/styled_text.dart';

class SliverTabsBottomPadding extends StatelessWidget {
  /// Footer: Sri Lanka + Mohamed Afraar + socials
  const SliverTabsBottomPadding({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 140, bottom: 240),
      child: Center(
        child: Column(
          children: [
            const StyledText(
              "Made with ♥️ in 🇱🇰",
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            4.vBox,
            Text(
              "Mohamed Afraar",
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 15,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: scheme.primary.withValues(alpha: 0.9),
                letterSpacing: 0.3,
              ),
            ),
            8.vBox,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RoundedContainer(
                  height: 30,
                  width: 30,
                  circularRadius: 30,
                  padding: const EdgeInsets.all(6),
                  child: SvgPicture.asset(
                    "assets/vectors/github.svg",
                    colorFilter: ColorFilter.mode(
                      scheme.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                  onPressed: () => MethodChannelService.instance
                      .launchUrl(AppConstants.githubUrl),
                ),
                4.hBox,
                RoundedContainer(
                  height: 30,
                  width: 30,
                  circularRadius: 30,
                  padding: const EdgeInsets.all(6),
                  child: SvgPicture.asset(
                    "assets/vectors/bmc.svg",
                    colorFilter: ColorFilter.mode(
                      scheme.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                  onPressed: () => MethodChannelService.instance
                      .launchUrl(AppConstants.bmcUrl),
                ),
                4.hBox,
                RoundedContainer(
                  height: 30,
                  width: 30,
                  circularRadius: 30,
                  padding: const EdgeInsets.all(6),
                  child: SvgPicture.asset(
                    "assets/vectors/instagram.svg",
                    colorFilter: ColorFilter.mode(
                      scheme.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                  onPressed: () => MethodChannelService.instance
                      .launchUrl(AppConstants.instagramUrl),
                ),
                4.hBox,
                RoundedContainer(
                  height: 30,
                  width: 30,
                  circularRadius: 30,
                  padding: const EdgeInsets.all(6),
                  child: SvgPicture.asset(
                    "assets/vectors/telegram.svg",
                    colorFilter: ColorFilter.mode(
                      scheme.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                  onPressed: () => MethodChannelService.instance
                      .launchUrl(AppConstants.telegramUrl),
                ),
              ],
            ),
          ],
        ),
      ),
    ).sliver;
  }
}
