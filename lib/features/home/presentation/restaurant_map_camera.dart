import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:thuraya/features/home/models/restaurant_map_marker.dart';

/// Camera geometry uses MapLibre's 512px Mercator world, in logical pixels.
abstract final class RestaurantMapCamera {
  static CameraPosition fit(
    List<RestaurantMapMarker> places, {
    required Size size,
    required EdgeInsets padding,
    required double minimumZoom,
    required double maximumZoom,
  }) {
    assert(places.isNotEmpty);
    final points = places.map(_project).toList(growable: false);
    final west = points.map((p) => p.dx).reduce(min);
    final east = points.map((p) => p.dx).reduce(max);
    final north = points.map((p) => p.dy).reduce(min);
    final south = points.map((p) => p.dy).reduce(max);
    final width = max(1.0, size.width - padding.horizontal);
    final height = max(1.0, size.height - padding.vertical);
    final scaleX = east == west
        ? double.infinity
        : width / (512 * (east - west));
    final scaleY = south == north
        ? double.infinity
        : height / (512 * (south - north));
    final zoom = (log(min(scaleX, scaleY)) / ln2)
        .clamp(minimumZoom, maximumZoom)
        .toDouble();
    final scale = 512 * pow(2, zoom);
    // Shift the target so the bounds sit in the usable space between controls.
    final x = (west + east) / 2 - (padding.left - padding.right) / (2 * scale);
    final y =
        (north + south) / 2 - (padding.top - padding.bottom) / (2 * scale);
    return CameraPosition(
      target: LatLng(atan(_sinh(pi * (1 - 2 * y))) * 180 / pi, x * 360 - 180),
      zoom: zoom,
    );
  }

  static bool overlap(
    RestaurantMapMarker first,
    RestaurantMapMarker second,
    double zoom,
  ) => (_project(first) - _project(second)).distance * 512 * pow(2, zoom) < 28;

  static Offset _project(RestaurantMapMarker place) {
    final latitude = place.latitude.clamp(-85.051129, 85.051129) * pi / 180;
    return Offset(
      (place.longitude + 180) / 360,
      (1 - log(tan(latitude) + 1 / cos(latitude)) / pi) / 2,
    );
  }

  static double _sinh(double value) => (exp(value) - exp(-value)) / 2;
}
