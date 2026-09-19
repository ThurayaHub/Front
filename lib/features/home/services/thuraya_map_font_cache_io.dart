import 'dart:io';

import 'package:flutter/services.dart';

Future<List<Uri>> cacheArabicMapFonts({
  required String regularAsset,
  required String boldAsset,
}) async {
  final fontDirectory = Directory(
    '${Directory.systemTemp.path}${Platform.pathSeparator}'
    'thuraya-map-fonts-v1',
  );
  await fontDirectory.create(recursive: true);

  final regularFont = await _copyFontAsset(
    assetPath: regularAsset,
    destination: File(
      '${fontDirectory.path}${Platform.pathSeparator}Tajawal-Regular.ttf',
    ),
  );
  final boldFont = await _copyFontAsset(
    assetPath: boldAsset,
    destination: File(
      '${fontDirectory.path}${Platform.pathSeparator}Tajawal-Bold.ttf',
    ),
  );

  return <Uri>[regularFont.uri, boldFont.uri];
}

Future<File> _copyFontAsset({
  required String assetPath,
  required File destination,
}) async {
  final data = await rootBundle.load(assetPath);
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

  if (!await destination.exists() ||
      await destination.length() != bytes.length) {
    await destination.writeAsBytes(bytes, flush: true);
  }
  return destination;
}
