import 'package:flutter/material.dart';
import 'package:thuraya/core/constants/app_assets.dart';

class ThurayaLogo extends StatelessWidget {
  const ThurayaLogo({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.semanticLabel = 'Thuraya',
  });

  final double? width;
  final double? height;
  final BoxFit fit;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.thurayaLogo,
      width: width,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.high,
      semanticLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }
}
