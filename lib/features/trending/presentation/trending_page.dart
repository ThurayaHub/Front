import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:thuraya/core/constants/app_assets.dart';
import 'package:thuraya/core/constants/app_spacing.dart';
import 'package:thuraya/core/routing/app_route_names.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/core/theme/app_text_styles.dart';
import 'package:thuraya/core/widgets/restaurant_image.dart';
import 'package:thuraya/core/widgets/thuraya_bottom_navigation_bar.dart';
import 'package:thuraya/core/widgets/thuraya_loading_indicator.dart';
import 'package:thuraya/core/widgets/thuraya_star_badge.dart';
import 'package:thuraya/features/choose_restaurant/models/restaurant_lookup.dart';
import 'package:thuraya/features/choose_restaurant/presentation/choose_restaurant_arabic_labels.dart';
import 'package:thuraya/features/trending/models/trending_restaurant_dto.dart';
import 'package:thuraya/features/trending/presentation/trending_controller.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

class TrendingPage extends StatefulWidget {
  const TrendingPage({super.key, this.controller});

  final TrendingController? controller;

  @override
  State<TrendingPage> createState() => _TrendingPageState();
}

class _TrendingPageState extends State<TrendingPage> {
  static const double _headerHeight = 68;

  late final TrendingController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TrendingController();
    _controller.addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.load());
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      key: const ValueKey('trending-page'),
      extendBody: true,
      backgroundColor: AppColors.background,
      bottomNavigationBar: const ThurayaBottomNavigationBar(
        selectedTab: ThurayaNavigationTab.trending,
      ),
      body: Column(
        children: [
          SizedBox(
            height: _headerHeight,
            child: _TrendingHeader(backLabel: l10n.back),
          ),
          Expanded(child: _buildBody(l10n)),
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    return switch (_controller.status) {
      TrendingLoadStatus.idle ||
      TrendingLoadStatus.loading => _TrendingLoading(l10n: l10n),
      TrendingLoadStatus.error => _TrendingError(
        l10n: l10n,
        message: l10n.trendingLoadError,
        retryLabel: l10n.retry,
        onRetry: () => _controller.load(refresh: true),
      ),
      TrendingLoadStatus.ready when _controller.restaurants.isEmpty =>
        RefreshIndicator(
          onRefresh: () => _controller.load(refresh: true),
          child: ListView(
            key: const ValueKey('trending-empty'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.lg,
              AppSpacing.screen,
              120,
            ),
            children: [
              _PageIntro(l10n: l10n),
              SizedBox(
                height: MediaQuery.sizeOf(context).height * .48,
                child: _TrendingEmpty(message: l10n.trendingEmpty),
              ),
            ],
          ),
        ),
      TrendingLoadStatus.ready => RefreshIndicator(
        onRefresh: () => _controller.load(refresh: true),
        child: ListView.separated(
          key: const ValueKey('trending-list'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.lg,
            AppSpacing.screen,
            120,
          ),
          itemCount: _controller.restaurants.length + 1,
          separatorBuilder: (_, index) =>
              SizedBox(height: index == 0 ? AppSpacing.lg : AppSpacing.md),
          itemBuilder: (context, index) {
            if (index == 0) return _PageIntro(l10n: l10n);
            final restaurant = _controller.restaurants[index - 1];
            return _TrendingCard(
              key: ValueKey('trending-card-${restaurant.id}'),
              restaurant: restaurant,
              priceLevel: _controller
                  .priceLevelById(restaurant.priceLevelId)
                  ?.name,
              category: restaurant.categoryIds.isEmpty
                  ? null
                  : _controller
                        .categoryById(restaurant.categoryIds.first)
                        ?.name,
              neighborhood: _controller.neighborhoodById(
                restaurant.neighborhoodId,
              ),
              onTap: () => Navigator.of(context).pushNamed(
                AppRouteNames.restaurantDetails,
                arguments: restaurant.id,
              ),
            );
          },
        ),
      ),
    };
  }
}

class _PageIntro extends StatelessWidget {
  const _PageIntro({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.trendingTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.start,
          style: AppTextStyles.screenTitle,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          l10n.trendingDescription,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.start,
          style: AppTextStyles.screenSubtitle,
        ),
      ],
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
              child: InkResponse(
                key: const ValueKey('trending-back'),
                onTap: () => Navigator.of(context).maybePop(),
                radius: 24,
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: Center(
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
    required this.restaurant,
    required this.priceLevel,
    required this.category,
    required this.neighborhood,
    required this.onTap,
  });

