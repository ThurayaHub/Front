import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:thuraya/core/constants/app_assets.dart';
import 'package:thuraya/core/constants/app_spacing.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/core/theme/app_text_styles.dart';
import 'package:thuraya/features/choose_restaurant/presentation/choose_restaurant_arabic_labels.dart';
import 'package:thuraya/features/home/models/restaurant_map_marker.dart';

class RestaurantSearchResultCard extends StatelessWidget {
  const RestaurantSearchResultCard({
    super.key,
    required this.restaurant,
    required this.onTap,
  });

  final RestaurantMapMarker restaurant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final categoryName = restaurant.primaryCategoryName?.trim();
    final neighborhood = restaurant.localizedNeighborhood(languageCode);
    final priceName = restaurant.priceLevelName?.trim();
    final metadata = <String>[
      if (categoryName != null && categoryName.isNotEmpty)
        ChooseRestaurantArabicLabels.categoryName(categoryName),
      if (neighborhood.isNotEmpty) neighborhood,
      if (priceName != null && priceName.isNotEmpty)
        ChooseRestaurantArabicLabels.priceSymbol(priceName),
    ];
    final thurayaRating =
        restaurant.thurayaRatingAverage == null ||
            restaurant.thurayaReviewCount <= 0
        ? null
        : (restaurant.thurayaRatingAverage! / 2).clamp(0, 5).toDouble();
    final userRating =
        restaurant.userRatingAverage == null || restaurant.reviewCount <= 0
        ? null
        : restaurant.userRatingAverage!.clamp(0, 5).toDouble();

    return Semantics(
      button: true,
      label: restaurant.localizedName(languageCode),
      child: Material(
        key: ValueKey('restaurant-result-${restaurant.id}'),
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 108,
                    height: 108,
                    child: _ResultImage(source: restaurant.mainPhotoUrl),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(top: 3, end: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          restaurant.localizedName(languageCode),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.homeCardTitle,
                        ),
                        if (metadata.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            metadata.join('  •  '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.homeCategory,
                          ),
                        ],
                        if (thurayaRating != null || userRating != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.md,
                            runSpacing: AppSpacing.xxs,
                            children: [
                              if (thurayaRating != null)
                                _SummaryRating(
                                  icon: AppAssets.homeThurayaRatingStar,
                                  value: thurayaRating,
                                  color: AppColors.primary,
                                ),
                              if (userRating != null)
                                _SummaryRating(
                                  icon: AppAssets.homeRatingStar,
                                  value: userRating,
                                  count: restaurant.reviewCount,
                                  color: AppColors.textPrimary,
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsetsDirectional.only(top: 42),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    size: 22,
                    color: AppColors.textMuted,
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

class _ResultImage extends StatelessWidget {
  const _ResultImage({required this.source});

  final String? source;

  @override
  Widget build(BuildContext context) {
    final fallback = Image.asset(
      AppAssets.restaurantDetailsCover,
      fit: BoxFit.cover,
    );
    final url = source?.trim();
    if (url == null || url.isEmpty) return fallback;
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : fallback,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

class _SummaryRating extends StatelessWidget {
  const _SummaryRating({
    required this.icon,
    required this.value,
    required this.color,
    this.count,
  });

  final String icon;
  final double value;
  final Color color;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(icon, width: 16, height: 16),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            value.toStringAsFixed(1),
            style: AppTextStyles.rating.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 3),
            Text('($count)', style: AppTextStyles.cardMetadata),
          ],
        ],
      ),
    );
  }
}
