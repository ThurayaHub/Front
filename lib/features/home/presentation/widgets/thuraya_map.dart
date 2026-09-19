import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:thuraya/core/routing/app_route_names.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/features/home/models/restaurant_map_marker.dart';
import 'package:thuraya/features/home/models/restaurant_search_filters.dart';
import 'package:thuraya/features/home/models/supported_map_region.dart';
import 'package:thuraya/features/home/presentation/widgets/restaurant_map_preview.dart';
import 'package:thuraya/features/home/presentation/widgets/restaurant_marker_layer.dart';
import 'package:thuraya/features/home/services/current_location_service.dart';
import 'package:thuraya/features/home/services/restaurant_map_service.dart';
import 'package:thuraya/features/home/services/thuraya_map_style_loader.dart';
import 'package:thuraya/features/restaurant_details/models/restaurant_details_dto.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

class ThurayaMap extends StatefulWidget {
  const ThurayaMap({
    super.key,
    this.region = SupportedMapRegions.riyadh,
    this.padding = EdgeInsets.zero,
    this.onMapCreated,
    this.locationService = const CurrentLocationService(),
    this.restaurantMapService,
    this.restaurants,
    this.onViewportChanged,
    this.fitRestaurants = false,
  });

  static const String customStyleAsset = 'assets/map/thuraya_map_style.json';

