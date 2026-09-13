import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, dynamic> style;
  late Map<String, Map<String, dynamic>> layers;

  setUpAll(() async {
    final source = await File(
      'assets/map/thuraya_map_style.json',
    ).readAsString();
    style = Map<String, dynamic>.from(jsonDecode(source) as Map);
    layers = {
      for (final layer in style['layers'] as List<dynamic>)
        (layer as Map<String, dynamic>)['id'] as String: layer,
    };
  });

  test('uses OpenFreeMap resources in a valid local MapLibre style', () {
    expect(style['version'], 8);
    expect(style['sprite'], startsWith('https://tiles.openfreemap.org/'));
    expect(style['glyphs'], startsWith('https://tiles.openfreemap.org/'));

    final sources = style['sources'] as Map<String, dynamic>;
    final openMapTiles = sources['openmaptiles'] as Map<String, dynamic>;
    expect(openMapTiles['type'], 'vector');
    expect(openMapTiles['url'], 'https://tiles.openfreemap.org/planet');
    expect(layers.length, (style['layers'] as List<dynamic>).length);
  });

  test('uses the Thuraya light palette without Bright road colors', () {
    expect(_paint(layers, 'background', 'background-color'), '#F7F8FA');
    expect(_paint(layers, 'highway-minor', 'line-color'), '#FFFFFF');
    expect(_paint(layers, 'highway-primary', 'line-color'), '#F6F0E2');
    expect(_paint(layers, 'highway-motorway', 'line-color'), '#F1E6CF');
    expect(_paint(layers, 'building', 'fill-color'), '#E8EAED');
    expect(_paint(layers, 'park', 'fill-color'), '#DCECDC');
    expect(_paint(layers, 'water', 'fill-color'), '#BFDEEC');

    final transportationLayers = layers.values.where(
      (layer) => layer['source-layer'] == 'transportation',
    );
    final encodedRoads = jsonEncode(transportationLayers.toList());
    for (final oldColor in [
      '#e9ac77',
      '#fc8',
      '#fea',
      '#ffdaa6',
      '#fff4c6',
      'rgba(200, 147, 102, 1)',
      'rgba(244, 209, 158, 1)',
      'hsl(28,76%,67%)',
    ]) {
      expect(encodedRoads, isNot(contains(oldColor)));
    }
  });

  test('hides basemap POIs and renders geographic labels Arabic-first', () {
    for (final layerId in ['poi_r20', 'poi_r7', 'poi_r1', 'poi_transit']) {
      final layout = layers[layerId]!['layout'] as Map<String, dynamic>;
      expect(layout['visibility'], 'none');
    }

    final localizedLabels = layers.values.where((layer) {
      if (layer['type'] != 'symbol') return false;
      final layout = layer['layout'];
      if (layout is! Map<String, dynamic>) return false;
      return jsonEncode(layout['text-field']).contains('name:nonlatin');
    });
    expect(localizedLabels, isNotEmpty);

    for (final layer in localizedLabels) {
      final layout = layer['layout'] as Map<String, dynamic>;
      final textField = jsonEncode(layout['text-field']);
      expect(textField, contains('name:ar'));
      expect(textField, isNot(contains('concat')));
    }

    final neighborhoodLayout =
        layers['label_other']!['layout'] as Map<String, dynamic>;
    expect(neighborhoodLayout['text-font'], ['Noto Sans Regular']);
    expect(neighborhoodLayout['text-letter-spacing'], 0);
    expect(neighborhoodLayout['text-transform'], 'none');
    expect(neighborhoodLayout['text-size'], [
      'interpolate',
      ['linear'],
      ['zoom'],
      8,
      12,
      12,
      14,
    ]);
  });
}

Object? _paint(
  Map<String, Map<String, dynamic>> layers,
  String layerId,
  String property,
) {
  final paint = layers[layerId]!['paint'] as Map<String, dynamic>;
  return paint[property];
}
