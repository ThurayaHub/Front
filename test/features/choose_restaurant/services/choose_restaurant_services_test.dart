import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:thuraya/core/network/api_client.dart';
import 'package:thuraya/features/choose_restaurant/models/choose_restaurant_dto.dart';
import 'package:thuraya/features/choose_restaurant/services/choose_restaurant_service.dart';
import 'package:thuraya/features/choose_restaurant/services/restaurant_lookup_service.dart';

void main() {
  test(
    'loads all restaurant choices from the existing lookup routes',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final paths = <String>[];

      server.listen((request) async {
        paths.add(request.uri.path);
        final data = switch (request.uri.path) {
          '/api/lookups/price-levels' => [
            {'id': 7, 'name': 'Medium', 'description': 'Mid-priced'},
          ],
          '/api/lookups/restaurant-categories' => [
            {'id': 19, 'name': 'Japanese', 'description': null},
          ],
          '/api/lookups/neighborhoods' => [
            {
              'id': 31,
              'nameAr': 'العليا',
              'nameEn': 'Al Olaya',
              'cityAr': 'الرياض',
              'cityEn': 'Riyadh',
              'countryCode': 'SA',
            },
          ],
          _ => <Object>[],
        };
        request.response
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(_success(data)));
        await request.response.close();
      });

      final apiClient = ApiClient(baseUrl: 'http://127.0.0.1:${server.port}');
      addTearDown(apiClient.close);
      final service = RestaurantLookupService(apiClient: apiClient);

      final values = await Future.wait([
        service.getPriceLevels(),
        service.getCategories(),
      ]);
      final neighborhoods = await service.getNeighborhoods();

      expect(
        paths.take(2),
        unorderedEquals([
          '/api/lookups/price-levels',
          '/api/lookups/restaurant-categories',
        ]),
      );
      expect(paths.last, '/api/lookups/neighborhoods');
      expect(values[0].single.id, 7);
      expect(values[1].single.id, 19);
      expect(neighborhoods.single.nameAr, 'العليا');
    },
  );

  test('posts the real selected IDs to the existing choose route', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    String? method;
    Uri? uri;
    Object? body;

    server.listen((request) async {
      method = request.method;
      uri = request.uri;
      body = jsonDecode(await utf8.decoder.bind(request).join());
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(_success(_recommendationData)));
      await request.response.close();
    });

    final apiClient = ApiClient(baseUrl: 'http://127.0.0.1:${server.port}');
    addTearDown(apiClient.close);
    final service = ChooseRestaurantService(apiClient: apiClient);
    final result = await service.choose(
      const ChooseRestaurantRequest(
        priceLevelIds: [7, 8],
        categoryIds: [19],
        neighborhoodIds: [31, 44],
      ),
    );

    expect(method, 'POST');
    expect(uri?.path, '/api/restaurants/choose');
    expect(body, {
      'priceLevelIds': [7, 8],
      'categoryIds': [19],
      'neighborhoodIds': [31, 44],
    });
    expect(result.id, 42);
    expect(result.nameArabic, 'مائدة الرياض');
    expect(result.categories.single.id, 19);
  });
}

Map<String, dynamic> _success(Object data) => {
  'success': true,
  'message': 'OK',
  'data': data,
  'errors': <String>[],
  'statusCode': 200,
};

final Map<String, dynamic> _recommendationData = {
  'id': 42,
  'name': 'Riyadh Table',
  'nameArabic': 'مائدة الرياض',
  'description': 'A modern restaurant.',
  'descriptionArabic': 'مطعم عصري.',
  'address': 'Riyadh',
  'latitude': 24.7136,
  'longitude': 46.6753,
  'googleMapsUrl': 'https://maps.example/42',
  'priceLevelId': 7,
  'priceLevelName': 'Medium',
  'neighborhoodId': 31,
  'neighborhoodNameAr': 'العليا',
  'neighborhoodNameEn': 'Al Olaya',
  'userRatingAverage': 4.5,
  'reviewCount': 8,
  'mainPhotoUrl': null,
  'hasThurayaStar': true,
  'categories': [
    {'id': 19, 'name': 'Japanese'},
  ],
};
