/*
A70 DIRECTION CONTRACT
THESIS: a tool timeline reads as one sewn operational log, never stacked cards.
OWN-WORLD: warm paper, ivory prose, mono instrumentation, semantic amber.
STORY: order is immediate; state and evidence remain one tap away.
FIRST VIEWPORT: an endpoint-exact rail carries compact events into the answer.
FORM: “diário costurado”, delegated selection; seed a70-sewn-log.
FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, and DESIGN.md.
*/

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/design_scale.dart';
import '../../../core/theme/hermes_motion.dart';
import '../../../core/theme/hermes_tokens.dart';
import '../../../core/widgets/code_surface.dart';
import '../../../domain/models/approval_request.dart';
import '../../../domain/models/attachment_envelope.dart';
import '../../../domain/models/chat_message.dart';
import '../../../domain/models/clarify_request.dart';
import '../../../domain/models/gateway_scaffolding.dart';
import '../../../domain/models/hermes_failure.dart';
import '../../../domain/models/model_selection.dart';
import '../../../domain/models/plain_text.dart';
import '../../../domain/models/tool_call.dart';
import '../../../domain/models/tool_card_view.dart';
import '../../../domain/models/turn_activity.dart';
import '../../settings/agent_persona.dart';
import '../tool_duration_formatter.dart';
import 'attachment_card.dart';
import 'hermes_markdown.dart';

/// Linha de metadados (mono, maiúsculas): "VOCÊ · 09:37" / "HERMES · H4 70B · 09:38".
class _MetaLine extends StatelessWidget {
  const _MetaLine(this.label, {this.right});
  final String label;
  final String? right;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final style = t.mono.copyWith(
      fontSize: 10,
      letterSpacing: 0.8,
      color: t.faint,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label.toUpperCase(), style: style.copyWith(color: t.dim)),
        if (right != null) ...[
          const SizedBox(width: 8),
          Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(color: t.faint, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(right!.toUpperCase(), style: style),
        ],
      ],
    );
  }
}

/// Separador floral entre turnos (o "❦" do design).
class Fleuron extends StatelessWidget {
  const Fleuron({super.key});
  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    Widget line() => Container(width: 32, height: 1, color: t.line);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          line(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '❦',
              style: t.serif.copyWith(fontSize: 14, color: t.faint, height: 1),
            ),
          ),
          line(),
        ],
      ),
    );
  }
}

/// Mensagem do usuário: à direita, itálica, com filete de destaque.
///
/// Tem estado só para guardar a leitura do envelope de anexo: o corpo pode ter
/// 100 KB de arquivo dentro, e reanalisá-lo a cada quadro da rolagem sairia
/// caro. A análise refaz quando o texto muda, e mais nunca.
class UserBubble extends StatefulWidget {
  const UserBubble(
    this.message, {
    super.key,
    this.persona = const AgentPersona(),
  });
  final UserMessage message;
  final AgentPersona persona;

  @override
  State<UserBubble> createState() => _UserBubbleState();
}

class _UserBubbleState extends State<UserBubble> {
  AttachmentEnvelope? _envelope;

  @override
  void initState() {
    super.initState();
    _analisar();
  }

  @override
  void didUpdateWidget(UserBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.text != widget.message.text ||
        oldWidget.message.scaffolding != widget.message.scaffolding) {
      _analisar();
    }
  }

  void _analisar() {
    final message = widget.message;
    _envelope = message.scaffolding
        ? null
        : parseAttachmentEnvelope(message.text);
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    // Andaime do runtime não é fala: não ganha bolha, filete âmbar nem o
    // rótulo "Você". Ver A23.
    if (message.scaffolding) {
      final split = splitGatewayScaffolding(message.text);
      if (split == null || split.visible.isEmpty) {
        return _ScaffoldingNote(split?.injected ?? message.text);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ScaffoldingNote(split.injected),
          const SizedBox(height: 6),
          UserBubble(message.copyWith(text: split.visible, scaffolding: false)),
        ],
      );
    }
    final t = HermesTokens.of(context);
    final envelope = _envelope;
    // O corpo em si já vem escalado pelo `DesignTextScaler` da raiz; aqui a
    // escala serve só para o que ele não alcança (folga e recuo).
    final scale = designScaleOf(context);
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.85,
        ),
        child: Container(
          padding: EdgeInsets.only(right: 14 * scale),
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: t.accent.withValues(alpha: 0.55),
                width: 2,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _MetaLine('Você', right: message.time),
              SizedBox(height: 8 * scale),
              if (envelope == null)
                Text(
                  message.text,
                  textAlign: TextAlign.right,
                  style: t
                      .serifIn(FontWeight.w400, italic: true)
                      .copyWith(fontSize: 16, height: 1.6, color: t.ink),
                )
              else ...[
                // O envelope do runtime vira card, e o arquivo fica atrás de um
                // toque. Ver A24.
                for (final anexo in envelope.attachments)
                  AttachmentCard(
                    attachment: anexo,
                    captionMayBeInContent: envelope.captionMayBeInContent,
                    persona: widget.persona,
                  ),
                // Só sai como fala o que dá para separar com segurança. Quando
                // não dá, nenhuma linha é exibida: errar mostrando de menos, e
                // nunca pondo palavra na boca de quem escreveu.
                if (envelope.caption.isNotEmpty) ...[
                  SizedBox(height: 2 * scale),
                  Text(
                    envelope.caption,
                    textAlign: TextAlign.right,
                    style: t
                        .serifIn(FontWeight.w400, italic: true)
                        .copyWith(fontSize: 16, height: 1.6, color: t.ink),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Mensagem do assistant: meta, raciocínio, timeline de tools e corpo.
typedef TimelineInteractionCallback = VoidCallback;

class AssistantBubble extends StatelessWidget {
  const AssistantBubble(
    this.message, {
    super.key,
    this.spinner = 'helix',
    this.chronologicalActivity = true,
    this.persona = const AgentPersona(),
    this.onTimelineInteraction,
  });
  final AssistantMessage message;

  /// Estilo da marca braille escolhido em Aparência, usado no ponto de escrita.
  final String spinner;

  /// O cronológico preserva a ordem real; o consolidado segue disponível.
  final bool chronologicalActivity;
  final AgentPersona persona;
  final TimelineInteractionCallback? onTimelineInteraction;

  @override
  Widget build(BuildContext context) {
    final scaffolding = splitGatewayScaffolding(message.text);
    final visibleText = scaffolding?.visible ?? message.text;
    final active =
        message.phase == ChatPhase.reasoning ||
        message.phase == ChatPhase.writing;
    final hasPresentation =
        visibleText.isNotEmpty ||
        message.reasoning.isNotEmpty ||
        message.activity.isNotEmpty ||
        message.thinking.isNotEmpty ||
        message.activityItems.isNotEmpty ||
        message.reasonTime != null ||
        message.tools.isNotEmpty ||
        active ||
        message.phase == ChatPhase.failed ||
        message.phase == ChatPhase.cancelled;
    // Defesa para dados históricos incompletos: não há metadados/marca sem corpo.
    if (!hasPresentation) {
      return scaffolding == null
          ? const SizedBox.shrink()
          : _ScaffoldingNote(scaffolding.injected);
    }

    final t = HermesTokens.of(context);
    final failed = message.phase == ChatPhase.failed;
    final cancelled = message.phase == ChatPhase.cancelled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetaLine(
          persona.displayName,
          right: '${shortModelLabel(message.model)} · ${message.time ?? ''}',
        ),
        const SizedBox(height: 8),

        if (chronologicalActivity &&
            (message.activityItems.isNotEmpty || message.thinking.isNotEmpty))
          _ChronologicalTimeline(
            message: message,
            onInteraction: onTimelineInteraction,
          )
        else ...[
          if (message.reasoning.isNotEmpty ||
              message.activity.isNotEmpty ||
              message.thinking.isNotEmpty ||
              message.reasonTime != null)
            _ReasoningBlock(
              message: message,
              onInteraction: onTimelineInteraction,
            ),
          if (message.tools.isNotEmpty) ...[
            const SizedBox(height: 2),
            _ToolTimeline(
              tools: message.tools,
              onInteraction: onTimelineInteraction,
            ),
          ],
        ],

        if (scaffolding != null) ...[
          _ScaffoldingNote(scaffolding.injected),
          if (visibleText.isNotEmpty) const SizedBox(height: 8),
        ],

        // corpo
        //
        // A35: o mesmo widget desenha o parcial e o final. Antes o parcial era
        // `RichText` cru e, ao concluir, a árvore inteira era trocada por
        // markdown com fade e desfoque de 650ms: o parágrafo se reorganizava
        // enquanto aparecia. Agora o markdown existe desde o primeiro token e o
        // fim do turno só apaga a marca, sem refluxo e sem troca.
        if (failed)
          // Se o turno chegou a escrever algo antes de cair, o parcial fica: é
          // trabalho real do Hermes, e apagá-lo esconderia o que já foi dito.
          // Ver A7.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (visibleText.isNotEmpty) ...[
                HermesMarkdown(visibleText, persona: persona),
                const SizedBox(height: 8),
              ],
              _FailureLine(message.error),
            ],
          )
        // Enquanto o turno está ativo o corpo existe mesmo sem texto: é ele que
        // hospeda a marca, então o sinal de atividade é contínuo do raciocínio
        // até a última palavra.
        else if (visibleText.isNotEmpty || active)
          HermesMarkdown(
            visibleText,
            // A chave mantém o mesmo elemento quando um bloco de raciocínio ou
            // de ferramenta nasce acima: sem ela o `Column` casaria os filhos
            // por posição, jogaria fora o estado e o cache de blocos junto.
            key: const ValueKey('corpo-da-resposta'),
            streaming: active,
            spinner: spinner,
            persona: persona,
          )
        else
          const SizedBox.shrink(),

        if (cancelled)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Cancelado',
              style: t.mono.copyWith(fontSize: 11, color: t.faint),
            ),
          ),

        // Vale também para turno que falhou ou foi cancelado com texto
        // parcial: o que o Hermes chegou a escrever é trabalho dele e se copia
        // igual. Ver A33.
        if (!active && visibleText.trim().isNotEmpty)
          _CopyResponse(markdown: visibleText),
      ],
    );
  }
}

