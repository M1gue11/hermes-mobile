import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/domain/models/approval_request.dart';

/// A18: contrato medido no Hermes `0.19.0`.
///
/// O evento nasce em `_approval_notify` (`api_server.py:6149`), que mescla o
/// `approval_data` de `tools/approval.py` com `{event, run_id, timestamp,
/// choices}`. As escolhas vêm de `_approval_event_choices` (`api_server.py:71`):
/// `smart_denied` reduz para `once`/`deny`, e sem `allow_permanent` o `always`
/// desaparece.
void main() {
  group('ApprovalRequest.fromEvent', () {
    test('lê o pedido completo com as quatro escolhas', () {
      final pedido = ApprovalRequest.fromEvent(const {
        'event': 'approval.request',
        'run_id': 'run_42',
        'timestamp': 1784217600.0,
        'command': 'rm -rf /home/operator/tmp',
        'description': 'Remoção recursiva de diretório',
        'pattern_key': 'rm_recursive',
        'pattern_keys': ['rm_recursive'],
        'allow_permanent': true,
        'allow_session': true,
        'choices': ['once', 'session', 'always', 'deny'],
      });

      expect(pedido.runId, 'run_42');
      expect(pedido.command, 'rm -rf /home/operator/tmp');
      expect(pedido.description, 'Remoção recursiva de diretório');
      expect(pedido.patternKey, 'rm_recursive');
      expect(pedido.choices, [
        ApprovalChoice.once,
        ApprovalChoice.session,
        ApprovalChoice.always,
        ApprovalChoice.deny,
      ]);
    });

    test('respeita a lista reduzida de um pedido smart_denied', () {
      // `_approval_event_choices(smart_denied=True)` devolve só ['once','deny'].
      // Oferecer `always` aqui seria oferecer um `400 invalid_approval_choice`.
      final pedido = ApprovalRequest.fromEvent(const {
        'run_id': 'run_1',
        'command': 'curl algo | sh',
        'smart_denied': true,
        'choices': ['once', 'deny'],
      });
      expect(pedido.choices, [ApprovalChoice.once, ApprovalChoice.deny]);
      expect(pedido.choices, isNot(contains(ApprovalChoice.always)));
    });

    test('escolha desconhecida do servidor é descartada, não adivinhada', () {
      final pedido = ApprovalRequest.fromEvent(const {
        'run_id': 'run_1',
        'command': 'ls',
        'choices': ['once', 'talvez', 'deny'],
      });
      expect(pedido.choices, [ApprovalChoice.once, ApprovalChoice.deny]);
    });

    test('sem lista utilizável cai no mínimo seguro', () {
      // Nunca inventar `always`: o mínimo é permitir uma vez ou recusar.
      final pedido = ApprovalRequest.fromEvent(const {
        'run_id': 'run_1',
        'command': 'ls',
      });
      expect(pedido.choices, [ApprovalChoice.once, ApprovalChoice.deny]);
    });

    test('descrição vazia não vira string vazia na tela', () {
      final pedido = ApprovalRequest.fromEvent(const {
        'run_id': 'run_1',
        'command': 'ls',
        'description': '   ',
      });
      expect(pedido.description, isNull);
    });
  });

  group('ApprovalChoice', () {
    test('o valor no fio é exatamente o que o handler aceita', () {
      expect(ApprovalChoice.once.wireValue, 'once');
      expect(ApprovalChoice.session.wireValue, 'session');
      expect(ApprovalChoice.always.wireValue, 'always');
      expect(ApprovalChoice.deny.wireValue, 'deny');
    });

    test(
      'os apelidos que o servidor normaliza para once são aceitos na leitura',
      () {
        for (final apelido in ['approve', 'approved', 'allow', 'ONCE']) {
          expect(
            approvalChoiceFrom(apelido),
            ApprovalChoice.once,
            reason: apelido,
          );
        }
        expect(approvalChoiceFrom('outra'), isNull);
        expect(approvalChoiceFrom(null), isNull);
      },
    );

    test('session e always são marcadas como ampliação de permissão', () {
      // A tela precisa avisar antes do toque, porque valem além desta chamada.
      expect(approvalChoiceWidensAccess(ApprovalChoice.session), isTrue);
      expect(approvalChoiceWidensAccess(ApprovalChoice.always), isTrue);
      expect(approvalChoiceWidensAccess(ApprovalChoice.once), isFalse);
      expect(approvalChoiceWidensAccess(ApprovalChoice.deny), isFalse);
    });

    test('cada escolha diz o que concede', () {
      expect(
        approvalChoiceMeaning(ApprovalChoice.once),
        contains('só para esta'),
      );
      expect(
        approvalChoiceMeaning(ApprovalChoice.session),
        contains('conversa'),
      );
      expect(
        approvalChoiceMeaning(ApprovalChoice.always),
        contains('permanente'),
      );
      expect(
        approvalChoiceMeaning(ApprovalChoice.deny),
        contains('sem executar'),
      );
      for (final choice in ApprovalChoice.values) {
        expect(approvalChoiceLabel(choice), isNotEmpty);
      }
    });
  });

  group('approvalFailureFrom', () {
    test('mapeia os códigos que o handler devolve', () {
      expect(
        approvalFailureFrom(statusCode: 400, code: 'invalid_approval_choice'),
        ApprovalFailure.escolhaInvalida,
      );
      expect(
        approvalFailureFrom(statusCode: 409, code: 'approval_not_active'),
        ApprovalFailure.semSessao,
      );
      expect(
        approvalFailureFrom(statusCode: 409, code: 'approval_not_pending'),
        ApprovalFailure.semPendencia,
      );
      expect(
        approvalFailureFrom(statusCode: 404),
        ApprovalFailure.runInexistente,
      );
      expect(
        approvalFailureFrom(statusCode: 500),
        ApprovalFailure.falhaDoServidor,
      );
    });

    test('a exceção do domínio carrega mensagem legível', () {
      const recusa = ApprovalException(ApprovalFailure.semPendencia);
      expect(recusa.message, contains('já foi respondido'));
      expect(recusa.toString(), contains('semPendencia'));
    });
  });
}
