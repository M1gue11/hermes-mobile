import 'package:flutter/material.dart';

Future<String?> showRenameConversationDialog(
  BuildContext context, {
  required String currentTitle,
}) => showDialog<String>(
  context: context,
  builder: (_) => _RenameConversationDialog(currentTitle: currentTitle),
);

/// Mantém o campo vivo durante toda a animação de saída da rota.
class _RenameConversationDialog extends StatefulWidget {
  const _RenameConversationDialog({required this.currentTitle});

  final String currentTitle;

  @override
  State<_RenameConversationDialog> createState() =>
      _RenameConversationDialogState();
}

class _RenameConversationDialogState extends State<_RenameConversationDialog> {
  late final TextEditingController _input;

  bool get _canSave => _input.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _input = TextEditingController(text: widget.currentTitle)
      ..addListener(_refreshSaveState);
  }

  void _refreshSaveState() => setState(() {});

  void _save() {
    if (!_canSave) return;
    Navigator.pop(context, _input.text.trim());
  }

  @override
  void dispose() {
    _input
      ..removeListener(_refreshSaveState)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Renomear conversa'),
      content: TextField(
        key: const ValueKey('rename-conversation-field'),
        controller: _input,
        autofocus: true,
        maxLength: 120,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(labelText: 'Nome da conversa'),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _canSave ? _save : null,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
