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
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:mindful/core/enums/app_theme_mode.dart';

class AppConstants {
  // App Defaults
  static const defaultThemeMode = AppThemeMode.dark;
  static const defaultMaterialColor = "Burgundy";
  static const defaultLocale = "en";
  static const defaultUsername = "Achiever";
  static const defaultCurve = Curves.easeOutCubic;
  static const defaultAnimDuration = Duration(milliseconds: 220);

  // Custom packages
  static const removedAppPackage = "com.android.removed";
  static const tetheringAppPackage = "com.android.tethering";

  /// External links — null hides the UI entry.
  static const String? githubUrl = "https://github.com/Afraar99/Solace";
  static const String? linkedInUrl =
      "https://www.linkedin.com/in/mohamed-afraar";
  static const String? xUrl = "https://x.com/afraar_99";

  /// Donation — kept off for now (enable later when ready).
  static const String? bmcUrl = null;
  static const String? gitHubDonationSectionUrl = null;
  static const String? githubFeedbackSectionUrl = null;

  static const String? instagramUrl = null;
  static const String? telegramUrl = null;
  static const String? supportEmailUrl = null;
  static const String? privacyPolicyUrl = null;
  static const String? faqsUrl =
      "https://github.com/Afraar99/Solace#download";

  static String? githubChangeLogUrl(String appVersion) =>
      "$githubUrl/releases/tag/v$appVersion";

  static const String? githubIssueDirectUrl =
      "https://github.com/Afraar99/Solace/issues/new";

  static const String? githubSuggestionDirectUrl =
      "https://github.com/Afraar99/Solace/issues/new";

  /// Returns localized list of days in a week in short
  ///  e.g., ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
  static List<String> daysShort(BuildContext context) {
    List<String> shortDays = [];

    final firstMonday = DateTime(0, 1, 2);
    for (int i = 1; i <= 7; i++) {
      String shortDay =
          DateFormat.E(Localizations.localeOf(context).languageCode)
              .format(firstMonday.add(i.days));
      shortDays.add(shortDay);
    }

    return shortDays;
  }
}
