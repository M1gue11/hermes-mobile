import 'attachment_envelope.dart';
import 'chat_message.dart';
import 'gateway_scaffolding.dart';
import 'plain_text.dart';

/// Índices das mensagens carregadas que contêm [rawQuery].
///
/// A busca segue a apresentação, não o payload bruto: markdown vira texto de
/// leitura e um anexo contribui com nome e legenda, mas não com os bytes que
/// ficam escondidos atrás do card. Assim um resultado sempre aponta para algo
/// que a pessoa consegue reconhecer na própria conversa.
List<int> conversationSearchMatches(
  List<ChatMessage> messages,
  String rawQuery,
) {
  final query = _normalize(rawQuery);
  if (query.isEmpty) return const <int>[];

  return <int>[
    for (var index = 0; index < messages.length; index++)
      if (_normalize(_searchableText(messages[index])).contains(query)) index,
  ];
}

String _searchableText(ChatMessage message) => switch (message) {
  UserMessage(:final text, :final scaffolding) =>
    scaffolding ? _scaffoldingPresentation(text) : _userPresentation(text),
  AssistantMessage(
    :final text,
    :final reasoning,
    :final activity,
    :final tools,
    :final error,
  ) =>
    <String>[
      reasoning,
      activity,
      for (final tool in tools)
        '${tool.name} ${tool.arg} ${tool.detail ?? ''} ${tool.output ?? ''}',
      _assistantPresentation(text),
      error ?? '',
    ].join('\n'),
};

String _scaffoldingPresentation(String text) {
  final split = splitGatewayScaffolding(text);
  if (split == null) return '';
  return '${gatewayScaffoldingLabel(split.injected)}\n${split.visible}';
}

String _assistantPresentation(String text) {
  final split = splitGatewayScaffolding(text);
  if (split == null) return markdownToPlainText(text);
  return '${gatewayScaffoldingLabel(split.injected)}\n'
      '${markdownToPlainText(split.visible)}';
}

String _userPresentation(String text) {
  final envelope = parseAttachmentEnvelope(text);
  if (envelope == null) return text;
  return <String>[
    for (final attachment in envelope.attachments) attachment.name,
    envelope.caption,
  ].join('\n');
}

/// Comparação indulgente para português: ignora caixa, acentos e diferenças
/// de espaço/quebra de linha, sem depender de pacote novo.
String _normalize(String value) {
  const accents = <String, String>{
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'å': 'a',
    'ç': 'c',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ñ': 'n',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ý': 'y',
    'ÿ': 'y',
  };
  final folded = StringBuffer();
  for (final rune in value.toLowerCase().runes) {
    final character = String.fromCharCode(rune);
    folded.write(accents[character] ?? character);
  }
  return folded.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}
