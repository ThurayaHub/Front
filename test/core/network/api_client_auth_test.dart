import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:thuraya/core/network/api_client.dart';

void main() {
  test('automatically sends the current Bearer token', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    String? authorizationHeader;
    server.listen((request) async {
      authorizationHeader = request.headers.value(
        HttpHeaders.authorizationHeader,
      );
      _writeSuccess(request.response);
    });

    final delegate = _FakeAuthorizationDelegate(accessToken: 'access-token');
    final client = ApiClient(
      baseUrl: 'http://127.0.0.1:${server.port}',
      authorizationDelegate: delegate,
    );
    addTearDown(client.close);

    await client.getResultData('/api/auth/me');

    expect(authorizationHeader, 'Bearer access-token');
  });

  test('refreshes once and retries a request after 401', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final authorizationHeaders = <String?>[];
    server.listen((request) async {
      final header = request.headers.value(HttpHeaders.authorizationHeader);
      authorizationHeaders.add(header);
      if (header == 'Bearer refreshed-token') {
        _writeSuccess(request.response);
      } else {
        _writeUnauthorized(request.response);
      }
    });

    final delegate = _FakeAuthorizationDelegate(
      accessToken: 'expired-token',
      refreshedToken: 'refreshed-token',
    );
    final client = ApiClient(
      baseUrl: 'http://127.0.0.1:${server.port}',
      authorizationDelegate: delegate,
    );
    addTearDown(client.close);

    final result = await client.getResultData('/api/protected');

    expect(result, {'ok': true});
    expect(authorizationHeaders, [
      'Bearer expired-token',
      'Bearer refreshed-token',
    ]);
    expect(delegate.refreshCount, 1);
    expect(delegate.clearCount, 0);
  });

  test('clears authentication when refresh cannot recover a 401', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async => _writeUnauthorized(request.response));

    final delegate = _FakeAuthorizationDelegate(accessToken: 'invalid-token');
    final client = ApiClient(
      baseUrl: 'http://127.0.0.1:${server.port}',
      authorizationDelegate: delegate,
    );
    addTearDown(client.close);

    await expectLater(
      client.getResultData('/api/protected'),
      throwsA(isA<AuthenticationRequiredException>()),
    );
    expect(delegate.refreshCount, 1);
    expect(delegate.clearCount, 1);
  });
}

void _writeSuccess(HttpResponse response) {
  response
    ..statusCode = HttpStatus.ok
    ..headers.contentType = ContentType.json
    ..write(
      jsonEncode({
        'success': true,
        'message': 'OK',
        'data': {'ok': true},
        'errors': <String>[],
        'statusCode': 200,
      }),
    );
  response.close();
}

void _writeUnauthorized(HttpResponse response) {
  response
    ..statusCode = HttpStatus.unauthorized
    ..headers.contentType = ContentType.json
    ..write(
      jsonEncode({
        'success': false,
        'message': 'Authentication is required.',
        'data': null,
        'errors': <String>[],
        'statusCode': 401,
      }),
    );
  response.close();
}

class _FakeAuthorizationDelegate implements ApiAuthorizationDelegate {
  _FakeAuthorizationDelegate({required this.accessToken, this.refreshedToken});

  String? accessToken;
  final String? refreshedToken;
  int refreshCount = 0;
  int clearCount = 0;

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<String?> refreshAccessToken() async {
    refreshCount++;
    accessToken = refreshedToken;
    return refreshedToken;
  }

  @override
  Future<void> clearSession() async {
    clearCount++;
    accessToken = null;
  }
}
