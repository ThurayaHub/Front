import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:thuraya/core/network/api_client.dart';
import 'package:thuraya/features/wheel/models/wheel_models.dart';
import 'package:thuraya/features/wheel/presentation/wheel_controller.dart';
import 'package:thuraya/features/wheel/services/wheel_service.dart';

void main() {
  test('creates an empty session and maps the backend winner by ID', () async {
      final gateway = _WheelGateway();
      final controller = WheelController(gateway: gateway);

      await controller.initialize();
      await controller.addOption('برجر');
      await controller.addOption('بيتزا');
      final added = await controller.addOption('قهوة');
      final selection = await controller.spin();

      expect(controller.status, WheelLoadStatus.ready);
      expect(added, isTrue);
      expect(controller.activeOptions.map((option) => option.id), [
        100,
        101,
        102,
      ]);
      expect(selection?.result.selectedOption.id, 101);
      expect(selection?.optionIndex, 1);
      expect(gateway.createCalls, 1);
      expect(gateway.spinCalls, 1);
    });

  test('restores the current backend session without creating another', () async {
    final gateway = _WheelGateway(currentSessionExists: true)
      ..options.add(
        const WheelOptionDto(id: 44, text: 'محفوظ', isActive: true),
      );
    final controller = WheelController(gateway: gateway);

    await controller.initialize();

    expect(controller.activeOptions.single.text, 'محفوظ');
    expect(gateway.getCurrentCalls, 1);
    expect(gateway.createCalls, 0);
  });

  test('soft-removes an option only after backend success', () async {
    final gateway = _WheelGateway();
    final controller = WheelController(gateway: gateway);
    await controller.initialize();
    await controller.addOption('برجر');
    final option = controller.activeOptions.single;

    expect(await controller.removeOption(option.id), isTrue);
    expect(controller.activeOptions, isEmpty);
    expect(gateway.options.single.isActive, isFalse);
  });

  test('guards a second spin while the first request is pending', () async {
    final gateway = _WheelGateway()..spinCompleter = Completer();
    final controller = WheelController(gateway: gateway);
    await controller.initialize();
    await controller.addOption('أ');
    await controller.addOption('ب');

    final first = controller.spin();
    final second = await controller.spin();
    expect(second, isNull);
    expect(gateway.spinCalls, 1);

    gateway.spinCompleter!.complete(gateway.spinResult);
    expect((await first)?.optionIndex, 1);
  });

  test('keeps current options and classifies forbidden failures', () async {
    final gateway = _WheelGateway();
    final controller = WheelController(gateway: gateway);
    await controller.initialize();
    await controller.addOption('أ');
    await controller.addOption('ب');
    gateway.addError = const ApiException('Forbidden', statusCode: 403);

    final added = await controller.addOption('ج');

    expect(added, isFalse);
    expect(controller.activeOptions.map((option) => option.text), ['أ', 'ب']);
    expect(controller.error, WheelErrorKind.forbidden);
  });

  test(
    'classifies 400, 404, and server failures without resetting state',
    () async {
      const cases = <int, WheelErrorKind>{
        400: WheelErrorKind.badRequest,
        404: WheelErrorKind.notFound,
        500: WheelErrorKind.network,
      };
      for (final entry in cases.entries) {
        final gateway = _WheelGateway();
        final controller = WheelController(gateway: gateway);
        await controller.initialize();
        await controller.addOption('أ');
        await controller.addOption('ب');
        gateway.addError = ApiException('Failure', statusCode: entry.key);

        expect(await controller.addOption('ج'), isFalse);
        expect(controller.error, entry.value);
        expect(controller.activeOptions, hasLength(2));
      }
    },
  );
}

class _WheelGateway implements WheelGateway {
  _WheelGateway({this.currentSessionExists = false});

  bool currentSessionExists;
  int createCalls = 0;
  int getCurrentCalls = 0;
  int spinCalls = 0;
  int nextOptionId = 100;
  ApiException? addError;
  Completer<WheelSpinResultDto>? spinCompleter;
  final List<WheelOptionDto> options = [];

  WheelSpinResultDto get spinResult => WheelSpinResultDto(
    id: 400,
    wheelSessionId: 7,
    selectedOption: options[1],
    createdAtUtc: DateTime.utc(2026, 9, 20),
  );

  @override
  Future<WheelSessionDto> createSession({String? name}) async {
    createCalls++;
    currentSessionExists = true;
    return _session();
  }

  @override
  Future<WheelSessionDto> getCurrentSession() async {
    getCurrentCalls++;
    if (!currentSessionExists) {
      throw const ApiException('Not found', statusCode: 404);
    }
    return _session();
  }

  @override
  Future<WheelSessionDto> getSession(int wheelSessionId) async => _session();

  @override
  Future<WheelOptionDto> addOption(int wheelSessionId, String text) async {
    if (addError case final error?) throw error;
    final option = WheelOptionDto(
      id: nextOptionId++,
      text: text,
      isActive: true,
    );
    options.add(option);
    return option;
  }

  @override
  Future<WheelOptionDto> removeOption(int wheelSessionId, int optionId) async {
    final index = options.indexWhere((option) => option.id == optionId);
    final removed = WheelOptionDto(
      id: options[index].id,
      text: options[index].text,
      isActive: false,
    );
    options[index] = removed;
    return removed;
  }

  @override
  Future<WheelSpinResultDto> spin(int wheelSessionId) {
    spinCalls++;
    return spinCompleter?.future ?? Future.value(spinResult);
  }

  WheelSessionDto _session() => WheelSessionDto(
    id: 7,
    name: null,
    options: List.unmodifiable(options),
    createdAtUtc: DateTime.utc(2026, 9, 20),
    updatedAtUtc: null,
  );
}
