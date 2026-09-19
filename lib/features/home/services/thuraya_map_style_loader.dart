import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:thuraya/features/home/services/thuraya_map_font_cache_stub.dart'
    if (dart.library.io) 'package:thuraya/features/home/services/thuraya_map_font_cache_io.dart'
    as map_font_cache;

/// Prepares the MapLibre style for the renderer used by the current platform.
///
/// OpenFreeMap's PBF glyph endpoint is retained as the fallback for Latin text.
/// On iOS, Arabic characters are instead backed by an OpenType font copied from
/// the application bundle. This makes MapLibre Native route Arabic through its
/// HarfBuzz complex-text shaper without depending on a third-party font request.
class ThurayaMapStyleLoader {
  const ThurayaMapStyleLoader._();

  static const String regularArabicFontAsset =
      'assets/fonts/Tajawal-Regular.ttf';
  static const String boldArabicFontAsset = 'assets/fonts/Tajawal-Bold.ttf';

  static Future<String> loadForCurrentPlatform({
    required String styleAsset,
    TargetPlatform? platform,
  }) async {
    final resolvedPlatform = platform ?? defaultTargetPlatform;
    if (kIsWeb || resolvedPlatform != TargetPlatform.iOS) {
      return styleAsset;
    }

    final styleJson = await rootBundle.loadString(styleAsset);
    final fontUris = await map_font_cache.cacheArabicMapFonts(
      regularAsset: regularArabicFontAsset,
      boldAsset: boldArabicFontAsset,
    );

    return useBundledArabicFonts(
      styleJson,
      regularFontUri: fontUris[0],
      boldFontUri: fontUris[1],
    );
  }

  @visibleForTesting
  static String useBundledArabicFonts(
    String styleJson, {
    required Uri regularFontUri,
    required Uri boldFontUri,
  }) {
    final style = jsonDecode(styleJson);
    if (style is! Map<String, dynamic>) {
      throw const FormatException('The MapLibre style root must be an object.');
    }

    final fontFaces = style['font-faces'];
    if (fontFaces is! Map<String, dynamic>) {
      throw const FormatException(
        'The MapLibre style must declare font-faces for Arabic shaping.',
      );
    }

    _replaceFontFaceUrl(
      fontFaces,
      fontStack: 'Noto Sans Regular',
      fontUri: regularFontUri,
    );
    _replaceFontFaceUrl(
      fontFaces,
      fontStack: 'Noto Sans Bold',
      fontUri: boldFontUri,
    );

    return jsonEncode(style);
  }

  static void _replaceFontFaceUrl(
    Map<String, dynamic> fontFaces, {
    required String fontStack,
    required Uri fontUri,
  }) {
    final faces = fontFaces[fontStack];
    if (faces is! List || faces.isEmpty || faces.first is! Map) {
      throw FormatException(
        'The MapLibre style has no usable $fontStack font-face.',
      );
    }

    final face = Map<String, dynamic>.from(faces.first as Map);
    face['url'] = fontUri.toString();
    faces[0] = face;
  }
}
