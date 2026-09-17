import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:thuraya/features/home/models/restaurant_map_marker.dart';
import 'package:thuraya/features/home/models/supported_map_region.dart';
import 'package:thuraya/features/home/services/restaurant_map_session_cache.dart';

void main() {
  test(
    'buffers and snaps a viewport, then reuses it for a small pan',
    () async {
      final cache = RestaurantMapSessionCache();
      final requestedBounds = <SupportedMapBounds>[];

      Future<List<RestaurantMapMarker>> loader(
        SupportedMapBounds bounds,
      ) async {
        requestedBounds.add(bounds);
        return const [_restaurantA, _restaurantB];
      }

      final first = await cache.load(
        visibleBounds: _firstViewport,
        cacheExtent: _riyadhExtent,
        resultSignature: 'marker|none',
        loader: loader,
      );
      final second = await cache.load(
        visibleBounds: _smallPanViewport,
        cacheExtent: _riyadhExtent,
        resultSignature: 'marker|none',
        loader: loader,
      );

      expect(first.map((restaurant) => restaurant.id), [1, 2]);
      expect(second.map((restaurant) => restaurant.id), [1, 2]);
      expect(requestedBounds, hasLength(1));
      expect(requestedBounds.single.southwestLatitude, closeTo(24.5, 0.000001));
      expect(
        requestedBounds.single.southwestLongitude,
        closeTo(46.5, 0.000001),
      );
      expect(requestedBounds.single.northeastLatitude, closeTo(24.7, 0.000001));
      expect(
        requestedBounds.single.northeastLongitude,
        closeTo(46.7, 0.000001),
      );
      expect(cache.networkRequestCount, 1);
      expect(cache.cacheHitCount, 1);
    },
  );

  test('uses separate cells for different filter signatures', () async {
    final cache = RestaurantMapSessionCache();
    var requests = 0;

    Future<List<RestaurantMapMarker>> loader(SupportedMapBounds _) async {
      requests++;
      return const [_restaurantA];
    }

    await cache.load(
      visibleBounds: _firstViewport,
      cacheExtent: _riyadhExtent,
      resultSignature: 'summary|category=italian',
      loader: loader,
    );
    await cache.load(
      visibleBounds: _firstViewport,
      cacheExtent: _riyadhExtent,
      resultSignature: 'summary|category=japanese',
      loader: loader,
    );

    expect(requests, 2);
    expect(cache.networkRequestCount, 2);
  });

  test('deduplicates identical requests already in flight', () async {
    final cache = RestaurantMapSessionCache();
    final completer = Completer<List<RestaurantMapMarker>>();
    var requests = 0;

    Future<List<RestaurantMapMarker>> loader(SupportedMapBounds _) {
      requests++;
      return completer.future;
    }

    final first = cache.load(
      visibleBounds: _firstViewport,
      cacheExtent: _riyadhExtent,
      resultSignature: 'marker|none',
      loader: loader,
    );
    final second = cache.load(
      visibleBounds: _firstViewport,
      cacheExtent: _riyadhExtent,
      resultSignature: 'marker|none',
      loader: loader,
    );
    await Future<void>.delayed(Duration.zero);
    expect(requests, 1);

    completer.complete(const [_restaurantA]);
    await Future.wait([first, second]);
    expect(cache.networkRequestCount, 1);
  });

  test('evicts least recently used cells at the configured bound', () async {
    final cache = RestaurantMapSessionCache(
      viewportBufferFraction: 0,
      cellSizeDegrees: 0.1,
      maximumCellCount: 2,
    );

    Future<List<RestaurantMapMarker>> loader(SupportedMapBounds _) async =>
        const [];

    for (final viewport in [_cellOne, _cellTwo, _cellThree]) {
      await cache.load(
        visibleBounds: viewport,
        cacheExtent: _riyadhExtent,
        resultSignature: 'marker|none',
        loader: loader,
      );
    }

    expect(cache.cachedCellCount, 2);
    expect(cache.networkRequestCount, 3);
  });
}

const _riyadhExtent = SupportedMapBounds(
  southwestLatitude: 24.3,
  southwestLongitude: 46.3,
  northeastLatitude: 25.2,
  northeastLongitude: 47.4,
);

const _firstViewport = SupportedMapBounds(
  southwestLatitude: 24.60,
  southwestLongitude: 46.60,
  northeastLatitude: 24.65,
  northeastLongitude: 46.65,
);

const _smallPanViewport = SupportedMapBounds(
  southwestLatitude: 24.61,
  southwestLongitude: 46.61,
  northeastLatitude: 24.66,
  northeastLongitude: 46.66,
);

const _cellOne = SupportedMapBounds(
  southwestLatitude: 24.51,
  southwestLongitude: 46.51,
  northeastLatitude: 24.59,
  northeastLongitude: 46.59,
);

const _cellTwo = SupportedMapBounds(
  southwestLatitude: 24.61,
  southwestLongitude: 46.61,
  northeastLatitude: 24.69,
  northeastLongitude: 46.69,
);

const _cellThree = SupportedMapBounds(
  southwestLatitude: 24.71,
  southwestLongitude: 46.71,
  northeastLatitude: 24.79,
  northeastLongitude: 46.79,
);

const _restaurantA = RestaurantMapMarker(
  id: 1,
  name: 'A',
  latitude: 24.61,
  longitude: 46.61,
  hasThurayaStar: false,
);

const _restaurantB = RestaurantMapMarker(
  id: 2,
  name: 'B',
  latitude: 24.64,
  longitude: 46.64,
  hasThurayaStar: true,
);
