import 'package:flutter/material.dart';
import 'package:thuraya/core/constants/app_assets.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

enum ThurayaStarBadgeVariant { iconOnly, compact, full }

/// A branded award marker for restaurants that hold the Thuraya Star.
///
/// This widget represents a binary distinction and is intentionally separate
/// from review and rating components.
class ThurayaStarBadge extends StatelessWidget {
  const ThurayaStarBadge({
    super.key,
    required this.hasThurayaStar,
    this.size = 22,
    this.showLabel = true,
    this.variant = ThurayaStarBadgeVariant.compact,
    this.onTap,
    this.label,
    this.semanticLabel,
  }) : assert(size > 0);

  final bool hasThurayaStar;
  final double size;
  final bool showLabel;
  final ThurayaStarBadgeVariant variant;
  final VoidCallback? onTap;
  final String? label;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (!hasThurayaStar) return const SizedBox.shrink();

    final resolvedLabel = label ?? AppLocalizations.of(context).thurayaStar;
    final icon = Image.asset(
      AppAssets.thurayaStar,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
      excludeFromSemantics: true,
    );
    final isIconOnly =
        variant == ThurayaStarBadgeVariant.iconOnly || !showLabel;
    final content = isIconOnly
        ? SizedBox.square(dimension: size, child: icon)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              SizedBox(width: variant == ThurayaStarBadgeVariant.full ? 8 : 5),
              Text(
                resolvedLabel,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: TextStyle(
                  color: AppColors.primary,
                  fontFamily: 'Tajawal',
                  fontSize: variant == ThurayaStarBadgeVariant.full
                      ? (size * .52).clamp(13, 16)
                      : (size * .52).clamp(10, 13),
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
            ],
          );
    final badge = isIconOnly
        ? content
        : Container(
            padding: EdgeInsetsDirectional.fromSTEB(
              variant == ThurayaStarBadgeVariant.full ? 10 : 7,
              variant == ThurayaStarBadgeVariant.full ? 7 : 4,
              variant == ThurayaStarBadgeVariant.full ? 12 : 8,
              variant == ThurayaStarBadgeVariant.full ? 7 : 4,
            ),
            decoration: BoxDecoration(
              color: variant == ThurayaStarBadgeVariant.full
                  ? AppColors.background
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(
                variant == ThurayaStarBadgeVariant.full ? 18 : 13,
              ),
              border: Border.all(
                color: AppColors.secondary.withValues(
                  alpha: variant == ThurayaStarBadgeVariant.full ? .48 : .3,
                ),
              ),
              boxShadow: variant == ThurayaStarBadgeVariant.full
                  ? const [
                      BoxShadow(
                        color: Color(0x12000666),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: content,
          );

    final interactiveBadge = onTap == null
        ? badge
        : Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(
                isIconOnly
                    ? size / 2
                    : variant == ThurayaStarBadgeVariant.full
                    ? 18
                    : 13,
              ),
              child: badge,
            ),
          );

    return Semantics(
      label: semanticLabel ?? resolvedLabel,
      image: onTap == null,
      button: onTap != null,
      child: Tooltip(
        message: resolvedLabel,
        child: interactiveBadge,
      ),
    );
  }
}
