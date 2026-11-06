import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:thuraya/core/routing/app_route_names.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/features/home/models/restaurant_map_marker.dart';
import 'package:thuraya/features/home/models/restaurant_search_filters.dart';
import 'package:thuraya/features/home/models/supported_map_region.dart';
import 'package:thuraya/features/home/presentation/restaurant_map_camera.dart';
import 'package:thuraya/features/home/presentation/widgets/restaurant_map_preview.dart';
import 'package:thuraya/features/home/presentation/widgets/restaurant_marker_layer.dart';
import 'package:thuraya/features/home/services/current_location_service.dart';
import 'package:thuraya/features/home/services/restaurant_map_service.dart';
import 'package:thuraya/features/home/services/thuraya_map_style_loader.dart';
import 'package:thuraya/features/restaurant_details/models/restaurant_details_dto.dart';
import 'package:thuraya/features/restaurant_details/services/restaurant_details_service.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

class ThurayaMap extends StatefulWidget {
  const ThurayaMap({
    super.key,
    this.region = SupportedMapRegions.riyadh,
    this.padding = EdgeInsets.zero,
    this.onMapCreated,
    this.locationService = const CurrentLocationService(),
    this.restaurantMapService,
    this.restaurantDetailsService,
    this.restaurants,
    this.selectedRestaurant,
    this.onSelectedRestaurantChanged,
    this.onViewportChanged,
    this.fitRestaurants = false,
    this.fitRequestId = 0,
  });

  static const String customStyleAsset = 'assets/map/thuraya_map_style.json';

  final SupportedMapRegion region;
  final EdgeInsets padding;
  final MapCreatedCallback? onMapCreated;
  final CurrentLocationService locationService;
  final RestaurantMapService? restaurantMapService;
  final RestaurantDetailsService? restaurantDetailsService;
  final List<RestaurantMapMarker>? restaurants;
  final RestaurantMapMarker? selectedRestaurant;
  final ValueChanged<RestaurantMapMarker?>? onSelectedRestaurantChanged;
  final Future<void> Function(SupportedMapBounds bounds)? onViewportChanged;
  final bool fitRestaurants;

  /// Identifies a new search fit; marker refreshes must retain the same value.
  final int fitRequestId;

  @override
  State<ThurayaMap> createState() => _ThurayaMapState();
}

class _ThurayaMapState extends State<ThurayaMap> {
  static const double _locationButtonSize = 44;
  static const Duration _markerRequestDebounce = Duration(milliseconds: 350);

  MapLibreMapController? _mapController;
  late final RestaurantMapService _restaurantMapService;
  late final bool _ownsRestaurantMapService;
  Timer? _markerDebounce;
  Timer? _attributionNoticeTimer;
  Map<int, RestaurantMapMarker> _visibleRestaurantMarkers = const {};
  RestaurantMapMarker? _selectedRestaurant;
  late double _currentZoom;
  int _markerRequestGeneration = 0;
  int _cameraIntent = 0;
  int? _pendingFitIntent = 0;
  int _sourceRevision = 0;
  int _selectionRevision = 0;
  Future<void> _layerWrites = Future.value();
  bool _isPlacePickerOpen = false;
  bool _needsSelectionFocus = false;
  bool _isStyleLoaded = false;
  bool _isMarkerLayerReady = false;
  bool _hasShownMarkerError = false;
  bool _isOpeningRestaurantDetails = false;
  bool _isLocating = false;
  bool _showAttributionNotice = true;
  late final Future<String> _mapStyle;

  @override
  void initState() {
    super.initState();
    _mapStyle = ThurayaMapStyleLoader.loadForCurrentPlatform(
      styleAsset: ThurayaMap.customStyleAsset,
    );
    _currentZoom = widget.region.initialZoom;
    _ownsRestaurantMapService = widget.restaurantMapService == null;
    _restaurantMapService =
        widget.restaurantMapService ?? RestaurantMapService();
    _selectedRestaurant = widget.selectedRestaurant;
    _needsSelectionFocus = _selectedRestaurant != null;
  }

