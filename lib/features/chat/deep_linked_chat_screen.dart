import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/paper_texture.dart';
import '../../domain/models/conversation.dart';
import 'chat_controller.dart';
import 'chat_screen.dart';

/// Abre uma conversa identificada pela rota, sem criar uma sessão intermediária.
///
/// O deep link conhece no mínimo o id. Título, modelo e provider são opcionais:
/// notificações e atalhos internos podem fornecê-los para a primeira pintura,
/// enquanto links externos continuam úteis apenas com o identificador durável.
class DeepLinkedChatScreen extends ConsumerStatefulWidget {
  const DeepLinkedChatScreen({
    super.key,
    required this.conversationId,
    this.title,
    this.model,
    this.provider,
  });

  final String conversationId;
  final String? title;
  final String? model;
  final String? provider;

  @override
  ConsumerState<DeepLinkedChatScreen> createState() =>
      _DeepLinkedChatScreenState();
}

class _DeepLinkedChatScreenState extends ConsumerState<DeepLinkedChatScreen> {
  var _opened = false;

  @override
  void initState() {
    super.initState();
    _scheduleOpen();
  }

  @override
  void didUpdateWidget(DeepLinkedChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId != widget.conversationId) {
      _opened = false;
      _scheduleOpen();
    }
  }

  void _scheduleOpen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final title = widget.title?.trim();
      unawaited(
        ref
            .read(chatControllerProvider.notifier)
            .openConversation(
              Conversation(
                id: widget.conversationId,
                title: title == null || title.isEmpty ? 'Conversa' : title,
                model: widget.model,
                provider: widget.provider,
              ),
            ),
      );
      setState(() => _opened = true);
    });
  }

  @override
  Widget build(BuildContext context) =>
      _opened ? const ChatScreen() : const Scaffold(body: PaperTexture());
}