/// As duas formas de copiar a resposta, no fim dela.
///
/// Duas e não uma porque servem a usos diferentes: o **markdown** é o que o
/// agente escreveu, e é o que se cola de volta num editor, num commit ou noutra
/// conversa com ele. O **texto** é o que está na tela, e é o que se cola numa
/// mensagem para gente, onde `**` e `#` viram sujeira.
///
/// Fica no fim do turno, e não no cabeçalho, porque é o lugar onde a leitura
/// termina e onde a decisão de levar aquilo embora acontece.
class _CopyResponse extends StatelessWidget {
  const _CopyResponse({required this.markdown});

  final String markdown;

  Future<void> _copiar(BuildContext context, String valor, String oque) async {
    await Clipboard.setData(ClipboardData(text: valor));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$oque copiado')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('copiar-resposta'),
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          _CopyAction(
            key: const ValueKey('copiar-markdown'),
            icon: Icons.data_object,
            label: 'MARKDOWN',
            onTap: () => _copiar(context, markdown, 'Markdown'),
          ),
          const SizedBox(width: 16),
          _CopyAction(
            key: const ValueKey('copiar-texto'),
            icon: Icons.notes,
            label: 'TEXTO',
            onTap: () =>
                _copiar(context, markdownToPlainText(markdown), 'Texto'),
          ),
        ],
      ),
    );
  }
}

class _CopyAction extends StatelessWidget {
  const _CopyAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: t.faint),
            const SizedBox(width: 6),
            Text(
              label,
              style: t.mono.copyWith(
                fontSize: 9.5,
                letterSpacing: 1.4,
                color: t.faint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Prévia de atividade colapsável. Não representa raciocínio nativo do modelo.
class _ReasoningBlock extends StatefulWidget {
  const _ReasoningBlock({required this.message, this.onInteraction});
  final AssistantMessage message;
  final TimelineInteractionCallback? onInteraction;
  @override
  State<_ReasoningBlock> createState() => _ReasoningBlockState();
}

class _ReasoningBlockState extends State<_ReasoningBlock> {
  bool _open = false;

  void _toggleOpen() {
    widget.onInteraction?.call();
    setState(() => _open = !_open);
  }

  /// O estado transitório também segura o cabeçalho ao vivo: ele pode chegar
  /// depois que o texto começou a sair, e nesse momento ainda é o único sinal
  /// de que o Hermes está trabalhando.
  bool get _streaming =>
      widget.message.phase == ChatPhase.reasoning ||
      widget.message.thinking.isNotEmpty;
  String get _content => widget.message.activity.isNotEmpty
      ? widget.message.activity
      : widget.message.reasoning;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final open = (_streaming || _open) && _content.isNotEmpty;
    // O kaomoji do gateway é o rótulo enquanto dura. Quando ele é limpo, o
    // cabeçalho volta ao texto padrão em vez de ficar preso no último estado.
    final liveLabel = widget.message.thinking.isEmpty
        ? 'Atividade…'
        : widget.message.thinking;
    final headerStyle = t.mono.copyWith(
      fontSize: 10.5,
      letterSpacing: 0.6,
      color: t.dim,
    );

    final header = InkWell(
      onTap: _streaming ? null : _toggleOpen,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.psychology_alt_outlined, size: 13, color: t.accent),
          const SizedBox(width: 7),
          if (_streaming)
            Flexible(
              child: _ThinkingPlaceholderText(
                text: liveLabel,
                style: headerStyle,
              ),
            )
          else ...[
            Text(
              'Atividade${widget.message.reasonTime != null ? ' · ${widget.message.reasonTime}' : ' · histórico'}'
                  .toUpperCase(),
              style: headerStyle,
            ),
            const SizedBox(width: 4),
            AnimatedRotation(
              turns: open ? 0.5 : 0,
              // Mesma duracao do corpo que se abre logo abaixo: seta e
              // conteudo sao o mesmo gesto, e terminar em tempos diferentes
              // fazia a seta chegar antes do texto.
              duration: motionOf(context, HermesMotion.revelar),
              curve: HermesMotion.curvaPadrao,
              child: Icon(Icons.keyboard_arrow_down, size: 14, color: t.faint),
            ),
          ],
        ],
      ),
    );

    final body = AnimatedSize(
      duration: motionOf(context, HermesMotion.revelar),
      curve: HermesMotion.curvaPadrao,
      alignment: Alignment.topLeft,
      child: open
          ? Padding(
              padding: const EdgeInsets.only(top: 8, left: 12),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: t.line, width: 2)),
                ),
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  _content,
                  style: t
                      .serifIn(FontWeight.w400, italic: true)
                      .copyWith(fontSize: 13.5, height: 1.62, color: t.dim),
                ),
              ),
            )
          : const SizedBox(width: double.infinity),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [header, body],
      ),
    );
  }
}

/// Diário do turno no modo cronológico.
///
/// A linha é uma estrutura única, não uma pilha de cards: notas e ferramentas
/// mantêm a densidade do Hermes Desktop e a posição em que chegaram no stream.
class _ChronologicalTimeline extends StatelessWidget {
  const _ChronologicalTimeline({required this.message, this.onInteraction});

  final AssistantMessage message;
  final TimelineInteractionCallback? onInteraction;