  final TrendingRestaurantDto restaurant;
  final String? priceLevel;
  final String? category;
  final NeighborhoodLookupDto? neighborhood;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final price = priceLevel?.trim();
    final categoryName = category?.trim();
    final neighborhoodName = neighborhood == null
        ? ''
        : languageCode == 'ar'
        ? neighborhood!.nameAr.trim()
        : neighborhood!.nameEn.trim();
    final metadata = <String>[
      if (price != null && price.isNotEmpty)
        ChooseRestaurantArabicLabels.priceSymbol(price),
      if (categoryName != null && categoryName.isNotEmpty)
        languageCode == 'ar'
            ? ChooseRestaurantArabicLabels.categoryName(categoryName)
            : categoryName,
      if (neighborhoodName.isNotEmpty) neighborhoodName,
    ];
    final description = restaurant.description?.trim();

    return Semantics(
      button: true,
      label:
          '${l10n.trendingRankLabel(restaurant.trendRank)}, '
          '${restaurant.name}',
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 124,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      RestaurantImage(source: restaurant.coverPhotoUrl),
                      PositionedDirectional(
                        top: AppSpacing.sm,
                        start: AppSpacing.sm,
                        child: _RankBadge(rank: restaurant.trendRank),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.sm,
                      AppSpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                restaurant.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.homeCardTitle,
                              ),
                            ),
                            if (restaurant.hasThurayaStar) ...[
                              const SizedBox(width: AppSpacing.xs),
                              ThurayaStarBadge(
                                key: ValueKey('trending-star-${restaurant.id}'),
                                hasThurayaStar: true,
                                size: 27,
                                showLabel: false,
                                variant: ThurayaStarBadgeVariant.iconOnly,
                              ),
                            ],
                          ],
                        ),
                        if (metadata.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            metadata.join('  •  '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.cardMetadata.copyWith(
                              fontSize: 13,
                            ),
                          ),
                        ],
                        if (description != null && description.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.detailsCaption.copyWith(
                              height: 1.45,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final style = switch (rank) {
      1 => (AppColors.secondary, AppColors.primary, AppColors.surface),
      2 => (const Color(0xFFE8E8EC), AppColors.primary, AppColors.surface),
      3 => (const Color(0xFFE7C7A9), AppColors.primary, AppColors.surface),
      _ => (AppColors.primary, AppColors.surface, AppColors.secondary),
    };
    return Container(
      key: ValueKey('trending-rank-$rank'),
      constraints: const BoxConstraints(minWidth: 42, minHeight: 34),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: style.$1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: style.$3, width: rank <= 3 ? 1.5 : 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            offset: Offset(0, 3),
            blurRadius: 8,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Text(
          '#$rank',
          style: TextStyle(
            color: style.$2,
            fontFamily: AppTextStyles.fontFamily,
            fontSize: rank <= 3 ? 16 : 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _TrendingLoading extends StatelessWidget {
  const _TrendingLoading({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('trending-loading'),
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.lg,
        AppSpacing.screen,
        120,
      ),
      children: [
        _PageIntro(l10n: l10n),
        const SizedBox(height: AppSpacing.lg),
        const SizedBox(height: 56, child: ThurayaLoadingIndicator()),
        const SizedBox(height: AppSpacing.lg),
        for (var index = 0; index < 3; index++) ...[
          Container(
            height: 148,
            decoration: BoxDecoration(
              color: AppColors.panel,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          if (index < 2) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _TrendingEmpty extends StatelessWidget {
  const _TrendingEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: const BoxDecoration(
                color: Color(0xFFEDEDF7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.trending_up_rounded,
                color: AppColors.primary,
                size: 38,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.cardTitle,
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendingError extends StatelessWidget {
  const _TrendingError({
    required this.l10n,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final AppLocalizations l10n;
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('trending-error'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.lg,
        AppSpacing.screen,
        120,
      ),
      children: [
        _PageIntro(l10n: l10n),
        SizedBox(
          height: MediaQuery.sizeOf(context).height * .52,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    color: AppColors.primary,
                    size: 44,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.cardTitle,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    key: const ValueKey('trending-retry'),
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(retryLabel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
