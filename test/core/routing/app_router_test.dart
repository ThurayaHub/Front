import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thuraya/core/routing/app_route_names.dart';
import 'package:thuraya/core/routing/app_router.dart';

void main() {
  test('restaurant details URL keeps a restart-safe restaurant ID', () {
    final route = AppRouter.onGenerateRoute(
      const RouteSettings(name: AppRouteNames.restaurantDetails, arguments: 42),
    );

    expect(route.settings.name, '/restaurant-details?id=42');
    expect(route.settings.arguments, 42);
  });

  test('restaurant details route restores its ID from the browser URL', () {
    final route = AppRouter.onGenerateRoute(
      const RouteSettings(name: '/restaurant-details?id=42'),
    );

    expect(route.settings.name, '/restaurant-details?id=42');
    expect(route.settings.arguments, 42);
  });

  test('legacy argument-less restaurant URL safely returns home', () {
    final route = AppRouter.onGenerateRoute(
      const RouteSettings(name: AppRouteNames.restaurantDetails),
    );

    expect(route.settings.name, AppRouteNames.home);
  });
}