  @override
  Widget build(BuildContext context) {
    final items = message.activityItems;
    final total = items.length + (message.thinking.isEmpty ? 0 : 1);
    final events = <Widget>[];
    final latestRunningToolIndex = message.thinking.isNotEmpty
        ? -1
        : items.lastIndexWhere(
            (item) =>
                item is TurnToolActivity &&
                item.tool.status == ToolStatus.running,
          );

    for (var index = 0; index < items.length; index++) {
      final first = index == 0;
      final last = index == total - 1;
      events.add(switch (items[index]) {
        TurnActivityPreview(:final id, :final text) => _ChronologicalNote(
          key: ValueKey('turn-activity-$id'),
          label: 'Atividade',
          text: text,
          active:
              index == items.length - 1 && message.phase == ChatPhase.reasoning,
          duration: index == items.length - 1 ? message.reasonTime : null,
          first: first,
          last: last,
          reasoning: false,
          onInteraction: onInteraction,
        ),
        TurnReasoning(:final id, :final text) => _ChronologicalNote(
          key: ValueKey('turn-reasoning-$id'),
          label: 'Raciocínio',
          text: text,
          active: false,
          duration: index == items.length - 1 ? message.reasonTime : null,
          first: first,
          last: last,
          reasoning: true,
          onInteraction: onInteraction,
        ),
        TurnToolActivity(:final id, :final tool) => _ToolEventRow(
          key: ValueKey('turn-tool-$id'),
          eventId: id,
          tool: tool,
          first: first,
          last: last,
          animateLive: index == latestRunningToolIndex,
          onInteraction: onInteraction,
        ),
      });
    }

    // Fecha a linha com o estado de agora. Não entra em [TurnActivity]: some
    // quando o gateway o limpa e, portanto, não reaparece como histórico.
    if (message.thinking.isNotEmpty) {
      events.add(
        _ChronologicalThinking(
          text: message.thinking,
          first: items.isEmpty,
          last: true,
        ),
      );
    }

    return Padding(
      key: const ValueKey('chronological-turn-activity'),
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: events,
      ),
    );
  }
}

/// O kaomoji do `thinking.delta` enquanto ele vale.
///
/// Fica fora de [TurnActivity] de propósito: é estado do turno em execução, e
/// entrar na lista era o que empilhava quatro kaomojis permanentes que a
/// conversa reaberta nunca teve.
class _ChronologicalThinking extends StatelessWidget {
  const _ChronologicalThinking({
    required this.text,
    required this.first,
    required this.last,
  });

