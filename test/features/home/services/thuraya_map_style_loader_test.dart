import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thuraya/features/home/services/thuraya_map_style_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('iOS loader uses MapLibre native PBF shaping for Arabic', () async {
    final prepared = await ThurayaMapStyleLoader.loadForCurrentPlatform(
      styleAsset: 'assets/map/thuraya_map_style.json',
      platform: TargetPlatform.iOS,
    );
    final style = jsonDecode(prepared) as Map<String, dynamic>;

    expect(style, isNot(contains('font-faces')));
    expect(style['glyphs'], contains('tiles.openfreemap.org/fonts/'));
  });

  test('PBF preparation changes no style content except font-faces', () {
    const source =
        '{'
        '"version":8,'
        '"glyphs":"https://tiles.openfreemap.org/fonts/{fontstack}/{range}.pbf",'
        '"font-faces":{"Noto Sans Regular":[{"url":"font.ttf"}]},'
        '"layers":[]'
        '}';

    final prepared = ThurayaMapStyleLoader.useNativePbfGlyphs(source);
    final style = jsonDecode(prepared) as Map<String, dynamic>;

    expect(style, isNot(contains('font-faces')));
    expect(style['version'], 8);
    expect(style['glyphs'], contains('tiles.openfreemap.org/fonts/'));
    expect(style['layers'], isEmpty);
  });
}
