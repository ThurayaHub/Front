import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thuraya/features/home/services/thuraya_map_style_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('iOS loader copies bundled fonts and returns a native style', () async {
    final prepared = await ThurayaMapStyleLoader.loadForCurrentPlatform(
      styleAsset: 'assets/map/thuraya_map_style.json',
      platform: TargetPlatform.iOS,
    );
    final style = jsonDecode(prepared) as Map<String, dynamic>;
    final fontFaces = style['font-faces'] as Map<String, dynamic>;

    for (final fontStack in ['Noto Sans Regular', 'Noto Sans Bold']) {
      final face = (fontFaces[fontStack] as List).single as Map;
      final fontUri = Uri.parse(face['url'] as String);
      expect(fontUri.scheme, 'file');
      expect(await File.fromUri(fontUri).exists(), isTrue);
    }
  });

  test('iOS style uses bundled OpenType fonts for Arabic shaping', () async {
    final source = await File(
      'assets/map/thuraya_map_style.json',
    ).readAsString();

    final prepared = ThurayaMapStyleLoader.useBundledArabicFonts(
      source,
      regularFontUri: Uri.file('/app/fonts/Tajawal-Regular.ttf'),
      boldFontUri: Uri.file('/app/fonts/Tajawal-Bold.ttf'),
    );
    final style = jsonDecode(prepared) as Map<String, dynamic>;
    final fontFaces = style['font-faces'] as Map<String, dynamic>;

    final regular = (fontFaces['Noto Sans Regular'] as List).single as Map;
    final bold = (fontFaces['Noto Sans Bold'] as List).single as Map;
    expect(regular['url'], 'file:///app/fonts/Tajawal-Regular.ttf');
    expect(bold['url'], 'file:///app/fonts/Tajawal-Bold.ttf');

    for (final face in [regular, bold]) {
      expect(
        face['unicode-range'],
        containsAll(<String>['U+0600-06FF', 'U+0750-077F', 'U+08A0-08FF']),
      );
    }

    expect(style['glyphs'], contains('tiles.openfreemap.org/fonts/'));
  });

  test('bundled Arabic fonts contain OpenType shaping tables', () async {
    for (final path in [
      ThurayaMapStyleLoader.regularArabicFontAsset,
      ThurayaMapStyleLoader.boldArabicFontAsset,
    ]) {
      final bytes = await File(path).readAsBytes();
      final binaryText = String.fromCharCodes(bytes);
      expect(
        binaryText,
        contains('GSUB'),
        reason: '$path must support shaping',
      );
      expect(binaryText, contains('GPOS'), reason: '$path must support layout');
      expect(binaryText, contains('arab'), reason: '$path must support Arabic');
    }
  });
}
