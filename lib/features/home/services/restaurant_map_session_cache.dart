import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:thuraya/features/home/models/restaurant_map_marker.dart';
import 'package:thuraya/features/home/models/supported_map_region.dart';

typedef RestaurantMapCellLoader =
    Future<List<RestaurantMapMarker>> Function(SupportedMapBounds bounds);

/// Bounded, in-memory geographic cache used only for the current app session.
///
/// Viewports are padded before they are snapped to stable cells. A small pan
/// therefore reuses the prefetched cells instead of producing a new request
/// for slightly different decimal bounds.
class RestaurantMapSessionCache {
  RestaurantMapSessionCache({
    this.viewportBufferFraction = 0.25,
    this.cellSizeDegrees = 0.1,
    this.maximumCellCount = 128,
  }) : assert(viewportBufferFraction >= 0),
       assert(cellSizeDegrees > 0),
       assert(maximumCellCount > 0);

  final double viewportBufferFraction;
  final double cellSizeDegrees;
  final int maximumCellCount;

  final LinkedHashMap<_CellKey, List<RestaurantMapMarker>> _cells =
      LinkedHashMap();
  final Map<_FetchKey, Future<void>> _inFlight = {};

  int _networkRequestCount = 0;
  int _cacheHitCount = 0;
  int _cacheMissCount = 0;

  Future<List<RestaurantMapMarker>> load({
    required SupportedMapBounds visibleBounds,
    required SupportedMapBounds cacheExtent,
    required String resultSignature,
    required RestaurantMapCellLoader loader,
  }) async {
    final requestedBounds = visibleBounds.expandedBy(
      viewportBufferFraction,
      constrainedTo: cacheExtent,
    );
    final requiredCells = _cellCoordinatesFor(requestedBounds);
    final missingCells = requiredCells
        .where(
          (cell) => !_cells.containsKey(
            _CellKey(resultSignature, cell.latitude, cell.longitude),
          ),
        )
        .toList(growable: false);

    if (missingCells.isEmpty) {
      _cacheHitCount++;
      final cachedRestaurants = _readCells(requiredCells, resultSignature);
      _log(
        'frontend cache hit',
        resultSignature,
        resultCount: cachedRestaurants.length,
        cellCount: requiredCells.length,
      );
      return cachedRestaurants;
    }

    _cacheMissCount++;
    _log(
      'frontend cache miss',
      resultSignature,
      cellCount: missingCells.length,
    );
    final fetchBounds =
        _boundsForCells(missingCells).intersection(cacheExtent) ??
        requestedBounds;
    final fetchKey = _FetchKey(resultSignature, fetchBounds);
    final existingRequest = _inFlight[fetchKey];
    if (existingRequest != null) {
      _log(
        'frontend in-flight hit',
        resultSignature,
        cellCount: missingCells.length,
      );
      await existingRequest;
    } else {
      final request = _fetchAndStore(
        fetchBounds: fetchBounds,
        resultSignature: resultSignature,
        loader: loader,
      );
      _inFlight[fetchKey] = request;
      try {
        await request;
      } finally {
        _inFlight.remove(fetchKey);
      }
    }

    return _readCells(requiredCells, resultSignature);
  }

  Future<void> _fetchAndStore({
    required SupportedMapBounds fetchBounds,
    required String resultSignature,
    required RestaurantMapCellLoader loader,
  }) async {
    _networkRequestCount++;
    final stopwatch = Stopwatch()..start();
    _log(
      'map request sent',
      resultSignature,
      cellCount: _cellCoordinatesFor(fetchBounds).length,
    );
    final restaurants = await loader(fetchBounds);
    stopwatch.stop();

    final fetchedCells = _cellCoordinatesFor(fetchBounds);
    final restaurantsByCell = <_CellCoordinate, List<RestaurantMapMarker>>{};
    for (final restaurant in restaurants) {
      final coordinate = _coordinateFor(
        restaurant.latitude,
        restaurant.longitude,
      );
      restaurantsByCell.putIfAbsent(coordinate, () => []).add(restaurant);
    }

    for (final coordinate in fetchedCells) {
      final key = _CellKey(
        resultSignature,
        coordinate.latitude,
        coordinate.longitude,
      );
      _cells.remove(key);
      _cells[key] = List.unmodifiable(
        restaurantsByCell[coordinate] ?? const <RestaurantMapMarker>[],
      );
    }
    _evictLeastRecentlyUsedCells();
    _log(
      'map request completed',
      resultSignature,
      resultCount: restaurants.length,
      cellCount: fetchedCells.length,
      duration: stopwatch.elapsed,
    );
  }

