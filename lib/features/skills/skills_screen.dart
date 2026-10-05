import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/hermes_motion.dart';
import '../../core/theme/hermes_tokens.dart';
import '../../core/widgets/failure_state.dart';
import '../../core/widgets/hermes_sheet.dart';
import '../../core/widgets/paper_texture.dart';
import '../../domain/models/hermes_failure.dart';
import '../../domain/models/hermes_skill.dart';
import 'skills_provider.dart';

/// Catálogo móvel das Skills efetivamente anunciadas pelo API Server.
///
/// O contrato atual de `/v1/skills` é somente leitura e entrega metadados. A
/// tela não oferece edição nem finge conseguir abrir um SKILL.md que não veio
/// na resposta.
class SkillsScreen extends ConsumerStatefulWidget {
  const SkillsScreen({super.key});

  @override
  ConsumerState<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends ConsumerState<SkillsScreen> {
  final _search = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _search.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(skillsCatalogProvider);
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: PaperTexture()),
          SafeArea(
            child: Column(
              children: [
                _SkillsBar(
                  onBack: context.pop,
                  onRefresh: () => ref.invalidate(skillsCatalogProvider),
                ),
                _SkillSearch(
                  controller: _search,
                  query: _query,
                  onChanged: (value) => setState(() => _query = value),
                  onClear: _clearSearch,
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: motionOf(context, HermesMotion.estado),
                    switchInCurve: HermesMotion.curvaChegada,
                    switchOutCurve: HermesMotion.curvaPadrao,
                    child: catalog.when(
                      loading: () =>
                          const _SkillsLoading(key: ValueKey('skills-loading')),
                      error: (error, _) => FailureState(
                        key: const ValueKey('skills-failure'),
                        failure: hermesFailureFrom(error),
                        keyPrefix: 'skills',
                        onRetry: () => ref.invalidate(skillsCatalogProvider),
                      ),
                      data: (skills) {
                        final filtered = _filterSkills(skills, _query);
                        if (skills.isEmpty) {
                          return const _SkillsEmpty(
                            key: ValueKey('skills-empty'),
                            filtered: false,
                          );
                        }
                        if (filtered.isEmpty) {
                          return _SkillsEmpty(
                            key: const ValueKey('skills-filter-empty'),
                            filtered: true,
                            onClear: _clearSearch,
                          );
                        }
                        return _SkillsList(
                          key: const ValueKey('skills-list'),
                          skills: filtered,
                          onRefresh: () async {
                            ref.invalidate(skillsCatalogProvider);
                            await ref.read(skillsCatalogProvider.future);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillsBar extends StatelessWidget {
  const _SkillsBar({required this.onBack, required this.onRefresh});

  final VoidCallback onBack;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.line)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 68),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Voltar',
                onPressed: onBack,
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: t.ink,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Skills',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t
                          .serifIn(FontWeight.w500)
                          .copyWith(fontSize: 20, color: t.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'API SERVER · SOMENTE LEITURA',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.mono.copyWith(
                        fontSize: 9,
                        letterSpacing: 1.15,
                        color: t.dim,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const ValueKey('skills-refresh'),
                tooltip: 'Atualizar Skills',
                onPressed: onRefresh,
                icon: Icon(Icons.refresh_rounded, size: 21, color: t.dim),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillSearch extends StatelessWidget {
  const _SkillSearch({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: TextField(
        key: const ValueKey('skills-search'),
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        cursorColor: t.accent,
        style: t.serif.copyWith(fontSize: 15, color: t.ink),
        decoration: InputDecoration(
          hintText: 'Buscar por nome, função ou categoria',
          hintStyle: t.serif.copyWith(fontSize: 15, color: t.dim),
          prefixIcon: Icon(Icons.search_rounded, size: 20, color: t.dim),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Limpar busca',
                  onPressed: onClear,
                  icon: Icon(Icons.close_rounded, size: 19, color: t.dim),
                ),
          filled: true,
          fillColor: t.bg2,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(color: t.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(color: t.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(color: t.accent.withValues(alpha: 0.7)),
          ),
        ),
      ),
    );
  }
}

class _SkillsList extends StatelessWidget {
  const _SkillsList({super.key, required this.skills, required this.onRefresh});

  final List<HermesSkill> skills;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return RefreshIndicator(
      color: t.accent,
      backgroundColor: t.bg2,
      onRefresh: onRefresh,
      child: ListView.separated(
        key: const ValueKey('skills-scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
        itemCount: skills.length,
        separatorBuilder: (_, _) => Divider(height: 1, color: t.line),
        itemBuilder: (context, index) => _SkillRow(skill: skills[index]),
      ),
    );
  }
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({required this.skill});

  final HermesSkill skill;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final category = _categoryOf(skill);
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.4;
    return Semantics(
      button: true,
      label: '${skill.name}. $category. Abrir detalhes.',
      child: InkWell(
        key: ValueKey('skill-row-${skill.name}'),
        onTap: () => _showSkillDetails(context, skill),
        borderRadius: BorderRadius.circular(14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.auto_stories_outlined,
                    size: 19,
                    color: t.dim,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (largeText) ...[
                        Text(
                          skill.name,
                          style: t
                              .monoIn(FontWeight.w500)
                              .copyWith(fontSize: 12, color: t.ink),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category.toUpperCase(),
                          style: t.mono.copyWith(
                            fontSize: 9,
                            letterSpacing: 0.85,
                            color: t.dim,
                          ),
                        ),
                      ] else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                skill.name,
                                style: t
                                    .monoIn(FontWeight.w500)
                                    .copyWith(fontSize: 12, color: t.ink),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              category.toUpperCase(),
                              textAlign: TextAlign.end,
                              style: t.mono.copyWith(
                                fontSize: 9,
                                letterSpacing: 0.85,
                                color: t.dim,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 5),
                      Text(
                        skill.description.trim().isEmpty
                            ? 'Sem descrição anunciada pelo gateway.'
                            : skill.description.trim(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: t.serif.copyWith(
                          fontSize: 14,
                          height: 1.35,
                          color: t.dim,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 19,
                    color: t.faint,
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

class _SkillsLoading extends StatelessWidget {
  const _SkillsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
      itemCount: 5,
      separatorBuilder: (_, _) => Divider(height: 1, color: t.line),
      itemBuilder: (_, index) => Semantics(
        label: 'Carregando skill',
        child: SizedBox(
          height: 76,
          child: Row(
            children: [
              _Skeleton(width: 19, height: 19, color: t.bg2),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FractionallySizedBox(
                      widthFactor: index.isEven ? 0.46 : 0.62,
                      child: _Skeleton(height: 10, color: t.bg2),
                    ),
                    const SizedBox(height: 9),
                    FractionallySizedBox(
                      widthFactor: index.isEven ? 0.78 : 0.68,
                      child: _Skeleton(height: 9, color: t.bg2),
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

class _Skeleton extends StatelessWidget {
  const _Skeleton({this.width, required this.height, required this.color});

  final double? width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(5),
    ),
  );
}

class _SkillsEmpty extends StatelessWidget {
  const _SkillsEmpty({super.key, required this.filtered, this.onClear});

  final bool filtered;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              filtered ? Icons.search_off_rounded : Icons.auto_stories_outlined,
              size: 26,
              color: t.faint,
            ),
            const SizedBox(height: 12),
            Text(
              filtered
                  ? 'Nenhuma Skill corresponde à busca.'
                  : 'O gateway não anunciou nenhuma Skill.',
              textAlign: TextAlign.center,
              style: t
                  .serifIn(FontWeight.w500)
                  .copyWith(fontSize: 18, color: t.ink),
            ),
            const SizedBox(height: 7),
            Text(
              filtered
                  ? 'Tente outro nome, função ou categoria.'
                  : 'Atualize o catálogo depois de carregar Skills no API Server.',
              textAlign: TextAlign.center,
              style: t.serif.copyWith(fontSize: 14, height: 1.45, color: t.dim),
            ),
            if (onClear != null) ...[
              const SizedBox(height: 14),
              TextButton(onPressed: onClear, child: const Text('Limpar busca')),
            ],
          ],
        ),
      ),
    );
  }
}

List<HermesSkill> _filterSkills(List<HermesSkill> skills, String query) {
  final needle = _searchKey(query);
  if (needle.isEmpty) return skills;
  return skills
      .where(
        (skill) => _searchKey(
          '${skill.name} ${skill.description} ${skill.category ?? ''}',
        ).contains(needle),
      )
      .toList(growable: false);
}

String _searchKey(String value) {
  const accented = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const plain = 'aaaaaeeeeiiiiooooouuuuc';
  final lower = value.trim().toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    final index = accented.indexOf(char);
    buffer.write(index < 0 ? char : plain[index]);
  }
  return buffer.toString();
}

String _categoryOf(HermesSkill skill) {
  final category = skill.category?.trim();
  return category == null || category.isEmpty ? 'sem categoria' : category;
}

Future<void> _showSkillDetails(BuildContext context, HermesSkill skill) {
  return showHermesSheet(
    context,
    title: skill.name,
    tag: '',
    child: _SkillDetails(skill: skill),
  );
}

class _SkillDetails extends StatelessWidget {
  const _SkillDetails({required this.skill});

  final HermesSkill skill;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final category = _categoryOf(skill);
    return Column(
      key: ValueKey('skill-details-${skill.name}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        Text(
          'IDENTIFICADOR',
          style: t.mono.copyWith(
            fontSize: 10,
            letterSpacing: 1.4,
            color: t.dim,
          ),
        ),
        const SizedBox(height: 8),
        SelectableText(
          skill.name,
          style: t
              .monoIn(FontWeight.w500)
              .copyWith(fontSize: 12, height: 1.45, color: t.ink),
        ),
        const SizedBox(height: 18),
        Text(
          'CATEGORIA',
          style: t.mono.copyWith(
            fontSize: 10,
            letterSpacing: 1.4,
            color: t.dim,
          ),
        ),
        const SizedBox(height: 8),
        SelectableText(
          category,
          style: t.mono.copyWith(fontSize: 11, color: t.ink),
        ),
        const SizedBox(height: 22),
        Text(
          'DESCRIÇÃO',
          style: t.mono.copyWith(
            fontSize: 10,
            letterSpacing: 1.4,
            color: t.dim,
          ),
        ),
        const SizedBox(height: 8),
        SelectableText(
          skill.description.trim().isEmpty
              ? 'O gateway não anunciou uma descrição para esta Skill.'
              : skill.description.trim(),
          style: t.serif.copyWith(fontSize: 16, height: 1.55, color: t.ink),
        ),
        const SizedBox(height: 24),
        Divider(height: 1, color: t.line),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, size: 18, color: t.accentInk),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'O API Server atual não expõe o conteúdo integral de SKILL.md. '
                'Por isso esta visualização mostra somente os metadados reais, '
                'sem oferecer edição ou ativação.',
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
    );
  }
}
