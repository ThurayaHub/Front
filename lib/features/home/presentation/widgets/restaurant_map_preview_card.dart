import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:thuraya/core/constants/app_assets.dart';
import 'package:thuraya/core/constants/app_spacing.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/core/theme/app_text_styles.dart';
import 'package:thuraya/core/widgets/thuraya_star_badge.dart';
import 'package:thuraya/features/restaurant_details/models/restaurant_details_dto.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

class RestaurantMapPreviewCard extends StatelessWidget {
  const RestaurantMapPreviewCard({
    super.key,
    required this.restaurant,
    required this.isFavorite,
    required this.isUpdatingFavorite,
    required this.onTap,
    required this.onFavoriteTap,
    required this.onClose,
  });

  static const double maxWidth = 300;
  static const double _imageHeight = 142;

  final RestaurantDetailsDto restaurant;
  final bool? isFavorite;
  final bool isUpdatingFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final name = restaurant.localizedName(languageCode);
    final description = restaurant.localizedDescription(languageCode).trim();
    final thurayaRating = _tenPointRatingOutOfFive(
      restaurant.thurayaReviewSummary.averageRating,
      restaurant.thurayaReviewSummary.totalReviews,
    );
    final userRating = _fivePointRating(
      restaurant.reviewSummary.userRatingAverage,
      restaurant.reviewSummary.reviewCount,
    );
    final hasRatings = thurayaRating != null || userRating != null;

    return Semantics(
      button: true,
      label: name,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: Material(
          color: AppColors.surface,
          elevation: 12,
          shadowColor: AppColors.shadow.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(28),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: const ValueKey('restaurant-preview-card'),
            onTap: onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: _imageHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _RestaurantPreviewImage(
                        photoUrl: _coverPhotoUrl(restaurant.photos),
                      ),
                      PositionedDirectional(
                        top: AppSpacing.sm,
                        start: AppSpacing.sm,
                        child: _ImageActionButton(
                          key: const ValueKey('restaurant-preview-favorite'),
                          semanticLabel: isFavorite == true
                              ? localizations.removeFromFavorites
                              : localizations.addToFavorites,
                          onPressed: isUpdatingFavorite ? null : onFavoriteTap,
                          child: isUpdatingFavorite
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                )
                              : Icon(
                                  isFavorite == true
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  size: 22,
                                  color: isFavorite == true
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                        ),
                      ),
                      PositionedDirectional(
                        top: AppSpacing.sm,
                        end: AppSpacing.sm,
                        child: _ImageActionButton(
                          key: const ValueKey('restaurant-preview-close'),
                          semanticLabel: MaterialLocalizations.of(
                            context,
                          ).closeButtonLabel,
                          onPressed: onClose,
                          child: const Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.start,
                              style: AppTextStyles.homeCardTitle,
                            ),
                          ),
                          if (restaurant.hasThurayaStar) ...[
                            const SizedBox(width: AppSpacing.xs),
                            ThurayaStarBadge(
                              key: ValueKey(
                                'restaurant-preview-thuraya-star-${restaurant.id}',
                              ),
                              hasThurayaStar: true,
                              size: 24,
                              showLabel: false,
                              variant: ThurayaStarBadgeVariant.iconOnly,
                            ),
                          ],
                        ],
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                          style: AppTextStyles.homeCategory.copyWith(
                            height: 1.45,
                          ),
                        ),
                      ],
                      if (hasRatings) ...[
                        const SizedBox(height: AppSpacing.sm),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.panelBorder,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            if (thurayaRating != null)
                              _PreviewRating(
                                key: const ValueKey(
                                  'restaurant-preview-thuraya-rating',
                                ),
                                iconAsset: AppAssets.homeThurayaRatingStar,
                                rating: thurayaRating,
                                textStyle: AppTextStyles.homeThurayaRating,
                              ),
                            if (thurayaRating != null && userRating != null)
                              const Spacer(),
                            if (userRating != null)
                              _PreviewRating(
                                key: const ValueKey(
                                  'restaurant-preview-user-rating',
                                ),
                                iconAsset: AppAssets.homeRatingStar,
                                rating: userRating,
                                reviewCount:
                                    restaurant.reviewSummary.reviewCount,
                                textStyle: AppTextStyles.homeRating,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String? _coverPhotoUrl(List<RestaurantPhotoDto> photos) {
    if (photos.isEmpty) {
      return null;
    }
    final coverPhotos = photos.where((photo) => photo.isCoverPhoto);
    final url = (coverPhotos.isNotEmpty ? coverPhotos.first : photos.first).url
        .trim();
    return url.isEmpty ? null : url;
  }

  static double? _tenPointRatingOutOfFive(double? value, int reviewCount) {
    if (value == null || reviewCount <= 0) {
      return null;
    }
    return (value / 2).clamp(0, 5).toDouble();
  }

  static double? _fivePointRating(double? value, int reviewCount) {
    if (value == null || reviewCount <= 0) {
      return null;
    }
    return value.clamp(0, 5).toDouble();
  }
}

class _RestaurantPreviewImage extends StatelessWidget {
  const _RestaurantPreviewImage({required this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final fallback = Image.asset(
      AppAssets.restaurantDetailsCover,
      key: const ValueKey('restaurant-preview-image-fallback'),
      fit: BoxFit.cover,
    );
    final source = photoUrl;
    if (source == null) {
      return fallback;
    }

    return Image.network(
      source,
      key: const ValueKey('restaurant-preview-image'),
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return child;
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            fallback,
            const ColoredBox(
              color: Color(0x4DFFFFFF),
              child: Center(
                child: SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        );
      },
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

class _ImageActionButton extends StatelessWidget {
  const _ImageActionButton({
    super.key,
    required this.semanticLabel,
    required this.onPressed,
    required this.child,
  });

  final String semanticLabel;
  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      child: Material(
        color: AppColors.surface.withValues(alpha: 0.94),
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox.square(dimension: 40, child: Center(child: child)),
        ),
      ),
    );
  }
}

class _PreviewRating extends StatelessWidget {
  const _PreviewRating({
    super.key,
    required this.iconAsset,
    required this.rating,
    required this.textStyle,
    this.reviewCount,
  });

  final String iconAsset;
  final double rating;
  final TextStyle textStyle;
  final int? reviewCount;

  @override
  Widget build(BuildContext context) {
    final count = reviewCount;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(iconAsset, width: 16, height: 16),
          const SizedBox(width: AppSpacing.xxs),
          Text(rating.toStringAsFixed(1), style: textStyle),
          if (count != null) ...[
            const SizedBox(width: AppSpacing.xxs),
            Text('($count)', style: AppTextStyles.cardMetadata),
          ],
        ],
      ),
    );
  }
}
