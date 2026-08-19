import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:thuraya/core/constants/app_assets.dart';
import 'package:thuraya/core/constants/app_spacing.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/core/theme/app_text_styles.dart';
import 'package:thuraya/features/home/models/restaurant_map_marker.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

class RestaurantPreviewCard extends StatelessWidget {
  const RestaurantPreviewCard({
    super.key,
    required this.restaurant,
    required this.onTap,
    required this.onClose,
  });

  static const double height = 116;

  final RestaurantMapMarker restaurant;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final restaurantName = restaurant.localizedName(languageCode);
    final category = restaurant.primaryCategoryName?.trim();
    final rating = restaurant.userRatingAverage == null
        ? null
        : (restaurant.userRatingAverage! / 2).clamp(0, 5).toDouble();
    final priceLevel = List.filled(
      restaurant.priceLevelId.clamp(0, 4),
      r'$',
    ).join();

    return Semantics(
      button: true,
      label: restaurant.name,
      child: Material(
        key: const ValueKey('restaurant-preview-card'),
        color: AppColors.surface,
        elevation: 8,
        shadowColor: AppColors.shadow.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    children: [
                      _PreviewImage(restaurant: restaurant),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(end: 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                      restaurantName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.start,
                                style: AppTextStyles.homeCardTitle,
                              ),
                              if ((category != null && category.isNotEmpty) ||
                                  priceLevel.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.xxs),
                                Row(
                                  children: [
                                    if (category != null && category.isNotEmpty)
                                      Expanded(
                                        child: Text(
                                          category,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.homeCategory,
                                        ),
                                      )
                                    else
                                      const Spacer(),
                                    if (priceLevel.isNotEmpty) ...[
                                      const SizedBox(width: AppSpacing.xs),
                                      Directionality(
                                        textDirection: TextDirection.ltr,
                                        child: Text(
                                          priceLevel,
                                          style: AppTextStyles.homeCategory,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                              if (rating != null) ...[
                                const SizedBox(height: AppSpacing.xxs),
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SvgPicture.asset(
                                        AppAssets.homeRatingStar,
                                        width: 15,
                                        height: 15,
                                      ),
                                      const SizedBox(width: AppSpacing.xxs),
                                      Text(
                                        rating.toStringAsFixed(1),
                                        style: AppTextStyles.homeRating,
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      Flexible(
                                        child: Text(
                                          localizations.ratingCount(
                                            restaurant.reviewCount,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.cardMetadata,
                                        ),
                                      ),
                                    ],
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
                PositionedDirectional(
                  top: AppSpacing.xxs,
                  end: AppSpacing.xxs,
                  child: Semantics(
                    button: true,
                    label: MaterialLocalizations.of(context).closeButtonLabel,
                    child: IconButton(
                      key: const ValueKey('restaurant-preview-close'),
                      onPressed: onClose,
                      visualDensity: VisualDensity.compact,
                      iconSize: 18,
                      color: AppColors.textMuted,
                      icon: const Icon(Icons.close_rounded),
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

class _PreviewImage extends StatelessWidget {
  const _PreviewImage({required this.restaurant});

  final RestaurantMapMarker restaurant;

  @override
  Widget build(BuildContext context) {
    final photoUrl = restaurant.mainPhotoUrl?.trim();

    return SizedBox.square(
      dimension: 92,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: photoUrl == null || photoUrl.isEmpty
                  ? const _PreviewImagePlaceholder()
                  : Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) =>
                          progress == null
                          ? child
                          : const _PreviewImagePlaceholder(showProgress: true),
                      errorBuilder: (_, _, _) =>
                          const _PreviewImagePlaceholder(),
                    ),
            ),
          ),
          if (restaurant.hasThurayaStar)
            PositionedDirectional(
              top: -4,
              start: -4,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.secondary, width: 2),
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  AppAssets.thurayaStar,
                  width: 13,
                  height: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PreviewImagePlaceholder extends StatelessWidget {
  const _PreviewImagePlaceholder({this.showProgress = false});

  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.panel,
      child: Center(
        child: showProgress
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              )
            : const Icon(
                Icons.restaurant_rounded,
                color: AppColors.textMuted,
                size: 32,
              ),
      ),
    );
  }
}
