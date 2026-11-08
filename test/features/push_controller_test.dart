import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/data/gateway_repository_provider.dart';
import 'package:hermes_mobile/domain/models/push_notice.dart';
import 'package:hermes_mobile/domain/repositories/push_transport.dart';
import 'package:hermes_mobile/features/chat/chat_controller.dart';
import 'package:hermes_mobile/features/chat/chat_state.dart';
import 'package:hermes_mobile/features/notifications/push_controller.dart';

import '../support/fake_gateway_repository.dart';
import '../support/fake_push.dart';

class _OpenChat extends ChatController {
  _OpenChat(this.sessionId);

  final String sessionId;

  @override
  ChatState build() => ChatState(sessionId: sessionId);
}

Future<void> _settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late FakePushTransport transport;
  late FakeLocalNotifier notifier;
  late MemoryPushRegistrationStore store;
  late FakeGatewayRepository gateway;

  ProviderContainer build({bool withGateway = true, String? openSession}) {
    final container = ProviderContainer(
      overrides: [
        if (openSession != null)
          chatControllerProvider.overrideWith(() => _OpenChat(openSession)),
        pushTransportProvider.overrideWithValue(transport),
        localNotifierProvider.overrideWithValue(notifier),
        pushRegistrationStoreProvider.overrideWithValue(store),
        pushEndpointTimeoutProvider.overrideWithValue(
          const Duration(milliseconds: 50),
        ),
        if (withGateway) gatewayRepositoryProvider.overrideWithValue(gateway),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    transport = FakePushTransport();
    notifier = FakeLocalNotifier();
    store = MemoryPushRegistrationStore();
    gateway = FakeGatewayRepository();
  });

  test('desligado nasce em off e não registra nada', () async {
    final container = build();
    container.read(pushControllerProvider);
    await _settle();

    expect(container.read(pushControllerProvider).phase, PushPhase.off);
    expect(transport.registrations, 0);
  });

  test(
    'ligar com um distribuidor registra no servidor com as chaves',
    () async {
      final container = build();
      container.read(pushControllerProvider);
      await _settle();

      await container.read(pushControllerProvider.notifier).enable();
      await _settle();

      final state = container.read(pushControllerProvider);
      expect(state.phase, PushPhase.active);
      expect(state.delivering, isTrue);
      expect(state.distributor, 'io.heckel.ntfy');
      expect(state.endpointHost, 'ntfy.example.org');
      expect(state.pluginAvailable, isTrue);
      expect(state.serverEncryption, isTrue);
      final registered = gateway.aparelhosDePush['phone-0001']!;
      expect(registered.endpoint, transport.endpoint);
      expect((registered.p256dh, registered.auth), ('pub-key', 'auth-key'));
      expect(store.value.enabled, isTrue);
      expect(store.value.syncedEndpoint, transport.endpoint);
    },
  );

  test('sem distribuidor fica esperando o ntfy, já ligado', () async {
    transport.installed = const [];
    final container = build();
    container.read(pushControllerProvider);
    await _settle();

    await container.read(pushControllerProvider.notifier).enable();

    final state = container.read(pushControllerProvider);
    expect(state.phase, PushPhase.needsDistributor);
    expect(state.enabled, isTrue);
    expect(transport.registrations, 0);
  });

  test('com dois distribuidores a pessoa escolhe', () async {
    transport.installed = const [
      'io.heckel.ntfy',
      'org.unifiedpush.distributor.nextpush',
    ];
    final container = build();
    container.read(pushControllerProvider);
    await _settle();
    final controller = container.read(pushControllerProvider.notifier);

    await controller.enable();
    expect(
      container.read(pushControllerProvider).phase,
      PushPhase.choosingDistributor,
    );

    await controller.chooseDistributor('io.heckel.ntfy');
    await _settle();
    expect(transport.current, 'io.heckel.ntfy');
    expect(container.read(pushControllerProvider).phase, PushPhase.active);
  });

  test('permissão negada não liga', () async {
    notifier.allowed = false;
    final container = build();
    container.read(pushControllerProvider);
    await _settle();

    await container.read(pushControllerProvider.notifier).enable();

    final state = container.read(pushControllerProvider);
    expect(state.permissionDenied, isTrue);
    expect(state.enabled, isFalse);
    expect(store.value.enabled, isFalse);
  });

  test('plugin ausente no servidor vira falha explicada', () async {
    gateway.pluginDePush = false;
    final container = build();
    container.read(pushControllerProvider);
    await _settle();

    await container.read(pushControllerProvider.notifier).enable();
    await _settle();

    final state = container.read(pushControllerProvider);
    expect(state.phase, PushPhase.failed);
    expect(state.pluginAvailable, isFalse);
    expect(state.synced, isFalse);

    gateway.pluginDePush = true;
    await container.read(pushControllerProvider.notifier).retry();
    await _settle();
    expect(container.read(pushControllerProvider).phase, PushPhase.active);
  });

  test('distribuidor que não responde vira falha com orientação', () async {
    transport.answerRegister = false;
    final container = build();
    container.read(pushControllerProvider);
    await _settle();

    await container.read(pushControllerProvider.notifier).enable();

    final state = container.read(pushControllerProvider);
    expect(state.phase, PushPhase.failed);
    expect(state.error, contains('app ntfy'));
    expect(state.busy, isFalse);
  });

  test('falha do distribuidor durante o registro traz a causa', () async {
    transport.answerRegister = false;
    final container = build();
    container.read(pushControllerProvider);
    await _settle();

    final enabling = container.read(pushControllerProvider.notifier).enable();
    await _settle();
    transport.emit(const PushRegistrationFailed('actionRequired'));
    await enabling;

    expect(
      container.read(pushControllerProvider).error,
      contains('precisa de atenção'),
    );
  });

  group('já ligado', () {
    setUp(() {
      transport.current = 'io.heckel.ntfy';
      store.value = (
        deviceId: 'phone-0001',
        enabled: true,
        endpoint: transport.endpoint,
        p256dh: 'pub-key',
        auth: 'auth-key',
        syncedEndpoint: transport.endpoint,
      );
      gateway.aparelhosDePush['phone-0001'] = (
        deviceId: 'phone-0001',
        endpoint: transport.endpoint,
        label: 'Hermes Mobile',
        p256dh: 'pub-key',
        auth: 'auth-key',
      );
    });

    test(
      'abertura registra no distribuidor e não reenvia o mesmo endpoint',
      () async {
        final container = build();
        container.read(pushControllerProvider);
        await _settle();

        expect(transport.registrations, 1);
        expect(container.read(pushControllerProvider).phase, PushPhase.active);
        expect(container.read(pushControllerProvider).synced, isTrue);
      },
    );

    test('endpoint renovado é mandado ao servidor', () async {
      final container = build();
      container.read(pushControllerProvider);
      await _settle();

      transport.emit(
        const PushEndpointIssued(
          url: 'https://ntfy.example.org/upNovo?up=1',
          p256dh: 'pub-2',
          auth: 'auth-2',
        ),
      );
      await _settle();

      expect(
        gateway.aparelhosDePush['phone-0001']!.endpoint,
        'https://ntfy.example.org/upNovo?up=1',
      );
      expect(
        store.value.syncedEndpoint,
        'https://ntfy.example.org/upNovo?up=1',
      );
    });

    test('endpoint provisório é ignorado', () async {
      final container = build();
      container.read(pushControllerProvider);
      await _settle();

      transport.emit(
        const PushEndpointIssued(url: 'https://fcm.example/x', temporary: true),
      );
      await _settle();

      expect(store.value.endpoint, transport.endpoint);
    });

    test(
      'push recebido vira aviso; resolvido apaga; lixo é ignorado',
      () async {
        final container = build();
        container.read(pushControllerProvider);
        await _settle();

        transport.push({
          'v': 1,
          'kind': 'input.requested',
          'session_id': 'sess-9',
          'input': 'approval',
          'request_id': 'r1',
          'title': 'Deploy',
        });
        transport.push({'v': 99, 'kind': 'turn.completed', 'session_id': 'x'});
        await _settle();
        transport.push({
          'v': 1,
          'kind': 'input.resolved',
          'session_id': 'sess-9',
          'request_id': 'r1',
        });
        await _settle();

        expect(notifier.shown, hasLength(1));
        expect(notifier.shown.single.title, 'Hermes precisa da sua aprovação');
        expect(notifier.shown.single.body, 'Deploy');
        expect(notifier.shown.single.urgent, isTrue);
        expect(notifier.cancelled, [noticeSlotId('input:r1')]);
      },
    );

    test('a conversa visível não recebe aviso de si mesma', () async {
      final container = build(openSession: 's1');
      container.read(pushControllerProvider);
      await _settle();
      final presence = container.read(appPresenceProvider.notifier);

      presence.update(resumed: true, onChat: true);
      transport.push({'v': 1, 'kind': 'turn.completed', 'session_id': 's1'});
      transport.push({'v': 1, 'kind': 'turn.completed', 'session_id': 's2'});
      await _settle();
      expect(notifier.shown.map((n) => n.payload), ['hermes://app/chat/s2']);

      presence.update(resumed: false);
      transport.push({'v': 1, 'kind': 'turn.failed', 'session_id': 's1'});
      await _settle();
      expect(notifier.shown, hasLength(2));
    });

    test('teste com endpoint expirado registra de novo', () async {
      gateway.resultadoDoTeste = (
        ok: false,
        status: 410,
        encrypted: true,
        gone: true,
      );
      final container = build();
      container.read(pushControllerProvider);
      await _settle();
      final before = transport.registrations;

      await container.read(pushControllerProvider.notifier).sendTest();
      await _settle();

      expect(gateway.testesDePush, ['phone-0001']);
      expect(container.read(pushControllerProvider).lastTest?.gone, isTrue);
      expect(transport.registrations, before + 1);
      expect(gateway.aparelhosDePush, contains('phone-0001'));
    });

    test(
      'desligar remove do servidor, cancela no distribuidor e limpa',
      () async {
        final container = build();
        container.read(pushControllerProvider);
        await _settle();

        await container.read(pushControllerProvider.notifier).disable();

        expect(gateway.aparelhosDePush, isEmpty);
        expect(transport.unregistrations, 1);
        expect(store.value.enabled, isFalse);
        expect(store.value.endpoint, isNull);
        expect(store.value.deviceId, 'phone-0001');
        expect(container.read(pushControllerProvider).phase, PushPhase.off);
      },
    );

    test('desligar sem Dashboard ainda desliga localmente', () async {
      final container = build(withGateway: false);
      container.read(pushControllerProvider);
      await _settle();

      await container.read(pushControllerProvider.notifier).disable();

      expect(transport.unregistrations, 1);
      expect(store.value.enabled, isFalse);
    });

    test(
      'servidor que esqueceu o aparelho recebe o registro de novo',
      () async {
        gateway.aparelhosDePush.clear();
        final container = build();
        container.read(pushControllerProvider);
        await _settle();

        expect(gateway.aparelhosDePush, contains('phone-0001'));
        expect(container.read(pushControllerProvider).synced, isTrue);
      },
    );

    test('distribuidor que cancela o registro aparece como falha', () async {
      final container = build();
      container.read(pushControllerProvider);
      await _settle();

      transport.emit(const PushUnregistered());
      await _settle();

      final state = container.read(pushControllerProvider);
      expect(state.phase, PushPhase.failed);
      expect(state.error, contains('cancelou'));
      expect(store.value.endpoint, isNull);
    });
  });
}
