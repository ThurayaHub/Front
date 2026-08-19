import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:thuraya/core/routing/app_route_names.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/features/home/models/restaurant_map_bounds.dart';
import 'package:thuraya/features/home/models/restaurant_map_marker.dart';
import 'package:thuraya/features/home/models/supported_map_region.dart';
import 'package:thuraya/features/home/presentation/widgets/restaurant_marker_layer.dart';
import 'package:thuraya/features/home/presentation/widgets/restaurant_preview_card.dart';
import 'package:thuraya/features/home/services/current_location_service.dart';
import 'package:thuraya/features/home/services/restaurant_map_service.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

class ThurayaMap extends StatefulWidget {
  const ThurayaMap({
    super.key,
    this.region = SupportedMapRegions.riyadh,
    this.padding = EdgeInsets.zero,
    this.onMapCreated,
    this.locationService = const CurrentLocationService(),
    this.restaurantMapService,
  });

  static const String openFreeMapLibertyStyle =
      'https://tiles.openfreemap.org/styles/liberty';

  final SupportedMapRegion region;
  final EdgeInsets padding;
  final MapCreatedCallback? onMapCreated;
  final CurrentLocationService locationService;
  final RestaurantMapService? restaurantMapService;

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
  List<Symbol> _restaurantSymbols = const [];
  Map<int, RestaurantMapMarker> _visibleRestaurantMarkers = const {};
  RestaurantMapMarker? _selectedRestaurant;
  DateTime? _lastRestaurantMarkerTap;
  int _markerRequestGeneration = 0;
  bool _isStyleLoaded = false;
  bool _isMarkerLayerReady = false;
  bool _hasShownMarkerError = false;
  bool _isOpeningRestaurantDetails = false;
  bool _isLocating = false;
  bool _showCurrentLocation = false;

  @override
  void initState() {
    super.initState();
    _ownsRestaurantMapService = widget.restaurantMapService == null;
    _restaurantMapService =
        widget.restaurantMapService ?? RestaurantMapService();
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController?.onFeatureTapped.remove(_onRestaurantMarkerTapped);
    _mapController?.onSymbolTapped.remove(_onRestaurantSymbolTapped);
    _mapController = controller;
    controller.onFeatureTapped.add(_onRestaurantMarkerTapped);
    controller.onSymbolTapped.add(_onRestaurantSymbolTapped);
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
    _restaurantSymbols = const [];
    if (_visibleRestaurantMarkers.isNotEmpty || _selectedRestaurant != null) {
      setState(() {
        _visibleRestaurantMarkers = const {};
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
      await controller.setSymbolIconAllowOverlap(true);
      if (!mounted || _mapController != controller || !_isStyleLoaded) {
        return;
      }
      _isMarkerLayerReady = true;
      _scheduleMarkerRefresh(immediate: true);
    } catch (_) {
      if (mounted && _mapController == controller) {
        _showMapMessage(
          AppLocalizations.of(context).restaurantMarkersUnavailable,
        );
      }
    }
  }

  void _onCameraMove(CameraPosition _) {
    _markerDebounce?.cancel();
    _markerRequestGeneration++;
  }

  void _onCameraIdle() {
    _scheduleMarkerRefresh();
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

      final markers = await _restaurantMapService.getMarkers(
        RestaurantMapBounds(
          north: supportedViewport.northeastLatitude,
          south: supportedViewport.southwestLatitude,
          east: supportedViewport.northeastLongitude,
          west: supportedViewport.southwestLongitude,
        ),
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

    final newSymbols = markers.isEmpty
        ? <Symbol>[]
        : await controller.addSymbols(
            [
              for (final marker in markers)
                SymbolOptions(
                  geometry: LatLng(marker.latitude, marker.longitude),
                  iconImage: RestaurantMarkerLayer.iconIdFor(marker.placeType),
                  iconSize: 0.74,
                  iconAnchor: 'center',
                ),
            ],
            [
              for (final marker in markers)
                <String, dynamic>{'restaurantId': marker.id},
            ],
          );

    if (!mounted || requestGeneration != _markerRequestGeneration) {
      if (newSymbols.isNotEmpty) {
        try {
          await controller.removeSymbols(newSymbols);
        } catch (_) {
          // A style reload may already have removed stale marker symbols.
        }
      }
      return;
    }

    final oldSymbols = _restaurantSymbols;
    _restaurantSymbols = newSymbols;
    final markersById = {for (final marker in markers) marker.id: marker};
    final selectedRestaurantId = _selectedRestaurant?.id;
    setState(() {
      _visibleRestaurantMarkers = markersById;
      _selectedRestaurant = selectedRestaurantId == null
          ? null
          : markersById[selectedRestaurantId];
    });
    if (oldSymbols.isNotEmpty) {
      try {
        await controller.removeSymbols(oldSymbols);
      } catch (_) {
        // Keep the successful update if stale symbols disappeared already.
      }
    }
  }

  void _onRestaurantMarkerTapped(
    Point<double> _,
    LatLng _,
    String featureId,
    String layerId,
    Annotation? _,
  ) {
    if (!RestaurantMarkerLayer.contains(layerId)) {
      return;
    }
    final restaurantId = int.tryParse(featureId);
    _selectRestaurant(restaurantId);
  }

  void _onRestaurantSymbolTapped(Symbol symbol) {
    final restaurantIdValue = symbol.data?['restaurantId'];
    final restaurantId = restaurantIdValue is num
        ? restaurantIdValue.toInt()
        : null;
    _selectRestaurant(restaurantId);
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
  }

  void _dismissRestaurantPreview() {
    if (_selectedRestaurant != null) {
      setState(() => _selectedRestaurant = null);
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

  void _openSelectedRestaurantDetails() {
    final restaurantId = _selectedRestaurant?.id;
    if (restaurantId == null || _isOpeningRestaurantDetails || !mounted) {
      return;
    }

    _isOpeningRestaurantDetails = true;
    unawaited(
      Navigator.of(context)
          .pushNamed(AppRouteNames.restaurantDetails, arguments: restaurantId)
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

      setState(() => _showCurrentLocation = true);
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(coordinates.latitude, coordinates.longitude),
          widget.region.currentLocationZoom,
        ),
        duration: const Duration(milliseconds: 900),
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
    _markerRequestGeneration++;
    _mapController?.onFeatureTapped.remove(_onRestaurantMarkerTapped);
    _mapController?.onSymbolTapped.remove(_onRestaurantSymbolTapped);
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
        MapLibreMap(
          key: const ValueKey('home-map'),
          styleString: ThurayaMap.openFreeMapLibertyStyle,
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
          myLocationEnabled: _showCurrentLocation,
          myLocationTrackingMode: MyLocationTrackingMode.none,
          logoEnabled: false,
          attributionButtonPosition: AttributionButtonPosition.bottomLeft,
          attributionButtonMargins: Point(8, widget.padding.bottom + 8),
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
                : RestaurantPreviewCard(
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