  final String text;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Semantics(
      liveRegion: true,
      label: 'Estado atual: $text',
      excludeSemantics: true,
      child: _TimelineEventFrame(
        first: first,
        last: last,
        marker: const _ReasoningTimelineMarker(active: true),
        header: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _ThinkingPlaceholderText(
              text: text,
              style: _noteLabelStyle(t),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChronologicalNote extends StatefulWidget {
  const _ChronologicalNote({
    super.key,
    required this.label,
    required this.text,
    required this.active,
    required this.duration,
    required this.first,
    required this.last,
    required this.reasoning,
    this.onInteraction,
  });

  final String label;
  final String text;
  final bool active;
  final String? duration;
  final bool first;
  final bool last;
  final bool reasoning;
  final TimelineInteractionCallback? onInteraction;

  @override
  State<_ChronologicalNote> createState() => _ChronologicalNoteState();
}

class _ChronologicalNoteState extends State<_ChronologicalNote> {
  bool _open = false;

  void _toggleOpen() {
    widget.onInteraction?.call();
    setState(() => _open = !_open);
  }

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final open = widget.active || _open;
    final formattedDuration = formatToolDuration(widget.duration);
    final suffix = formattedDuration == null ? '' : ' · $formattedDuration';
    final label = '${widget.label}$suffix';

    return Semantics(
      button: true,
      expanded: open,
      label: open ? 'Recolher $label' : 'Abrir $label',
      child: _TimelineEventFrame(
        first: widget.first,
        last: widget.last,
        marker: widget.reasoning
            ? _ReasoningTimelineMarker(active: widget.active)
            : widget.active
            ? const _LiveToolMarker()
            : const _NoteTimelineMarker(),
        markerExtent: widget.reasoning || widget.active ? 20 : 10,
        header: _TimelineTapSurface(
          onTap: widget.active ? null : _toggleOpen,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: _noteLabelStyle(
                      t,
                    ).copyWith(color: widget.active ? t.accent : t.dim),
                  ),
                ),
                if (widget.active)
                  Text(
                    'AGORA',
                    style: t.mono.copyWith(
                      fontSize: 9.5,
                      letterSpacing: 0.7,
                      color: t.accent,
                    ),
                  )
                else
                  _TimelineChevron(
                    key: ValueKey('turn-note-chevron-${widget.key}'),
                    open: open,
                  ),
              ],
            ),
          ),
        ),
        detail: _TimelineDisclosure(
          transitionKey: ValueKey('turn-note-transition-${widget.key}'),
          child: open
              ? Padding(
                  key: const ValueKey('turn-note-detail-open'),
                  padding: const EdgeInsets.only(right: 4, bottom: 7),
                  child: Text(
                    widget.text,
                    style: t
                        .serifIn(FontWeight.w400, italic: true)
                        .copyWith(fontSize: 13.5, height: 1.55, color: t.dim),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

TextStyle _noteLabelStyle(HermesTokens t) => t
    .serifIn(FontWeight.w600)
    .copyWith(fontSize: 13.5, height: 1.25, color: t.dim);

class _ThinkingPlaceholderText extends StatelessWidget {
  const _ThinkingPlaceholderText({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final baseColor = Color.lerp(t.accent, t.dim, 0.28)!;
    final label = Text(
      text,
      style: style.copyWith(color: baseColor),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    if (reduceMotionOf(context)) return label;

    return label
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: HermesMotion.brilho,
          curve: Curves.linear,
          color: t.ink,
          angle: 0,
          padding: 0,
        );
  }
}

/// Feedback de toque sem a mancha retangular do splash Material.
///
/// O diário já tem trilho e marcadores como materialidade; preencher a linha
/// inteira ao pressionar cria um card que não existe. O gesto responde com um
/// deslocamento curto e perda mínima de tinta, preservando hover, foco e teclado.
class _TimelineTapSurface extends StatefulWidget {
  const _TimelineTapSurface({
    super.key,
    required this.onTap,
    required this.child,
  });

  final VoidCallback? onTap;
  final Widget child;

  @override
  State<_TimelineTapSurface> createState() => _TimelineTapSurfaceState();
}

class _TimelineTapSurfaceState extends State<_TimelineTapSurface> {
  bool _pressed = false;
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final enabled = widget.onTap != null;
    return InkWell(
      onTap: widget.onTap,
      onHighlightChanged: enabled
          ? (pressed) => setState(() => _pressed = pressed)
          : null,
      onHover: enabled ? (hovered) => setState(() => _hovered = hovered) : null,
      onFocusChange: enabled
          ? (focused) => setState(() => _focused = focused)
          : null,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: motionOf(context, HermesMotion.estado),
        curve: HermesMotion.curvaPadrao,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: _focused
                  ? t.accent.withValues(alpha: 0.62)
                  : Colors.transparent,
            ),
          ),
        ),
        child: AnimatedSlide(
          offset: _pressed ? const Offset(0.004, 0) : Offset.zero,
          duration: motionOf(context, HermesMotion.toque),
          curve: HermesMotion.curvaToque,
          child: AnimatedOpacity(
            opacity: _pressed ? 0.82 : (_hovered ? 0.94 : 1),
            duration: motionOf(context, HermesMotion.toque),
            curve: HermesMotion.curvaToque,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _TimelineChevron extends StatelessWidget {
  const _TimelineChevron({super.key, required this.open});

  final bool open;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return SizedBox(
      width: 28,
      child: Align(
        alignment: Alignment.centerRight,
        child: AnimatedRotation(
          turns: open ? 0.5 : 0,
          duration: motionOf(
            context,
            open
                ? HermesMotion.revelar
                : HermesMotion.saidaDe(HermesMotion.revelar),
          ),
          curve: open ? HermesMotion.curvaChegada : HermesMotion.curvaPadrao,
          child: Icon(Icons.keyboard_arrow_down, size: 15, color: t.dim),
        ),
      ),
    );
  }
}

/// Uma única gramática de divulgação para notas e evidência técnica.
///
/// Só a altura muda. O conteúdo nasce imediatamente no fluxo, sem fade, slide
/// ou sobreposição concorrendo com o layout. Ao fechar, a última tinta continua
/// montada e é recortada junto da altura; ela só sai da árvore no fim. Com
/// redução de movimento, o estado troca diretamente, sem criar um render
/// animado de duração zero.
class _TimelineDisclosure extends StatefulWidget {
  const _TimelineDisclosure({required this.transitionKey, required this.child});

  final Key transitionKey;
  final Widget? child;

  @override
  State<_TimelineDisclosure> createState() => _TimelineDisclosureState();
}

class _TimelineDisclosureState extends State<_TimelineDisclosure>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _heightFactor;
  Widget? _retainedChild;
  bool? _reduceMotion;

  @override
  void initState() {
    super.initState();
    _retainedChild = widget.child;
    _controller = AnimationController(
      vsync: this,
      duration: HermesMotion.revelar,
      reverseDuration: HermesMotion.saidaDe(HermesMotion.revelar),
      value: widget.child == null ? 0 : 1,
    )..addStatusListener(_handleStatus);
    _heightFactor = CurvedAnimation(
      parent: _controller,
      curve: HermesMotion.curvaPadrao,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = reduceMotionOf(context);
    if (reduced == _reduceMotion) return;
    _reduceMotion = reduced;
    _controller.stop();
    _controller.value = widget.child == null ? 0 : 1;
    _retainedChild = widget.child;
  }

  @override
  void didUpdateWidget(covariant _TimelineDisclosure oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_reduceMotion ?? reduceMotionOf(context)) {
      _controller.stop();
      _controller.value = widget.child == null ? 0 : 1;
      _retainedChild = widget.child;
      return;
    }
    if (widget.child != null) {
      _retainedChild = widget.child;
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _handleStatus(AnimationStatus status) {
    if (status != AnimationStatus.dismissed ||
        widget.child != null ||
        _retainedChild == null ||
        !mounted) {
      return;
    }
    setState(() => _retainedChild = null);
  }

  @override
  void dispose() {
    _heightFactor.dispose();
    _controller
      ..removeStatusListener(_handleStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const closed = SizedBox(
      key: ValueKey('timeline-detail-closed'),
      width: double.infinity,
    );
    if (_reduceMotion ?? reduceMotionOf(context)) {
      return KeyedSubtree(
        key: widget.transitionKey,
        child: widget.child ?? closed,
      );
    }
    return AnimatedBuilder(
      key: widget.transitionKey,
      animation: _heightFactor,
      child: SizedBox(width: double.infinity, child: _retainedChild ?? closed),
      builder: (context, child) => ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: _heightFactor.value,
          child: child,
        ),
      ),
    );
  }
}

class _ToolEventRow extends StatefulWidget {
  const _ToolEventRow({
    super.key,
    required this.eventId,
    required this.tool,
    required this.first,
    required this.last,
    this.animateLive = false,
    this.onInteraction,
  });

  final String eventId;
  final ToolCall tool;
  final bool first;
  final bool last;
  final bool animateLive;
  final TimelineInteractionCallback? onInteraction;

  @override
  State<_ToolEventRow> createState() => _ToolEventRowState();
}

class _ToolEventRowState extends State<_ToolEventRow> {
  bool _open = false;

  void _toggleOpen() {
    widget.onInteraction?.call();
    setState(() => _open = !_open);
  }

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final tool = widget.tool;
    final running = tool.status == ToolStatus.running;
    final error = tool.status == ToolStatus.error;
    final visibleStatus = running ? 'EXEC' : (error ? 'ERRO' : null);
    final semanticsStatus = running
        ? 'em execução'
        : (error ? 'com erro' : 'concluída');
    final metaColor = running ? t.accent : (error ? _toolErrorColor(t) : t.dim);
    final duration = formatToolDuration(tool.duration);
    final hasDetails =
        tool.detail?.trim().isNotEmpty == true ||
        tool.output?.trim().isNotEmpty == true;
    final semanticsDuration = duration == null ? '' : ', duração $duration';

    return Semantics(
      button: hasDetails,
      expanded: hasDetails ? _open : null,
      label: hasDetails
          ? '${_open ? 'Recolher' : 'Abrir'} ferramenta ${tool.name}, '
                '$semanticsStatus$semanticsDuration'
          : 'Ferramenta ${tool.name}, $semanticsStatus$semanticsDuration',
      child: _TimelineEventFrame(
        first: widget.first,
        last: widget.last,
        marker: _ToolStatusMarker(
          status: tool.status,
          animateLive: widget.animateLive,
        ),
        header: _TimelineTapSurface(
          key: ValueKey('turn-tool-toggle-${widget.eventId}'),
          onTap: hasDetails ? _toggleOpen : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      key: ValueKey(
                        'turn-tool-content-column-${widget.eventId}',
                      ),
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          key: ValueKey(
                            'turn-tool-primary-row-${widget.eventId}',
                          ),
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            _ToolKindIcon(tool.name),
                            const SizedBox(width: 7),
                            Expanded(child: _ToolName(tool.name)),
                            if (visibleStatus != null || duration != null) ...[
                              const SizedBox(width: 8),
                              _ToolStatusMeta(
                                status: visibleStatus,
                                duration: duration,
                                color: metaColor,
                              ),
                            ],
                          ],
                        ),
                        if (tool.arg.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: _ToolArgument(
                              tool.arg,
                              key: ValueKey(
                                'turn-tool-preview-${widget.eventId}',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (hasDetails)
                    _TimelineChevron(
                      key: ValueKey(
                        'turn-tool-chevron-column-${widget.eventId}',
                      ),
                      open: _open,
                    ),
                ],
              ),
            ),
          ),
        ),
        detail: _TimelineDisclosure(
          transitionKey: ValueKey(
            'turn-tool-detail-transition-${widget.eventId}',
          ),
          child: _open && hasDetails
              ? _ToolDetails(
                  key: ValueKey('turn-tool-detail-${widget.eventId}'),
                  tool: tool,
                )
              : null,
        ),
      ),
    );
  }
}

enum _ToolKind {
  terminal,
  readFile,
  writeFile,
  patch,
  web,
  vision,
  skill,
  other,
}

_ToolKind _toolKindFor(String rawName) {
  final name = rawName.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '_');
  if ({
    'terminal',
    'shell',
    'shell_command',
    'exec_command',
    'execute_code',
    'run_command',
  }.contains(name)) {
    return _ToolKind.terminal;
  }
  if ({'read_file', 'file_read', 'get_file', 'open_file'}.contains(name)) {
    return _ToolKind.readFile;
  }
  if ({'write_file', 'create_file', 'save_file'}.contains(name)) {
    return _ToolKind.writeFile;
  }
  if (name == 'patch' || name == 'apply_patch' || name == 'edit_file') {
    return _ToolKind.patch;
  }
  if ({
    'vision_analyse',
    'vision_analyze',
    'image_analyse',
    'image_analyze',
    'view_image',
  }.contains(name)) {
    return _ToolKind.vision;
  }
  if ({'skill_view', 'skill_read', 'skills_read'}.contains(name)) {
    return _ToolKind.skill;
  }
  if (name == 'web_search' ||
      name == 'web_run' ||
      name.startsWith('browser_') ||
      name == 'open_url' ||
      name == 'fetch_url') {
    return _ToolKind.web;
  }
  return _ToolKind.other;
}

class _ToolKindIcon extends StatelessWidget {
  const _ToolKindIcon(this.toolName);

