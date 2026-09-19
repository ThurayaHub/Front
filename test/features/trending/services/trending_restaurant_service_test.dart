import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:thuraya/core/network/api_client.dart';
import 'package:thuraya/features/trending/services/trending_restaurant_service.dart';

void main() {
  test('loads the backend trending DTO without recalculating ranks', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    String? requestedMethod;
    Uri? requestedUri;

    server.listen((request) async {
      requestedMethod = request.method;
      requestedUri = request.uri;
      request.response
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'success': true,
            'message': 'Trending restaurants retrieved successfully.',
            'data': [
              {
                'id': 42,
                'name': 'Riyadh Table',
                'description': 'A modern Saudi restaurant.',
                'address': 'Al Olaya, Riyadh',
                'latitude': 24.7136,
                'longitude': 46.6753,
                'priceLevelId': 2,
                'neighborhoodId': 31,
                'trendRank': 7,
                'hasThurayaStar': true,
                'coverPhotoUrl': '/uploads/restaurants/42/cover.jpg',
                'categoryIds': [5, 9],
              },
            ],
            'errors': <String>[],
            'statusCode': 200,
          }),
        );
      await request.response.close();
    });

    final apiClient = ApiClient(baseUrl: 'http://127.0.0.1:${server.port}');
    addTearDown(apiClient.close);
    final service = TrendingRestaurantService(apiClient: apiClient);

    final restaurants = await service.getTrending();

    expect(requestedMethod, 'GET');
    expect(requestedUri?.path, '/api/restaurants/trending');
    expect(restaurants, hasLength(1));
    final restaurant = restaurants.single;
    expect(restaurant.id, 42);
    expect(restaurant.name, 'Riyadh Table');
    expect(restaurant.trendRank, 7);
    expect(restaurant.hasThurayaStar, isTrue);
    expect(restaurant.priceLevelId, 2);
    expect(restaurant.neighborhoodId, 31);
    expect(restaurant.categoryIds, [5, 9]);
    expect(restaurant.coverPhotoUrl, '/uploads/restaurants/42/cover.jpg');
  });

  test('rejects a malformed trending response', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));

    server.listen((request) async {
      request.response
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'success': true,
            'message': 'OK',
            'data': {'items': <Object>[]},
            'errors': <String>[],
            'statusCode': 200,
          }),
        );
      await request.response.close();
    });

    final apiClient = ApiClient(baseUrl: 'http://127.0.0.1:${server.port}');
    addTearDown(apiClient.close);
    final service = TrendingRestaurantService(apiClient: apiClient);

    expect(service.getTrending(), throwsA(isA<ApiException>()));
  });
}
