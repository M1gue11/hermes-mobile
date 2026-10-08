import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:unifiedpush_platform_interface/data/push_message.dart';
import 'package:unifiedpush_platform_interface/data/push_endpoint.dart';
import 'package:unifiedpush_platform_interface/data/failed_reason.dart';
import 'package:unifiedpush_platform_interface/data/public_key_set.dart';
import 'package:hermes_mobile/features/notifications/push_controller.dart';
import 'package:hermes_mobile/features/notifications/push_runtime.dart';
import 'package:hermes_mobile/features/notifications/push_store.dart';
import 'package:hermes_mobile/features/notifications/unifiedpush_adapter.dart';
import 'push_notice_check.dart' show envelope;

class MemoryStore implements PushStore {
  Map<String, dynamic> state = {};
  bool failWrite = false;
  bool failRead = false;
  Completer<void>? readGate;
  @override
  Future<Map<String, dynamic>> read() async {
    await readGate?.future;
    if (failRead) throw StateError('neutral storage error');
    return {...state};
  }

  @override
  Future<void> write(Map<String, dynamic> next) async {
    if (failWrite) throw StateError('neutral storage error');
    state = {...next};
  }
}

class FakeAdapter implements PushAdapter {
  late PushCallbacks callbacks;
  bool result = false;
  bool defaultResult = true;
  bool failUnregister = false;
  bool failRegister = false;
  int initializations = 0;
  int registrations = 0;
  int unregistrations = 0;
  int defaults = 0;
  String? saved;
  @override
  Future<bool> initialize(PushCallbacks value) async {
    initializations++;
    callbacks = value;
    return result;
  }

  @override
  Future<List<String>> distributors() async => ['com.example.distributor'];
  @override
  Future<String?> distributor() async => saved;
  @override
  Future<bool> useDefault() async {
    defaults++;
    if (defaultResult) saved = 'com.example.distributor';
    return defaultResult;
  }

  @override
  Future<void> select(String value) async {
    saved = value;
  }

  @override
  Future<void> register() async {
    registrations++;
    if (failRegister) throw StateError('neutral');
  }

  @override
  Future<void> unregister() async {
    unregistrations++;
    if (failUnregister) throw StateError('neutral');
    saved = null;
  }
}

