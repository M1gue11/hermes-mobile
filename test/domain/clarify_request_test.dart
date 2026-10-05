import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/domain/models/clarify_request.dart';

void main() {
  test(
    'normaliza batch sem perder perguntas válidas nem respostas de replay',
    () {
      final request = ClarifyRequest.fromGateway({
        'request_id': ' batch-1 ',
        'questions': [
          {
            'qid': 'q0',
            'question': ' Válida ',
            'choices': [' Sim ', '', 3],
          },
          {'qid': '', 'question': 'Inválida'},
          {
            'qid': 'q2',
            'question': 'Outra',
            'choices': ['a\nb'],
          },
          {'qid': 'q2', 'question': 'Duplicada'},
        ],
        'answers': {
          'q0': 'Sim',
          'q2': ['x', 'y'],
          'estranha': 'não',
        },
      });

      expect(request.isValid, isTrue);
      expect(request.questions.map((question) => question.id), ['q0', 'q2']);
      expect(request.questions.first.choices, ['Sim']);
      expect(request.questions.last.choices, isEmpty);
      expect(request.answers, {
        'q0': 'Sim',
        'q2': ['x', 'y'],
      });
    },
  );

  test('decodifica resposta JSON de multiselect no replay', () {
    final request = ClarifyRequest.fromGateway({
      'request_id': 'batch-json',
      'questions': [
        {
          'qid': 'q0',
          'question': 'Quais?',
          'choices': ['Web', 'Mobile'],
          'multi_select': true,
        },
      ],
      'answers': {'q0': '["Web","Mobile"]'},
    });

    expect(request.answers['q0'], ['Web', 'Mobile']);
  });

  test('sem questions o pedido é inválido: o gateway só manda batch', () {
    final request = ClarifyRequest.fromGateway({
      'request_id': 'single',
      'question': 'Qual formato?',
    });

    expect(request.questions, isEmpty);
    expect(request.isValid, isFalse);
  });

  group('edição de respostas travadas', () {
    ClarifyRequest batch({Map<String, Object?>? answers}) =>
        ClarifyRequest.fromGateway({
          'request_id': 'srq-1',
          'questions': [
            {'qid': 'q0', 'question': 'Primeira'},
            {'qid': 'q1', 'question': 'Segunda'},
            {'qid': 'q2', 'question': 'Terceira'},
          ],
          'answers': answers ?? const {'q0': 'A', 'q1': null},
        });

    test('resposta não nula é editável enquanto há pergunta pendente', () {
      final request = batch();

      expect(request.canEditAnswer('q0'), isTrue);
      // `null` é um skip confirmado.
      expect(request.canEditAnswer('q1'), isFalse);
      expect(request.canEditAnswer('q2'), isFalse);
    });

    test('sem pergunta pendente não edita', () {
      final completo = batch(answers: {'q0': 'A', 'q1': 'B', 'q2': 'C'});

      expect(completo.canEditAnswer('q0'), isFalse);
    });
  });
}
