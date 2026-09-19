import 'package:flutter/foundation.dart';
import 'package:thuraya/core/network/api_client.dart';
import 'package:thuraya/features/wheel/models/wheel_models.dart';
import 'package:thuraya/features/wheel/services/wheel_service.dart';

enum WheelLoadStatus { idle, loading, ready, error }

enum WheelErrorKind {
  badRequest,
  forbidden,
  notFound,
  network,
  invalidResponse,
}

class WheelController extends ChangeNotifier {
  WheelController({WheelGateway? gateway})
    : _gateway = gateway ?? WheelService(),
      _ownsGateway = gateway == null;

  final WheelGateway _gateway;
  final bool _ownsGateway;
  bool _disposed = false;

  WheelLoadStatus status = WheelLoadStatus.idle;
  WheelSessionDto? session;
  WheelErrorKind? error;
  bool isAdding = false;
  bool isRequestingSpin = false;

  List<WheelOptionDto> get activeOptions => List.unmodifiable(
    session?.options.where((option) => option.isActive) ?? const [],
  );

  bool get isMutating => isAdding || isRequestingSpin;

  Future<void> initialize(List<String> initialOptions) async {
    if (status == WheelLoadStatus.loading || status == WheelLoadStatus.ready) {
      return;
    }
    status = WheelLoadStatus.loading;
    error = null;
    _notify();

    try {
      session ??= await _gateway.createSession();
      for (final text in initialOptions) {
        final alreadyAdded = session!.options.any(
          (option) => option.isActive && option.text == text,
        );
        if (!alreadyAdded) {
          final option = await _gateway.addOption(session!.id, text);
          _replaceSessionOptions([...session!.options, option]);
        }
      }
      status = WheelLoadStatus.ready;
    } on AuthenticationRequiredException {
      error = WheelErrorKind.network;
      status = WheelLoadStatus.error;
      _notify();
      rethrow;
    } catch (exception) {
      error = _classify(exception);
      status = WheelLoadStatus.error;
    }
    _notify();
  }

  Future<bool> addOption(String text) async {
    final currentSession = session;
    if (currentSession == null || isMutating) return false;
    isAdding = true;
    error = null;
    _notify();
    try {
      final option = await _gateway.addOption(currentSession.id, text);
      _replaceSessionOptions([...currentSession.options, option]);
      return true;
    } on AuthenticationRequiredException {
      error = WheelErrorKind.network;
      rethrow;
    } catch (exception) {
      error = _classify(exception);
      return false;
    } finally {
      isAdding = false;
      _notify();
    }
  }

  Future<WheelSpinSelection?> spin() async {
    final currentSession = session;
    if (currentSession == null || isMutating) return null;
    isRequestingSpin = true;
    error = null;
    _notify();
    try {
      final result = await _gateway.spin(currentSession.id);
      var options = activeOptions;
      var index = options.indexWhere(
        (option) => option.id == result.selectedOption.id,
      );
      if (index < 0) {
        final refreshed = await _gateway.getSession(currentSession.id);
        session = refreshed;
        options = activeOptions;
        index = options.indexWhere(
          (option) => option.id == result.selectedOption.id,
        );
      }
      if (index < 0 || !result.selectedOption.isActive) {
        error = WheelErrorKind.invalidResponse;
        return null;
      }
      return WheelSpinSelection(result: result, optionIndex: index);
    } on AuthenticationRequiredException {
      error = WheelErrorKind.network;
      rethrow;
    } catch (exception) {
      error = _classify(exception);
      return null;
    } finally {
      isRequestingSpin = false;
      _notify();
    }
  }

  void clearError() {
    if (error == null) return;
    error = null;
    _notify();
  }

  void _replaceSessionOptions(List<WheelOptionDto> options) {
    final current = session!;
    session = WheelSessionDto(
      id: current.id,
      name: current.name,
      options: List.unmodifiable(options),
      createdAtUtc: current.createdAtUtc,
      updatedAtUtc: current.updatedAtUtc,
    );
  }

  WheelErrorKind _classify(Object exception) {
    if (exception is FormatException || exception is TypeError) {
      return WheelErrorKind.invalidResponse;
    }
    if (exception is ApiException) {
      return switch (exception.statusCode) {
        400 => WheelErrorKind.badRequest,
        403 => WheelErrorKind.forbidden,
        404 => WheelErrorKind.notFound,
        _ => WheelErrorKind.network,
      };
    }
    return WheelErrorKind.network;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    if (_ownsGateway && _gateway is WheelService) {
      _gateway.close();
    }
    super.dispose();
  }
}
