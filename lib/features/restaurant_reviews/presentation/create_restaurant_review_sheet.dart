import 'package:flutter/material.dart';
import 'package:thuraya/core/constants/app_spacing.dart';
import 'package:thuraya/core/network/api_client.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/core/theme/app_text_styles.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

typedef SubmitRestaurantReview =
    Future<void> Function(int stars, String comment);

class CreateRestaurantReviewSheet extends StatefulWidget {
  const CreateRestaurantReviewSheet({
    super.key,
    required this.restaurantName,
    required this.onSubmit,
  });

  static const int commentMaxLength = 4000;

  final String restaurantName;
  final SubmitRestaurantReview onSubmit;

  @override
  State<CreateRestaurantReviewSheet> createState() =>
      _CreateRestaurantReviewSheetState();
}

class _CreateRestaurantReviewSheetState
    extends State<CreateRestaurantReviewSheet> {
  final TextEditingController _commentController = TextEditingController();
  int _stars = 0;
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _canSubmit => !_isSubmitting && _stars > 0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.onSubmit(_stars, _commentController.text);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = error.statusCode == 409
            ? AppLocalizations.of(context).reviewDuplicateError
            : AppLocalizations.of(context).reviewSubmitError;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = AppLocalizations.of(context).reviewSubmitError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.screen,
            AppSpacing.sm,
            AppSpacing.screen,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.panelBorder,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.writeYourReview,
                key: const ValueKey('review-sheet-title'),
                textAlign: TextAlign.center,
                style: AppTextStyles.detailsTitle.copyWith(fontSize: 23),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                widget.restaurantName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.detailsMetadata,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.yourRating,
                textAlign: TextAlign.center,
                style: AppTextStyles.detailsAwardTitle,
              ),
              const SizedBox(height: AppSpacing.sm),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final value = index + 1;
                    return IconButton(
                      key: ValueKey('review-star-$value'),
                      tooltip: _ratingLabel(l10n, value),
                      onPressed: _isSubmitting
                          ? null
                          : () => setState(() {
                              _stars = value;
                              _errorMessage = null;
                            }),
                      iconSize: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      icon: Icon(
                        value <= _stars
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: AppColors.secondary,
                      ),
                    );
                  }),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: _stars == 0
                    ? const SizedBox(height: 22)
                    : Text(
                        _ratingLabel(l10n, _stars),
                        key: ValueKey('review-rating-label-$_stars'),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.detailsMetadata.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.reviewCommentLabel,
                style: AppTextStyles.detailsAwardTitle,
              ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                key: const ValueKey('review-comment-field'),
                controller: _commentController,
                enabled: !_isSubmitting,
                maxLines: 5,
                minLines: 4,
                maxLength: CreateRestaurantReviewSheet.commentMaxLength,
                textAlign: TextAlign.start,
                textInputAction: TextInputAction.newline,
                onChanged: (_) => setState(() => _errorMessage = null),
                decoration: InputDecoration(
                  hintText: l10n.reviewCommentHint,
                  hintStyle: const TextStyle(color: AppColors.inputHint),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.all(AppSpacing.md),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: AppColors.panelBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: AppColors.panelBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              if (_errorMessage case final message?) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  key: const ValueKey('review-submit-error'),
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                key: const ValueKey('review-submit-button'),
                onPressed: _canSubmit ? _submit : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : Text(l10n.submitReview),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _ratingLabel(AppLocalizations l10n, int stars) {
    return switch (stars) {
      1 => l10n.reviewRatingBad,
      2 => l10n.reviewRatingAcceptable,
      3 => l10n.reviewRatingGood,
      4 => l10n.reviewRatingVeryGood,
      5 => l10n.reviewRatingExcellent,
      _ => '',
    };
  }
}
