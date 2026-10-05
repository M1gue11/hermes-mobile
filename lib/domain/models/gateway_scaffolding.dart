/// Reconhece turno `role: user` que **não** foi escrito por gente.
///
/// Observado no aparelho: uma bolha `VOCÊ` cujo texto começa com
/// `[Your active task list was preserved across context compression]`. Isso é
/// injeção do compressor de contexto, em inglês, persistida com papel de
/// usuário, e a tela a apresentava como se o dono do aparelho tivesse escrito
/// aquilo. Ver A23.
///
/// **Reconhecer por marcador de texto não é heurística nossa.** É o método do
/// próprio servidor, e ele explica por quê, em
/// `ContextCompressor._is_synthetic_compression_user_turn`:
///
/// > SessionDB preserves role/content but not underscore-prefixed metadata,
/// > so the stable todo and continuation content markers are authoritative.
///
/// Ou seja: os campos que marcariam o turno como sintético (`_todo_snapshot_
/// synthetic`, `_empty_recovery_synthetic`, a chave de metadado de sumário) são
/// de processo e **não sobrevivem à persistência**. Depois do banco, o marcador
/// de conteúdo é a fonte autoritativa, para o servidor e para nós.
///
/// Os prefixos abaixo saíram de `_SYNTHETIC_USER_PREFIXES`
/// (`agent/conversation_compression.py`), de `TODO_INJECTION_HEADER`
/// (`tools/todo_tool.py`) e de `SUMMARY_PREFIX`/`LEGACY_SUMMARY_PREFIX`
/// (`agent/context_compressor.py`) na versão `0.19.0`.
///
/// Alguns prefixos do servidor são mais longos do que os daqui: eles seguem com
/// um travessão U+2014, que este repositório não aceita em arquivo. Cortei no
/// último caractere seguro. O corte **não** afrouxa o reconhecimento de forma
/// perigosa: `[CONTEXT COMPACTION` e `[PRIOR CONTEXT` já são colchetes de
/// marcador de runtime, não texto que alguém digitaria numa conversa.
const gatewayScaffoldingPrefixes = <String>[
  // Injeção do compressor: a lista de tarefas preservada na compactação.
  '[Your active task list was preserved across context compression]',
  // Recuperação de resposta truncada ou de tool call perdida.
  '[System: Your previous response was truncated',
  '[System: The previous response was cut off',
  '[System: Your previous tool call',
  // Aviso de processo em segundo plano.
  '[IMPORTANT: Background process ',
  // Sumário de compactação, que o compressor às vezes fixa como `user` para
  // manter a alternância exigida pelos providers.
  '[CONTEXT COMPACTION',
  '[CONTEXT SUMMARY]:',
  '[PRIOR CONTEXT',
  '[END OF PRIOR CONTEXT',
];

/// Conteúdos que o servidor compara por igualdade, não por prefixo.
const gatewayScaffoldingExact = <String>[
  'Continue from the compressed conversation context above. '
      'This marker exists because no human user turn was available.',
  'Continue from the compressed conversation context above. '
      'This marker exists because the compacted transcript contained '
      'no preserved user turn.',
];

/// Este turno é andaime do runtime, e não fala de quem está usando o app?
bool isGatewayScaffolding(String text) {
  final limpo = text.trim();
  if (limpo.isEmpty) return false;
  if (gatewayScaffoldingExact.contains(limpo)) return true;
  return gatewayScaffoldingPrefixes.any(limpo.startsWith);
}

/// Partes apresentáveis de um payload que mistura andaime e fala real.
///
/// O compressor pode persistir o resumo sozinho ou fundi-lo ao primeiro turno
/// preservado para manter a alternância aceita pelo provider. O texto bruto
/// continua no modelo e volta ao servidor; este split serve somente à
/// apresentação, busca e cópia.
typedef GatewayScaffoldingContent = ({String injected, String visible});

const _summaryEndPrefix = '--- END OF CONTEXT SUMMARY';
const _priorContextPrefix = '[PRIOR CONTEXT';
const _priorContextEndPrefix = '[END OF PRIOR CONTEXT';

GatewayScaffoldingContent? splitGatewayScaffolding(String raw) {
  final text = raw.trimLeft();
  if (!isGatewayScaffolding(text)) return null;

  if (text.startsWith(_priorContextPrefix)) {
    final headerEnd = text.indexOf(']');
    final delimiter = headerEnd < 0
        ? -1
        : text.indexOf(_priorContextEndPrefix, headerEnd + 1);
    if (headerEnd >= 0 && delimiter >= 0) {
      final delimiterEnd = text.indexOf(']', delimiter);
      if (delimiterEnd >= 0) {
        final priorHeader = text.substring(0, headerEnd + 1).trim();
        final prior = text.substring(headerEnd + 1, delimiter).trim();
        final priorEnd = text.substring(delimiter, delimiterEnd + 1).trim();
        final summary = _splitSummaryEnd(
          text.substring(delimiterEnd + 1).trimLeft(),
        );
        return (
          injected: [
            priorHeader,
            priorEnd,
            summary.injected,
          ].where((part) => part.isNotEmpty).join('\n'),
          visible: [
            prior,
            summary.visible,
          ].where((part) => part.isNotEmpty).join('\n\n'),
        );
      }
    }
  }

  return _splitSummaryEnd(text);
}

GatewayScaffoldingContent _splitSummaryEnd(String text) {
  final marker = text.indexOf(_summaryEndPrefix);
  if (marker < 0) return (injected: text.trim(), visible: '');
  final lineEnd = text.indexOf('\n', marker);
  return (
    injected: text.substring(0, marker).trim(),
    visible: lineEnd < 0 ? '' : text.substring(lineEnd + 1).trim(),
  );
}

/// Rótulo curto do andaime, para a tela dizer o que entrou no contexto sem
/// despejar o texto inteiro.
///
/// Sem isto restariam duas opções ruins: mostrar tudo, que é o defeito atual, ou
/// esconder, que apagaria da leitura algo que de fato entrou no contexto do
/// agente e mudou a resposta seguinte.
String gatewayScaffoldingLabel(String text) {
  final limpo = text.trim();
  if (limpo.startsWith('[Your active task list was preserved')) {
    return 'lista de tarefas preservada na compactação';
  }
  if (limpo.startsWith('[CONTEXT COMPACTION') ||
      limpo.startsWith('[CONTEXT SUMMARY]:') ||
      limpo.startsWith('[PRIOR CONTEXT') ||
      limpo.startsWith('[END OF PRIOR CONTEXT')) {
    return 'resumo da conversa anterior';
  }
  if (limpo.startsWith('[System: Your previous response was truncated') ||
      limpo.startsWith('[System: The previous response was cut off')) {
    return 'aviso de resposta truncada';
  }
  if (limpo.startsWith('[System: Your previous tool call')) {
    return 'aviso de chamada de ferramenta perdida';
  }
  if (limpo.startsWith('[IMPORTANT: Background process ')) {
    return 'aviso de processo em segundo plano';
  }
  if (gatewayScaffoldingExact.contains(limpo)) {
    return 'retomada após compactação';
  }
  return 'contexto injetado pelo gateway';
}
