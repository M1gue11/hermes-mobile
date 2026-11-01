import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/code_surface.dart';
import '../../core/widgets/failure_state.dart';
import '../../core/widgets/paper_texture.dart';
import '../../core/theme/hermes_tokens.dart';
import '../../domain/models/hermes_failure.dart';
import '../../domain/models/hermes_skill.dart';
import '../../domain/repositories/gateway_repository.dart';
import 'skill_top_bar.dart';
import 'skills_provider.dart';

/// Localização da tela de detalhe. O nome vai na query porque pode ser um
/// caminho relativo (`categoria/skill`) quando há duplicatas no servidor.
String skillDetailLocation(String name) =>
    Uri(path: '/skills/skill', queryParameters: {'name': name}).toString();

String skillEditorLocation(String name) =>
    Uri(path: '/skills/skill/edit', queryParameters: {'name': name}).toString();

String skillCategoryLabel(HermesSkill skill) {
  final category = skill.category?.trim();
  return category == null || category.isEmpty ? 'sem categoria' : category;
}

/// Texto para a pessoa a partir de uma falha do Dashboard.
String skillsGatewayMessage(Object error) => switch (error) {
  GatewayAuthenticationRequired() =>
    'O login do Dashboard não está válido. Entre novamente em Conexão.',
  GatewayOperationException(:final message) => message,
  _ => 'O Dashboard não respondeu como esperado.',
};

