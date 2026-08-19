import 'package:flutter/material.dart';
import 'package:thuraya/core/theme/app_colors.dart';

abstract final class AppTextStyles {
  static const String fontFamily = 'Tajawal';

  static const TextStyle screenTitle = TextStyle(
    color: AppColors.primary,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 36 / 28,
  );

  static const TextStyle screenSubtitle = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
  );

  static const TextStyle wheelSubtitle = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 28 / 18,
  );

  static const TextStyle homeSearchHint = TextStyle(
    color: AppColors.inputHint,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle homeCardTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 22.5 / 18,
  );

  static const TextStyle homeDistance = TextStyle(
    color: AppColors.inputHint,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
  );

  static const TextStyle homeCategory = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 21 / 14,
  );

  static const TextStyle homeRating = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
  );

  static const TextStyle homeThurayaRating = TextStyle(
    color: AppColors.primary,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 24 / 16,
  );

  static const TextStyle detailsTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 36 / 28,
  );

  static const TextStyle detailsMetadata = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
  );

  static const TextStyle cardTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 28 / 20,
  );

  static const TextStyle cardMetadata = TextStyle(
    color: AppColors.textMuted,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
  );

  static const TextStyle badgeLabel = TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
  );

  static const TextStyle rating = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 20 / 14,
  );

  static const TextStyle detailsRating = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 28 / 20,
  );

  static const TextStyle detailsAwardTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 20 / 14,
  );

  static const TextStyle detailsCaption = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
  );

  static const TextStyle detailsReviewLink = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    decoration: TextDecoration.underline,
    decorationColor: AppColors.textSecondary,
  );

  static const TextStyle detailsActionLabel = TextStyle(
    color: AppColors.primary,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
  );

  static const TextStyle detailsBody = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 26 / 16,
  );

  static const TextStyle detailsGalleryLink = TextStyle(
    color: AppColors.primary,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
  );

  static const TextStyle reviewName = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 24 / 16,
  );

  static const TextStyle reviewDate = TextStyle(
    color: AppColors.textMuted,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
  );

  static const TextStyle navigationLabel = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 10.5,
    fontWeight: FontWeight.w500,
    height: 14 / 10.5,
  );

  static const TextTheme textTheme = TextTheme(
    headlineMedium: screenTitle,
    titleLarge: cardTitle,
    bodyLarge: screenSubtitle,
    bodySmall: cardMetadata,
    labelSmall: navigationLabel,
  );
}
