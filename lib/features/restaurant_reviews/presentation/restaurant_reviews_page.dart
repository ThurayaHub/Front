import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:thuraya/core/constants/app_assets.dart';
import 'package:thuraya/core/constants/app_spacing.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/core/theme/app_text_styles.dart';
import 'package:thuraya/core/widgets/rating_stars.dart';
import 'package:thuraya/features/restaurants/models/restaurant.dart';
import 'package:thuraya/features/restaurants/models/restaurant_review.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

class RestaurantReviewsPage extends StatelessWidget {
  const RestaurantReviewsPage({super.key, required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final reviews = restaurant.reviews
        .where((review) => review.isPublished)
        .toList(growable: false);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _ReviewsHeader(
            title: localizations.reviewsTitle,
            backLabel: localizations.back,
          ),
          Expanded(
            child: ListView(
              key: const ValueKey('restaurant-reviews-list'),
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.screen,
                AppSpacing.lg,
                AppSpacing.screen,
                40,
              ),
              children: [
                Text(
                  restaurant.name,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: AppSpacing.md),
                _RatingSummary(
                  rating: restaurant.rating,
                  reviewCount: restaurant.reviewCount,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (reviews.isEmpty)
                  const _EmptyReviews()
                else
                  for (var index = 0; index < reviews.length; index++) ...[
                    _ReviewCard(review: reviews[index]),
                    if (index != reviews.length - 1)
                      const SizedBox(height: AppSpacing.sm),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewsHeader extends StatelessWidget {
  const _ReviewsHeader({required this.title, required this.backLabel});

  final String title;
  final String backLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('restaurant-reviews-header'),
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
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
      child: Row(
        children: [
          Semantics(
            button: true,
            label: backLabel,
            child: GestureDetector(
              key: const ValueKey('restaurant-reviews-back'),
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: SvgPicture.asset(
                    AppAssets.restaurantBackArrow,
                    width: 16,
                    height: 16,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: AppTextStyles.cardTitle.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 40, height: 40),
        ],
      ),
    );
  }
}

class _RatingSummary extends StatelessWidget {
  const _RatingSummary({required this.rating, required this.reviewCount});

  final double rating;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Container(
      height: 112,
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        border: Border.all(color: AppColors.panelBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000666),
            offset: Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  rating.toStringAsFixed(1),
                  style: AppTextStyles.screenTitle,
                ),
                const SizedBox(width: AppSpacing.xs),
                const RatingStars(
                  rating: 1,
                  maxStars: 1,
                  starSize: 28,
                  spacing: 0,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            localizations.ratingCount(reviewCount),
            style: AppTextStyles.detailsAwardTitle,
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final RestaurantReview review;

  @override
  Widget build(BuildContext context) {
    final rating = review.ratingOutOfFive;
    final comment = review.comment?.trim();
    final formattedDate = MaterialLocalizations.of(
      context,
    ).formatMediumDate(review.createdAtUtc.toLocal());

    return Container(
      key: ValueKey('review-card-${review.id}'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        border: Border.all(color: AppColors.panelBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000666),
            offset: Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.reviewerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.reviewName,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_formatRating(rating), style: AppTextStyles.rating),
                    const SizedBox(width: AppSpacing.xxs),
                    const RatingStars(
                      rating: 1,
                      maxStars: 1,
                      starSize: 16,
                      spacing: 0,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: RatingStars(rating: rating),
          ),
          if (comment != null && comment.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              comment,
              textAlign: TextAlign.right,
              style: AppTextStyles.detailsBody,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            formattedDate,
            textAlign: TextAlign.right,
            style: AppTextStyles.reviewDate,
          ),
        ],
      ),
    );
  }

  String _formatRating(double rating) {
    return rating == rating.roundToDouble()
        ? rating.toStringAsFixed(0)
        : rating.toStringAsFixed(1);
  }
}

class _EmptyReviews extends StatelessWidget {
  const _EmptyReviews();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return SizedBox(
      key: const ValueKey('restaurant-reviews-empty'),
      height: 240,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const RatingStars(rating: 0, maxStars: 1, starSize: 32, spacing: 0),
          const SizedBox(height: AppSpacing.md),
          Text(
            localizations.noReviewsYet,
            textAlign: TextAlign.center,
            style: AppTextStyles.screenSubtitle,
          ),
        ],
      ),
    );
  }
}
