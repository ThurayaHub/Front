import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Prepares the MapLibre style for the renderer used by the current platform.
///
/// MapLibre Native 6.28's OpenType `font-faces` path shapes Arabic glyphs but
/// lays them out in left-to-right order. On iOS, keep the whole label on the
/// PBF glyph path, where MapLibre applies Arabic shaping and the Unicode bidi
/// algorithm together. Other platforms retain the original style unchanged.
class ThurayaMapStyleLoader {
  const ThurayaMapStyleLoader._();

  static Future<String> loadForCurrentPlatform({
    required String styleAsset,
    TargetPlatform? platform,
  }) async {
    final resolvedPlatform = platform ?? defaultTargetPlatform;
    if (kIsWeb || resolvedPlatform != TargetPlatform.iOS) {
      return styleAsset;
    }

    final styleJson = await rootBundle.loadString(styleAsset);
    return useNativePbfGlyphs(styleJson);
  }

  @visibleForTesting
  static String useNativePbfGlyphs(String styleJson) {
    final style = jsonDecode(styleJson);
    if (style is! Map<String, dynamic>) {
      throw const FormatException('The MapLibre style root must be an object.');
    }

    style.remove('font-faces');

    return jsonEncode(style);
  }
}
