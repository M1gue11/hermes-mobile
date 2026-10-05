import 'tool_call.dart';

/// O que o card de ferramentas mostra quando a lista é longa.
///
/// Observado ao verificar o A4: uma resposta que usou muitas ferramentas rende
/// um card de mais de vinte linhas que domina a thread e empurra o texto para
/// longe. O card é atividade de apoio, não a resposta.
///
/// Duas regras não negociáveis, e é por elas que isto é função pura e testada:
///
/// 1. **Linha que falhou nunca é escondida.** Colapsar é abreviar o que correu
///    bem; esconder um erro atrás de um "mais N" faria a tela mentir sobre o que
///    aconteceu.
/// 2. **Linha em execução nunca é escondida.** Ela é o que está acontecendo
///    agora, que é justamente o motivo de olhar o card durante uma run.
class ToolCardView {
  const ToolCardView({required this.visible, required this.hidden});

  /// Linhas a desenhar, na ordem original.
  final List<ToolCall> visible;

  /// Quantas ficaram de fora. Zero quando tudo aparece.
  final int hidden;

  bool get collapsed => hidden > 0;
}

/// Limite padrão de linhas visíveis com o card fechado.
const int toolCardCollapseLimit = 6;

ToolCardView toolCardView(
  List<ToolCall> tools, {
  bool expanded = false,
  int limit = toolCardCollapseLimit,
}) {
  // Esconder uma única linha não paga o custo de um controle a mais na tela.
  if (expanded || tools.length <= limit + 1) {
    return ToolCardView(visible: List<ToolCall>.unmodifiable(tools), hidden: 0);
  }

  final visible = <ToolCall>[];
  for (var index = 0; index < tools.length; index++) {
    final tool = tools[index];
    final obrigatoria =
        tool.status == ToolStatus.error || tool.status == ToolStatus.running;
    if (index < limit || obrigatoria) visible.add(tool);
  }
  return ToolCardView(
    visible: List<ToolCall>.unmodifiable(visible),
    hidden: tools.length - visible.length,
  );
}