  final String toolName;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final kind = _toolKindFor(toolName);
    final (keyName, icon) = switch (kind) {
      _ToolKind.terminal => ('terminal', Icons.terminal_rounded),
      _ToolKind.readFile => ('read-file', Icons.file_open_outlined),
      _ToolKind.writeFile => ('write-file', Icons.note_add_outlined),
      _ToolKind.patch => ('patch', Icons.difference_outlined),
      _ToolKind.web => ('web', Icons.travel_explore_outlined),
      _ToolKind.vision => ('vision', Icons.image_search_outlined),
      _ToolKind.skill => ('skill', Icons.auto_stories_outlined),
      _ToolKind.other => ('other', Icons.extension_outlined),
    };
    return ExcludeSemantics(
      child: Icon(
        icon,
        key: ValueKey('tool-kind-icon-$keyName'),
        size: 13,
        color: t.faint,
      ),
    );
  }
}

class _ToolName extends StatelessWidget {
  const _ToolName(this.name);
  final String name;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: t.mono.copyWith(fontSize: 11.5, color: t.ink),
    );
  }
}

class _ToolArgument extends StatelessWidget {
  const _ToolArgument(this.argument, {super.key});
  final String argument;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Text(
      argument,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: t.mono.copyWith(fontSize: 11.5, color: t.dim),
    );
  }
}

Color _toolErrorColor(HermesTokens t) => Color.lerp(t.accentInk, t.ink, 0.28)!;

class _ToolStatusMeta extends StatelessWidget {
  const _ToolStatusMeta({
    required this.status,
    required this.duration,
    required this.color,
  });

  final String? status;
  final String? duration;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final label = switch ((status, duration)) {
      (final status?, final duration?) => '$status · $duration',
      (final status?, null) => status,
      (null, final duration?) => duration,
      (null, null) => '',
    };
    return Text(
      label,
      maxLines: 1,
      textAlign: TextAlign.right,
      overflow: TextOverflow.fade,
      softWrap: false,
      style: t.mono.copyWith(fontSize: 9.5, letterSpacing: 0.55, color: color),
    );
  }
}

/// Une cabeçalho e detalhe sem deixar o trilho sobrar nas extremidades.
class _TimelineEventFrame extends StatelessWidget {
  const _TimelineEventFrame({
    required this.first,
    required this.last,
    required this.marker,
    required this.header,
    this.markerExtent = 20,
    this.detail,
  });

  final bool first;
  final bool last;
  final Widget marker;
  final Widget header;
  final double markerExtent;
  final Widget? detail;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final tail = detail ?? const SizedBox(height: 4);
    final showTail = detail != null || !last;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          width: 24,
          child: CustomPaint(
            key: const ValueKey('timeline-rail-canvas'),
            painter: TimelineRailPainter(
              first: first,
              last: last,
              markerExtent: markerExtent,
              color: t.line,
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 48,
              child: Center(
                child: ExcludeSemantics(
                  child: SizedBox.square(
                    key: const ValueKey('timeline-marker'),
                    dimension: markerExtent,
                    child: Center(child: marker),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  if (showTail)
                    Padding(
                      padding: EdgeInsets.only(bottom: last ? 0 : 4),
                      child: tail,
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Desenha um único filete por evento, sem emendas entre cabeçalho e detalhe.
///
/// O canvas abre apenas o respiro aprovado ao redor do marcador. O overshoot de
/// 1 dp nas bordas elimina frestas de rasterização entre eventos adjacentes.
class TimelineRailPainter extends CustomPainter {
  const TimelineRailPainter({
    required this.first,
    required this.last,
    required this.markerExtent,
    required this.color,
    this.markerGap = 3.5,
  });

  final bool first;
  final bool last;
  final double markerExtent;
  final Color color;
  final double markerGap;

  static const markerCenter = 24.0;

  double get beforeEnd => markerCenter - markerExtent / 2 - markerGap;
  double get afterStart => markerCenter + markerExtent / 2 + markerGap;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final rail = Paint()
      ..color = color
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.butt;
    if (!first) {
      canvas.drawLine(Offset(x, -1), Offset(x, beforeEnd), rail);
    }
    if (!last) {
      canvas.drawLine(Offset(x, afterStart), Offset(x, size.height + 1), rail);
    }
  }

  @override
  bool shouldRepaint(covariant TimelineRailPainter oldDelegate) =>
      first != oldDelegate.first ||
      last != oldDelegate.last ||
      markerExtent != oldDelegate.markerExtent ||
      markerGap != oldDelegate.markerGap ||
      color != oldDelegate.color;
}

class _NoteTimelineMarker extends StatelessWidget {
  const _NoteTimelineMarker();

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: t.dim,
        border: Border.all(color: t.surface, width: 2),
      ),
    );
  }
}

class _ReasoningTimelineMarker extends StatelessWidget {
  const _ReasoningTimelineMarker({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final color = active ? t.accent : t.dim;
    return SizedBox.square(
      dimension: 20,
      child: DecoratedBox(
        decoration: BoxDecoration(color: t.surface, shape: BoxShape.circle),
        child: Icon(
          Icons.psychology_alt_outlined,
          key: const ValueKey('reasoning-timeline-icon'),
          size: 15,
          color: color,
        ),
      ),
    );
  }
}

class _ToolStatusMarker extends StatelessWidget {
  const _ToolStatusMarker({required this.status, required this.animateLive});
  final ToolStatus status;
  final bool animateLive;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return SizedBox.square(
      dimension: 20,
      child: AnimatedSwitcher(
        duration: motionOf(context, HermesMotion.estado),
        switchInCurve: HermesMotion.curvaChegada,
        switchOutCurve: HermesMotion.curvaPadrao,
        child: switch (status) {
          ToolStatus.running => _LiveToolMarker(
            key: const ValueKey('tool-marker-running'),
            animate: animateLive,
          ),
          ToolStatus.done => Container(
            key: const ValueKey('tool-marker-done'),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: t.positive, width: 1.4),
            ),
            child: Icon(Icons.check_rounded, size: 13, color: t.positive),
          ),
          ToolStatus.error => Transform.rotate(
            key: const ValueKey('tool-marker-error'),
            angle: 0.785398,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: _toolErrorColor(t), width: 1.4),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Transform.rotate(
                angle: -0.785398,
                child: Icon(
                  Icons.priority_high_rounded,
                  size: 13,
                  color: _toolErrorColor(t),
                ),
              ),
            ),
          ),
        },
      ),
    );
  }
}

class _LiveToolMarker extends StatefulWidget {
  const _LiveToolMarker({super.key, this.animate = true});

  final bool animate;

  @override
  State<_LiveToolMarker> createState() => _LiveToolMarkerState();
}

