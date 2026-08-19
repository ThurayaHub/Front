import 'dart:async';

import 'package:geolocator/geolocator.dart';

enum CurrentLocationFailure {
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
}

class CurrentLocationException implements Exception {
  const CurrentLocationException(this.failure);

  final CurrentLocationFailure failure;
}

class CurrentCoordinates {
  const CurrentCoordinates({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class CurrentLocationService {
  const CurrentLocationService();

  Future<CurrentCoordinates> getCurrentCoordinates() async {
    try {
      final servicesEnabled = await Geolocator.isLocationServiceEnabled();
      if (!servicesEnabled) {
        throw const CurrentLocationException(
          CurrentLocationFailure.servicesDisabled,
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        throw const CurrentLocationException(
          CurrentLocationFailure.permissionDeniedForever,
        );
      }
      if (permission == LocationPermission.denied) {
        throw const CurrentLocationException(
          CurrentLocationFailure.permissionDenied,
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      return CurrentCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on CurrentLocationException {
      rethrow;
    } on LocationServiceDisabledException {
      throw const CurrentLocationException(
        CurrentLocationFailure.servicesDisabled,
      );
    } on PermissionDeniedException {
      throw const CurrentLocationException(
        CurrentLocationFailure.permissionDenied,
      );
    } on TimeoutException {
      throw const CurrentLocationException(CurrentLocationFailure.unavailable);
    } catch (_) {
      throw const CurrentLocationException(CurrentLocationFailure.unavailable);
    }
  }

  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
