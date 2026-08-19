import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:thuraya/core/constants/app_assets.dart';
import 'package:thuraya/core/constants/app_spacing.dart';
import 'package:thuraya/core/routing/app_route_names.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/core/theme/app_text_styles.dart';
import 'package:thuraya/core/widgets/thuraya_bottom_navigation_bar.dart';
import 'package:thuraya/features/restaurants/data/mock_restaurants.dart';
import 'package:thuraya/features/restaurants/models/restaurant.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

class TrendingPage extends StatelessWidget {
  const TrendingPage({super.key});

  static const double _headerHeight = 68;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final places = MockRestaurants.localized(localizations);

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.background,
      bottomNavigationBar: const ThurayaBottomNavigationBar(
        selectedTab: ThurayaNavigationTab.trending,
      ),
      body: Column(
        children: [
          SizedBox(
            height: _headerHeight,
            child: _TrendingHeader(backLabel: localizations.back),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.screen,
                  AppSpacing.lg,
                  AppSpacing.screen,
                  40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          localizations.trendingTitle,
                          maxLines: 1,
                          textAlign: TextAlign.right,
                          style: AppTextStyles.screenTitle,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          localizations.trendingDescription,
                          maxLines: 1,
                          textAlign: TextAlign.right,
                          style: AppTextStyles.screenSubtitle,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    for (var index = 0; index < places.length; index++) ...[
                      _TrendingCard(
                        key: ValueKey('trending-card-$index'),
                        place: places[index],
                        hotLabel: localizations.activeNow,
                        onTap: () => Navigator.of(context).pushNamed(
                          AppRouteNames.restaurantDetails,
                          arguments: places[index],
                        ),
                      ),
                      if (index != places.length - 1)
                        const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendingHeader extends StatelessWidget {
  const _TrendingHeader({required this.backLabel});

  final String backLabel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('trending-header'),
      decoration: const BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Color(0x0D1A237E),
            offset: Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screen,
          vertical: AppSpacing.md,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Semantics(
              button: true,
              label: backLabel,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).maybePop(),
                child: SizedBox(
                  width: 16,
                  height: 26,
                  child: Align(
                    alignment: AlignmentDirectional.topCenter,
                    child: SvgPicture.asset(
                      AppAssets.backArrow,
                      width: 16,
                      height: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 42.13, height: 36),
          ],
        ),
      ),
    );
  }
}

class _TrendingCard extends StatelessWidget {
  const _TrendingCard({
    super.key,
    required this.place,
    required this.hotLabel,
    required this.onTap,
  });

  static const double _radius = 32;

  final Restaurant place;
  final String hotLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: place.name,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 272,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(_radius),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D1A237E),
                offset: Offset(0, 4),
                blurRadius: 20,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_radius),
            child: Stack(
              children: [
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 192,
                      child: Image.asset(
                        place.cardImage,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      ),
                    ),
                    SizedBox(
                      height: 80,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    place.name,
                                    maxLines: 1,
                                    textAlign: TextAlign.right,
                                    style: AppTextStyles.cardTitle,
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(
                                    place.cardDetails,
                                    maxLines: 1,
                                    textAlign: TextAlign.right,
                                    style: AppTextStyles.cardMetadata,
                                  ),
                                ],
                              ),
                            ),
                            _CardStatus(
                              status: place.cardStatus,
                              rating: place.rating,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (place.isHot)
                  PositionedDirectional(
                    top: AppSpacing.sm,
                    start: AppSpacing.sm,
                    child: _HotBadge(label: hotLabel),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HotBadge extends StatelessWidget {
  const _HotBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.hot,
        borderRadius: BorderRadius.all(Radius.circular(9999)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 4),
            blurRadius: 6,
            spreadRadius: -1,
          ),
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 2),
            blurRadius: 4,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(AppAssets.hot, width: 10.667, height: 12.667),
          const SizedBox(width: AppSpacing.xxs),
          Text(label, style: AppTextStyles.badgeLabel),
        ],
      ),
    );
  }
}

class _CardStatus extends StatelessWidget {
  const _CardStatus({required this.status, required this.rating});

  final RestaurantCardStatus status;
  final double rating;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      RestaurantCardStatus.thurayaStar => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.secondary, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              offset: Offset(0, 1),
              blurRadius: 1,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: SvgPicture.asset(
          AppAssets.thurayaStar,
          width: 13.333,
          height: 12.667,
        ),
      ),
      RestaurantCardStatus.rating => Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(AppAssets.ratingStar, width: 15, height: 14.25),
            const SizedBox(width: AppSpacing.xxs),
            Text(rating.toStringAsFixed(1), style: AppTextStyles.rating),
          ],
        ),
      ),
    };
  }
}