class _LiveToolMarkerState extends State<_LiveToolMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: HermesMotion.brilho,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.animate || reduceMotionOf(context)) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _LiveToolMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.animate || reduceMotionOf(context)) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Container(
      key: ValueKey(
        widget.animate
            ? 'tool-marker-running-animated'
            : 'tool-marker-running-static',
      ),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: t.accent, width: 1.4),
        color: t.surface,
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final active = (_controller.value * 3).floor() % 3;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var index = 0; index < 3; index++) ...[
                if (index > 0) const SizedBox(width: 1.5),
                Container(
                  width: 2.5,
                  height: 2.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: t.accent.withValues(
                      alpha: index == active ? 1 : 0.28,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ToolDetails extends StatelessWidget {
  const _ToolDetails({super.key, required this.tool});
  final ToolCall tool;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final detailRaw = tool.detail?.trim() ?? '';
    final outputRaw = tool.output?.trimRight() ?? '';
    final detail = _toolDetailPresentation(
      '${tool.name == 'terminal' && detailRaw.isNotEmpty ? r'$ ' : ''}$detailRaw',
    );
    final output = _toolDetailPresentation(outputRaw);
    final labelStyle = _toolDetailLabelStyle(t);
    final codeStyle = _toolDetailCodeStyle(t, t.ink);
    final textScaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);

    double measuredTextHeight(String value, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: value, style: style),
        textDirection: direction,
        textScaler: textScaler,
      )..layout();
      return painter.height;
    }

    double sectionHeight(_ToolDetailPresentation section) =>
        measuredTextHeight(section.text, codeStyle) +
        measuredTextHeight('SAÍDA', labelStyle) +
        5;

    final hasDetail = detail.text.isNotEmpty;
    final hasOutput = output.text.isNotEmpty;
    final contentHeight =
        20 +
        (hasDetail ? sectionHeight(detail) : 0) +
        (hasDetail && hasOutput ? 12 : 0) +
        (hasOutput ? sectionHeight(output) : 0);
    final surfaceHeight = math.min(260.0, contentHeight.ceilToDouble());

    return Padding(
      padding: const EdgeInsets.only(top: 2, right: 2, bottom: 8),
      child: CodeSurface(
        key: const ValueKey('tool-details-code-surface'),
        child: SizedBox(
          height: surfaceHeight,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasDetail)
                  _ToolDetailSection(
                    label: 'ARGUMENTOS',
                    presentation: detail,
                    color: t.ink,
                  ),
                if (hasDetail && hasOutput) const SizedBox(height: 12),
                if (hasOutput)
                  _ToolDetailSection(
                    label: 'SAÍDA',
                    presentation: output,
                    color: tool.status == ToolStatus.error
                        ? _toolErrorColor(t)
                        : t.cStr,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolDetailSection extends StatelessWidget {
  const _ToolDetailSection({
    required this.label,
    required this.presentation,
    required this.color,
  });

  final String label;
  final _ToolDetailPresentation presentation;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _toolDetailLabelStyle(t)),
        const SizedBox(height: 5),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: presentation.structured
              ? SelectableText.rich(
                  HermesSyntaxHighlighter(
                    t,
                    fontSize: 11,
                    lineHeight: 1.55,
                    plainColor: color,
                  ).format(presentation.text),
                )
              : SelectableText(
                  presentation.text,
                  style: _toolDetailCodeStyle(t, color),
                ),
        ),
      ],
    );
  }
}

typedef _ToolDetailPresentation = ({String text, bool structured});

_ToolDetailPresentation _toolDetailPresentation(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return (text: '', structured: false);

  var candidate = text;
  final fenced = RegExp(
    r'^```(?:json)?\s*([\s\S]*?)\s*```$',
    caseSensitive: false,
  ).firstMatch(candidate);
  if (fenced != null) candidate = fenced.group(1)!.trim();

  try {
    final decoded = jsonDecode(candidate);
    if (decoded is Map || decoded is List) {
      const encoder = JsonEncoder.withIndent('  ');
      return (text: encoder.convert(decoded), structured: true);
    }
  } on FormatException {
    // Saídas de terminal e diffs continuam literais quando não são JSON válido.
  }
  return (text: text, structured: false);
}

TextStyle _toolDetailLabelStyle(HermesTokens t) =>
    t.mono.copyWith(fontSize: 9, letterSpacing: 1.2, color: t.dim);

TextStyle _toolDetailCodeStyle(HermesTokens t, Color color) =>
    t.mono.copyWith(fontSize: 11, height: 1.55, color: color);

/// Entrada e saída do pedido de aprovação na cauda da conversa.
///
/// O card nasce preso à borda inferior, junto do composer: ele se revela para
/// cima, sem fazer um botão atravessar o ponto onde o dedo já estava. Durante
/// qualquer movimento, toque e semântica ficam suspensos; uma decisão só pode
/// ser tomada depois que o card assentou por completo.
class ApprovalCardTransition extends StatelessWidget {
  const ApprovalCardTransition({
    super.key,
    required this.request,
    required this.onChoice,
    this.respondingTo,
  });

  final ApprovalRequest? request;
  final void Function(ApprovalChoice) onChoice;
  final ApprovalChoice? respondingTo;

  @override
  Widget build(BuildContext context) {
    // O card se revela ocupando espaço novo, então usa a duração de revelar do
    // desenho; a saída é metade dela, pela regra do A34. Antes eram 360 e 180
    // com uma curva própria, escritos aqui: números avulsos que ninguém mais no
    // app falava. Ver [HermesMotion].
    final entrada = motionOf(context, HermesMotion.revelar);
    final saida = motionOf(context, HermesMotion.saidaDe(HermesMotion.revelar));
    final current = request;
    final child = current == null
        ? const SizedBox.shrink(key: ValueKey('approval-card-absent'))
        : KeyedSubtree(
            key: ValueKey((
              current.runId,
              current.command,
              current.description,
              current.patternKey,
              current.choices.join(','),
            )),
            child: ApprovalCard(
              request: current,
              onChoice: onChoice,
              respondingTo: respondingTo,
            ),
          );

    return AnimatedSwitcher(
      key: const ValueKey('approval-card-transition'),
      duration: entrada,
      reverseDuration: saida,
      switchInCurve: HermesMotion.curvaChegada,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.bottomCenter,
        children: [...previousChildren, ?currentChild],
      ),
      transitionBuilder: (child, animation) {
        final reveal = ClipRect(
          child: SizeTransition(
            sizeFactor: animation,
            alignment: Alignment.bottomCenter,
            child: FadeTransition(opacity: animation, child: child),
          ),
        );
        return AnimatedBuilder(
          animation: animation,
          child: reveal,
          builder: (context, child) {
            final settled = animation.status == AnimationStatus.completed;
            return ExcludeSemantics(
              excluding: !settled,
              child: IgnorePointer(ignoring: !settled, child: child),
            );
          },
        );
      },
      child: child,
    );
  }
}

/// Pergunta bloqueante do gateway, no mesmo ponto de decisão da aprovação.
class ClarifyCardTransition extends StatelessWidget {
  const ClarifyCardTransition({
    super.key,
    required this.request,
    required this.onAnswer,
    this.respondingTo,
    this.error,
    this.persona = const AgentPersona(),
  });

  final ClarifyRequest? request;
  final void Function(String questionId, Object answer) onAnswer;
  final String? respondingTo;
  final String? error;
  final AgentPersona persona;

  @override
  Widget build(BuildContext context) {
    final current = request;
    final child = current == null
        ? const SizedBox.shrink(key: ValueKey('clarify-card-absent'))
        : ClarifyCard(
            key: ValueKey(current.requestId),
            request: current,
            onAnswer: onAnswer,
            respondingTo: respondingTo,
            error: error,
            persona: persona,
          );
    return AnimatedSwitcher(
      key: const ValueKey('clarify-card-transition'),
      duration: motionOf(context, HermesMotion.revelar),
      reverseDuration: motionOf(
        context,
        HermesMotion.saidaDe(HermesMotion.revelar),
      ),
      switchInCurve: HermesMotion.curvaChegada,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => ClipRect(
        child: SizeTransition(
          sizeFactor: animation,
          alignment: Alignment.bottomCenter,
          child: FadeTransition(opacity: animation, child: child),
        ),
      ),
      child: child,
    );
  }
}

class ClarifyCard extends StatefulWidget {
  const ClarifyCard({
    super.key,
    required this.request,
    required this.onAnswer,
    this.respondingTo,
    this.error,
    this.persona = const AgentPersona(),
  });

