import 'package:flutter/foundation.dart';

/// Gênero gramatical usado somente pela voz da interface.
enum AgentGender {
  masculine('Masculino'),
  feminine('Feminino');

  const AgentGender(this.label);

  final String label;
}

/// Única fonte para nome, artigos e flexões visíveis da persona.
///
/// Referências técnicas ao produto, à API e ao runtime continuam sendo Hermes;
/// esta classe cobre apenas textos em que o aplicativo fala sobre o agente.
@immutable
class AgentPersona {
  const AgentPersona({this.name = '', this.gender});

  final String name;
  final AgentGender? gender;

  String get displayName {
    final normalized = name.trim();
    return normalized.isEmpty ? 'Hermes' : normalized;
  }

  String get uppercaseName => displayName.toUpperCase();

  String get composerHint => switch (gender) {
    AgentGender.feminine => 'Peça à $displayName…',
    AgentGender.masculine => 'Peça ao $displayName…',
    null => 'Fale com $displayName…',
  };

  String get clarificationSemantics => switch (gender) {
    AgentGender.feminine => 'A $displayName está te perguntando algo',
    AgentGender.masculine => 'O $displayName está te perguntando algo',
    null => '$displayName está te perguntando algo',
  };

  String get questionLabel => '$uppercaseName PERGUNTA';

  String get respondingSemantics => '$displayName está respondendo';

  String get imageNoteLabel => 'o que $displayName viu';
}
