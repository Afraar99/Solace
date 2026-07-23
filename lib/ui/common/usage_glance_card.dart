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
import 'package:mindful/core/enums/item_position.dart';
import 'package:mindful/core/extensions/ext_num.dart';
import 'package:mindful/core/utils/widget_utils.dart';
import 'package:mindful/ui/common/rounded_container.dart';
import 'package:mindful/ui/common/styled_text.dart';
import 'package:skeletonizer/skeletonizer.dart';

class UsageGlanceCard extends StatelessWidget {
  const UsageGlanceCard({
    super.key,
    required this.title,
    required this.info,
    this.icon,
    this.onTap,
    this.badge,
    this.isPrimary = false,
    this.position = ItemPosition.mid,
  });

  final IconData? icon;
  final bool isPrimary;
  final String title;
  final String info;
  final VoidCallback? onTap;
  final ItemPosition position;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final mini = icon == null;
    final scheme = Theme.of(context).colorScheme;

    return RoundedContainer(
      circularRadius: 12,
      borderRadius: getBorderRadiusFromPosition(position),
      padding: const EdgeInsets.all(16),
      color: isPrimary
          ? scheme.primary.withValues(alpha: 0.12)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      onPressed: onTap,
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!mini)
                Icon(
                  icon,
                  color: isPrimary ? scheme.primary : scheme.onSurface,
                  size: 20,
                ),
              mini ? 0.vBox : 12.vBox,
              StyledText(
                title,
                fontSize: 12,
                color: scheme.onSurface.withValues(alpha: 0.65),
              ),
              Skeleton.leaf(
                child: FittedBox(
                  child: StyledText(
                    info.isEmpty ? " " : info,
                    fontSize: 22,
                    maxLines: 1,
                    fontWeight: FontWeight.w700,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.topRight,
            child: badge ?? 0.hBox,
          ),
        ],
      ),
    );
  }
}
