import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:thuraya/core/constants/app_assets.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/core/theme/app_text_styles.dart';

class DynamicWheel extends StatelessWidget {
  const DynamicWheel({
    super.key,
    required this.options,
    required this.rotation,
    this.size = 320,
  });

  final List<String> options;
  final double rotation;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey('wheel-option-count-${options.length}'),
      width: size,
      height: size + 24,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 24,
            child: Semantics(
              image: true,
              label: options.join('، '),
              child: Container(
                width: size,
                height: size,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x261A237E),
                      offset: Offset(0, 8),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: Transform.rotate(
                  angle: rotation,
                  child: CustomPaint(painter: _WheelPainter(options: options)),
                ),
              ),
            ),
          ),
          Positioned(
            top: 24,
            width: size,
            height: size,
            child: Center(
              child: Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: AppColors.background, width: 4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A000000),
                      offset: Offset(0, 4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.awardStar,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: SvgPicture.asset(
              AppAssets.wheelPointer,
              width: 24,
              height: 30,
            ),
          ),
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  const _WheelPainter({required this.options});

  final List<String> options;

  static const _sectionColors = [
    AppColors.background,
    AppColors.panel,
    Color(0xFFFFF7DC),
    Color(0xFFF0F0FA),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 2;
    final bounds = Rect.fromCircle(center: center, radius: radius);

    if (options.isEmpty) {
      canvas.drawCircle(center, radius, Paint()..color = AppColors.background);
    } else {
      final sweep = math.pi * 2 / options.length;
      for (var index = 0; index < options.length; index++) {
        final start = -math.pi / 2 + index * sweep;
        final section = Path()
          ..moveTo(center.dx, center.dy)
          ..arcTo(bounds, start, sweep, false)
          ..close();

        canvas.drawPath(
          section,
          Paint()..color = _sectionColors[index % _sectionColors.length],
        );
        canvas.drawPath(
          section,
          Paint()
            ..color = const Color(0x33000666)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );

        _paintLabel(
          canvas,
          center,
          radius,
          start + sweep / 2,
          sweep,
          options[index],
        );
      }
    }

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.award
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  void _paintLabel(
    Canvas canvas,
    Offset center,
    double radius,
    double angle,
    double sweep,
    String label,
  ) {
    final fontSize = switch (options.length) {
      <= 6 => 14.0,
      <= 10 => 12.0,
      _ => 10.0,
    };
    final maxWidth = (radius * sweep * 0.78).clamp(42.0, 106.0).toDouble();
    final position = Offset(
      center.dx + math.cos(angle) * radius * 0.64,
      center.dy + math.sin(angle) * radius * 0.64,
    );
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: AppColors.primary,
          fontFamily: AppTextStyles.fontFamily,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          height: 1.15,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);

    painter.paint(
      canvas,
      Offset(position.dx - painter.width / 2, position.dy - painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_WheelPainter oldDelegate) {
    return oldDelegate.options.length != options.length ||
        !_listEquals(oldDelegate.options, options);
  }

  bool _listEquals(List<String> first, List<String> second) {
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }
}
