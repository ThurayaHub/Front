import 'package:flutter/material.dart';
import 'package:thuraya/core/constants/app_assets.dart';
import 'package:thuraya/core/network/api_config.dart';
import 'package:thuraya/core/theme/app_colors.dart';

/// Shared restaurant image renderer for absolute and API-relative photo URLs.
class RestaurantImage extends StatelessWidget {
  const RestaurantImage({
    super.key,
    required this.source,
    this.fit = BoxFit.cover,
  });

  final String? source;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final fallback = Image.asset(
      AppAssets.restaurantDetailsCover,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
    );
    final value = source?.trim();
    if (value == null || value.isEmpty) return fallback;

    final url = value.startsWith('http://') || value.startsWith('https://')
        ? value
        : _absoluteApiUrl(value);
    return Image.network(
      url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) => fallback,
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : ColoredBox(
              color: AppColors.panel,
              child: Center(
                child: SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    value: progress.expectedTotalBytes == null
                        ? null
                        : progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!,
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
    );
  }
}

String _absoluteApiUrl(String value) {
  final normalized = value.startsWith('/') ? value.substring(1) : value;
  final base = ApiConfig.baseUrl.endsWith('/')
      ? Uri.parse(ApiConfig.baseUrl)
      : Uri.parse('${ApiConfig.baseUrl}/');
  return base.resolve(normalized).toString();
}
