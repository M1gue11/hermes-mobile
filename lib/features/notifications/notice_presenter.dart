import '../../domain/models/push_notice.dart';
import '../../domain/repositories/local_notifier.dart';
import '../settings/agent_persona.dart';

/// O que fazer com um [PushNotice] neste aparelho.
sealed class NoticeDecision {
  const NoticeDecision();
}

final class ShowNotice extends NoticeDecision {
  const ShowNotice(this.notice);
  final LocalNotice notice;
}

final class CancelNotice extends NoticeDecision {
  const CancelNotice(this.id);
  final int id;
}

final class IgnoreNotice extends NoticeDecision {
  const IgnoreNotice();
}

/// Decide e redige o aviso. [viewing] é verdadeiro quando a pessoa está com
/// esta conversa aberta na tela: ali a resposta e o cartão de aprovação já
/// aparecem, e um aviso por cima só atrapalha.
NoticeDecision decideNotice(
  PushNotice notice, {
  required AgentPersona persona,
  bool viewing = false,
}) {
  final id = noticeSlotId(notice.slot);
  if (notice.clearsSlot) return CancelNotice(id);
  if (viewing && notice.kind != PushNoticeKind.test) {
    return const IgnoreNotice();
  }
  final title = switch (notice.kind) {
    PushNoticeKind.turnCompleted => persona.noticeReplied,
    PushNoticeKind.turnFailed => persona.noticeFailed,
    PushNoticeKind.turnInterrupted => 'Turno interrompido',
    PushNoticeKind.inputRequested => switch (notice.input) {
      PushInputKind.clarify => persona.noticeQuestion,
      PushInputKind.sudo => persona.noticeSudo,
      _ => persona.noticeApproval,
    },
    PushNoticeKind.test => 'Notificações ativas',
    PushNoticeKind.inputResolved => '',
  };
  final body = notice.kind == PushNoticeKind.test
      ? persona.noticeTestBody
      : notice.title ?? 'Toque para abrir a conversa.';
  return ShowNotice((
    id: id,
    title: title,
    body: body,
    payload: notice.sessionId.isEmpty
        ? null
        : conversationDeepLink(notice.sessionId),
    urgent: notice.needsAttention,
  ));
}

/// O mesmo esquema que o Android já abre (`hermes://app/chat/<id>`).
String conversationDeepLink(String sessionId) =>
    'hermes://app/chat/${Uri.encodeComponent(sessionId)}';
