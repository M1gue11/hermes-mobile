import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/hermes_tokens.dart';
import '../../core/widgets/paper_texture.dart';
import 'skill_detail_screen.dart';
import '../../core/widgets/screen_top_bar.dart';
import 'skills_provider.dart';

/// Editor do `SKILL.md` inteiro.
///
/// Sair com alterações pede confirmação, e gravar compara antes com a versão
/// que estava no servidor quando o editor abriu.
class SkillEditorScreen extends ConsumerStatefulWidget {
  const SkillEditorScreen({super.key, required this.name});

  final String name;

  @override
  ConsumerState<SkillEditorScreen> createState() => _SkillEditorScreenState();
}

class _SkillEditorScreenState extends ConsumerState<SkillEditorScreen> {
  final _text = TextEditingController();
  String? _baseline;
  var _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    ref.listenManual(skillContentProvider(widget.name), (_, next) {
      if (_baseline == null && next.hasValue) {
        _baseline = next.requireValue;
        _text.text = next.requireValue;
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _dirty => _baseline != null && _text.text != _baseline;

  Future<void> _save({bool overwrite = false}) async {
    final baseline = _baseline;
    if (baseline == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(skillManagementProvider)
          .save(
            widget.name,
            baseline: baseline,
            content: _text.text,
            overwrite: overwrite,
          );
      if (!mounted) return;
      if (result == SkillSaveResult.changedOnServer) {
        setState(() => _saving = false);
        if (await _confirmOverwrite() == true) await _save(overwrite: true);
        return;
      }
      _baseline = _text.text;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('SKILL.md salvo.')));
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = skillsGatewayMessage(error);
      });
    }
  }

  Future<bool?> _confirmOverwrite() => showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('O SKILL.md mudou no servidor'),
      content: const Text(
        'Esta Skill foi alterada depois que o editor abriu, talvez pelo '
        'próprio agente. Salvar agora substitui essa versão pela sua.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const ValueKey('skill-overwrite'),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Substituir'),
        ),
      ],
    ),
  );

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descartar alterações?'),
        content: const Text('As edições no SKILL.md ainda não foram salvas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar editando'),
          ),
          FilledButton(
            key: const ValueKey('skill-discard'),
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
    final content = ref.watch(skillContentProvider(widget.name));
    return ListenableBuilder(
      listenable: _text,
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
                      title: widget.name,
                      subtitle: _dirty ? 'SKILL.MD · NÃO SALVO' : 'SKILL.MD',
                      leadingIcon: Icons.close_rounded,
                      leadingTooltip: 'Fechar editor',
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
                            key: const ValueKey('skill-save'),
                            onPressed: _dirty ? _save : null,
                            child: const Text('Salvar'),
                          ),
                      ],
                    ),
                    if (_error case final error?)
                      Container(
                        key: const ValueKey('skill-save-error'),
                        width: double.infinity,
                        color: t.bg2,
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                        child: Text(
                          'O Dashboard recusou: $error',
                          style: t.serif.copyWith(
                            fontSize: 14,
                            height: 1.45,
                            color: t.accentInk,
                          ),
                        ),
                      ),
                    Expanded(
                      child: switch ((_baseline, content)) {
                        (final String _, _) => TextField(
                          key: const ValueKey('skill-editor'),
                          controller: _text,
                          readOnly: _saving,
                          expands: true,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          textAlignVertical: TextAlignVertical.top,
                          cursorColor: t.accent,
                          style: t.mono.copyWith(
                            fontSize: 12.5,
                            height: 1.5,
                            color: t.ink,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.fromLTRB(18, 16, 18, 40),
                          ),
                        ),
                        (_, AsyncError(:final error)) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Text(
                              skillsGatewayMessage(error),
                              textAlign: TextAlign.center,
                              style: t.serif.copyWith(
                                fontSize: 15,
                                height: 1.5,
                                color: t.dim,
                              ),
                            ),
                          ),
                        ),
                        _ => const Center(child: CircularProgressIndicator()),
                      },
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