  @override
  void didUpdateWidget(covariant ThurayaMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fitRequestId != widget.fitRequestId) {
      _pendingFitIntent = ++_cameraIntent;
    }
    // A parent echoing a native marker selection must not focus it twice.
    if (oldWidget.selectedRestaurant?.id != widget.selectedRestaurant?.id &&
        _selectedRestaurant?.id != widget.selectedRestaurant?.id) {
      _setSelection(widget.selectedRestaurant);
    }
    final fitIntent = _takeFitIntent();
    if ((!identical(oldWidget.restaurants, widget.restaurants) ||
            fitIntent != null) &&
        widget.restaurants != null &&
        _isStyleLoaded &&
        _isMarkerLayerReady &&
        _mapController != null) {
      final requestGeneration = ++_markerRequestGeneration;
      unawaited(
        _showControlledRestaurants(
          controller: _mapController!,
          markers: widget.restaurants!,
          requestGeneration: requestGeneration,
          fitCameraIntent: fitIntent,
        ),
      );
    }
  }

  int? _takeFitIntent() {
    if (!widget.fitRestaurants || !_isMarkerLayerReady) return null;
    final intent = _pendingFitIntent;
    _pendingFitIntent = null;
    return _selectedRestaurant == null ? intent : null;
  }

  bool _isCurrentCameraIntent(int intent) => mounted && intent == _cameraIntent;

  // All programmatic movement passes through this gate. Async work captures an
  // intent before waiting, so a later selection or user gesture always wins.
  Future<void> _updateCamera(
    CameraUpdate update,
    int intent, {
    bool animate = true,
  }) async {
    final controller = _mapController;
    if (controller == null || !_isCurrentCameraIntent(intent)) return;
    if (animate) {
      await controller.animateCamera(
        update,
        duration: const Duration(milliseconds: 650),
      );
    } else {
      await controller.moveCamera(update);
    }
  }

  void _onMapPointerDown(PointerDownEvent _) {
    _cameraIntent++;
    _needsSelectionFocus = false;
  }

  Future<void> _writeLayers(Future<void> Function() write) {
    final next = _layerWrites.then((_) async {
      if (mounted) await write();
    });
    // Recover the queue after a transient native/style error without swallowing
    // the error returned to the caller of this particular operation.
    _layerWrites = next.catchError((Object error, StackTrace stack) {
      debugPrint('Unable to update restaurant map layers: $error');
    });
    return next;
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController?.onFeatureTapped.remove(_onRestaurantMarkerTapped);
    _mapController = controller;
    controller.onFeatureTapped.add(_onRestaurantMarkerTapped);
    widget.onMapCreated?.call(controller);
    setState(() {});
  }

  void _onStyleLoaded() {
    final controller = _mapController;
    if (controller == null) {
      return;
    }
    _isStyleLoaded = true;
    _isMarkerLayerReady = false;
    if (_showAttributionNotice) {
      _attributionNoticeTimer?.cancel();
      // OSM permits collapsing visible credits after five seconds. The native
      // information button keeps the source and licence links available.
      // https://osmfoundation.org/wiki/Attribution_Guidelines#Interactive_maps
      _attributionNoticeTimer = Timer(
        const Duration(seconds: 5),
        _dismissAttributionNotice,
      );
    }
    setState(() {
      _visibleRestaurantMarkers = const {};
    });
    unawaited(_initializeRestaurantMarkerLayer(controller));
  }

  Future<void> _initializeRestaurantMarkerLayer(
    MapLibreMapController controller,
  ) async {
    try {
      // Native addImage uses the screen image density; Web registers at 1x.
      // Compensate in icon-size so glyphs match their circles on every display.
      final imagePixelRatio = kIsWeb
          ? 1.0
          : MediaQuery.devicePixelRatioOf(context);
      await RestaurantMarkerLayer.install(
        controller,
        imagePixelRatio: imagePixelRatio,
      );
      if (!mounted || _mapController != controller || !_isStyleLoaded) {
        return;
      }
      _isMarkerLayerReady = true;
      final controlledRestaurants = widget.restaurants;
      if (controlledRestaurants == null) {
        _scheduleMarkerRefresh(immediate: true);
      } else {
        final requestGeneration = ++_markerRequestGeneration;
        await _showControlledRestaurants(
          controller: controller,
          markers: controlledRestaurants,
          requestGeneration: requestGeneration,
          fitCameraIntent: _takeFitIntent(),
        );
        if (widget.onViewportChanged != null) {
          _scheduleMarkerRefresh(immediate: true);
        }
      }
      final selected = _selectedRestaurant;
      if (selected != null && _needsSelectionFocus) {
        _setSelection(selected);
      }
    } catch (error, stackTrace) {
      debugPrint('Unable to install restaurant marker layers: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted && _mapController == controller) {
        _showMapMessage(
          AppLocalizations.of(context).restaurantMarkersUnavailable,
        );
      }
    }
  }

  void _onCameraMove(CameraPosition position) {
    _currentZoom = position.zoom;
    if (widget.restaurants != null && widget.onViewportChanged == null) return;
    _markerDebounce?.cancel();
    _markerRequestGeneration++;
  }

  void _onCameraIdle() {
    if (widget.restaurants == null || widget.onViewportChanged != null) {
      _scheduleMarkerRefresh();
    }
  }

  void _scheduleMarkerRefresh({bool immediate = false}) {
    if (!_isStyleLoaded || !_isMarkerLayerReady || _mapController == null) {
      return;
    }

    _markerDebounce?.cancel();
    final requestGeneration = ++_markerRequestGeneration;
    if (immediate) {
      unawaited(_loadRestaurantMarkers(requestGeneration));
      return;
    }

    _markerDebounce = Timer(
      _markerRequestDebounce,
      () => _loadRestaurantMarkers(requestGeneration),
    );
  }

  Future<void> _loadRestaurantMarkers(int requestGeneration) async {
    final controller = _mapController;
    if (controller == null || requestGeneration != _markerRequestGeneration) {
      return;
    }

    try {
      final visibleRegion = await controller.getVisibleRegion();
      if (!mounted || requestGeneration != _markerRequestGeneration) {
        return;
      }

      final visibleBounds = SupportedMapBounds(
        southwestLatitude: visibleRegion.southwest.latitude,
        southwestLongitude: visibleRegion.southwest.longitude,
        northeastLatitude: visibleRegion.northeast.latitude,
        northeastLongitude: visibleRegion.northeast.longitude,
      );
      final supportedViewport = widget.region.bounds.intersection(
        visibleBounds,
      );
      if (supportedViewport == null) {
        return;
      }

      final onViewportChanged = widget.onViewportChanged;
      if (onViewportChanged != null) {
        await onViewportChanged(supportedViewport);
        return;
      }

      final markers = await _restaurantMapService.loadViewport(
        RestaurantSearchFilters(),
        supportedViewport,
        cacheExtent: widget.region.bounds,
        includeListMetadata: false,
      );
      if (!mounted || requestGeneration != _markerRequestGeneration) {
        return;
      }

      await _replaceRestaurantMarkers(
        controller: controller,
        markers: markers,
        requestGeneration: requestGeneration,
      );
      if (requestGeneration == _markerRequestGeneration) {
        _hasShownMarkerError = false;
      }
    } catch (_) {
      if (!mounted ||
          requestGeneration != _markerRequestGeneration ||
          _hasShownMarkerError) {
        return;
      }
      _hasShownMarkerError = true;
      _showMapMessage(
        AppLocalizations.of(context).restaurantMarkersUnavailable,
      );
    }
  }

  Future<void> _replaceRestaurantMarkers({
    required MapLibreMapController controller,
    required List<RestaurantMapMarker> markers,
    required int requestGeneration,
  }) async {
    final languageCode = Localizations.localeOf(context).languageCode;
    await _writeLayers(() async {
      if (_mapController != controller ||
          requestGeneration != _markerRequestGeneration) {
        return;
      }
      await RestaurantMarkerLayer.update(controller, markers, languageCode);
      if (!mounted || _mapController != controller) return;
      final markersById = {for (final marker in markers) marker.id: marker};
      _sourceRevision++;
      setState(() {
        _visibleRestaurantMarkers = markersById;
        // A viewport refresh may omit the selected place. Its separate source
        // must keep the highlight and preview until the user dismisses it.
        _selectedRestaurant =
            markersById[_selectedRestaurant?.id] ?? _selectedRestaurant;
      });
      await RestaurantMarkerLayer.updateSelected(
        controller,
        _selectedRestaurant,
        languageCode,
      );
    });
  }

  Future<void> _showControlledRestaurants({
    required MapLibreMapController controller,
    required List<RestaurantMapMarker> markers,
    required int requestGeneration,
    required int? fitCameraIntent,
  }) async {
    await _replaceRestaurantMarkers(
      controller: controller,
      markers: markers,
      requestGeneration: requestGeneration,
    );
    if (fitCameraIntent == null ||
        !_isCurrentCameraIntent(fitCameraIntent) ||
        _selectedRestaurant != null ||
        markers.isEmpty ||
        !mounted ||
        requestGeneration != _markerRequestGeneration) {
      return;
    }

    if (markers.length == 1) {
      final restaurant = markers.single;
      await _updateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(restaurant.latitude, restaurant.longitude),
          RestaurantMarkerLayer.individualFocusZoom,
        ),
        fitCameraIntent,
      );
      return;
    }

    final fit = RestaurantMapCamera.fit(
      markers,
      size: context.size ?? MediaQuery.sizeOf(context),
      padding: EdgeInsets.fromLTRB(
        48,
        widget.padding.top + 36,
        48,
        widget.padding.bottom + 48,
      ),
      minimumZoom: widget.region.minimumZoom,
      maximumZoom: widget.region.maximumZoom,
    );
    await _updateCamera(
      CameraUpdate.newLatLngZoom(fit.target, fit.zoom),
      fitCameraIntent,
    );
  }

  void _onRestaurantMarkerTapped(
    Point<double> point,
    LatLng _,
    String featureId,
    String layerId,
    Annotation? _,
  ) {
    if (!RestaurantMarkerLayer.contains(layerId)) {
      return;
    }
    final intent = ++_cameraIntent;
    unawaited(_resolveFeatureTap(point, featureId, layerId, intent));
  }

  Future<void> _resolveFeatureTap(
    Point<double> point,
    String featureId,
    String layerId,
    int intent,
  ) async {
    final controller = _mapController;
    if (controller == null || !_isMarkerLayerReady) return;
    final sourceRevision = _sourceRevision;
    bool current() =>
        _isCurrentCameraIntent(intent) &&
        _mapController == controller &&
        sourceRevision == _sourceRevision;
    try {
      final isCluster = RestaurantMarkerLayer.isCluster(layerId);
      final features = await controller.queryRenderedFeatures(
        point,
        isCluster
            ? [RestaurantMarkerLayer.clusterLayerId]
            : RestaurantMarkerLayer.interactiveLayerIds,
        isCluster
            ? const ['has', 'point_count']
            : const [
                '!',
                ['has', 'point_count'],
              ],
      );
      if (!mounted || !current()) return;
      if (!isCluster) {
        final places = _placesFromFeatures(features);
        final tapped = _visibleRestaurantMarkers[int.tryParse(featureId)];
        if (tapped != null && !places.any((place) => place.id == tapped.id)) {
          places.insert(0, tapped);
        }
        if (places.length > 1) {
          await _showPlacePicker(places, intent);
        } else if (places.isNotEmpty) {
          _setSelection(places.single, notify: true);
        }
        return;
      }
      if (features.isEmpty) return;
      final feature = features.first as Map;
      final properties = feature['properties'] as Map;
      final clusterId = (properties['cluster_id'] as num).toInt();
      final count = (properties['point_count'] as num).toInt();
      final values = await Future.wait<Object>([
        controller.getClusterExpansionZoom(
          RestaurantMarkerLayer.sourceId,
          clusterId,
        ),
        controller.getClusterLeaves(
          RestaurantMarkerLayer.sourceId,
          clusterId,
          limit: count,
        ),
      ]);
      if (!mounted || !current()) return;
      final places = _placesFromFeatures(values[1] as List);
      if (places.isEmpty) return;
      _setSelection(null, notify: true);
      // Co-located venues cannot become distinct even at maximum zoom.
      if (places.length > 1 &&
          places.every(
            (place) => RestaurantMapCamera.overlap(
              places.first,
              place,
              widget.region.maximumZoom,
            ),
          )) {
        await _showPlacePicker(places, intent);
        return;
      }
      final expansionZoom = (values[0] as int).toDouble();
      final minimumZoom = max(
        _currentZoom,
        expansionZoom + 0.25,
      ).clamp(widget.region.minimumZoom, widget.region.maximumZoom).toDouble();
      final fit = RestaurantMapCamera.fit(
        places,
        size: context.size ?? MediaQuery.sizeOf(context),
        padding: EdgeInsets.fromLTRB(
          48,
          widget.padding.top + 36,
          48,
          widget.padding.bottom + 48,
        ),
        minimumZoom: minimumZoom,
        maximumZoom: widget.region.maximumZoom,
      );
      // Fit the actual leaves when they can all be shown individually. A wide
      // cluster may span more than one screen: use its native split zoom then.
      await _updateCamera(
        CameraUpdate.newLatLngZoom(fit.target, fit.zoom),
        intent,
      );
    } catch (error) {
      if (!current()) return;
      // A source may have been reclustered between the hit test and lookup.
      debugPrint('Unable to resolve restaurant map tap: $error');
      final restaurant = _visibleRestaurantMarkers[int.tryParse(featureId)];
      if (!RestaurantMarkerLayer.isCluster(layerId) && restaurant != null) {
        _setSelection(restaurant, notify: true);
      }
    }
  }

  List<RestaurantMapMarker> _placesFromFeatures(List features) {
    final places = <int, RestaurantMapMarker>{};
    for (final feature in features.whereType<Map>()) {
      final properties = feature['properties'];
      final id = properties is Map
          ? properties['restaurantId'] ?? feature['id']
          : feature['id'];
      final place =
          _visibleRestaurantMarkers[id is num
              ? id.toInt()
              : int.tryParse('$id')];
      if (place != null) places[place.id] = place;
    }
    return places.values.toList();
  }

  Future<void> _showPlacePicker(
    List<RestaurantMapMarker> places,
    int intent,
  ) async {
    if (!_isCurrentCameraIntent(intent) || _isPlacePickerOpen) return;
    _isPlacePickerOpen = true;
    final languageCode = Localizations.localeOf(context).languageCode;
    try {
      final selected = await showModalBottomSheet<RestaurantMapMarker>(
        context: context,
        showDragHandle: true,
        backgroundColor: AppColors.surface,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.6,
        ),
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  AppLocalizations.of(context).chooseRestaurant,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: places.length,
                  itemBuilder: (context, index) {
                    final place = places[index];
                    return ListTile(
                      key: ValueKey('map-place-choice-${place.id}'),
                      leading: Icon(
                        place.placeType == RestaurantMapPlaceType.cafe
                            ? Icons.local_cafe_rounded
                            : Icons.restaurant_rounded,
                        color: AppColors.primary,
                      ),
                      title: Text(place.localizedName(languageCode)),
                      subtitle:
                          place.localizedNeighborhood(languageCode).isEmpty
                          ? null
                          : Text(place.localizedNeighborhood(languageCode)),
                      onTap: () => Navigator.of(context).pop(place),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
      if (selected != null && _isCurrentCameraIntent(intent)) {
        _setSelection(selected, notify: true);
      }
    } finally {
      _isPlacePickerOpen = false;
    }
  }

  void _setSelection(RestaurantMapMarker? restaurant, {bool notify = false}) {
    if (!mounted) return;
    final revision = ++_selectionRevision;
    final intent = restaurant == null ? _cameraIntent : ++_cameraIntent;
    _needsSelectionFocus = restaurant != null && !_isMarkerLayerReady;
    setState(() => _selectedRestaurant = restaurant);
    if (notify) widget.onSelectedRestaurantChanged?.call(restaurant);
    final controller = _mapController;
    if (controller != null && _isMarkerLayerReady) {
      final languageCode = Localizations.localeOf(context).languageCode;
      unawaited(
        _writeLayers(() async {
          if (_mapController != controller || revision != _selectionRevision) {
            return;
          }
          await RestaurantMarkerLayer.updateSelected(
            controller,
            restaurant,
            languageCode,
          );
        }),
      );
      if (restaurant != null) {
        unawaited(
          _updateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(restaurant.latitude, restaurant.longitude),
              max(_currentZoom, RestaurantMarkerLayer.individualFocusZoom)
                  .clamp(widget.region.minimumZoom, widget.region.maximumZoom)
                  .toDouble(),
            ),
            intent,
          ),
        );
      }
    }
  }

  void _dismissRestaurantPreview() {
    if (_selectedRestaurant != null) {
      _cameraIntent++;
      _setSelection(null, notify: true);
    }
  }

  void _onMapTapped(Point<double> _, LatLng _) {
    _dismissAttributionNotice();
    _cameraIntent++;
    _dismissRestaurantPreview();
  }

  void _dismissAttributionNotice() {
    _attributionNoticeTimer?.cancel();
    if (mounted && _showAttributionNotice) {
      setState(() => _showAttributionNotice = false);
    }
  }

  void _openSelectedRestaurantDetails(RestaurantDetailsDto details) {
    if (_isOpeningRestaurantDetails || !mounted) {
      return;
    }

    _isOpeningRestaurantDetails = true;
    unawaited(
      Navigator.of(context)
          .pushNamed(
            AppRouteNames.restaurantDetailsFor(details.id),
            arguments: details,
          )
          .whenComplete(() => _isOpeningRestaurantDetails = false),
    );
  }

  Future<void> _moveToCurrentLocation() async {
    if (_isLocating || _mapController == null) {
      return;
    }

    setState(() => _isLocating = true);
    final intent = ++_cameraIntent;

    try {
      final coordinates = await widget.locationService.getCurrentCoordinates();
      if (!mounted || !_isCurrentCameraIntent(intent)) {
        return;
      }

      if (!widget.region.contains(
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
      )) {
        final localizations = AppLocalizations.of(context);
        final languageCode = Localizations.localeOf(context).languageCode;
        _showMapMessage(
          localizations.serviceAvailableInRegion(
            widget.region.localizedName(languageCode),
          ),
        );
        return;
      }

      // Use one absolute, non-animated update. On iOS, animateCamera uses a
      // fly-to transition that can be interrupted or advance only partway,
      // making repeated taps appear necessary after the map has been panned.
      await _updateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(coordinates.latitude, coordinates.longitude),
          widget.region.currentLocationZoom,
        ),
        intent,
        animate: false,
      );
    } on CurrentLocationException catch (error) {
      if (mounted) {
        _handleLocationFailure(error.failure);
      }
    } catch (_) {
      if (mounted) {
        _showMapMessage(AppLocalizations.of(context).locationUnavailable);
      }
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  void _handleLocationFailure(CurrentLocationFailure failure) {
    final localizations = AppLocalizations.of(context);

    switch (failure) {
      case CurrentLocationFailure.servicesDisabled:
        _showMapMessage(
          localizations.locationServicesDisabled,
          action: () {
            unawaited(widget.locationService.openLocationSettings());
          },
        );
      case CurrentLocationFailure.permissionDenied:
        _showMapMessage(localizations.locationPermissionDenied);
      case CurrentLocationFailure.permissionDeniedForever:
        _showMapMessage(
          localizations.locationPermissionPermanentlyDenied,
          action: () {
            unawaited(widget.locationService.openAppSettings());
          },
        );
      case CurrentLocationFailure.unavailable:
        _showMapMessage(localizations.locationUnavailable);
    }
  }

  void _showMapMessage(String message, {VoidCallback? action}) {
    final messenger = ScaffoldMessenger.of(context);
    final localizations = AppLocalizations.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, textAlign: TextAlign.start),
          action: action == null
              ? null
              : SnackBarAction(
                  label: localizations.settings,
                  onPressed: action,
                ),
        ),
      );
  }

  @override
  void dispose() {
    _markerDebounce?.cancel();
    _attributionNoticeTimer?.cancel();
    _markerRequestGeneration++;
    _mapController?.onFeatureTapped.remove(_onRestaurantMarkerTapped);
    if (_ownsRestaurantMapService) {
      _restaurantMapService.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeAreaTop = MediaQuery.paddingOf(context).top;
    final locationButtonTop = safeAreaTop + widget.padding.top + 8;
    final localizations = AppLocalizations.of(context);
    final regionBounds = widget.region.bounds;
    final previewBottom = max(widget.padding.bottom + 24, 72.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        FutureBuilder<String>(
          future: _mapStyle,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const ColoredBox(color: AppColors.background);
            }

            if (snapshot.hasError) {
              FlutterError.reportError(
                FlutterErrorDetails(
                  exception: snapshot.error!,
                  stack: snapshot.stackTrace,
                  library: 'Thuraya map style loader',
                  context: ErrorDescription(
                    'while preparing bundled Arabic map fonts',
                  ),
                ),
              );
            }

            return Listener(
              onPointerDown: _onMapPointerDown,
              onPointerSignal: (_) => _cameraIntent++,
              child: MapLibreMap(
                key: const ValueKey('home-map'),
                annotationOrder: const [],
                styleString: snapshot.data ?? ThurayaMap.customStyleAsset,
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    widget.region.centerLatitude,
                    widget.region.centerLongitude,
                  ),
                  zoom: widget.region.initialZoom,
                ),
                cameraTargetBounds: CameraTargetBounds(
                  LatLngBounds(
                    southwest: LatLng(
                      regionBounds.southwestLatitude,
                      regionBounds.southwestLongitude,
                    ),
                    northeast: LatLng(
                      regionBounds.northeastLatitude,
                      regionBounds.northeastLongitude,
                    ),
                  ),
                ),
                minMaxZoomPreference: MinMaxZoomPreference(
                  widget.region.minimumZoom,
                  widget.region.maximumZoom,
                ),
                onMapCreated: _onMapCreated,
                onStyleLoadedCallback: _onStyleLoaded,
                onCameraMove: _onCameraMove,
                onCameraIdle: _onCameraIdle,
                // Native platforms only emit camera positions when enabled.
                // Keep selection/cluster zoom based on the user's actual view.
                trackCameraPosition: true,
                onMapClick: _onMapTapped,
                featureTapsTriggersMapClick: false,
                scrollGesturesEnabled: true,
                zoomGesturesEnabled: true,
                doubleClickZoomEnabled: true,
                rotateGesturesEnabled: false,
                tiltGesturesEnabled: false,
                compassEnabled: false,
                // The custom Thuraya location button below owns this interaction.
                // Enabling MapLibre's native location UI creates a second
                // location control/indicator on iOS.
                myLocationEnabled: false,
                myLocationTrackingMode: MyLocationTrackingMode.none,
                logoEnabled: false,
                attributionButtonPosition: AttributionButtonPosition.bottomLeft,
                attributionButtonMargins: Point(8, widget.padding.bottom + 8),
                // MapLibre reads linked provider credits from the source TileJSON
                // and opens its built-in attribution UI when the (i) is tapped.
                attributionButtonColor: AppColors.primary,
              ),
            );
          },
        ),
        if (_showAttributionNotice)
          Positioned(
            // Leave room for the native button on either side in LTR and RTL.
            left: 44,
            right: 44,
            bottom: widget.padding.bottom + 8,
            child: IgnorePointer(
              child: Align(
                alignment: AlignmentDirectional.bottomStart,
                child: Material(
                  key: const ValueKey('map-attribution-notice'),
                  color: AppColors.surface.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      'OpenFreeMap · © OpenMapTiles\n© OpenStreetMap contributors',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          top: locationButtonTop,
          right: 20,
          child: Semantics(
            button: true,
            enabled: !_isLocating && _mapController != null,
            label: _isLocating
                ? localizations.locatingCurrentLocation
                : localizations.currentLocation,
            child: Tooltip(
              message: localizations.currentLocation,
              child: Material(
                key: const ValueKey('home-current-location'),
                color: AppColors.surface,
                elevation: 4,
                shadowColor: AppColors.shadow.withValues(alpha: 0.2),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _isLocating || _mapController == null
                      ? null
                      : _moveToCurrentLocation,
                  customBorder: const CircleBorder(),
                  child: SizedBox.square(
                    dimension: _locationButtonSize,
                    child: Center(
                      child: _isLocating
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : Icon(
                              Icons.my_location_rounded,
                              size: 21,
                              color: _mapController == null
                                  ? AppColors.textMuted
                                  : AppColors.primary,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        PositionedDirectional(
          start: 20,
          end: 20,
          bottom: previewBottom,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _selectedRestaurant == null
                ? const SizedBox.shrink(
                    key: ValueKey('restaurant-preview-empty'),
                  )
                : RestaurantMapPreview(
                    key: ValueKey(
                      'restaurant-preview-${_selectedRestaurant!.id}',
                    ),
                    restaurant: _selectedRestaurant!,
                    detailsService: widget.restaurantDetailsService,
                    onTap: _openSelectedRestaurantDetails,
                    onClose: _dismissRestaurantPreview,
                  ),
          ),
        ),
      ],
    );
  }
}
