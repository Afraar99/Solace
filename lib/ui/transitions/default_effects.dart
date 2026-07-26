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

class DefaultEffects {
  static List<Effect> get transitionIn => [
        FadeEffect(
          duration: 280.ms,
          curve: Curves.easeOut,
          begin: 0,
          end: 1,
        ),
        MoveEffect(
          duration: 280.ms,
          curve: Curves.easeOutCubic,
          begin: const Offset(0, 24),
          end: Offset.zero,
        ),
      ];
}