void main() {
  late MemoryStore store;
  late FakeAdapter adapter;
  late PushController controller;
  const instance = OfficialPushAdapter.instance;
  setUp(() {
    store = MemoryStore();
    adapter = FakeAdapter();
    controller = PushController(adapter: adapter, store: store, android: true);
  });
  tearDown(() async {
    await controller.settled;
    controller.dispose();
  });
  Future<void> select() async {
    await controller.start();
    await controller.enable();
    await controller.choose(distributor: 'com.example.distributor');
  }

  test(
    'initialize false/true permissionNoAction never implies backend enrollment',
    () async {
      await controller.start();
      expect(controller.initialized, true);
      expect(controller.optedIn, false);
      expect(controller.distributorRegistered, false);
      expect(adapter.registrations, 0);
      adapter.result = true;
      await controller.start();
      expect(controller.distributorRegistered, true);
      expect(adapter.registrations, 0);
      expect(controller.status, 'Desligado');
      expect(
        PushController.backend,
        'Backend pendente — enrollment autenticado ainda não existe',
      );
      await controller.choose(defaultChoice: true);
      expect(adapter.defaults, 0);
    },
  );
  test(
    'explicit selection, endpoint, registrationFailed and temp unavailable',
    () async {
      await select();
      expect(adapter.registrations, 1);
      adapter.callbacks.endpoint(
        PushEndpoint(
          'https://example.com/push',
          PublicKeySet('neutral-key', 'neutral-auth'),
        ),
        instance,
      );
      await controller.settled;
      expect(controller.hasEndpoint, true);
      expect(controller.status, contains('backend pendente'));
      adapter.callbacks.failed(FailedReason.actionRequired, instance);
      await controller.settled;
      expect(controller.distributorRegistered, false);
      expect(controller.hasEndpoint, true);
      expect(controller.status, contains('Registro falhou'));
      adapter.callbacks.unavailable(instance);
      await controller.settled;
      expect(controller.status, 'Temporariamente indisponível');
    },
  );
  test('default choice and absent default require consent', () async {
    await controller.start();
    await controller.enable();
    adapter.defaultResult = false;
    await controller.choose(defaultChoice: true);
    expect(adapter.registrations, 0);
    adapter.defaultResult = true;
    await controller.choose(defaultChoice: true);
    expect(controller.selected, 'com.example.distributor');
    expect(adapter.registrations, 1);
  });
  test(
    'unknown distributor and changing active registration are rejected',
    () async {
      await controller.start();
      await controller.enable();
      await controller.choose(distributor: 'com.example.absent');
      expect(adapter.registrations, 0);
      await controller.choose(distributor: 'com.example.distributor');
      await controller.choose(defaultChoice: true);
      expect(adapter.defaults, 0);
    },
  );
  test('register failure remains pending, never ready', () async {
    adapter.failRegister = true;
    await select();
    expect(controller.status, 'Falha — tente novamente');
    expect(controller.distributorRegistered, false);
    expect(controller.optedIn, true);
    expect(controller.selected, isNotNull);
    adapter.failRegister = false;
    await controller.retryRegistration();
    expect(adapter.registrations, 2);
    expect(controller.distributorRegistered, true);
  });
  test(
    'restored register failure exposes a retryable inactive state',
    () async {
      store.state = {'opt_in': true, 'distributor': 'com.example.distributor'};
      adapter.saved = 'com.example.distributor';
      adapter.failRegister = true;
      await controller.start();
      expect(controller.initialized, true);
      expect(controller.startupHealthy, false);
      expect(controller.distributorRegistered, false);
      adapter.failRegister = false;
      await controller.retryRegistration();
      expect(adapter.registrations, 2);
      expect(controller.distributorRegistered, true);
      expect(controller.startupHealthy, true);
    },
  );

  test('foreground startup retries after transient storage failure', () async {
    store.failRead = true;
    await startPushForeground(controller);
    expect(controller.startupHealthy, false);
    store.failRead = false;
    await startPushForeground(controller);
    await controller.settled;
    expect(controller.startupHealthy, true);
    expect(adapter.initializations, 1);
  });
  test(
    'headless backgroundNoUI never invokes normal app or register',
    () async {
      store.state = {'opt_in': true, 'distributor': 'com.example.distributor'};
      var ui = 0;
      await bootstrapPush(['--unifiedpush-bg'], controller, () async {
        ui++;
        throw StateError('chat/socket/global store must not initialize');
      });
      expect(ui, 0);
      expect(adapter.registrations, 0);
      adapter.callbacks.message(PushMessage(envelope(), true), instance);
      await controller.settled;
      expect(controller.receiver.accepted, 1);
      adapter.callbacks.message(PushMessage(envelope(), true), instance);
      adapter.callbacks.message(
        PushMessage(envelope({'event_id': 'event_2'}), false),
        instance,
      );
      adapter.callbacks.message(
        PushMessage(envelope({'event_id': 'event_3'}), true),
        'other',
      );
      await controller.settled;
      expect(controller.receiver.accepted, 1);
    },
  );
  test(
    'normal bootstrap calls app once and restores only opted registration',
    () async {
      store.state = {'opt_in': true, 'distributor': 'com.example.distributor'};
      adapter.saved = 'com.example.distributor';
      var ui = 0;
      await bootstrapPush([], controller, () async {
        ui++;
      });
      expect(ui, 1);
      expect(adapter.registrations, 1);
    },
  );
  test('opt-out messages and late endpoints ignored', () async {
    await controller.start();
    adapter.callbacks.message(PushMessage(envelope(), true), instance);
    adapter.callbacks.endpoint(
      PushEndpoint('https://example.com/push', null),
      instance,
    );
    await controller.settled;
    expect(controller.receiver.accepted, 0);
    expect(controller.hasEndpoint, false);
  });
  test(
    'revoke failure preserves endpoint and selection but suppresses receiving',
    () async {
      await select();
      adapter.callbacks.endpoint(
        PushEndpoint(
          'https://example.com/push',
          PublicKeySet('neutral-key', 'neutral-auth'),
        ),
        instance,
      );
      await controller.settled;
      adapter.failUnregister = true;
      await controller.revoke();
      expect(controller.optedIn, false);
      expect(controller.hasEndpoint, true);
      expect(controller.selected, isNotNull);
      adapter.callbacks.message(PushMessage(envelope(), true), instance);
      await controller.settled;
      expect(controller.receiver.accepted, 0);
      adapter.failUnregister = false;
      await controller.revoke();
      expect(controller.hasEndpoint, false);
      expect(controller.selected, null);
      expect(adapter.unregistrations, 2);
    },
  );
  test(
    'storage failure before revoke never unregisters or erases safe state',
    () async {
      await select();
      store.failWrite = true;
      store.readGate = Completer<void>();
      adapter.callbacks.message(PushMessage(envelope(), true), instance);
      await Future<void>.delayed(Duration.zero);
      final revocation = controller.revoke();
      expect(controller.optedIn, false);
      expect(store.state['opt_in'], true);
      store.readGate!.complete();
      await revocation;
      expect(store.state['opt_in'], true);
      expect(adapter.unregistrations, 0);
      expect(controller.optedIn, false);
      expect(controller.selected, isNotNull);
      adapter.callbacks.message(PushMessage(envelope(), true), instance);
      await controller.settled;
      expect(controller.receiver.accepted, 0);
    },
  );
  test(
    'unregistered callback and callback read errors handled asynchronously',
    () async {
      await select();
      store.failRead = true;
      expect(
        () =>
            adapter.callbacks.message(PushMessage(envelope(), true), instance),
        returnsNormally,
      );
      await controller.settled;
      expect(controller.receiver.accepted, 0);
      store.failRead = false;
      adapter.callbacks.unregistered(instance);
      await controller.settled;
      expect(controller.optedIn, false);
      expect(controller.selected, null);
    },
  );
  for (final readFailure in [true, false]) {
    test(
      'unregistered suppresses immediately with storage ${readFailure ? 'read' : 'write'} failure',
      () async {
        await select();
        adapter.callbacks.endpoint(
          PushEndpoint(
            'https://example.com/push',
            PublicKeySet('neutral-key', 'neutral-auth'),
          ),
          instance,
        );
        await controller.settled;
        store.readGate = Completer<void>();
        adapter.callbacks.message(PushMessage(envelope(), true), instance);
        await Future<void>.delayed(Duration.zero);
        store.failRead = readFailure;
        store.failWrite = !readFailure;
        expect(() => adapter.callbacks.unregistered(instance), returnsNormally);
        expect(controller.optedIn, false);
        expect(controller.distributorRegistered, false);
        store.readGate!.complete();
        await controller.settled;
        expect(controller.status, 'Falha — tente novamente');
        expect(store.state['opt_in'], true);
        expect(controller.hasEndpoint, true);
        expect(controller.selected, 'com.example.distributor');
        store.failRead = false;
        store.failWrite = false;
        adapter.callbacks.message(PushMessage(envelope(), true), instance);
        await controller.settled;
        expect(controller.receiver.accepted, 0);
        await controller.revoke();
        expect(controller.selected, null);
      },
    );
  }

  test(
    'foreground start is once and allows explicit opt-in/selection',
    () async {
      await startPushForeground(controller);
      await controller.settled;
      expect(controller.initialized, true);
      expect(controller.optedIn, false);
      expect(adapter.registrations, 0);
      await controller.enable();
      await controller.choose(distributor: 'com.example.distributor');
      expect(adapter.registrations, 1);
      await startPushForeground(controller);
      await controller.settled;
      expect(adapter.initializations, 1);
    },
  );

  test('unsupported foreground never initializes adapter', () async {
    final unsupported = PushController(
      adapter: adapter,
      store: store,
      android: false,
    );
    await startPushForeground(unsupported);
    expect(adapter.initializations, 0);
    unsupported.dispose();
  });

  test('unsupported platform performs no package actions', () async {
    final unsupported = PushController(
      adapter: adapter,
      store: store,
      android: false,
    );
    await unsupported.start();
    await unsupported.enable();
    await unsupported.choose(defaultChoice: true);
    await unsupported.revoke();
    expect(unsupported.initialized, false);
    expect(adapter.registrations, 0);
    unsupported.dispose();
  });
}
