import 'dart:convert';
import 'dart:io';

import 'package:thuraya/core/network/api_config.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient({
    String? baseUrl,
    HttpClient? httpClient,
    this.requestTimeout = const Duration(seconds: 12),
  }) : _baseUri = Uri.parse(baseUrl ?? ApiConfig.baseUrl),
       _httpClient = httpClient ?? HttpClient();

  final Uri _baseUri;
  final HttpClient _httpClient;
  final Duration requestTimeout;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String> queryParameters = const {},
  }) async {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final baseWithTrailingSlash = _baseUri.toString().endsWith('/')
        ? _baseUri
        : Uri.parse('${_baseUri.toString()}/');
    final uri = baseWithTrailingSlash
        .resolve(normalizedPath)
        .replace(
          queryParameters: queryParameters.isEmpty ? null : queryParameters,
        );

    final request = await _httpClient.getUrl(uri).timeout(requestTimeout);
    request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);

    final response = await request.close().timeout(requestTimeout);
    final body = await utf8.decoder
        .bind(response)
        .join()
        .timeout(requestTimeout);

    Object? decodedBody;
    if (body.isNotEmpty) {
      try {
        decodedBody = jsonDecode(body);
      } on FormatException {
        throw ApiException(
          'The server returned an invalid response.',
          statusCode: response.statusCode,
        );
      }
    }

    if (response.statusCode < HttpStatus.ok ||
        response.statusCode >= HttpStatus.multipleChoices) {
      throw ApiException(
        _readMessage(decodedBody) ?? 'The request failed.',
        statusCode: response.statusCode,
      );
    }

    if (decodedBody is! Map) {
      throw ApiException(
        'The server returned an invalid response.',
        statusCode: response.statusCode,
      );
    }

    return Map<String, dynamic>.from(decodedBody);
  }

  Future<Object?> getResultData(
    String path, {
    Map<String, String> queryParameters = const {},
  }) async {
    final response = await getJson(path, queryParameters: queryParameters);
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

  void close() => _httpClient.close(force: true);

  static String? _readMessage(Object? decodedBody) {
    if (decodedBody is Map && decodedBody['message'] is String) {
      return decodedBody['message'] as String;
    }
    return null;
  }
}
