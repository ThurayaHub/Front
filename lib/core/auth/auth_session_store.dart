import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:thuraya/core/auth/models/auth_models.dart';

abstract interface class AuthSessionStore {
  Future<AuthSession?> read();

  Future<void> write(AuthSession session);

  Future<void> clear();
}

class SecureAuthSessionStore implements AuthSessionStore {
  SecureAuthSessionStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(migrateWithBackup: true),
          );

  static const String _sessionKey = 'thuraya.auth.session.v1';

  final FlutterSecureStorage _storage;

  @override
  Future<AuthSession?> read() async {
    final encodedSession = await _storage.read(key: _sessionKey);
    if (encodedSession == null || encodedSession.isEmpty) {
      return null;
    }
    final json = jsonDecode(encodedSession);
    if (json is! Map) {
      throw const FormatException(
        'The stored authentication session is invalid.',
      );
    }
    return AuthSession.fromJson(Map<String, dynamic>.from(json));
  }

  @override
  Future<void> write(AuthSession session) {
    return _storage.write(
      key: _sessionKey,
      value: jsonEncode(session.toJson()),
    );
  }

  @override
  Future<void> clear() {
    return _storage.delete(key: _sessionKey);
  }
}