/// Detalhe de uma Skill. Com o catálogo do Dashboard, mostra o `SKILL.md`
/// integral, a ativação no perfil e o acesso ao editor; com o do API Server,
/// só os metadados que ele anuncia.
class SkillDetailScreen extends ConsumerWidget {
  const SkillDetailScreen({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(skillsCatalogProvider);
    final data = catalog.value;
    final skill = data?.skills.where((item) => item.name == name).firstOrNull;
    final manageable = data?.manageable ?? false;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: PaperTexture()),
          SafeArea(
            child: Column(
              children: [
                SkillTopBar(
                  title: name,
                  subtitle: skill == null
                      ? 'SKILL'
                      : skillCategoryLabel(skill).toUpperCase(),
                  onLeading: context.pop,
                  actions: [
                    if (manageable && skill != null)
                      IconButton(
                        key: const ValueKey('skill-edit'),
                        tooltip: 'Editar SKILL.md',
                        onPressed: () =>
                            context.push(skillEditorLocation(name)),
                        icon: Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: HermesTokens.of(context).dim,
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: switch ((data, catalog)) {
                    (null, AsyncError(:final error)) => FailureState(
                      failure: hermesFailureFrom(error),
                      keyPrefix: 'skill',
                      onRetry: () => ref.invalidate(skillsCatalogProvider),
                    ),
                    (null, _) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    (_, _) when skill == null => const _SkillMissing(),
                    _ => _SkillDetailBody(skill: skill, manageable: manageable),
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillMissing extends StatelessWidget {
  const _SkillMissing();

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          'Esta Skill não está mais no catálogo.',
          textAlign: TextAlign.center,
          style: t
              .serifIn(FontWeight.w500)
              .copyWith(fontSize: 18, color: t.ink),
        ),
      ),
    );
  }
}

class _SkillDetailBody extends StatelessWidget {
  const _SkillDetailBody({required this.skill, required this.manageable});

  final HermesSkill skill;
  final bool manageable;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return ListView(
      key: ValueKey('skill-details-${skill.name}'),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
      children: [
        if (manageable && skill.enabled != null)
          _SkillEnabledRow(skill: skill)
        else
          Row(
            children: [
              Icon(Icons.check_circle_outline, size: 18, color: t.positive),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Disponível para o agente',
                  style: t.mono.copyWith(fontSize: 11, color: t.ink),
                ),
              ),
            ],
          ),
        const SizedBox(height: 20),
        const _Label('IDENTIFICADOR'),
        const SizedBox(height: 8),
        SelectableText(
          skill.name,
          style: t
              .monoIn(FontWeight.w500)
              .copyWith(fontSize: 12, height: 1.45, color: t.ink),
        ),
        const SizedBox(height: 18),
        const _Label('CATEGORIA'),
        const SizedBox(height: 8),
        SelectableText(
          skillCategoryLabel(skill),
          style: t.mono.copyWith(fontSize: 11, color: t.ink),
        ),
        const SizedBox(height: 22),
        const _Label('DESCRIÇÃO'),
        const SizedBox(height: 8),
        SelectableText(
          skill.description.trim().isEmpty
              ? 'Nenhuma descrição foi anunciada para esta Skill.'
              : skill.description.trim(),
          style: t.serif.copyWith(fontSize: 16, height: 1.55, color: t.ink),
        ),
        const SizedBox(height: 24),
        if (manageable) ...[
          const _Label('SKILL.MD'),
          const SizedBox(height: 10),
          _SkillContent(name: skill.name),
        ] else ...[
          Divider(height: 1, color: t.line),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: t.accentInk),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'O API Server não expõe o conteúdo integral de SKILL.md nem a '
                  'ativação. Com o Dashboard conectado, esta tela também lê, '
                  'edita e ativa ou desativa a Skill.',
                  style: t.serif.copyWith(
                    fontSize: 14,
                    height: 1.5,
                    color: t.dim,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Text(
      text,
      style: t.mono.copyWith(fontSize: 10, letterSpacing: 1.4, color: t.dim),
    );
  }
}

/// Ativação da Skill no perfil atual. O valor exibido vem do catálogo; o
/// pedido em curso aparece já no estado pedido e volta se o Dashboard recusar.
class _SkillEnabledRow extends ConsumerStatefulWidget {
  const _SkillEnabledRow({required this.skill});

  final HermesSkill skill;

  @override
  ConsumerState<_SkillEnabledRow> createState() => _SkillEnabledRowState();
}

class _SkillEnabledRowState extends ConsumerState<_SkillEnabledRow> {
  bool? _requested;

  @override
  void didUpdateWidget(_SkillEnabledRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.skill.enabled == _requested) _requested = null;
  }

  Future<void> _toggle(bool enabled) async {
    setState(() => _requested = enabled);
    try {
      await ref
          .read(skillManagementProvider)
          .setEnabled(widget.skill.name, enabled: enabled);
    } catch (error) {
      if (!mounted) return;
      setState(() => _requested = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(skillsGatewayMessage(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final enabled = _requested ?? widget.skill.enabled ?? true;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                enabled ? 'Ativa para o agente' : 'Desativada',
                style: t.serif.copyWith(fontSize: 15.5, color: t.ink),
              ),
              const SizedBox(height: 2),
              Text(
                enabled
                    ? 'O agente pode carregar esta Skill neste perfil.'
                    : 'O agente não carrega esta Skill neste perfil.',
                style: t.serif.copyWith(fontSize: 13, color: t.dim),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch(
          key: const ValueKey('skill-enabled-switch'),
          value: enabled,
          activeThumbColor: t.bg,
          activeTrackColor: t.accent,
          onChanged: _requested == null ? _toggle : null,
        ),
      ],
    );
  }
}

class _SkillContent extends ConsumerWidget {
  const _SkillContent({required this.name});

  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = HermesTokens.of(context);
    final content = ref.watch(skillContentProvider(name));
    // Depois de salvar, o valor anterior continua à vista durante a releitura.
    return switch ((content.value, content)) {
      (final String value, _) => CodeSurface(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: SelectableText(
            value,
            key: const ValueKey('skill-content'),
            style: t.mono.copyWith(fontSize: 11.5, height: 1.5, color: t.ink),
          ),
        ),
      ),
      (_, AsyncError(:final error)) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            skillsGatewayMessage(error),
            style: t.serif.copyWith(fontSize: 14, height: 1.5, color: t.dim),
          ),
          TextButton(
            key: const ValueKey('skill-content-retry'),
            onPressed: () => ref.invalidate(skillContentProvider(name)),
            child: const Text('Tentar de novo'),
          ),
        ],
      ),
      _ => Text(
        'Carregando SKILL.md…',
        style: t.mono.copyWith(fontSize: 11, color: t.dim),
      ),
    };
  }
}
