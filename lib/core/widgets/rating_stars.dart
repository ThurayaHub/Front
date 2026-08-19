import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:thuraya/core/constants/app_assets.dart';
import 'package:thuraya/core/theme/app_colors.dart';

class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.maxStars = 5,
    this.starSize = 18,
    this.spacing = 2,
  });

  final double rating;
  final int maxStars;
  final double starSize;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < maxStars; index++) ...[
            _FractionalRatingStar(
              fill: (rating - index).clamp(0, 1).toDouble(),
              size: starSize,
            ),
            if (index != maxStars - 1) SizedBox(width: spacing),
          ],
        ],
      ),
    );
  }
}

class _FractionalRatingStar extends StatelessWidget {
  const _FractionalRatingStar({required this.fill, required this.size});

  final double fill;
  final double size;

  @override
  Widget build(BuildContext context) {
    final height = size * 25.333 / 26.667;

    return SizedBox(
      width: size,
      height: height,
      child: Stack(
        children: [
          SvgPicture.asset(
            AppAssets.restaurantRatingStar,
            width: size,
            height: height,
            colorFilter: const ColorFilter.mode(
              AppColors.panelBorder,
              BlendMode.srcIn,
            ),
          ),
          if (fill > 0)
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              width: size * fill,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.centerLeft,
                  minWidth: size,
                  maxWidth: size,
                  child: SvgPicture.asset(
                    AppAssets.restaurantRatingStar,
                    width: size,
                    height: height,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
