import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:thuraya/features/choose_restaurant/models/restaurant_lookup.dart';
import 'package:thuraya/features/choose_restaurant/services/restaurant_lookup_service.dart';
import 'package:thuraya/features/home/models/restaurant_map_marker.dart';
import 'package:thuraya/features/home/models/restaurant_search_filters.dart';
import 'package:thuraya/features/home/models/supported_map_region.dart';
import 'package:thuraya/features/home/services/restaurant_map_service.dart';

enum RestaurantResultsView { map, list }

class RestaurantSearchController extends ChangeNotifier {
  RestaurantSearchController({
    RestaurantSearchGateway? searchGateway,
    RestaurantLookupGateway? lookupGateway,
    this.region = SupportedMapRegions.riyadh,
  }) : _searchGateway = searchGateway ?? RestaurantMapService(),
       _lookupGateway = lookupGateway ?? RestaurantLookupService(),
       _ownsSearchGateway = searchGateway == null,
       _ownsLookupGateway = lookupGateway == null;

  final RestaurantSearchGateway _searchGateway;
  final RestaurantLookupGateway _lookupGateway;
  final bool _ownsSearchGateway;
  final bool _ownsLookupGateway;
  final SupportedMapRegion region;

  RestaurantSearchFilters filters = RestaurantSearchFilters();
  RestaurantResultsView resultsView = RestaurantResultsView.map;
  List<RestaurantMapMarker> results = const [];
  List<RestaurantLookupItemDto> priceLevels = const [];
  List<RestaurantLookupItemDto> categories = const [];
  bool isLoading = false;
  bool hasSearchError = false;
  bool isLoadingLookups = false;
  bool hasLookupError = false;
  bool _initialized = false;
  int _requestGeneration = 0;
  SupportedMapBounds? _currentViewport;
  String? _inFlightRequestSignature;
  bool _resultsIncludeListMetadata = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await loadLookups();
  }

  Future<void> loadLookups() async {
    if (isLoadingLookups) return;
    isLoadingLookups = true;
    hasLookupError = false;
    notifyListeners();
    try {
      final values = await Future.wait([
        _lookupGateway.getPriceLevels(),
        _lookupGateway.getCategories(),
      ]);
      priceLevels = values[0];
      categories = values[1];
      hasLookupError = false;
    } catch (_) {
      hasLookupError = true;
    } finally {
      isLoadingLookups = false;
      notifyListeners();
    }
  }

  Future<void> applyFilters(RestaurantSearchFilters value) async {
    final changed = value != filters;
    filters = value;
    if (changed) {
      _requestGeneration++;
      _inFlightRequestSignature = null;
      _resultsIncludeListMetadata = false;
      hasSearchError = false;
    }
    notifyListeners();
    if ((changed || hasSearchError) && _currentViewport != null) {
      await search(force: true);
    }
  }

  Future<void> loadViewport(SupportedMapBounds bounds) async {
    _currentViewport = bounds;
    await search(force: true);
  }

  Future<void> search({bool force = false}) async {
    final viewport = _currentViewport;
    if (viewport == null) return;
    final includeListMetadata = resultsView == RestaurantResultsView.list;
    final requestSignature = [
      filters.cacheSignature,
      includeListMetadata ? 'summary' : 'marker',
      viewport.southwestLatitude,
      viewport.southwestLongitude,
      viewport.northeastLatitude,
      viewport.northeastLongitude,
    ].join('|');
    if (isLoading && requestSignature == _inFlightRequestSignature) return;
    if (isLoading && !force) return;
    final requestGeneration = ++_requestGeneration;
    _inFlightRequestSignature = requestSignature;
    isLoading = true;
    hasSearchError = false;
    notifyListeners();
    try {
      final nextResults = await _searchGateway.loadViewport(
        filters,
        viewport,
        cacheExtent: region.bounds,
        includeListMetadata: includeListMetadata,
      );
      if (requestGeneration != _requestGeneration) return;
      results = nextResults;
      _resultsIncludeListMetadata = includeListMetadata;
      hasSearchError = false;
    } catch (_) {
      if (requestGeneration != _requestGeneration) return;
      hasSearchError = true;
    } finally {
      if (requestGeneration == _requestGeneration) {
        _inFlightRequestSignature = null;
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> clearAll() => applyFilters(RestaurantSearchFilters());

  void setResultsView(RestaurantResultsView value) {
    if (resultsView == value) return;
    resultsView = value;
    notifyListeners();
    if (value == RestaurantResultsView.list &&
        !_resultsIncludeListMetadata &&
        _currentViewport != null) {
      unawaited(search(force: true));
    }
  }

  RestaurantLookupItemDto? priceLevelById(int id) {
    for (final item in priceLevels) {
      if (item.id == id) return item;
    }
    return null;
  }

  RestaurantLookupItemDto? categoryById(int id) {
    for (final item in categories) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  void dispose() {
    _requestGeneration++;
    if (_ownsSearchGateway && _searchGateway is RestaurantMapService) {
      _searchGateway.close();
    }
    if (_ownsLookupGateway && _lookupGateway is RestaurantLookupService) {
      _lookupGateway.close();
    }
    super.dispose();
  }
}