  List<RestaurantMapMarker> _readCells(
    List<_CellCoordinate> coordinates,
    String resultSignature,
  ) {
    final restaurantsById = <int, RestaurantMapMarker>{};
    for (final coordinate in coordinates) {
      final key = _CellKey(
        resultSignature,
        coordinate.latitude,
        coordinate.longitude,
      );
      final restaurants = _cells.remove(key);
      if (restaurants == null) continue;
      _cells[key] = restaurants;
      for (final restaurant in restaurants) {
        restaurantsById[restaurant.id] = restaurant;
      }
    }
    final result = restaurantsById.values.toList(growable: false)
      ..sort((left, right) => left.name.compareTo(right.name));
    return result;
  }

  List<_CellCoordinate> _cellCoordinatesFor(SupportedMapBounds bounds) {
    const boundaryEpsilon = 1e-9;
    final south = (bounds.southwestLatitude / cellSizeDegrees).floor();
    final north =
        ((bounds.northeastLatitude - boundaryEpsilon) / cellSizeDegrees)
            .floor();
    final west = (bounds.southwestLongitude / cellSizeDegrees).floor();
    final east =
        ((bounds.northeastLongitude - boundaryEpsilon) / cellSizeDegrees)
            .floor();
    return [
      for (var latitude = south; latitude <= north; latitude++)
        for (var longitude = west; longitude <= east; longitude++)
          _CellCoordinate(latitude, longitude),
    ];
  }

  _CellCoordinate _coordinateFor(double latitude, double longitude) {
    return _CellCoordinate(
      (latitude / cellSizeDegrees).floor(),
      (longitude / cellSizeDegrees).floor(),
    );
  }

  SupportedMapBounds _boundsForCells(List<_CellCoordinate> cells) {
    var south = cells.first.latitude;
    var north = cells.first.latitude;
    var west = cells.first.longitude;
    var east = cells.first.longitude;
    for (final cell in cells.skip(1)) {
      if (cell.latitude < south) south = cell.latitude;
      if (cell.latitude > north) north = cell.latitude;
      if (cell.longitude < west) west = cell.longitude;
      if (cell.longitude > east) east = cell.longitude;
    }
    return SupportedMapBounds(
      southwestLatitude: south * cellSizeDegrees,
      southwestLongitude: west * cellSizeDegrees,
      northeastLatitude: (north + 1) * cellSizeDegrees,
      northeastLongitude: (east + 1) * cellSizeDegrees,
    );
  }

  void _evictLeastRecentlyUsedCells() {
    while (_cells.length > maximumCellCount) {
      _cells.remove(_cells.keys.first);
    }
  }

  void _log(
    String event,
    String resultSignature, {
    int? resultCount,
    int? cellCount,
    Duration? duration,
  }) {
    if (!kDebugMode) return;
    final resultText = resultCount == null ? '' : '; resultCount=$resultCount';
    final cellText = cellCount == null ? '' : '; cellCount=$cellCount';
    final durationText = duration == null
        ? ''
        : '; durationMs=${duration.inMilliseconds}';
    debugPrint(
      '[restaurant-map] $event; signature=${resultSignature.hashCode}'
      '$resultText$cellText$durationText',
    );
  }

  @visibleForTesting
  int get cachedCellCount => _cells.length;

  @visibleForTesting
  int get networkRequestCount => _networkRequestCount;

  @visibleForTesting
  int get cacheHitCount => _cacheHitCount;

  @visibleForTesting
  int get cacheMissCount => _cacheMissCount;

  void clear() {
    _cells.clear();
    _inFlight.clear();
  }
}

class _CellCoordinate {
  const _CellCoordinate(this.latitude, this.longitude);

  final int latitude;
  final int longitude;

  @override
  bool operator ==(Object other) =>
      other is _CellCoordinate &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

class _CellKey {
  const _CellKey(this.resultSignature, this.latitude, this.longitude);

  final String resultSignature;
  final int latitude;
  final int longitude;

  @override
  bool operator ==(Object other) =>
      other is _CellKey &&
      other.resultSignature == resultSignature &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(resultSignature, latitude, longitude);
}

class _FetchKey {
  const _FetchKey(this.resultSignature, this.bounds);

  final String resultSignature;
  final SupportedMapBounds bounds;

  @override
  bool operator ==(Object other) =>
      other is _FetchKey &&
      other.resultSignature == resultSignature &&
      other.bounds.southwestLatitude == bounds.southwestLatitude &&
      other.bounds.southwestLongitude == bounds.southwestLongitude &&
      other.bounds.northeastLatitude == bounds.northeastLatitude &&
      other.bounds.northeastLongitude == bounds.northeastLongitude;

  @override
  int get hashCode => Object.hash(
    resultSignature,
    bounds.southwestLatitude,
    bounds.southwestLongitude,
    bounds.northeastLatitude,
    bounds.northeastLongitude,
  );
}
