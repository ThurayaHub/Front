import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:thuraya/core/constants/app_assets.dart';
import 'package:thuraya/core/constants/app_spacing.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/core/theme/app_text_styles.dart';
import 'package:thuraya/core/widgets/rating_stars.dart';
import 'package:thuraya/core/widgets/thuraya_loading_indicator.dart';
import 'package:thuraya/features/restaurant_reviews/models/restaurant_reviews_data.dart';
import 'package:thuraya/features/restaurant_reviews/services/restaurant_review_service.dart';
import 'package:thuraya/features/restaurants/models/restaurant.dart';
import 'package:thuraya/features/restaurants/models/restaurant_review.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

class RestaurantReviewsPage extends StatefulWidget {
  RestaurantReviewsPage({
    super.key,
    required Restaurant restaurant,
    this.reviewService,
  }) : data = RestaurantReviewsData.fromRestaurant(restaurant);

  const RestaurantReviewsPage.fromData({
    super.key,
    required this.data,
    this.reviewService,
  });

  final RestaurantReviewsData data;
  final RestaurantReviewService? reviewService;

  @override
  State<RestaurantReviewsPage> createState() => _RestaurantReviewsPageState();
}

enum _ReviewListStatus { loading, ready, error }

class _RestaurantReviewsPageState extends State<RestaurantReviewsPage> {
  late final RestaurantReviewService _reviewService;
  late final bool _ownsReviewService;
  late List<RestaurantReview> _reviews;
  late _ReviewListStatus _status;

  @override
  void initState() {
    super.initState();
    _ownsReviewService = widget.reviewService == null;
    _reviewService = widget.reviewService ?? RestaurantReviewService();
    _reviews = widget.data.reviews
        .where((review) => review.isPublished)
        .toList(growable: false);
    _status = widget.data.hasReviewList
        ? _ReviewListStatus.ready
        : _ReviewListStatus.loading;
    if (!widget.data.hasReviewList) {
      unawaited(_loadReviews());
    }
  }

  @override
  void dispose() {
    if (_ownsReviewService) _reviewService.close();
    super.dispose();
  }

  Future<void> _loadReviews({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() => _status = _ReviewListStatus.loading);
    }
    try {
      final reviews = await _reviewService.getReviews(widget.data.restaurantId);
      if (!mounted) return;
      setState(() {
        _reviews = reviews
            .where((review) => review.isPublished)
            .toList(growable: false);
        _status = _ReviewListStatus.ready;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = _ReviewListStatus.error);
    }
  }

  Future<void> _refresh() async {
    if (widget.data.hasReviewList) return;
    await _loadReviews(showLoading: false);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _ReviewsHeader(
            title: localizations.reviewsTitle,
            backLabel: localizations.back,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                key: const ValueKey('restaurant-reviews-list'),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.screen,
                  AppSpacing.lg,
                  AppSpacing.screen,
                  40,
                ),
                itemCount:
                    _status == _ReviewListStatus.ready && _reviews.isNotEmpty
                    ? _reviews.length + 1
                    : 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          widget.data.restaurantName,
                          textAlign: TextAlign.start,
                          style: AppTextStyles.cardTitle,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _RatingSummary(
                          rating: widget.data.rating,
                          reviewCount: widget.data.reviewCount,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        switch (_status) {
                          _ReviewListStatus.loading => _ReviewsLoading(
                            semanticLabel: localizations.loadingReviews,
                          ),
                          _ReviewListStatus.error => _ReviewListError(
                            onRetry: _loadReviews,
                          ),
                          _ReviewListStatus.ready when _reviews.isEmpty =>
                            const _EmptyReviews(),
                          _ReviewListStatus.ready => const SizedBox.shrink(),
                        },
                      ],
                    );
                  }

                  final reviewIndex = index - 1;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: reviewIndex == _reviews.length - 1
                          ? 0
                          : AppSpacing.sm,
                    ),
                    child: _ReviewCard(review: _reviews[reviewIndex]),
                  );
                },
              ),
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
                  textAlign: TextAlign.start,
                  style: AppTextStyles.reviewName,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                formattedDate,
                textAlign: TextAlign.end,
                style: AppTextStyles.reviewDate,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [RatingStars(rating: rating)],
            ),
          ),
          if (comment != null && comment.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              comment,
              key: ValueKey('review-comment-${review.id}'),
              textAlign: TextAlign.start,
              style: AppTextStyles.detailsBody,
            ),
          ],
        ],
      ),
    );
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

class _ReviewsLoading extends StatelessWidget {
  const _ReviewsLoading({required this.semanticLabel});

  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('restaurant-reviews-loading'),
      height: 220,
      child: Center(
        child: ThurayaLoadingIndicator(size: 82, semanticLabel: semanticLabel),
      ),
    );
  }
}

class _ReviewListError extends StatelessWidget {
  const _ReviewListError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return SizedBox(
      key: const ValueKey('restaurant-reviews-error'),
      height: 220,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.rate_review_outlined,
              color: AppColors.textMuted,
              size: 34,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              localizations.reviewsLoadError,
              textAlign: TextAlign.center,
              style: AppTextStyles.screenSubtitle,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              key: const ValueKey('restaurant-reviews-retry'),
              onPressed: onRetry,
              child: Text(localizations.retry),
            ),
          ],
        ),
      ),
    );
  }
}
