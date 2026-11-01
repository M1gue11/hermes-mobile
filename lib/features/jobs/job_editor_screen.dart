import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/hermes_tokens.dart';
import '../../core/widgets/paper_texture.dart';
import '../../core/widgets/screen_top_bar.dart';
import 'job_labels.dart';
import 'jobs_provider.dart';

/// Criação de uma rotina. O servidor interpreta e valida a agenda; a recusa
/// dele aparece aqui sem fechar o formulário.
class JobEditorScreen extends ConsumerStatefulWidget {
  const JobEditorScreen({super.key});

  @override
  ConsumerState<JobEditorScreen> createState() => _JobEditorScreenState();
}

class _JobEditorScreenState extends ConsumerState<JobEditorScreen> {
  final _name = TextEditingController();
  final _schedule = TextEditingController();
  final _prompt = TextEditingController();
  late final _fields = Listenable.merge([_name, _schedule, _prompt]);
  var _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _schedule.dispose();
    _prompt.dispose();
    super.dispose();
  }

  bool get _dirty =>
      _name.text.trim().isNotEmpty ||
      _schedule.text.trim().isNotEmpty ||
      _prompt.text.trim().isNotEmpty;

  bool get _complete =>
      _name.text.trim().isNotEmpty &&
      _schedule.text.trim().isNotEmpty &&
      _prompt.text.trim().isNotEmpty;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(cronJobActionsProvider.notifier)
          .create(
            name: _name.text.trim(),
            schedule: _schedule.text.trim(),
            prompt: _prompt.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Rotina criada.')));
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = jobFailureText(error);
      });
    }
  }

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descartar rotina?'),
        content: const Text('O que você preencheu ainda não foi salvo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar editando'),
          ),
          FilledButton(
            key: const ValueKey('job-discard'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return ListenableBuilder(
      listenable: _fields,
      builder: (context, _) => PopScope(
        canPop: !_dirty && !_saving,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && !_saving) _confirmDiscard();
        },
        child: Scaffold(
          body: Stack(
            children: [
              const Positioned.fill(child: PaperTexture()),
              SafeArea(
                child: Column(
                  children: [
                    ScreenTopBar(
                      title: 'Nova rotina',
                      subtitle: 'AGENDAMENTO',
                      leadingIcon: Icons.close_rounded,
                      leadingTooltip: 'Fechar',
                      onLeading: () => Navigator.of(context).maybePop(),
                      actions: [
                        if (_saving)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            child: SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else
                          TextButton(
                            key: const ValueKey('job-save'),
                            onPressed: _complete ? _save : null,
                            child: const Text('Criar'),
                          ),
                      ],
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
                        children: [
                          if (_error case final error?)
                            Padding(
                              key: const ValueKey('job-save-error'),
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                'O Hermes recusou: $error',
                                style: t.serif.copyWith(
                                  fontSize: 14,
                                  height: 1.45,
                                  color: t.accentInk,
                                ),
                              ),
                            ),
                          _Field(
                            fieldKey: const ValueKey('job-name'),
                            controller: _name,
                            label: 'Nome',
                            hint: 'Resumo da manhã',
                            enabled: !_saving,
                          ),
                          const SizedBox(height: 16),
                          _Field(
                            fieldKey: const ValueKey('job-schedule'),
                            controller: _schedule,
                            label: 'Agenda',
                            hint: 'every monday 9am',
                            mono: true,
                            enabled: !_saving,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Exemplos: every 30m · every day at 9am · '
                            '0 9 * * 1-5 · 2026-12-01T09:00',
                            style: t.mono.copyWith(
                              fontSize: 10.5,
                              height: 1.5,
                              color: t.dim,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _Field(
                            fieldKey: const ValueKey('job-prompt'),
                            controller: _prompt,
                            label: 'Pedido',
                            hint: 'O que o agente deve fazer a cada execução',
                            minLines: 5,
                            enabled: !_saving,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'A rotina roda sem ninguém acompanhando e usa as '
                            'ferramentas liberadas no servidor.',
                            style: t.serif.copyWith(
                              fontSize: 13,
                              height: 1.45,
                              color: t.dim,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.hint,
    required this.enabled,
    this.mono = false,
    this.minLines = 1,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool enabled;
  final bool mono;
  final int minLines;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final style = (mono ? t.mono : t.serif).copyWith(
      fontSize: mono ? 13 : 15,
      color: t.ink,
    );
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: t.line),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: t.mono.copyWith(
            fontSize: 10,
            letterSpacing: 1.4,
            color: t.dim,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: fieldKey,
          controller: controller,
          enabled: enabled,
          minLines: minLines,
          maxLines: minLines == 1 ? 1 : null,
          keyboardType: minLines == 1
              ? TextInputType.text
              : TextInputType.multiline,
          cursorColor: t.accent,
          style: style,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: style.copyWith(color: t.faint),
            filled: true,
            fillColor: t.bg2,
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: BorderSide(color: t.accent.withValues(alpha: 0.7)),
            ),
          ),
        ),
      ],
    );
  }
}
