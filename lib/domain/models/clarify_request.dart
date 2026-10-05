import 'dart:convert';

/// Resposta de uma pergunta de clarify.
///
/// Perguntas comuns usam [String]; uma pergunta `multi_select` usa
/// `List<String>` na UI. No wire de `clarify.lock`, multi-select é JSON em uma
/// string, como exige o servidor. `null` é um skip confirmado.
typedef ClarifyAnswer = Object?;

class ClarifyQuestion {
  const ClarifyQuestion({
    required this.id,
    required this.question,
    this.choices = const [],
    this.multiSelect = false,
  });

  final String id;
  final String question;
  final List<String> choices;
  final bool multiSelect;
}

/// Pedido `clarify` que o Gateway TUI manda como server request JSON-RPC.
///
/// É sempre um batch de perguntas (`questions`), e cada uma é travada por
/// `clarify.lock`; o último lock resolve o pedido no servidor. [requestId] é o
/// `id` do envelope do server request. Em reconnect, [answers] contém as
/// respostas já travadas. Respostas não nulas podem ser editadas e travadas de
/// novo até a última pergunta; `null` representa skip e continua concluído.
class ClarifyRequest {
  const ClarifyRequest({
    required this.requestId,
    required this.questions,
    this.answers = const {},
  });

  final String requestId;
  final List<ClarifyQuestion> questions;
  final Map<String, ClarifyAnswer> answers;

  bool get isValid => requestId.isNotEmpty && questions.isNotEmpty;
  bool isAnswered(String questionId) => answers.containsKey(questionId);

  /// Uma resposta já travada (e não nula) pode ser editada enquanto o batch
  /// tem pergunta pendente; `null` é um skip confirmado e continua concluído.
  bool canEditAnswer(String questionId) =>
      isAnswered(questionId) &&
      answers[questionId] != null &&
      questions.any((question) => !isAnswered(question.id));

  ClarifyRequest withAnswer(String questionId, ClarifyAnswer answer) =>
      ClarifyRequest(
        requestId: requestId,
        questions: questions,
        answers: {...answers, questionId: answer},
      );

  factory ClarifyRequest.fromGateway(Map<String, dynamic> payload) {
    final questions = _questions(payload['questions']);
    return ClarifyRequest(
      requestId: _string(payload['request_id']),
      questions: questions,
      answers: _answers(payload['answers'], questions),
    );
  }

  static String _string(Object? value) => value is String ? value.trim() : '';

  /// Mesma normalização defensiva das referências Desktop/TUI: uma escolha
  /// inválida não torna a pergunta inválida, apenas abre resposta livre.
  static List<String> _choices(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<String>()
        .map((choice) => choice.trim())
        .where(
          (choice) =>
              choice.isNotEmpty &&
              choice.length <= 200 &&
              !choice.contains('\n'),
        )
        .toList(growable: false);
  }

  static List<ClarifyQuestion> _questions(Object? raw) {
    if (raw is! List) return const [];
    final seenIds = <String>{};
    final result = <ClarifyQuestion>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final row = Map<String, dynamic>.from(item);
      final id = _string(row['qid']);
      final question = _string(row['question']);
      // Duplicar qid deixaria o segundo cartão responder a mesma pergunta.
      if (id.isEmpty || question.isEmpty || !seenIds.add(id)) continue;
      final choices = _choices(row['choices']);
      result.add(
        ClarifyQuestion(
          id: id,
          question: question,
          choices: choices,
          multiSelect: row['multi_select'] == true && choices.isNotEmpty,
        ),
      );
    }
    return List.unmodifiable(result);
  }

  static Map<String, ClarifyAnswer> _answers(
    Object? raw,
    List<ClarifyQuestion> questions,
  ) {
    if (raw is! Map) return const {};
    final questionById = {
      for (final question in questions) question.id: question,
    };
    final result = <String, ClarifyAnswer>{};
    raw.forEach((key, value) {
      final id = _string(key);
      final question = questionById[id];
      if (question == null) return;
      if (value == null) {
        // The server uses null for an explicitly skipped/locked question.
        // Keeping the key is what makes reconnect not ask it again.
        result[id] = null;
      } else if (value is String) {
        if (question.multiSelect) {
          try {
            final decoded = jsonDecode(value);
            if (decoded is List && decoded.every((entry) => entry is String)) {
              result[id] = List<String>.unmodifiable(decoded.cast<String>());
              return;
            }
          } on FormatException {
            // A legacy server may have stored a plain string; keep it visible.
          }
        }
        result[id] = value;
      } else if (value is List && value.every((entry) => entry is String)) {
        result[id] = List<String>.unmodifiable(value.cast<String>());
      }
    });
    return Map.unmodifiable(result);
  }
}
