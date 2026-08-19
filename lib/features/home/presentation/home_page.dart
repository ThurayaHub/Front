import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:thuraya/core/constants/app_assets.dart';
import 'package:thuraya/core/constants/app_spacing.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/core/theme/app_text_styles.dart';
import 'package:thuraya/core/widgets/thuraya_bottom_navigation_bar.dart';
import 'package:thuraya/features/home/presentation/widgets/thuraya_map.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.panel,
      bottomNavigationBar: const ThurayaBottomNavigationBar(
        selectedTab: ThurayaNavigationTab.home,
      ),
      body: Stack(
        key: const ValueKey('home-page'),
        fit: StackFit.expand,
        children: [
          const ThurayaMap(padding: EdgeInsets.only(top: 106, bottom: 90)),
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.screen,
                  AppSpacing.screen,
                  AppSpacing.screen,
                  0,
                ),
                child: const Align(
                  alignment: Alignment.topCenter,
                  child: _HomeSearchBar(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeSearchBar extends StatelessWidget {
  const _HomeSearchBar();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(9999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          key: const ValueKey('home-search-bar'),
          height: 66,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 25),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(
              color: AppColors.inputHint.withValues(alpha: 0.3),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x141A237E),
                offset: Offset(0, 4),
                blurRadius: 20,
              ),
            ],
          ),
          child: Row(
            children: [
              SvgPicture.asset(AppAssets.homeSearch, width: 30, height: 18),
              Expanded(
                child: TextField(
                  key: const ValueKey('home-search-input'),
                  textAlign: TextAlign.right,
                  textInputAction: TextInputAction.search,
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                  style: AppTextStyles.homeSearchHint.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: localizations.searchRestaurant,
                    hintStyle: AppTextStyles.homeSearchHint,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: localizations.filterRestaurants,
                child: GestureDetector(
                  key: const ValueKey('home-filter'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: SizedBox(
                    width: 24,
                    height: 32,
                    child: Center(
                      child: SvgPicture.asset(
                        AppAssets.homeFilter,
                        width: 18,
                        height: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
