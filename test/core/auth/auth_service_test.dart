import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:thuraya/core/auth/auth_service.dart';
import 'package:thuraya/core/network/api_client.dart';

void main() {
  test(
    'uses the backend phone login endpoint and parses its token pair',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      String? requestMethod;
      Uri? requestUri;
      Object? requestBody;
      server.listen((request) async {
        requestMethod = request.method;
        requestUri = request.uri;
        requestBody = jsonDecode(await utf8.decoder.bind(request).join());
        _writeAuthResponse(request.response);
      });

      final client = ApiClient(
        baseUrl: 'http://127.0.0.1:${server.port}',
        useAuthentication: false,
      );
      addTearDown(client.close);
      final service = AuthService(apiClient: client);

      final response = await service.loginWithPhone(' +966500000000 ');

      expect(requestMethod, 'POST');
      expect(requestUri?.path, '/api/auth/login-phone');
      expect(requestBody, {'phoneNumber': '+966500000000'});
      expect(response.isNewUser, isFalse);
      expect(response.user?.id, 7);
      expect(response.accessToken, 'access-token');
      expect(response.refreshToken, 'refresh-token');
    },
  );

  test('uses the backend refresh and logout endpoints', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final requests = <(String, String, Object?)>[];
    server.listen((request) async {
      final body = jsonDecode(await utf8.decoder.bind(request).join());
      requests.add((request.method, request.uri.path, body));
      if (request.uri.path.endsWith('/refresh')) {
        _writeAuthResponse(request.response);
      } else {
        request.response
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'success': true,
              'message': 'Logged out successfully.',
              'data': <String, dynamic>{},
              'errors': <String>[],
              'statusCode': 200,
            }),
          );
        await request.response.close();
      }
    });

    final client = ApiClient(
      baseUrl: 'http://127.0.0.1:${server.port}',
      useAuthentication: false,
    );
    addTearDown(client.close);
    final service = AuthService(apiClient: client);

    await service.refresh('old-refresh-token');
    await service.logout('current-refresh-token');

    expect(requests, hasLength(2));
    expect(requests[0].$1, 'POST');
    expect(requests[0].$2, '/api/auth/refresh');
    expect(requests[0].$3, {'refreshToken': 'old-refresh-token'});
    expect(requests[1].$1, 'POST');
    expect(requests[1].$2, '/api/auth/logout');
    expect(requests[1].$3, {'refreshToken': 'current-refresh-token'});
  });
}

void _writeAuthResponse(HttpResponse response) {
  response
    ..statusCode = HttpStatus.ok
    ..headers.contentType = ContentType.json
    ..write(
      jsonEncode({
        'success': true,
        'message': 'Logged in successfully.',
        'data': {
          'isNewUser': false,
          'user': {
            'id': 7,
            'name': 'Thuraya User',
            'email': 'user@example.com',
            'phoneNumber': '+966500000000',
            'role': 'User',
          },
          'accessToken': 'access-token',
          'refreshToken': 'refresh-token',
          'accessTokenExpiresAtUtc': '2026-09-08T12:15:00Z',
          'refreshTokenExpiresAtUtc': '2026-10-08T12:00:00Z',
        },
        'errors': <String>[],
        'statusCode': 200,
      }),
    );
  response.close();
}
