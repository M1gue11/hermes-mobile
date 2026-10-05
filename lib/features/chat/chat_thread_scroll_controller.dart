import 'package:flutter/widgets.dart';

/// Estado efêmero da navegação vertical de uma conversa.
@immutable
class ChatThreadScrollState {
  const ChatThreadScrollState({required this.following, required this.missed});

  const ChatThreadScrollState.atEnd() : following = true, missed = 0;

  final bool following;
  final int missed;

  @override
  bool operator ==(Object other) =>
      other is ChatThreadScrollState &&
      following == other.following &&
      missed == other.missed;

  @override
  int get hashCode => Object.hash(following, missed);
}

/// Controla quando a conversa deve acompanhar seu fim cronológico.
class ChatThreadScrollController {
  ChatThreadScrollController()
    : position = ScrollController(keepScrollOffset: false),
      state = ValueNotifier(const ChatThreadScrollState.atEnd());

  final ScrollController position;
  final ValueNotifier<ChatThreadScrollState> state;
  int _followEpoch = 0;
  int _scheduledEpoch = -1;

  bool get following => state.value.following;

  /// Suspende o acompanhamento por intenção explícita do usuário.
  ///
  /// A pausa é pegajosa: voltar fisicamente ao fim não a desfaz. Só
  /// uma ação explícita de retorno, um novo envio ou outra conversa reatam o
  /// acompanhamento.
  void pauseFollowing() {
    _cancelPendingFollow();
    _setPaused();
  }

  void _setPaused() {
    final current = state.value;
    if (!current.following) return;
    state.value = ChatThreadScrollState(
      following: false,
      missed: current.missed,
    );
  }

  /// Sincroniza o fim depois que o conteúdo terminar o layout deste quadro.
  ///
  /// Atualizações repetidas no mesmo quadro são agrupadas. Se a pessoa iniciar
  /// um gesto antes da callback, [pauseFollowing] invalida o pedido e nenhum
  /// ajuste programático acontece durante a releitura.
  void scheduleFollowToEnd() {
    if (!following) return;
    final epoch = _followEpoch;
    if (_scheduledEpoch == epoch) return;
    _scheduledEpoch = epoch;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scheduledEpoch == epoch) _scheduledEpoch = -1;
      if (epoch != _followEpoch || !following || !position.hasClients) return;
      syncFollowToEnd();
    });
  }

  /// Sincroniza uma métrica que já foi calculada pelo layout atual.
  ///
  /// [ScrollMetricsNotification] chega depois de a extensão mudar; nesse ponto
  /// não precisamos esperar outro quadro para alcançar a nova cauda.
  void syncFollowToEnd() {
    if (!following || !position.hasClients) return;
    final end = position.position.maxScrollExtent;
    if ((position.offset - end).abs() > 0.1) position.jumpTo(end);
  }

  void _cancelPendingFollow() {
    _followEpoch++;
    _scheduledEpoch = -1;
  }

  /// Uma conversa nova começa diretamente no fim, sem animação.
  void resetForConversation() {
    _cancelPendingFollow();
    state.value = const ChatThreadScrollState.atEnd();
    scheduleFollowToEnd();
  }

  void recordArrivals(int count) {
    if (count <= 0 || following) return;
    final current = state.value;
    state.value = ChatThreadScrollState(
      following: false,
      missed: current.missed + count,
    );
  }

  /// Volta ao fim estável da lista e pode ser interrompido por um novo gesto.
  Future<void> animateToEnd({
    required Duration duration,
    required Curve curve,
  }) async {
    _cancelPendingFollow();
    state.value = const ChatThreadScrollState.atEnd();
    if (!position.hasClients) {
      scheduleFollowToEnd();
      return;
    }
    final end = position.position.maxScrollExtent;
    if (duration == Duration.zero) {
      position.jumpTo(end);
    } else {
      await position.animateTo(end, duration: duration, curve: curve);
    }
    scheduleFollowToEnd();
  }

  void dispose() {
    _cancelPendingFollow();
    position.dispose();
    state.dispose();
  }
}
