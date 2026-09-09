import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:thuraya/core/network/api_client.dart';
import 'package:thuraya/features/account/services/profile_service.dart';

void main() {
  test(
    'uses the four existing profile endpoints and parses their DTOs',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final paths = <String>[];

      server.listen((request) async {
        paths.add(request.uri.path);
        final data = switch (request.uri.path) {
          '/api/profile' => {
            'userId': 7,
            'name': 'سارة',
            'phoneNumber': '+966500000000',
            'email': 'sara@example.com',
            'isEmailVerified': true,
            'reviewCount': 1,
          },
          '/api/profile/details' => {
            'userId': 7,
            'name': 'سارة',
            'phoneNumber': '+966500000000',
            'email': 'sara@example.com',
            'isEmailVerified': true,
            'createdAtUtc': '2024-03-02T00:00:00Z',
            'emailVerifiedAtUtc': '2024-03-03T00:00:00Z',
          },
          '/api/profile/favorites' => [
            {
              'restaurantId': 42,
              'nameEn': 'Riyadh Table',
              'nameAr': 'مائدة الرياض',
              'mainPhotoUrl': '/images/table.jpg',
              'userRatingAverage': 4.0,
              'priceLevelId': 2,
              'priceLevelName': 'Medium',
              'neighborhoodId': 3,
              'neighborhoodNameAr': 'العليا',
              'neighborhoodNameEn': 'Olaya',
              'hasThurayaStar': true,
            },
          ],
          '/api/profile/reviews' => [
            {
              'reviewId': 11,
              'restaurantId': 42,
              'restaurantNameEn': 'Riyadh Table',
              'restaurantNameAr': 'مائدة الرياض',
              'restaurantMainPhotoUrl': '/images/table.jpg',
              'rating': 5,
              'comment': 'رائع',
              'createdAtUtc': '2026-09-01T00:00:00Z',
              'updatedAtUtc': null,
            },
          ],
          _ => null,
        };
        request.response
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'success': true,
              'message': null,
              'data': data,
              'errors': <String>[],
              'statusCode': 200,
            }),
          );
        await request.response.close();
      });

      final client = ApiClient(
        baseUrl: 'http://127.0.0.1:${server.port}',
        useAuthentication: false,
      );
      addTearDown(client.close);
      final service = ProfileService(apiClient: client);

      final summary = await service.getSummary();
      final details = await service.getDetails();
      final favorites = await service.getFavorites();
      final reviews = await service.getReviews();

      expect(paths, [
        '/api/profile',
        '/api/profile/details',
        '/api/profile/favorites',
        '/api/profile/reviews',
      ]);
      expect(summary.name, 'سارة');
      expect(details.createdAtUtc.year, 2024);
      expect(favorites.single.arabicName, 'مائدة الرياض');
      expect(reviews.single.rating, 5);
    },
  );
}