  final ClarifyRequest request;
  final void Function(String questionId, Object answer) onAnswer;
  final String? respondingTo;
  final String? error;
  final AgentPersona persona;

  @override
  State<ClarifyCard> createState() => _ClarifyCardState();
}

class _ClarifyCardState extends State<ClarifyCard> {
  final _answers = <String, TextEditingController>{};
  final _selected = <String, Set<String>>{};

  @override
  void initState() {
    super.initState();
    _prefillEditableAnswers(widget.request);
  }

  @override
  void didUpdateWidget(covariant ClarifyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _prefillEditableAnswers(widget.request, old: oldWidget.request);
  }

  @override
  void dispose() {
    for (final controller in _answers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _answerFor(String id) =>
      _answers.putIfAbsent(id, TextEditingController.new);

  bool _sameAnswer(Object? a, Object? b) =>
      a is List && b is List ? listEquals(a, b) : a == b;

  void _prefillEditableAnswers(ClarifyRequest request, {ClarifyRequest? old}) {
    for (final question in request.questions) {
      if (!request.canEditAnswer(question.id)) continue;
      final answer = request.answers[question.id]!;
      if (old != null &&
          old.canEditAnswer(question.id) &&
          _sameAnswer(old.answers[question.id], answer)) {
        continue;
      }
      final controller = _answerFor(question.id);
      final values = answer is List
          ? answer.whereType<String>().toList(growable: false)
          : <String>[];
      if (question.multiSelect) {
        final choices = values.where(question.choices.contains).toSet();
        _selected[question.id] = choices;
        final freeText = values
            .where((value) => !question.choices.contains(value))
            .join(', ');
        controller.text = freeText;
      } else {
        controller.text = answer is String ? answer : values.join(', ');
      }
    }
  }

  bool _respondingTo(String id) => widget.respondingTo == id;

  void _submit(ClarifyQuestion question, [String? choice]) {
    final id = question.id;
    if (_respondingTo(id)) return;
    if (question.multiSelect) {
      final selected = {...?_selected[id]};
      final typed = _answerFor(id).text.trim();
      if (typed.isNotEmpty) selected.add(typed);
      if (selected.isNotEmpty) {
        widget.onAnswer(id, List<String>.unmodifiable(selected));
      }
      return;
    }
    final answer = (choice ?? _answerFor(id).text).trim();
    if (answer.isNotEmpty) widget.onAnswer(id, answer);
  }

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final persona = widget.persona;
    return Semantics(
      container: true,
      liveRegion: true,
      label: persona.clarificationSemantics,
      child: Container(
        key: const ValueKey('clarify-card'),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: t.bg2,
          border: Border.all(color: t.accent, width: 1.5),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.question_answer_outlined, size: 14, color: t.accent),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    persona.questionLabel,
                    style: t.mono.copyWith(
                      fontSize: 9.5,
                      letterSpacing: 1.6,
                      color: t.accent,
                    ),
                  ),
                ),
                if (widget.respondingTo != null)
                  SizedBox.square(
                    dimension: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: t.accent,
                    ),
                  ),
              ],
            ),
            for (final question in widget.request.questions) ...[
              const SizedBox(height: 10),
              _question(t, question),
            ],
            if (widget.error?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                widget.error!,
                key: const ValueKey('clarify-error'),
                style: t.serif.copyWith(
                  fontSize: 13,
                  height: 1.4,
                  color: t.accentInk,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _question(HermesTokens t, ClarifyQuestion question) {
    final answered = widget.request.isAnswered(question.id);
    final editableLocked = widget.request.canEditAnswer(question.id);
    final prefix = '${question.id}-';
    if (answered && !editableLocked) {
      final answer = widget.request.answers[question.id];
      final text = answer == null
          ? 'Pergunta ignorada'
          : answer is List
          ? answer.join(', ')
          : '$answer';
      return Semantics(
        label: answer == null
            ? 'Pergunta ignorada: ${question.question}'
            : 'Pergunta concluída: ${question.question}. Resposta: $text',
        child: Text(
          '✓ ${question.question}\n$text',
          style: t.serif.copyWith(fontSize: 14, height: 1.45, color: t.dim),
        ),
      );
    }
    final selected = _selected.putIfAbsent(question.id, () => <String>{});
    final responding = _respondingTo(question.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.question,
          style: t.serif.copyWith(fontSize: 15, height: 1.5, color: t.ink),
        ),
        if (question.choices.isNotEmpty) ...[
          const SizedBox(height: 9),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final choice in question.choices)
                OutlinedButton(
                  key: ValueKey('clarify-choice-$prefix$choice'),
                  onPressed: responding
                      ? null
                      : () {
                          if (question.multiSelect) {
                            setState(
                              () => selected.contains(choice)
                                  ? selected.remove(choice)
                                  : selected.add(choice),
                            );
                          } else {
                            setState(
                              () => selected
                                ..clear()
                                ..add(choice),
                            );
                            _submit(question, choice);
                          }
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: t.ink,
                    minimumSize: const Size(48, 48),
                    side: BorderSide(
                      color: selected.contains(choice) ? t.accent : t.line,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                  ),
                  child: Text(choice),
                ),
            ],
          ),
        ],
        const SizedBox(height: 9),
        TextField(
          key: ValueKey('clarify-answer-$prefix'),
          controller: _answerFor(question.id),
          enabled: !responding,
          minLines: 1,
          maxLines: 4,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => _submit(question),
          style: t.serif.copyWith(fontSize: 16, color: t.ink),
          decoration: InputDecoration(
            hintText: 'Escreva sua resposta',
            suffixIcon: IconButton(
              key: ValueKey('clarify-submit-$prefix'),
              tooltip: question.multiSelect ? 'Enviar escolhas' : 'Responder',
              onPressed: responding ? null : () => _submit(question),
              icon: const Icon(Icons.arrow_upward_rounded),
            ),
          ),
        ),
      ],
    );
  }
}

/// Pedido de aprovação de execução de ferramenta.
///
/// Fica na thread, no lugar onde a decisão precisa ser tomada, e **nada é
/// aprovado por omissão**: enquanto ninguém toca, a run segue parada no servidor
/// com a thread do agente bloqueada.
///
/// O comando vem redigido pelo próprio Hermes; a tela mostra o que recebeu e não
/// tenta reconstruir nada. As escolhas também vêm do servidor por pedido, então
/// só aparece botão que ele aceita.
class ApprovalCard extends StatelessWidget {
  const ApprovalCard({
    super.key,
    required this.request,
    required this.onChoice,
    this.respondingTo,
  });

  final ApprovalRequest request;
  final void Function(ApprovalChoice) onChoice;
  final ApprovalChoice? respondingTo;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Container(
      key: const ValueKey('approval-card'),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: t.bg2,
        border: Border.all(color: t.accentInk, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, size: 14, color: t.accentInk),
              const SizedBox(width: 7),
              Text(
                'APROVAÇÃO NECESSÁRIA',
                style: t.mono.copyWith(
                  fontSize: 9.5,
                  letterSpacing: 1.6,
                  color: t.accentInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (request.description != null) ...[
            Text(
              request.description!,
              style: t.serif.copyWith(fontSize: 14, height: 1.5, color: t.ink),
            ),
            const SizedBox(height: 9),
          ],
          // O comando roda na horizontal em vez de quebrar: quem aprova precisa
          // ler exatamente o que vai executar.
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: t.codeBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              child: SelectableText(
                request.command,
                style: t.mono.copyWith(fontSize: 12, height: 1.5, color: t.ink),
              ),
            ),
          ),
          if (request.patternKey != null) ...[
            const SizedBox(height: 7),
            Text(
              'Regra: ${request.patternKey}',
              style: t.mono.copyWith(fontSize: 10, color: t.faint),
            ),
          ],
          const SizedBox(height: 12),
          for (final choice in request.choices)
            _ApprovalButton(
              choice: choice,
              busy: respondingTo == choice,
              onTap: respondingTo == null ? () => onChoice(choice) : null,
            ),
        ],
      ),
    );
  }
}

