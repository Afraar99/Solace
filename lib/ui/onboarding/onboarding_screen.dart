/*
 *
 *  * Copyright (c) 2024 Solace
 *
 */

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindful/config/navigation/navigation_service.dart';
import 'package:mindful/core/extensions/ext_build_context.dart';
import 'package:mindful/core/extensions/ext_num.dart';
import 'package:mindful/config/app_constants.dart';
import 'package:mindful/models/permissions_model.dart';
import 'package:mindful/providers/system/mindful_settings_provider.dart';
import 'package:mindful/providers/system/permissions_provider.dart';
import 'package:mindful/ui/onboarding/name_setup_page.dart';
import 'package:mindful/ui/onboarding/onboarding_page.dart';
import 'package:mindful/ui/onboarding/permission_page.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({
    required this.isOnboardingDone,
    super.key,
  });

  final bool isOnboardingDone;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _OnboardingState();
}

class _OnboardingState extends ConsumerState<OnboardingScreen> {
  static const _permissionsIndex = 3;
  static const _nameIndex = 4;

  int _currentPage = 0;
  ProviderSubscription? _subscription;
  final PageController _controller = PageController();
  final TextEditingController _nameController = TextEditingController();
  final _animCurve = Curves.easeInOut;
  final _animDuration = AppConstants.defaultAnimDuration;

  late final List<Widget> _pages = [
    OnboardingPage(
      title: context.locale.onboarding_page_one_title,
      imgArtPath: "assets/illustrations/onboarding_1.png",
      description: context.locale.onboarding_page_one_info,
    ),
    OnboardingPage(
      title: context.locale.onboarding_page_two_title,
      imgArtPath: "assets/illustrations/onboarding_2.png",
      description: context.locale.onboarding_page_two_info,
    ),
    OnboardingPage(
      title: context.locale.onboarding_page_three_title,
      imgArtPath: "assets/illustrations/onboarding_3.png",
      description: context.locale.onboarding_page_three_info,
    ),
    const PermissionsPage(),
    NameSetupPage(controller: _nameController),
  ];

  @override
  void initState() {
    super.initState();

    final existing =
        ref.read(mindfulSettingsProvider).username.trim();
    if (existing.isNotEmpty && existing != AppConstants.defaultUsername) {
      _nameController.text = existing;
    }

    /// When all essential permissions are granted, move to name setup
    /// (or finish immediately if this is a returning permission-only flow
    /// and a custom name is already set).
    _subscription = ref.listenManual<PermissionsModel>(
      permissionProvider,
      (_, perms) {
        if (!_haveEssential(perms)) return;

        final username = ref.read(mindfulSettingsProvider).username.trim();
        final hasCustomName = username.isNotEmpty &&
            username != AppConstants.defaultUsername;

        if (widget.isOnboardingDone && hasCustomName) {
          _finishOnboarding();
          _subscription?.close();
          return;
        }

        _goToNamePage();
      },
    );

    /// Returning user missing permissions → jump to permissions page
    if (widget.isOnboardingDone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _goToPermissionsPage();
      });
    }
  }

  @override
  void dispose() {
    _subscription?.close();
    _nameController.dispose();
    _controller.dispose();
    super.dispose();
  }

  bool _haveEssential(PermissionsModel perms) =>
      perms.haveUsageAccessPermission &&
      perms.haveDisplayOverlayPermission &&
      perms.haveAlarmsPermission &&
      perms.haveNotificationPermission;

  void _finishOnboarding() async {
    if (!mounted) return;

    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      ref.read(mindfulSettingsProvider.notifier).changeUsername(name);
    }

    ref.read(mindfulSettingsProvider.notifier).markOnboardingDone();

    Future.delayed(200.ms, () {
      if (!mounted) return;
      NavigationService.instance
          .init(showChangeLogsToo: !widget.isOnboardingDone);
    });
  }

  void _goToPermissionsPage() {
    if (!mounted) return;
    _controller.animateToPage(
      _permissionsIndex,
      duration: _animDuration,
      curve: _animCurve,
    );
  }

  void _goToNamePage() {
    if (!mounted) return;
    _controller.animateToPage(
      _nameIndex,
      duration: _animDuration,
      curve: _animCurve,
    );
  }

  void _onPrimaryAction({required bool haveAllEssentialPermissions}) {
    if (_currentPage == _permissionsIndex) {
      if (!haveAllEssentialPermissions) return;
      _goToNamePage();
      return;
    }

    if (_currentPage == _nameIndex) {
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        context.showSnackAlert(
          'Please enter your name to continue',
          icon: FluentIcons.person_20_filled,
        );
        return;
      }
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNamePage = _currentPage == _nameIndex;
    final isPermissionsPage = _currentPage == _permissionsIndex;
    final showSkip = _currentPage < _permissionsIndex;
    final perms = ref.watch(permissionProvider);
    final haveAllEssentialPermissions = _haveEssential(perms);
    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) => SystemNavigator.pop(),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: TextButton(
                    onPressed: _goToPermissionsPage,
                    child: Text(context.locale.onboarding_skip_btn_label),
                  )
                      .animate(target: showSkip ? 1 : 0)
                      .scale(duration: 100.ms),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _pages.length,
                  onPageChanged: (i) {
                    /// Block swipe onto name page until permissions are granted
                    if (i == _nameIndex &&
                        !_haveEssential(ref.read(permissionProvider))) {
                      _controller.jumpToPage(_permissionsIndex);
                      setState(() => _currentPage = _permissionsIndex);
                      return;
                    }
                    setState(() => _currentPage = i);
                  },
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _pages[index],
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                color: Theme.of(context).scaffoldBackgroundColor,
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: Row(
                  children: [
                    SmoothPageIndicator(
                      controller: _controller,
                      count: _pages.length,
                      effect: ExpandingDotsEffect(
                        dotWidth: 10,
                        dotHeight: 10,
                        spacing: 6,
                        expansionFactor: 2.5,
                        dotColor: scheme.secondaryContainer,
                        activeDotColor: scheme.primary,
                      ),
                    ),
                    const Spacer(),
                    IconButton.filledTonal(
                      onPressed: () => _controller.previousPage(
                        curve: _animCurve,
                        duration: _animDuration,
                      ),
                      padding: const EdgeInsets.all(10),
                      icon: const Icon(FluentIcons.caret_left_20_filled),
                    )
                        .animate(target: _currentPage > 0 ? 1 : 0)
                        .scale(duration: 150.ms),
                    4.hBox,
                    if (isPermissionsPage || isNamePage)
                      FilledButton(
                        onPressed: (isPermissionsPage &&
                                    !haveAllEssentialPermissions)
                            ? null
                            : () => _onPrimaryAction(
                                  haveAllEssentialPermissions:
                                      haveAllEssentialPermissions,
                                ),
                        child: Text(
                          isNamePage
                              ? 'Continue'
                              : context
                                  .locale.onboarding_finish_setup_btn_label,
                        ),
                      ).animate(target: 1).scale(
                            duration: 250.ms,
                            alignment: Alignment.centerRight,
                          )
                    else
                      IconButton.filled(
                        padding: const EdgeInsets.all(10),
                        onPressed: () {
                          /// Don't enter name page until permissions are ready
                          if (_currentPage == _permissionsIndex - 1) {
                            _controller.nextPage(
                              curve: _animCurve,
                              duration: _animDuration,
                            );
                            return;
                          }
                          _controller.nextPage(
                            curve: _animCurve,
                            duration: _animDuration,
                          );
                        },
                        icon: const Icon(FluentIcons.caret_right_20_filled),
                      ).animate(target: 1).scale(duration: 150.ms),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
