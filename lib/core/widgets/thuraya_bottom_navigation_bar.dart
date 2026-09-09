import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:thuraya/core/auth/authentication_guard.dart';
import 'package:thuraya/core/constants/app_assets.dart';
import 'package:thuraya/core/constants/app_spacing.dart';
import 'package:thuraya/core/routing/app_route_names.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/core/theme/app_text_styles.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

enum ThurayaNavigationTab { home, trending, wheel, chooseRestaurant, account }

class ThurayaBottomNavigationBar extends StatelessWidget {
  const ThurayaBottomNavigationBar({super.key, required this.selectedTab});

  final ThurayaNavigationTab selectedTab;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          key: const ValueKey('thuraya-bottom-navigation'),
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          decoration: const BoxDecoration(
            color: Color(0xCCFCF9F8),
            boxShadow: [
              BoxShadow(
                color: Color(0x141A237E),
                offset: Offset(0, -4),
                blurRadius: 20,
              ),
            ],
          ),
          child: Row(
            children: [
              _NavigationItem(
                key: const ValueKey('navigation-home'),
                assetIcon: AppAssets.navHome,
                label: localizations.home,
                iconWidth: 18,
                iconHeight: 18,
                isActive: selectedTab == ThurayaNavigationTab.home,
                onTap: () => _selectTab(context, ThurayaNavigationTab.home),
              ),
              _NavigationItem(
                key: const ValueKey('navigation-trending'),
                assetIcon: AppAssets.navTrending,
                label: localizations.trending,
                iconWidth: 20,
                iconHeight: 18,
                isActive: selectedTab == ThurayaNavigationTab.trending,
                onTap: () => _selectTab(context, ThurayaNavigationTab.trending),
              ),
              _NavigationItem(
                key: const ValueKey('navigation-wheel'),
                materialIcon: Icons.donut_large,
                label: localizations.wheel,
                iconWidth: 18,
                iconHeight: 18,
                isActive: selectedTab == ThurayaNavigationTab.wheel,
                onTap: () => _selectTab(context, ThurayaNavigationTab.wheel),
              ),
              _NavigationItem(
                key: const ValueKey('navigation-choose-restaurant'),
                materialIcon: Icons.restaurant_menu,
                label: localizations.chooseRestaurantNavigation,
                iconWidth: 18,
                iconHeight: 18,
                isActive: selectedTab == ThurayaNavigationTab.chooseRestaurant,
                onTap: () =>
                    _selectTab(context, ThurayaNavigationTab.chooseRestaurant),
              ),
              _NavigationItem(
                key: const ValueKey('navigation-account'),
                assetIcon: AppAssets.navProfile,
                label: localizations.account,
                iconWidth: 16,
                iconHeight: 16,
                isActive: selectedTab == ThurayaNavigationTab.account,
                onTap: () => _selectTab(context, ThurayaNavigationTab.account),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectTab(
    BuildContext context,
    ThurayaNavigationTab tab,
  ) async {
    if (tab == selectedTab) return;

    if (tab == ThurayaNavigationTab.account) {
      await AuthenticationGuard.requireAuthentication<void>(context, () async {
        if (context.mounted) _navigateToTab(context, tab);
      });
      return;
    }

    _navigateToTab(context, tab);
  }

  void _navigateToTab(BuildContext context, ThurayaNavigationTab tab) {
    if (tab == ThurayaNavigationTab.home) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    final routeName = switch (tab) {
      ThurayaNavigationTab.account => AppRouteNames.account,
      ThurayaNavigationTab.trending => AppRouteNames.trending,
      ThurayaNavigationTab.wheel => AppRouteNames.wheel,
      ThurayaNavigationTab.chooseRestaurant => AppRouteNames.chooseRestaurant,
      _ => null,
    };

    if (routeName == null) return;

    if (selectedTab == ThurayaNavigationTab.home) {
      Navigator.of(context).pushNamed(routeName);
    } else {
      Navigator.of(context).pushReplacementNamed(routeName);
    }
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    super.key,
    this.assetIcon,
    this.materialIcon,
    required this.label,
    required this.iconWidth,
    required this.iconHeight,
    required this.isActive,
    this.onTap,
  }) : assert(assetIcon != null || materialIcon != null);

  final String? assetIcon;
  final IconData? materialIcon;
  final String label;
  final double iconWidth;
  final double iconHeight;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.textSecondary;

    return Expanded(
      child: Semantics(
        button: onTap != null,
        selected: isActive,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: iconWidth,
                  height: iconHeight,
                  child: assetIcon != null
                      ? SvgPicture.asset(
                          assetIcon!,
                          width: iconWidth,
                          height: iconHeight,
                          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                        )
                      : Icon(materialIcon, size: iconWidth, color: color),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.clip,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.navigationLabel.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
