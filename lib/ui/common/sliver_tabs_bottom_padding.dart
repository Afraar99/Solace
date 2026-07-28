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
  /// Footer: Sri Lanka + Mohamed Afraar + optional socials
  const SliverTabsBottomPadding({super.key});

  Widget? _socialIcon({
    required ColorScheme scheme,
    required String assetPath,
    required String? url,
  }) {
    if (url == null || url.isEmpty) return null;

    return RoundedContainer(
      height: 30,
      width: 30,
      circularRadius: 30,
      padding: const EdgeInsets.all(6),
      child: SvgPicture.asset(
        assetPath,
        colorFilter: ColorFilter.mode(
          scheme.primary,
          BlendMode.srcIn,
        ),
      ),
      onPressed: () => MethodChannelService.instance.launchUrl(url),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final socialIcons = [
      _socialIcon(
        scheme: scheme,
        assetPath: 'assets/vectors/github.svg',
        url: AppConstants.githubUrl,
      ),
      _socialIcon(
        scheme: scheme,
        assetPath: 'assets/vectors/linkedin.svg',
        url: AppConstants.linkedInUrl,
      ),
      _socialIcon(
        scheme: scheme,
        assetPath: 'assets/vectors/x.svg',
        url: AppConstants.xUrl,
      ),
      _socialIcon(
        scheme: scheme,
        assetPath: 'assets/vectors/bmc.svg',
        url: AppConstants.bmcUrl,
      ),
      _socialIcon(
        scheme: scheme,
        assetPath: 'assets/vectors/instagram.svg',
        url: AppConstants.instagramUrl,
      ),
      _socialIcon(
        scheme: scheme,
        assetPath: 'assets/vectors/telegram.svg',
        url: AppConstants.telegramUrl,
      ),
    ].whereType<Widget>().toList();

    return Padding(
      padding: const EdgeInsets.only(top: 140, bottom: 240),
      child: Center(
        child: Column(
          children: [
            const StyledText(
              'Made with ♥️ in 🇱🇰',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            4.vBox,
            Text(
              'Mohamed Afraar',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 15,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: scheme.primary.withValues(alpha: 0.9),
                letterSpacing: 0.3,
              ),
            ),
            if (socialIcons.isNotEmpty) ...[
              8.vBox,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < socialIcons.length; i++) ...[
                    if (i > 0) 4.hBox,
                    socialIcons[i],
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    ).sliver;
  }
}
