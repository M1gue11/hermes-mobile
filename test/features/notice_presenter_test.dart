import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/domain/models/push_notice.dart';
import 'package:hermes_mobile/features/notifications/notice_presenter.dart';
import 'package:hermes_mobile/features/settings/agent_persona.dart';

void main() {
  const persona = AgentPersona(name: 'Atena', gender: AgentGender.feminine);

  ShowNotice show(PushNotice notice, {AgentPersona p = persona}) =>
      decideNotice(notice, persona: p) as ShowNotice;

  test('turno concluído: persona no título, conversa no corpo, deep link', () {
    final shown = show(
      const PushNotice(
        kind: PushNoticeKind.turnCompleted,
        sessionId: 'sess/1',
        title: 'Refatorar backup',
      ),
    ).notice;

    expect(shown.title, 'Atena respondeu');
    expect(shown.body, 'Refatorar backup');
    expect(shown.payload, 'hermes://app/chat/sess%2F1');
    expect(shown.urgent, isFalse);
    expect(shown.id, noticeSlotId('turn:sess/1'));
  });

  test('sem título a conversa é genérica e sem persona o nome é Hermes', () {
    final shown = show(
      const PushNotice(kind: PushNoticeKind.turnFailed, sessionId: 's'),
      p: const AgentPersona(),
    ).notice;

    expect(shown.title, 'Hermes parou com erro');
    expect(shown.body, 'Toque para abrir a conversa.');
  });

  test('cada espera tem o próprio texto e vai pelo canal urgente', () {
    String title(PushInputKind input) => show(
      PushNotice(
        kind: PushNoticeKind.inputRequested,
        sessionId: 's',
        input: input,
        requestId: 'r-${input.name}',
      ),
    ).notice.title;

    expect(title(PushInputKind.approval), 'Atena precisa da sua aprovação');
    expect(title(PushInputKind.clarify), 'Atena fez uma pergunta');
    expect(title(PushInputKind.sudo), 'Atena pede a senha de sudo');
    expect(
      show(
        const PushNotice(
          kind: PushNoticeKind.inputRequested,
          sessionId: 's',
          input: PushInputKind.approval,
          requestId: 'r',
        ),
      ).notice.urgent,
      isTrue,
    );
  });

  test(
    'resolvido apaga o aviso do mesmo pedido, mesmo com a conversa aberta',
    () {
      final decision = decideNotice(
        const PushNotice(
          kind: PushNoticeKind.inputResolved,
          sessionId: 's',
          requestId: 'r1',
        ),
        persona: persona,
        viewing: true,
      );

      expect(decision, isA<CancelNotice>());
      expect((decision as CancelNotice).id, noticeSlotId('input:r1'));
    },
  );

  test('com a conversa na tela o aviso dela é ignorado, menos o teste', () {
    expect(
      decideNotice(
        const PushNotice(kind: PushNoticeKind.turnCompleted, sessionId: 's'),
        persona: persona,
        viewing: true,
      ),
      isA<IgnoreNotice>(),
    );
    final test = decideNotice(
      const PushNotice(kind: PushNoticeKind.test),
      persona: persona,
      viewing: true,
    );
    expect(test, isA<ShowNotice>());
    final shown = (test as ShowNotice).notice;
    expect(shown.title, 'Notificações ativas');
    expect(shown.body, 'Os avisos de Atena chegam neste aparelho.');
    expect(shown.payload, isNull);
  });
}
