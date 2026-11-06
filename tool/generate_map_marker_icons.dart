// Regenerate the two shared map glyph PNGs after editing their SVG sources:
// flutter test tool/generate_map_marker_icons.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('rasterize map glyphs at 3x the SVG size', () async {
    final previewRecorder = ui.PictureRecorder();
    final preview = ui.Canvas(previewRecorder)..scale(3);
    preview.drawColor(const ui.Color(0xFFF7F8FA), ui.BlendMode.src);
    var index = 0;
    for (final name in ['restaurant', 'cafe']) {
      final svg = await File('assets/map/${name}_icon.svg').readAsString();
      final picture = await vg.loadPicture(SvgStringLoader(svg), null);
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder)..scale(3);
      canvas.drawPicture(picture.picture);
      final scaled = recorder.endRecording();
      final image = await scaled.toImage(72, 72);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'assets/map/${name}_icon.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      for (final selected in [false, true]) {
        final center = ui.Offset(40 + index * 60, selected ? 88 : 32);
        final radius = selected ? 20.0 : 16.0;
        preview.drawCircle(
          center,
          radius + 2.5,
          ui.Paint()
            ..color = const ui.Color(0x33000666)
            ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3),
        );
        preview.drawCircle(
          center,
          radius,
          ui.Paint()
            ..color = selected
                ? const ui.Color(0xFFD4AF37)
                : const ui.Color(0xFF000666),
        );
        preview.drawCircle(
          center,
          radius,
          ui.Paint()
            ..color = const ui.Color(0xFFFFFFFF)
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = selected ? 3 : 2.25,
        );
        final iconSize = selected ? 26.0 : 22.0;
        preview.drawImageRect(
          image,
          const ui.Rect.fromLTWH(0, 0, 72, 72),
          ui.Rect.fromCenter(center: center, width: iconSize, height: iconSize),
          ui.Paint()..filterQuality = ui.FilterQuality.high,
        );
      }
      index++;
      image.dispose();
      scaled.dispose();
      picture.picture.dispose();
    }
    final previewPicture = previewRecorder.endRecording();
    final previewImage = await previewPicture.toImage(420, 360);
    final previewBytes = await previewImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    await File(
      '.dart_tool/map_marker_preview.png',
    ).writeAsBytes(previewBytes!.buffer.asUint8List());
    previewImage.dispose();
    previewPicture.dispose();
  });
}
