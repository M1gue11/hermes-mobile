import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/main.dart' as app;
import 'package:hermes_mobile/core/widgets/hermes_startup_splash.dart';
import 'package:hermes_mobile/features/notifications/push_runtime.dart';
import 'push_controller_test.dart' show FakeAdapter, MemoryStore;
import 'package:hermes_mobile/features/notifications/push_controller.dart';

void main() {
  test(
    'default main routes service args before all foreground steps',
    () async {
      final steps = <String>[];
      await app.runMainForTest(
        ['extra', '--unifiedpush-bg'],
        app.MainStartupOverrides(
          headless: () async {
            steps.add('headless');
          },
          binding: () => fail('widget binding'),
          foreground: () async => fail('foreground receiver'),
          readSettings: () async => fail('settings/secrets'),
          launch: (_) => fail('runApp/gate/provider/network'),
        ),
      );
      expect(steps, ['headless']);
    },
  );

  test(
    'real foreground composition restores once and preserves settings fallback',
    () async {
      final adapter = FakeAdapter();
      final store = MemoryStore();
      final controller = PushController(
        adapter: adapter,
        store: store,
        android: true,
      );
      final steps = <String>[];
      Widget? output;
      await app.runMainForTest(
        [],
        app.MainStartupOverrides(
          headless: () async => fail('headless'),
          binding: () {
            steps.add('binding');
          },
          foreground: () async {
            steps.add('receiver');
            await Future.wait([
              startPushForeground(controller),
              startPushForeground(controller),
            ]);
          },
          readSettings: () async {
            steps.add('settings');
            throw StateError('neutral');
          },
          launch: (widget) {
            steps.add('runApp');
            output = widget;
          },
        ),
      );
      await startPushForeground(controller); // Sheet uses the same runtime API.
      expect(steps, ['binding', 'receiver', 'settings', 'runApp']);
      expect(adapter.initializations, 1);
      expect(adapter.registrations, 0);
      expect(controller.optedIn, false);
      expect(store.state, isEmpty);
      expect(output, isA<HermesStartupSplash>());
      final gate =
          (output as HermesStartupSplash).child as app.HermesConnectionGate;
      expect(gate.initialSettings, isNull);
      controller.dispose();
    },
  );
  test(
    'default main restores saved opt-in registration once with sheet startup',
    () async {
      final adapter = FakeAdapter()..saved = 'com.example.distributor';
      final store = MemoryStore()
        ..state = {'opt_in': true, 'distributor': 'com.example.distributor'};
      final controller = PushController(
        adapter: adapter,
        store: store,
        android: true,
      );
      var launches = 0;
      await app.runMainForTest(
        [],
        app.MainStartupOverrides(
          headless: () async => fail('headless'),
          binding: () {},
          foreground: () => startPushForeground(controller),
          readSettings: () async => null,
          launch: (_) {
            launches++;
          },
        ),
      );
      await startPushForeground(controller);
      await controller.start();
      expect(launches, 1);
      expect(adapter.initializations, 1);
      expect(adapter.registrations, 1);
      expect(controller.backendEnrolled, false);
      controller.dispose();
    },
  );
}
