import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:thuraya/features/home/models/restaurant_map_marker.dart';
import 'package:thuraya/features/home/presentation/restaurant_map_camera.dart';

void main() {
  test('fits every location inside the space between map controls', () {
    const places = [_southwest, _northeast];
    const size = Size(390, 844);
    const padding = EdgeInsets.fromLTRB(48, 202, 48, 138);
    final camera = RestaurantMapCamera.fit(
      places,
      size: size,
      padding: padding,
      minimumZoom: 9.5,
      maximumZoom: 20,
    );
    final center = _project(camera.target, camera.zoom);
    for (final place in places) {
      final screen =
          _project(LatLng(place.latitude, place.longitude), camera.zoom) -
          center +
          Offset(size.width / 2, size.height / 2);
      expect(
        screen.dx,
        inInclusiveRange(
          padding.left - 0.001,
          size.width - padding.right + 0.001,
        ),
      );
      expect(
        screen.dy,
        inInclusiveRange(
          padding.top - 0.001,
          size.height - padding.bottom + 0.001,
        ),
      );
    }
  });

  test('identical coordinates yield a finite target at maximum zoom', () {
    final camera = RestaurantMapCamera.fit(
      [_southwest, _southwest],
      size: const Size(320, 600),
      padding: const EdgeInsets.all(48),
      minimumZoom: 9.5,
      maximumZoom: 20,
    );
    expect(camera.zoom, 20);
    expect(camera.target.latitude, closeTo(_southwest.latitude, 0.000001));
    expect(camera.target.longitude, closeTo(_southwest.longitude, 0.000001));
    expect(RestaurantMapCamera.overlap(_southwest, _southwest, 20), isTrue);
    expect(RestaurantMapCamera.overlap(_southwest, _northeast, 20), isFalse);
  });

  test(
    'native expansion zoom can be enforced for a cluster wider than the screen',
    () {
      final camera = RestaurantMapCamera.fit(
        [_southwest, _northeast],
        size: const Size(320, 600),
        padding: const EdgeInsets.fromLTRB(48, 200, 48, 130),
        minimumZoom: 15,
        maximumZoom: 20,
      );
      expect(camera.zoom, 15);
      // The target must be recomputed at the expansion zoom, rather than retaining
      // the large padding offset calculated for the zoomed-out search bounds.
      expect(camera.target.latitude, closeTo(24.75, 0.002));
      expect(camera.target.longitude, closeTo(46.75, 0.000001));
    },
  );
}

Offset _project(LatLng location, double zoom) {
  final sine = sin(location.latitude * pi / 180);
  final scale = 512 * pow(2, zoom);
  return Offset(
    (location.longitude + 180) / 360 * scale,
    (0.5 - log((1 + sine) / (1 - sine)) / (4 * pi)) * scale,
  );
}

const _southwest = RestaurantMapMarker(
  id: 1,
  name: 'Southwest',
  latitude: 24.7,
  longitude: 46.7,
  hasThurayaStar: false,
);
const _northeast = RestaurantMapMarker(
  id: 2,
  name: 'Northeast',
  latitude: 24.8,
  longitude: 46.8,
  hasThurayaStar: false,
);
