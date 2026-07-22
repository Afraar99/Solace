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

/// Priority level for a todo item.
enum TodoPriority {
  low,
  medium,
  high,
}

extension TodoPriorityX on TodoPriority {
  String get label => switch (this) {
        TodoPriority.low => 'Low',
        TodoPriority.medium => 'Medium',
        TodoPriority.high => 'High',
      };

  Color chipColor(ColorScheme scheme) => switch (this) {
        TodoPriority.low => scheme.tertiary,
        TodoPriority.medium => scheme.primary,
        TodoPriority.high => scheme.error,
      };

  int get sortWeight => switch (this) {
        TodoPriority.high => 0,
        TodoPriority.medium => 1,
        TodoPriority.low => 2,
      };
}