  final SupportedMapRegion region;
  final EdgeInsets padding;
  final MapCreatedCallback? onMapCreated;
  final CurrentLocationService locationService;
  final RestaurantMapService? restaurantMapService;
  final List<RestaurantMapMarker>? restaurants;
  final Future<void> Function(SupportedMapBounds bounds)? onViewportChanged;
  final bool fitRestaurants;

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
  Timer? _clusterLabelDebounce;
  Map<int, RestaurantMapMarker> _visibleRestaurantMarkers = const {};
  List<_ClusterLabel> _clusterLabels = const [];
  RestaurantMapMarker? _selectedRestaurant;
  DateTime? _lastRestaurantMarkerTap;
  late double _currentZoom;
  int _markerRequestGeneration = 0;
  int _clusterLabelGeneration = 0;
  bool _isStyleLoaded = false;
  bool _isMarkerLayerReady = false;
  bool _hasShownMarkerError = false;
  bool _isOpeningRestaurantDetails = false;
  bool _isLocating = false;
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
  }

  @override
  void didUpdateWidget(covariant ThurayaMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((!identical(oldWidget.restaurants, widget.restaurants) ||
            oldWidget.fitRestaurants != widget.fitRestaurants) &&
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
          fitCamera: widget.fitRestaurants,
        ),
      );
    }
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
    _clusterLabelGeneration++;
    _clusterLabelDebounce?.cancel();
    if (_visibleRestaurantMarkers.isNotEmpty || _selectedRestaurant != null) {
      setState(() {
        _visibleRestaurantMarkers = const {};
        _clusterLabels = const [];
        _selectedRestaurant = null;
      });
    }
    unawaited(_initializeRestaurantMarkerLayer(controller));
  }

  Future<void> _initializeRestaurantMarkerLayer(
    MapLibreMapController controller,
  ) async {
    try {
      await RestaurantMarkerLayer.install(controller);
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
          fitCamera: widget.fitRestaurants,
        );
        if (widget.onViewportChanged != null) {
          _scheduleMarkerRefresh(immediate: true);
        }
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
    _clusterLabelGeneration++;
    _clusterLabelDebounce?.cancel();
    if (_clusterLabels.isNotEmpty && mounted) {
      setState(() => _clusterLabels = const []);
    }
    if (widget.restaurants != null && widget.onViewportChanged == null) return;
    _markerDebounce?.cancel();
    _markerRequestGeneration++;
  }

  void _onCameraIdle() {
    if (widget.restaurants == null || widget.onViewportChanged != null) {
      _scheduleMarkerRefresh();
    } else {
      _scheduleClusterLabelRefresh();
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
    await RestaurantMarkerLayer.update(
      controller,
      markers,
      Localizations.localeOf(context).languageCode,
    );

    if (!mounted || requestGeneration != _markerRequestGeneration) {
      return;
    }

    final markersById = {for (final marker in markers) marker.id: marker};
    final selectedRestaurantId = _selectedRestaurant?.id;
    final selectedRestaurant = selectedRestaurantId == null
        ? null
        : markersById[selectedRestaurantId];
    setState(() {
      _visibleRestaurantMarkers = markersById;
      _selectedRestaurant = selectedRestaurant;
    });
    await RestaurantMarkerLayer.updateSelected(
      controller,
      selectedRestaurant,
      Localizations.localeOf(context).languageCode,
    );
    _scheduleClusterLabelRefresh(delay: const Duration(milliseconds: 850));
  }

  void _scheduleClusterLabelRefresh({
    Duration delay = const Duration(milliseconds: 180),
  }) {
    if (!_isStyleLoaded || !_isMarkerLayerReady || _mapController == null) {
      return;
    }
    _clusterLabelDebounce?.cancel();
    final generation = ++_clusterLabelGeneration;
    _clusterLabelDebounce = Timer(
      delay,
      () => _refreshClusterLabels(generation: generation),
    );
  }

  Future<void> _refreshClusterLabels({
    required int generation,
    bool allowRetry = true,
  }) async {
    final controller = _mapController;
    if (!mounted ||
        controller == null ||
        !_isMarkerLayerReady ||
        generation != _clusterLabelGeneration) {
      return;
    }

    try {
      final mediaQuery = MediaQuery.of(context);
      final size = mediaQuery.size;
      final pixelRatio = mediaQuery.devicePixelRatio;
      final features = await controller.querySourceFeatures(
        RestaurantMarkerLayer.sourceId,
        null,
        const ['has', 'point_count'],
      );
      if (features.isEmpty &&
          allowRetry &&
          _visibleRestaurantMarkers.length > 1 &&
          _currentZoom <= RestaurantMarkerLayer.clusterMaxZoom) {
        _clusterLabelDebounce = Timer(
          const Duration(milliseconds: 650),
          () =>
              _refreshClusterLabels(generation: generation, allowRetry: false),
        );
        return;
      }
      final clusters = <({int count, LatLng coordinates})>[];
      for (final rawFeature in features) {
        if (rawFeature is! Map) continue;
        final feature = Map<String, dynamic>.from(rawFeature);
        final rawProperties = feature['properties'];
        final rawGeometry = feature['geometry'];
        if (rawProperties is! Map || rawGeometry is! Map) continue;
        final properties = Map<String, dynamic>.from(rawProperties);
        final geometry = Map<String, dynamic>.from(rawGeometry);
        final countValue = properties['point_count'];
        final coordinateValues = geometry['coordinates'];
        if (countValue is! num ||
            coordinateValues is! List ||
            coordinateValues.length < 2 ||
            coordinateValues[0] is! num ||
            coordinateValues[1] is! num) {
          continue;
        }
        clusters.add((
          count: countValue.toInt(),
          coordinates: LatLng(
            (coordinateValues[1] as num).toDouble(),
            (coordinateValues[0] as num).toDouble(),
          ),
        ));
      }
      final points = await controller.toScreenLocationBatch(
        clusters.map((cluster) => cluster.coordinates),
      );
      if (!mounted ||
          controller != _mapController ||
          generation != _clusterLabelGeneration) {
        return;
      }

      final labels = <_ClusterLabel>[];
      for (var index = 0; index < clusters.length; index++) {
        final point = points[index];
        final logicalPoint = Offset(point.x / pixelRatio, point.y / pixelRatio);
        if (logicalPoint.dx < 0 ||
            logicalPoint.dy < 0 ||
            logicalPoint.dx > size.width ||
            logicalPoint.dy > size.height) {
          continue;
        }
        labels.add(
          _ClusterLabel(count: clusters[index].count, position: logicalPoint),
        );
      }
      setState(() => _clusterLabels = labels);
    } catch (_) {
      // Native circles still communicate density if a transient query races a
      // style reload. The next idle frame will retry the count overlay.
    }
  }

  Future<void> _showControlledRestaurants({
    required MapLibreMapController controller,
    required List<RestaurantMapMarker> markers,
    required int requestGeneration,
    required bool fitCamera,
  }) async {
    await _replaceRestaurantMarkers(
      controller: controller,
      markers: markers,
      requestGeneration: requestGeneration,
    );
    if (!fitCamera ||
        markers.isEmpty ||
        !mounted ||
        requestGeneration != _markerRequestGeneration) {
      return;
    }

    if (markers.length == 1) {
      final restaurant = markers.single;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(restaurant.latitude, restaurant.longitude),
          14.5,
        ),
        duration: const Duration(milliseconds: 650),
      );
      return;
    }

    var south = markers.first.latitude;
    var north = markers.first.latitude;
    var west = markers.first.longitude;
    var east = markers.first.longitude;
    for (final restaurant in markers.skip(1)) {
      south = min(south, restaurant.latitude);
      north = max(north, restaurant.latitude);
      west = min(west, restaurant.longitude);
      east = max(east, restaurant.longitude);
    }
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(south, west),
          northeast: LatLng(north, east),
        ),
        left: 48,
        top: widget.padding.top + 36,
        right: 48,
        bottom: widget.padding.bottom + 48,
      ),
      duration: const Duration(milliseconds: 650),
    );
  }

  void _onRestaurantMarkerTapped(
    Point<double> _,
    LatLng coordinates,
    String featureId,
    String layerId,
    Annotation? _,
  ) {
    if (!RestaurantMarkerLayer.contains(layerId)) {
      return;
    }
    if (RestaurantMarkerLayer.isCluster(layerId)) {
      _lastRestaurantMarkerTap = DateTime.now();
      _dismissRestaurantPreview();
      unawaited(_zoomIntoCluster(coordinates));
      return;
    }
    final restaurantId = int.tryParse(featureId);
    _selectRestaurant(restaurantId);
  }

  Future<void> _zoomIntoCluster(LatLng coordinates) async {
    final controller = _mapController;
    if (controller == null) return;

    final nextZoom = min(
      max(_currentZoom + 2, 12.5),
      RestaurantMarkerLayer.individualFocusZoom,
    );
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(coordinates, nextZoom),
      duration: const Duration(milliseconds: 500),
    );
  }

  void _selectRestaurant(int? restaurantId) {
    final restaurant = restaurantId == null
        ? null
        : _visibleRestaurantMarkers[restaurantId];
    if (restaurant == null || !mounted) {
      return;
    }

    _lastRestaurantMarkerTap = DateTime.now();
    setState(() => _selectedRestaurant = restaurant);
    final controller = _mapController;
    if (controller != null && _isMarkerLayerReady) {
      unawaited(
        RestaurantMarkerLayer.updateSelected(
          controller,
          restaurant,
          Localizations.localeOf(context).languageCode,
        ),
      );
    }
  }

  void _dismissRestaurantPreview() {
    if (_selectedRestaurant != null) {
      setState(() => _selectedRestaurant = null);
      final controller = _mapController;
      if (controller != null && _isMarkerLayerReady) {
        unawaited(
          RestaurantMarkerLayer.updateSelected(
            controller,
            null,
            Localizations.localeOf(context).languageCode,
          ),
        );
      }
    }
  }

  void _onMapTapped(Point<double> _, LatLng _) {
    final markerTap = _lastRestaurantMarkerTap;
    if (markerTap != null &&
        DateTime.now().difference(markerTap) <
            const Duration(milliseconds: 250)) {
      return;
    }
    _dismissRestaurantPreview();
  }

  void _openSelectedRestaurantDetails(RestaurantDetailsDto details) {
    if (_isOpeningRestaurantDetails || !mounted) {
      return;
    }

    _isOpeningRestaurantDetails = true;
    unawaited(
      Navigator.of(context)
          .pushNamed(AppRouteNames.restaurantDetails, arguments: details)
          .whenComplete(() => _isOpeningRestaurantDetails = false),
    );
  }

  Future<void> _moveToCurrentLocation() async {
    if (_isLocating || _mapController == null) {
      return;
    }

    setState(() => _isLocating = true);

    try {
      final coordinates = await widget.locationService.getCurrentCoordinates();
      if (!mounted) {
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
      await _mapController?.moveCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(coordinates.latitude, coordinates.longitude),
          widget.region.currentLocationZoom,
        ),
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
    _clusterLabelDebounce?.cancel();
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

            return MapLibreMap(
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
              onMapClick: _onMapTapped,
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
            );
          },
        ),
        IgnorePointer(
          child: Stack(
            children: [
              for (final cluster in _clusterLabels)
                Positioned(
                  left: cluster.position.dx - 22,
                  top: cluster.position.dy - 22,
                  child: SizedBox.square(
                    dimension: 44,
                    child: Center(
                      child: Text(
                        cluster.count.toString(),
                        maxLines: 1,
                        style: const TextStyle(
                          color: AppColors.onPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          height: 1,
                          shadows: [
                            Shadow(color: Color(0x33000666), blurRadius: 1),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
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
                    onTap: _openSelectedRestaurantDetails,
                    onClose: _dismissRestaurantPreview,
                  ),
          ),
        ),
      ],
    );
  }
}

class _ClusterLabel {
  const _ClusterLabel({required this.count, required this.position});

  final int count;
  final Offset position;
}
