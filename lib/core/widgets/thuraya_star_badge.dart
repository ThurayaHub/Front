import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:thuraya/core/constants/app_assets.dart';
import 'package:thuraya/core/theme/app_colors.dart';

/// The official compact Thuraya Star treatment used on restaurant cards.
class ThurayaStarBadge extends StatelessWidget {
  const ThurayaStarBadge({super.key, required this.semanticLabel});

  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: true,
      child: Tooltip(
        message: semanticLabel,
        child: Container(
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
      ),
    );
  }
}