class _ApprovalButton extends StatelessWidget {
  const _ApprovalButton({
    required this.choice,
    required this.onTap,
    this.busy = false,
  });

  final ApprovalChoice choice;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final recusa = choice == ApprovalChoice.deny;
    // `session` e `always` concedem além desta chamada, então a tela avisa antes
    // do toque, não depois.
    final amplia = approvalChoiceWidensAccess(choice);
    final cor = recusa ? t.accentInk : (amplia ? t.accent : t.positive);

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('approval-${choice.wireValue}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: cor.withValues(alpha: 0.6)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (busy)
                      SizedBox.square(
                        dimension: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: cor,
                        ),
                      )
                    else
                      Icon(
                        recusa
                            ? Icons.block
                            : (amplia
                                  ? Icons.warning_amber_rounded
                                  : Icons.check),
                        size: 14,
                        color: cor,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      approvalChoiceLabel(choice),
                      style: t.serif.copyWith(fontSize: 14.5, color: cor),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.only(left: 22),
                  child: Text(
                    approvalChoiceMeaning(choice),
                    style: t.mono.copyWith(
                      fontSize: 10,
                      height: 1.4,
                      color: t.faint,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Nota de contexto que o runtime injetou como se fosse fala do usuário.
///
/// Três caminhos possíveis e por que este: **mostrar como bolha** é o defeito
/// original, porque atribui à pessoa um texto em inglês que ela não escreveu;
/// **esconder** apagaria da leitura algo que entrou no contexto do agente e
/// mudou a resposta seguinte; então fica uma nota discreta, centrada, que diz o
/// que foi injetado e abre sob toque para quem quiser ler o texto exato.
class _ScaffoldingNote extends StatefulWidget {
  const _ScaffoldingNote(this.text);
  final String text;

  @override
  State<_ScaffoldingNote> createState() => _ScaffoldingNoteState();
}

class _ScaffoldingNoteState extends State<_ScaffoldingNote> {
  bool _aberto = false;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Padding(
      key: const ValueKey('andaime-do-gateway'),
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: () => setState(() => _aberto = !_aberto),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.data_object, size: 12, color: t.faint),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      'CONTEXTO DO GATEWAY · ${gatewayScaffoldingLabel(widget.text).toUpperCase()}',
                      textAlign: TextAlign.center,
                      style: t.mono.copyWith(
                        fontSize: 9.5,
                        letterSpacing: 1.2,
                        color: t.faint,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _aberto ? Icons.expand_less : Icons.expand_more,
                    size: 13,
                    color: t.faint,
                  ),
                ],
              ),
              if (_aberto) ...[
                const SizedBox(height: 8),
                // O texto vai como veio, sem tradução: é o que o modelo leu.
                SelectableText(
                  widget.text,
                  style: t.mono.copyWith(
                    fontSize: 11,
                    height: 1.5,
                    color: t.dim,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A linha de falha de um turno, dentro da própria bolha.
///
/// Fica na bolha, e não numa tela de erro, porque a conversa continua: o resto
/// da thread segue legível e o composer segue aberto para tentar de novo com
/// outras palavras. Uma tela de erro por cima disso tiraria o contexto.
class _FailureLine extends StatelessWidget {
  const _FailureLine(this.error);
  final String? error;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Row(
      key: const ValueKey('turno-falhou'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline, size: 15, color: t.accentInk),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            error == null || error!.isEmpty
                ? const HermesFailure(
                    HermesFailureKind.respostaInesperada,
                  ).title
                : error!,
            style: t.serif.copyWith(
              fontSize: 15,
              color: t.accentInk,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

/// Timeline de tool calls, separada do texto final.
///
/// Colapsa sozinha quando fica longa. A regra de o que fica visível é do
/// domínio, em [toolCardView], porque "nunca esconder erro nem execução em
/// curso" é decisão de produto e merece teste, não um `take(6)` na árvore.
class _ToolTimeline extends StatefulWidget {
  const _ToolTimeline({required this.tools, this.onInteraction});
  final List<ToolCall> tools;
  final TimelineInteractionCallback? onInteraction;

  @override
  State<_ToolTimeline> createState() => _ToolTimelineState();
}

class _ToolTimelineState extends State<_ToolTimeline> {
  bool _expandido = false;

  void _toggleExpanded() {
    widget.onInteraction?.call();
    setState(() => _expandido = !_expandido);
  }

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final collapsedView = toolCardView(widget.tools);
    final latestRunning = widget.tools.lastIndexWhere(
      (tool) => tool.status == ToolStatus.running,
    );
    final collapsible = collapsedView.collapsed || _expandido;
    final leadingCount =
        collapsible && widget.tools.length > toolCardCollapseLimit
        ? toolCardCollapseLimit
        : widget.tools.length;
    final leadingIndexes = List<int>.generate(leadingCount, (index) => index);
    final trailingIndexes = <int>[
      for (var index = leadingCount; index < widget.tools.length; index++)
        if (_expandido ||
            widget.tools[index].status == ToolStatus.error ||
            widget.tools[index].status == ToolStatus.running)
          index,
    ];

    Widget rowsFor(List<int> indexes) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var position = 0; position < indexes.length; position++)
          _ToolEventRow(
            key: ValueKey(
              'consolidated-tool-'
              '${widget.tools[indexes[position]].id ?? indexes[position]}',
            ),
            eventId:
                'consolidated-'
                '${widget.tools[indexes[position]].id ?? indexes[position]}',
            tool: widget.tools[indexes[position]],
            first: position == 0,
            last: position == indexes.length - 1,
            animateLive: indexes[position] == latestRunning,
            onInteraction: widget.onInteraction,
          ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'FERRAMENTAS',
                style: t.mono.copyWith(
                  fontSize: 9.5,
                  letterSpacing: 1.6,
                  color: t.dim,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(child: Container(height: 1, color: t.line)),
              const SizedBox(width: 9),
              Text(
                '${widget.tools.length}',
                style: t.mono.copyWith(fontSize: 9.5, color: t.dim),
              ),
            ],
          ),
          const SizedBox(height: 4),
          rowsFor(leadingIndexes),
          if (collapsible) ...[
            _ToolCardToggle(
              key: const ValueKey('tool-card-toggle'),
              hidden: collapsedView.hidden,
              expanded: _expandido,
              onTap: _toggleExpanded,
            ),
            _TimelineDisclosure(
              transitionKey: const ValueKey('tool-card-list-transition'),
              child: rowsFor(trailingIndexes),
            ),
          ],
        ],
      ),
    );
  }
}

/// Controle de abrir e fechar o card longo. Diz **quantas** linhas estão
/// escondidas, porque "mostrar mais" sem número não deixa julgar se vale o
/// toque.
class _ToolCardToggle extends StatelessWidget {
  const _ToolCardToggle({
    super.key,
    required this.hidden,
    required this.expanded,
    required this.onTap,
  });
  final int hidden;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final rotulo = expanded
        ? 'MOSTRAR MENOS'
        : 'MAIS $hidden ${hidden == 1 ? 'FERRAMENTA' : 'FERRAMENTAS'}';
    return Padding(
      padding: const EdgeInsets.only(left: 32, top: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              Icon(
                expanded ? Icons.expand_less : Icons.expand_more,
                size: 14,
                color: t.dim,
              ),
              const SizedBox(width: 7),
              Text(
                rotulo,
                style: t.mono.copyWith(
                  fontSize: 9.5,
                  letterSpacing: 1.4,
                  color: t.dim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
