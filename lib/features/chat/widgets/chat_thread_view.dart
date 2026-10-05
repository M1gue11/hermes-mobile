import 'package:flutter/material.dart';

import '../../../core/theme/hermes_motion.dart';
import '../../../core/theme/hermes_tokens.dart';
import '../chat_thread_scroll_controller.dart';

typedef ChatThreadItemBuilder =
    Widget Function(BuildContext context, int chronologicalIndex);

// Até este ponto a thread ainda pode caber inteira no viewport. Shrink-wrap
// faz conversas curtas nascerem no topo; acima dele a lista volta ao caminho
// lazy normal. Com o espaçamento mínimo dos itens, 12 mensagens já excedem a
// altura útil dos telefones suportados, então a troca não produz salto visual.
const _topAlignedMessageLimit = 12;

/// Viewport cronológico da conversa.
class ChatThreadView extends StatefulWidget {
  const ChatThreadView({
    super.key,
    required this.messageCount,
    required this.scroll,
    required this.itemBuilder,
    required this.onJumpToEnd,
  });

  final int messageCount;
  final ChatThreadScrollController scroll;
  final ChatThreadItemBuilder itemBuilder;
  final VoidCallback onJumpToEnd;

  @override
  State<ChatThreadView> createState() => _ChatThreadViewState();
}

class _ChatThreadViewState extends State<ChatThreadView> {
  @override
  void initState() {
    super.initState();
    widget.scroll.scheduleFollowToEnd();
  }

  @override
  void didUpdateWidget(covariant ChatThreadView oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.scroll.scheduleFollowToEnd();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ChatThreadScrollState>(
      valueListenable: widget.scroll.state,
      builder: (context, scrollState, _) => Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: NotificationListener<ScrollMetricsNotification>(
              onNotification: (notification) {
                if (notification.depth == 0) {
                  widget.scroll.syncFollowToEnd();
                }
                return false;
              },
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification.depth != 0) return false;
                  final directDragStart =
                      notification is ScrollStartNotification &&
                      notification.dragDetails != null;
                  final directDragUpdate =
                      notification is ScrollUpdateNotification &&
                      notification.dragDetails != null;
                  if (directDragStart || directDragUpdate) {
                    widget.scroll.pauseFollowing();
                  }
                  return false;
                },
                child: ListView.builder(
                  key: const ValueKey('chat-thread'),
                  controller: widget.scroll.position,
                  shrinkWrap: widget.messageCount <= _topAlignedMessageLimit,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                  itemCount: widget.messageCount + 1,
                  itemBuilder: (context, chronologicalIndex) =>
                      widget.itemBuilder(context, chronologicalIndex),
                ),
              ),
            ),
          ),
          Positioned(
            right: 14,
            bottom: 12,
            child: _JumpToEnd(
              visible: !scrollState.following,
              missed: scrollState.missed,
              onTap: widget.onJumpToEnd,
            ),
          ),
        ],
      ),
    );
  }
}

/// Retorno ao fim oferecido apenas a quem subiu para reler.
class _JumpToEnd extends StatelessWidget {
  const _JumpToEnd({
    required this.visible,
    required this.missed,
    required this.onTap,
  });

  final bool visible;
  final int missed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final novidade = missed > 0;
    final cor = novidade ? t.accent : t.dim;
    final label = switch (missed) {
      0 => null,
      1 => '1 NOVA',
      _ => '$missed NOVAS',
    };

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: motionOf(context, HermesMotion.estado),
        curve: HermesMotion.curvaPadrao,
        child: Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                key: const ValueKey('jump-to-end'),
                padding: EdgeInsets.symmetric(
                  horizontal: novidade ? 13 : 9,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: t.surface,
                  border: Border.all(color: novidade ? t.accent : t.line),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: t.bg.withValues(alpha: 0.75),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (label != null) ...[
                      Text(
                        label,
                        style: t.mono.copyWith(
                          fontSize: 10.5,
                          letterSpacing: 0.9,
                          color: cor,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Icon(
                      Icons.keyboard_double_arrow_down,
                      size: 15,
                      color: cor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
