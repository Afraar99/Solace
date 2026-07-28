/*
 *
 *  * Copyright (c) 2024 Solace
 *
 */

import 'dart:math';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindful/config/navigation/app_routes.dart';
import 'package:mindful/core/enums/item_position.dart';
import 'package:mindful/core/extensions/ext_build_context.dart';
import 'package:mindful/core/extensions/ext_num.dart';
import 'package:mindful/core/extensions/ext_widget.dart';
import 'package:mindful/core/services/method_channel_service.dart';
import 'package:mindful/config/app_constants.dart';
import 'package:mindful/core/utils/widget_utils.dart';
import 'package:mindful/ui/common/breathing_widget.dart';
import 'package:mindful/ui/common/default_list_tile.dart';
import 'package:mindful/ui/common/rounded_container.dart';
import 'package:mindful/ui/common/content_section_header.dart';
import 'package:mindful/ui/common/sliver_primary_action_container.dart';
import 'package:mindful/ui/common/sliver_app_version_info.dart';
import 'package:mindful/ui/common/styled_text.dart';
import 'package:mindful/ui/common/sliver_tabs_bottom_padding.dart';

class TabAbout extends ConsumerWidget {
  const TabAbout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedbackUrl = AppConstants.githubFeedbackSectionUrl;
    final githubUrl = AppConstants.githubUrl;
    final issueUrl = AppConstants.githubIssueDirectUrl;
    final suggestionUrl = AppConstants.githubSuggestionDirectUrl;
    final emailUrl = AppConstants.supportEmailUrl;
    final privacyUrl = AppConstants.privacyPolicyUrl;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverAppVersionInfo(),

        /// Brand logo
        BreathingWidget(
          dimension: min(360, MediaQuery.of(context).size.width * 0.7),
          child: RoundedContainer(
            circularRadius: 120,
            color: const Color(0xFFC5D4A8),
            padding: const EdgeInsets.all(28),
            child: Image.asset(
              'assets/logo/solace_logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ).sliver,

        /// Title
        const StyledText(
          'Solace',
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ).centered.sliver,

        /// Tag line about focus
        StyledText(
          context.locale.mindful_tagline,
          fontSize: 16,
          isSubtitle: true,
        ).centered.sliver,

        24.vSliverBox,

        if (feedbackUrl != null)
          SliverPrimaryActionContainer(
            isVisible: true,
            radius: getBorderRadiusFromPosition(ItemPosition.top),
            icon: FluentIcons.handshake_20_regular,
            title: context.locale.donation_card_title,
            information: context.locale.donation_card_info,
            positiveBtn: FilledButton.icon(
              icon: const Icon(FluentIcons.heart_20_filled),
              label: Text(context.locale.donation_card_button_donate),
              onPressed: () =>
                  MethodChannelService.instance.launchUrl(feedbackUrl),
            ),
          ),

        /// Change log
        DefaultListTile(
          position:
              feedbackUrl != null ? ItemPosition.bottom : ItemPosition.top,
          leadingIcon: FluentIcons.slide_text_20_regular,
          titleText: context.locale.changelog_tile_title,
          subtitleText: context.locale.changelog_tile_subtitle,
          trailing: const Icon(FluentIcons.chevron_right_20_regular),
          onPressed: () =>
              Navigator.of(context).pushNamed(AppRoutes.changeLogsPath),
        ).sliver,

        if (githubUrl != null ||
            issueUrl != null ||
            suggestionUrl != null ||
            emailUrl != null) ...[
          ContentSectionHeader(title: context.locale.contribute_heading).sliver,
          if (githubUrl != null)
            DefaultListTile(
              position: _resolveLinkPosition(
                isFirst: true,
                isLast: issueUrl == null &&
                    suggestionUrl == null &&
                    emailUrl == null,
              ),
              leadingIcon: FluentIcons.code_20_regular,
              titleText: context.locale.github_tile_title,
              subtitleText: context.locale.github_tile_subtitle,
              onPressed: () =>
                  MethodChannelService.instance.launchUrl(githubUrl),
            ).sliver,
          if (issueUrl != null)
            DefaultListTile(
              position: _resolveLinkPosition(
                isFirst: githubUrl == null,
                isLast: suggestionUrl == null && emailUrl == null,
              ),
              leadingIcon: FluentIcons.bug_20_regular,
              titleText: context.locale.report_issue_tile_title,
              subtitleText: context.locale.redirected_to_github_subtitle,
              onPressed: () =>
                  MethodChannelService.instance.launchUrl(issueUrl),
            ).sliver,
          if (suggestionUrl != null)
            DefaultListTile(
              position: _resolveLinkPosition(
                isFirst: githubUrl == null && issueUrl == null,
                isLast: emailUrl == null,
              ),
              leadingIcon: FluentIcons.lightbulb_filament_20_regular,
              titleText: context.locale.suggest_idea_tile_title,
              subtitleText: context.locale.redirected_to_github_subtitle,
              onPressed: () =>
                  MethodChannelService.instance.launchUrl(suggestionUrl),
            ).sliver,
          if (emailUrl != null)
            DefaultListTile(
              position: ItemPosition.bottom,
              leadingIcon: FluentIcons.mail_20_regular,
              titleText: context.locale.write_email_tile_title,
              subtitleText: context.locale.write_email_tile_subtitle,
              onPressed: () =>
                  MethodChannelService.instance.launchUrl(emailUrl),
            ).sliver,
        ],

        if (privacyUrl != null) ...[
          ContentSectionHeader(title: context.locale.privacy_policy_heading)
              .sliver,
          StyledText(context.locale.privacy_policy_info).sliver,
          12.vSliverBox,
          FilledButton.tonalIcon(
            icon: const Icon(FluentIcons.info_20_regular),
            label: Text(context.locale.more_details_button),
            onPressed: () =>
                MethodChannelService.instance.launchUrl(privacyUrl),
          ).rightCentered.sliver,
        ],

        const SliverTabsBottomPadding(),
      ],
    );
  }

  ItemPosition _resolveLinkPosition({
    required bool isFirst,
    required bool isLast,
  }) {
    if (isFirst && isLast) return ItemPosition.none;
    if (isFirst) return ItemPosition.top;
    if (isLast) return ItemPosition.bottom;
    return ItemPosition.mid;
  }
}
