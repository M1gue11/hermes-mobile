import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/domain/models/operational_notice.dart';
import 'package:hermes_mobile/features/notifications/notification_inbox.dart';
import 'package:hermes_mobile/features/notifications/notification_sheet.dart';
import 'package:hermes_mobile/features/settings/agent_persona.dart';
import 'package:hermes_mobile/features/settings/settings_provider.dart';
import '../support/notice_clock.dart';
import 'package:hermes_mobile/features/chat/widgets/sheets.dart';

void main() {
  testWidgets('persona, texto plain, read/unread e mute efetivo no sheet', (
    tester,
  ) async {
    final clock = NoticeClock();
    final inbox = NotificationInbox(now: clock.now, timer: clock.timer);
    addTearDown(inbox.dispose);
    inbox.accept(
      'durable',
      'r',
      const NoticeShow(
        key: 'key',
        kind: 'custom',
        level: NoticeLevel.warning,
        text: '**Aviso** https://example.com/',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationInboxProvider.overrideWithValue(inbox),
          agentPersonaProvider.overrideWithValue(
            const AgentPersona(name: 'Cláudia', gender: AgentGender.feminine),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.build(),
          home: const Scaffold(
            body: SingleChildScrollView(child: NotificationSheet()),
          ),
        ),
      ),
    );
    expect(find.text('Avisos de Cláudia'), findsOneWidget);
    expect(find.text('**Aviso** https://example.com/'), findsOneWidget);
    expect(find.text('1 não lidas'), findsOneWidget);
    await tester.ensureVisible(find.text('Marcar lida'));
    await tester.tap(find.text('Marcar lida'));
    await tester.pump();
    expect(find.text('0 não lidas'), findsOneWidget);
    inbox.run('durable', 'r', NoticeCategory.progress);
    await tester.ensureVisible(
      find.byKey(const ValueKey('notice-preference-progress')),
    );
    await tester.tap(find.byKey(const ValueKey('notice-preference-progress')));
    await tester.pump();
    clock.advance(NotificationInbox.progressDelay);
    expect(inbox.enabled(NoticeCategory.progress), isFalse);
    expect(inbox.entries, hasLength(1));
    await tester.ensureVisible(find.text('Remover'));
    await tester.tap(find.text('Remover'));
    await tester.pump();
    expect(find.text('Nenhum aviso local.'), findsOneWidget);
  });

  testWidgets('abrir conversa navega pela sessão codificada e fecha sheets', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final inbox = NotificationInbox();
    addTearDown(inbox.dispose);
    const session = 'durável /?#%';
    inbox.accept(
      session,
      'r',
      const NoticeShow(
        key: '/fake',
        kind: 'custom',
        level: NoticeLevel.info,
        text: 'https://example.com/ação',
      ),
    );
    String? captured;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Consumer(
            builder: (context, ref, _) => Scaffold(
              body: TextButton(
                onPressed: () => showSettingsSheet(context, ref),
                child: const Text('Abrir ajustes'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/chat/:conversationId',
          builder: (context, state) {
            captured = state.pathParameters['conversationId'];
            return const Scaffold(body: Text('Conversa durável'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationInboxProvider.overrideWithValue(inbox),
          agentPersonaProvider.overrideWithValue(
            const AgentPersona(name: 'Cláudia'),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.build(),
          routerConfig: router,
        ),
      ),
    );
    await tester.tap(find.text('Abrir ajustes'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Notificações'));
    await tester.tap(find.text('Notificações'));
    await tester.pumpAndSettle();
    expect(find.text('Avisos de Cláudia'), findsOneWidget);
    await tester.ensureVisible(find.text('Abrir conversa'));
    await tester.tap(find.text('Abrir conversa'));
    await tester.pumpAndSettle();
    expect(captured, session);
    expect(find.text('Conversa durável'), findsOneWidget);
    expect(find.text('Notificações'), findsNothing);
    expect(find.text('Ajustes'), findsNothing);
    expect(find.text('Avisos de Cláudia'), findsNothing);
    expect(inbox.entries.single.read, isTrue);
  });
}
