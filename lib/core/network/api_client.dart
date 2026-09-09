import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:thuraya/core/network/api_config.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class AuthenticationRequiredException extends ApiException {
  const AuthenticationRequiredException(super.message)
    : super(statusCode: 401);
}

abstract interface class ApiAuthorizationDelegate {
  Future<String?> getAccessToken();

  Future<String?> refreshAccessToken();

  Future<void> clearSession();
}

class ApiClient {
  ApiClient({
    String? baseUrl,
    http.Client? httpClient,
    this.authorizationDelegate,
    this.useAuthentication = true,
    this.requestTimeout = const Duration(seconds: 12),
  }) : _baseUri = Uri.parse(baseUrl ?? ApiConfig.baseUrl),
       _httpClient = httpClient ?? http.Client();

  static ApiAuthorizationDelegate? defaultAuthorizationDelegate;

  final Uri _baseUri;
  final http.Client _httpClient;
  final ApiAuthorizationDelegate? authorizationDelegate;
  final bool useAuthentication;
  final Duration requestTimeout;

  ApiAuthorizationDelegate? get _authDelegate => useAuthentication
      ? (authorizationDelegate ?? defaultAuthorizationDelegate)
      : null;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String> queryParameters = const {},
  }) {
    return _requestJson('GET', path, queryParameters: queryParameters);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Object? body,
    Map<String, String> queryParameters = const {},
  }) {
    return _requestJson(
      'POST',
      path,
      queryParameters: queryParameters,
      body: body,
    );
  }

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    Object? body,
    Map<String, String> queryParameters = const {},
  }) {
    return _requestJson(
      'DELETE',
      path,
      queryParameters: queryParameters,
      body: body,
    );
  }

  Future<Object?> getResultData(
    String path, {
    Map<String, String> queryParameters = const {},
  }) async {
    final response = await getJson(path, queryParameters: queryParameters);
    return _resultData(response);
  }

  Future<Object?> postResultData(
    String path, {
    Object? body,
    Map<String, String> queryParameters = const {},
  }) async {
    final response = await postJson(
      path,
      body: body,
      queryParameters: queryParameters,
    );
    return _resultData(response);
  }

  Future<Object?> deleteResultData(
    String path, {
    Object? body,
    Map<String, String> queryParameters = const {},
  }) async {
    final response = await deleteJson(
      path,
      body: body,
      queryParameters: queryParameters,
    );
    return _resultData(response);
  }

  Future<Map<String, dynamic>> _requestJson(
    String method,
    String path, {
    required Map<String, String> queryParameters,
    Object? body,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final authDelegate = _authDelegate;
    final accessToken = await authDelegate?.getAccessToken();
    var response = await _sendRequest(
      method,
      uri,
      body: body,
      accessToken: accessToken,
    );

    if (response.statusCode == 401 && authDelegate != null) {
      final refreshedToken = await authDelegate.refreshAccessToken();
      if (refreshedToken != null && refreshedToken.isNotEmpty) {
        response = await _sendRequest(
          method,
          uri,
          body: body,
          accessToken: refreshedToken,
        );
      }

      if (response.statusCode == 401) {
        await authDelegate.clearSession();
        throw AuthenticationRequiredException(
          _readMessage(response.body) ?? 'Authentication is required.',
        );
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _readMessage(response.body) ?? 'The request failed.',
        statusCode: response.statusCode,
      );
    }

    if (response.body is! Map) {
      throw ApiException(
        'The server returned an invalid response.',
        statusCode: response.statusCode,
      );
    }

    return Map<String, dynamic>.from(response.body as Map);
  }

  Uri _buildUri(String path, Map<String, String> queryParameters) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final baseWithTrailingSlash = _baseUri.toString().endsWith('/')
        ? _baseUri
        : Uri.parse('${_baseUri.toString()}/');
    return baseWithTrailingSlash
        .resolve(normalizedPath)
        .replace(
          queryParameters: queryParameters.isEmpty ? null : queryParameters,
        );
  }

  Future<_ApiResponse> _sendRequest(
    String method,
    Uri uri, {
    Object? body,
    String? accessToken,
  }) async {
    final request = http.Request(method, uri);
    request.headers['Accept'] = 'application/json';
    if (accessToken != null && accessToken.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final rawResponse = await _httpClient.send(request).timeout(requestTimeout);
    final responseBody = await rawResponse.stream
        .bytesToString()
        .timeout(requestTimeout);

    Object? decodedBody;
    if (responseBody.isNotEmpty) {
      try {
        decodedBody = jsonDecode(responseBody);
      } on FormatException {
        throw ApiException(
          'The server returned an invalid response.',
          statusCode: rawResponse.statusCode,
        );
      }
    }

    return _ApiResponse(rawResponse.statusCode, decodedBody);
  }

  Object? _resultData(Map<String, dynamic> response) {
    if (response['success'] != true) {
      final statusCode = response['statusCode'];
      throw ApiException(
        response['message'] is String
            ? response['message'] as String
            : 'The request failed.',
        statusCode: statusCode is num ? statusCode.toInt() : null,
      );
    }
    return response['data'];
  }

  void close() => _httpClient.close();

  static String? _readMessage(Object? decodedBody) {
    if (decodedBody is Map && decodedBody['message'] is String) {
      return decodedBody['message'] as String;
    }
    return null;
  }
}

class _ApiResponse {
  const _ApiResponse(this.statusCode, this.body);

  final int statusCode;
  final Object? body;
}
