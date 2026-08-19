import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:thuraya/features/home/services/current_location_service.dart';

void main() {
  late GeolocatorPlatform originalPlatform;
  late _FakeGeolocatorPlatform fakePlatform;
  const service = CurrentLocationService();

  setUp(() {
    originalPlatform = GeolocatorPlatform.instance;
    fakePlatform = _FakeGeolocatorPlatform();
    GeolocatorPlatform.instance = fakePlatform;
  });

  tearDown(() {
    GeolocatorPlatform.instance = originalPlatform;
  });

  test(
    'returns one current position when foreground access is granted',
    () async {
      fakePlatform.permission = LocationPermission.whileInUse;

      final coordinates = await service.getCurrentCoordinates();

      expect(coordinates.latitude, 24.7136);
      expect(coordinates.longitude, 46.6753);
      expect(fakePlatform.locationRequests, 1);
      expect(fakePlatform.requestedPermission, isFalse);
      expect(fakePlatform.lastSettings?.accuracy, LocationAccuracy.high);
      expect(fakePlatform.lastSettings?.timeLimit, const Duration(seconds: 15));
    },
  );

  test('requests permission once when it has not been granted yet', () async {
    fakePlatform.permission = LocationPermission.denied;
    fakePlatform.requestedPermissionResult = LocationPermission.whileInUse;

    await service.getCurrentCoordinates();

    expect(fakePlatform.requestedPermission, isTrue);
    expect(fakePlatform.locationRequests, 1);
  });

  test(
    'reports disabled location services before requesting permission',
    () async {
      fakePlatform.servicesEnabled = false;

      await expectLater(
        service.getCurrentCoordinates(),
        throwsA(_failure(CurrentLocationFailure.servicesDisabled)),
      );
      expect(fakePlatform.requestedPermission, isFalse);
      expect(fakePlatform.locationRequests, 0);
    },
  );

  test('reports denied permission without requesting a position', () async {
    fakePlatform.permission = LocationPermission.denied;
    fakePlatform.requestedPermissionResult = LocationPermission.denied;

    await expectLater(
      service.getCurrentCoordinates(),
      throwsA(_failure(CurrentLocationFailure.permissionDenied)),
    );
    expect(fakePlatform.locationRequests, 0);
  });

  test('reports permanently denied permission', () async {
    fakePlatform.permission = LocationPermission.deniedForever;

    await expectLater(
      service.getCurrentCoordinates(),
      throwsA(_failure(CurrentLocationFailure.permissionDeniedForever)),
    );
    expect(fakePlatform.locationRequests, 0);
  });

  test('maps a position lookup error to unavailable', () async {
    fakePlatform.permission = LocationPermission.whileInUse;
    fakePlatform.positionError = StateError('GPS fix unavailable');

    await expectLater(
      service.getCurrentCoordinates(),
      throwsA(_failure(CurrentLocationFailure.unavailable)),
    );
  });
}

Matcher _failure(CurrentLocationFailure failure) {
  return isA<CurrentLocationException>().having(
    (error) => error.failure,
    'failure',
    failure,
  );
}

class _FakeGeolocatorPlatform extends GeolocatorPlatform {
  bool servicesEnabled = true;
  LocationPermission permission = LocationPermission.denied;
  LocationPermission requestedPermissionResult = LocationPermission.denied;
  bool requestedPermission = false;
  int locationRequests = 0;
  Object? positionError;
  LocationSettings? lastSettings;

  @override
  Future<bool> isLocationServiceEnabled() async => servicesEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async {
    requestedPermission = true;
    return requestedPermissionResult;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    locationRequests++;
    lastSettings = locationSettings;
    if (positionError case final error?) {
      throw error;
    }

    return Position(
      longitude: 46.6753,
      latitude: 24.7136,
      timestamp: DateTime(2026),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}
