import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/core/theme/hermes_motion.dart';
import 'package:hermes_mobile/core/theme/hermes_tokens.dart';
import 'package:hermes_mobile/core/widgets/code_surface.dart';
import 'package:hermes_mobile/data/hermes_repository_provider.dart';
import 'package:hermes_mobile/domain/models/chat_message.dart';
import 'package:hermes_mobile/domain/models/tool_call.dart';
import 'package:hermes_mobile/domain/models/turn_activity.dart';
import 'package:hermes_mobile/features/chat/widgets/message_bubbles.dart';
import 'package:hermes_mobile/features/chat/widgets/sheets.dart';
import 'package:hermes_mobile/features/settings/settings_provider.dart';

import '../support/fake_hermes_repository.dart';

const message = AssistantMessage(
  id: 'a1',
  phase: ChatPhase.done,
  activity: 'Primeiro passo. Segundo passo.',
  tools: [
    ToolCall(
      name: 'execute_code',
      arg: 'print("oi")',
      detail: 'print("oi")',
      output: 'oi\nexit 0',
      status: ToolStatus.done,
    ),
    ToolCall(name: 'terminal', arg: 'flutter test', status: ToolStatus.done),
  ],
  activityItems: [
    TurnActivity.activity(id: 'n1', text: 'Primeiro passo.'),
    TurnActivity.tool(
      id: 't1',
      tool: ToolCall(
        name: 'execute_code',
        arg: 'print("oi")',
        detail: 'print("oi")',
        output: 'oi\nexit 0',
        status: ToolStatus.done,
      ),
    ),
    TurnActivity.activity(id: 'n2', text: 'Segundo passo.'),
    TurnActivity.tool(
      id: 't2',
      tool: ToolCall(
        name: 'terminal',
        arg: 'flutter test',
        status: ToolStatus.done,
      ),
    ),
  ],
  text: 'Pronto.',
);

Future<void> closeAnimations(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 1));
}

double contrastRatio(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final darker = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  testWidgets('modo cronológico é padrão e intercala notas e ferramentas', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(
          body: SingleChildScrollView(child: AssistantBubble(message)),
        ),
      ),
    );
    await tester.pump();

    final firstNote = find.byKey(const ValueKey('turn-activity-n1'));
    final firstTool = find.byKey(const ValueKey('turn-tool-t1'));
    final secondNote = find.byKey(const ValueKey('turn-activity-n2'));
    final secondTool = find.byKey(const ValueKey('turn-tool-t2'));
    expect(firstNote, findsOneWidget);
    expect(firstTool, findsOneWidget);
    expect(secondNote, findsOneWidget);
    expect(secondTool, findsOneWidget);
    expect(
      tester.getTopLeft(firstNote).dy,
      lessThan(tester.getTopLeft(firstTool).dy),
    );
    expect(
      tester.getTopLeft(firstTool).dy,
      lessThan(tester.getTopLeft(secondNote).dy),
    );
    expect(
      tester.getTopLeft(secondNote).dy,
      lessThan(tester.getTopLeft(secondTool).dy),
    );
    expect(find.text('FERRAMENTAS'), findsNothing);
    expect(find.byKey(const ValueKey('turn-tool-detail-t1')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('turn-tool-toggle-t1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('turn-tool-detail-t1')), findsOneWidget);
    expect(find.text('ARGUMENTOS'), findsOneWidget);
    expect(find.text('SAÍDA'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('turn-tool-toggle-t1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('turn-tool-detail-t1')), findsNothing);

    await closeAnimations(tester);
  });

  testWidgets('divulgações da timeline registram intenção de releitura', (
    tester,
  ) async {
    var interactions = 0;
    void onInteraction() => interactions++;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: AssistantBubble(
              message,
              onTimelineInteraction: onInteraction,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('turn-activity-n1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('turn-tool-toggle-t1')));
    await tester.pumpAndSettle();
    expect(interactions, 2);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: AssistantBubble(
              message,
              chronologicalActivity: false,
              onTimelineInteraction: onInteraction,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('ATIVIDADE · HISTÓRICO'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('turn-tool-toggle-consolidated-0')),
    );
    await tester.pumpAndSettle();
    expect(interactions, 4);

    await closeAnimations(tester);
  });

  testWidgets('ambos os modos compartilham duração com uma casa decimal', (
    tester,
  ) async {
    const tool = ToolCall(
      name: 'read_file',
      arg: 'lib/main.dart',
      duration: '1.26',
      status: ToolStatus.done,
    );
    const timed = AssistantMessage(
      id: 'timed',
      phase: ChatPhase.done,
      tools: [tool],
      activityItems: [TurnActivity.tool(id: 'timed-tool', tool: tool)],
      text: 'Pronto.',
    );

    for (final chronological in [true, false]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(),
          home: Scaffold(
            body: AssistantBubble(timed, chronologicalActivity: chronological),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('1.3s'), findsOneWidget);
      expect(find.textContaining('OK'), findsNothing);
      await closeAnimations(tester);
    }
  });

  testWidgets('execução e erro têm texto; sucesso usa só forma e duração', (
    tester,
  ) async {
    const mixed = AssistantMessage(
      id: 'mixed',
      phase: ChatPhase.writing,
      activityItems: [
        TurnActivity.tool(
          id: 'running',
          tool: ToolCall(name: 'terminal', status: ToolStatus.running),
        ),
        TurnActivity.tool(
          id: 'done',
          tool: ToolCall(
            name: 'read_file',
            duration: '0.24',
            status: ToolStatus.done,
          ),
        ),
        TurnActivity.tool(
          id: 'error',
          tool: ToolCall(
            name: 'web_search',
            duration: '1.74',
            status: ToolStatus.error,
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(body: AssistantBubble(mixed)),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('tool-marker-running')), findsOneWidget);
    expect(find.byKey(const ValueKey('tool-marker-done')), findsOneWidget);
    expect(find.byKey(const ValueKey('tool-marker-error')), findsOneWidget);
    expect(find.text('EXEC'), findsOneWidget);
    expect(find.text('0.2s'), findsOneWidget);
    expect(find.textContaining('OK'), findsNothing);
    expect(find.text('ERRO · 1.7s'), findsOneWidget);
    final background = Theme.of(
      tester.element(find.text('EXEC')),
    ).scaffoldBackgroundColor;
    for (final label in ['EXEC', '0.2s', 'ERRO · 1.7s']) {
      final text = tester.widget<Text>(find.text(label));
      expect(
        contrastRatio(text.style!.color!, background),
        greaterThanOrEqualTo(4.5),
        reason: '$label precisa permanecer legível em alto contraste',
      );
    }

    await closeAnimations(tester);
  });

  testWidgets('só a ferramenta viva mais recente anima', (tester) async {
    const concurrent = AssistantMessage(
      id: 'concurrent',
      phase: ChatPhase.writing,
      activityItems: [
        TurnActivity.tool(
          id: 'running-first',
          tool: ToolCall(name: 'read_file', status: ToolStatus.running),
        ),
        TurnActivity.tool(
          id: 'running-latest',
          tool: ToolCall(name: 'terminal', status: ToolStatus.running),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(body: AssistantBubble(concurrent)),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('tool-marker-running-static')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tool-marker-running-animated')),
      findsOneWidget,
    );

    await closeAnimations(tester);
  });

  testWidgets('detalhe curto abraça conteúdo e preserva contraste', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(
          body: SingleChildScrollView(child: AssistantBubble(message)),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('turn-tool-toggle-t1')));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(CodeSurface)).height, lessThan(180));
    final context = tester.element(find.text('ARGUMENTOS'));
    final tokens = HermesTokens.of(context);
    for (final label in ['ARGUMENTOS', 'SAÍDA']) {
      final text = tester.widget<Text>(find.text(label));
      expect(
        contrastRatio(text.style!.color!, tokens.codeBg),
        greaterThanOrEqualTo(4.5),
      );
    }

    await closeAnimations(tester);
  });

  testWidgets('saída única ocupa só a altura do próprio conteúdo', (
    tester,
  ) async {
    const outputOnly = AssistantMessage(
      id: 'output-only',
      phase: ChatPhase.done,
      activityItems: [
        TurnActivity.tool(
          id: 'patch',
          tool: ToolCall(
            name: 'patch',
            arg: '/mnt/example-vault',
            output: 'arquivo atualizado',
            status: ToolStatus.done,
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(body: AssistantBubble(outputOnly)),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('turn-tool-toggle-patch')));
    await tester.pumpAndSettle();

    expect(
      tester
          .getSize(find.byKey(const ValueKey('tool-details-code-surface')))
          .height,
      lessThan(90),
    );
    final surface = tester.getRect(
      find.byKey(const ValueKey('tool-details-code-surface')),
    );
    final disclosure = tester.getRect(
      find.byKey(const ValueKey('turn-tool-detail-transition-patch')),
    );
    expect(surface.left, closeTo(disclosure.left, 0.01));
    expect(surface.right, closeTo(disclosure.right - 2, 0.01));

    await closeAnimations(tester);
  });

  testWidgets('JSON válido é formatado e recebe realce de sintaxe', (
    tester,
  ) async {
    const jsonMessage = AssistantMessage(
      id: 'json',
      phase: ChatPhase.done,
      activityItems: [
        TurnActivity.tool(
          id: 'json-tool',
          tool: ToolCall(
            name: 'patch',
            output: '{"success":true,"count":2,"items":["a","b"]}',
            status: ToolStatus.done,
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(body: AssistantBubble(jsonMessage)),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('turn-tool-toggle-json-tool')));
    await tester.pumpAndSettle();

    final selectable = tester.widget<SelectableText>(
      find.byType(SelectableText),
    );
    final span = selectable.textSpan!;
    expect(
      span.toPlainText(),
      '{\n  "success": true,\n  "count": 2,\n  "items": [\n    "a",\n    "b"\n  ]\n}',
    );
    final colors = <Color>{};
    void collectColors(InlineSpan current) {
      if (current is! TextSpan) return;
      if (current.style?.color case final color?) colors.add(color);
      for (final child in current.children ?? const <InlineSpan>[]) {
        collectColors(child);
      }
    }

    collectColors(span);
    final tokens = HermesTokens.of(tester.element(find.text('SAÍDA')));
    expect(colors, containsAll(<Color>[tokens.cStr, tokens.cNum, tokens.cKey]));

    await closeAnimations(tester);
  });

  testWidgets('divulgação revela e recolhe somente a altura', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(body: AssistantBubble(message)),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('turn-tool-toggle-t1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    final disclosure = find.byKey(
      const ValueKey('turn-tool-detail-transition-t1'),
    );
    expect(tester.widget(disclosure), isA<AnimatedBuilder>());
    final midHeight = tester.getSize(disclosure).height;
    expect(midHeight, greaterThan(0));
    expect(
      find.descendant(of: disclosure, matching: find.byType(SizeTransition)),
      findsNothing,
    );
    expect(
      find.descendant(of: disclosure, matching: find.byType(FadeTransition)),
      findsNothing,
    );
    expect(
      find.descendant(of: disclosure, matching: find.byType(SlideTransition)),
      findsNothing,
    );

    await tester.pumpAndSettle();
    final fullHeight = tester.getSize(disclosure).height;
    expect(fullHeight, greaterThan(midHeight));

    await tester.tap(find.byKey(const ValueKey('turn-tool-toggle-t1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final closingHeight = tester.getSize(disclosure).height;
    expect(closingHeight, greaterThan(0));
    expect(closingHeight, lessThan(fullHeight));
    final detail = find.byKey(const ValueKey('turn-tool-detail-t1'));
    expect(
      detail,
      findsOneWidget,
      reason: 'a tinta deve permanecer montada enquanto a altura recolhe',
    );
    final clippingAncestors = find.ancestor(
      of: detail,
      matching: find.byType(ClipRect),
    );
    expect(clippingAncestors, findsWidgets);
    for (final element in clippingAncestors.evaluate()) {
      final renderBox = element.renderObject! as RenderBox;
      expect(
        renderBox.size.height,
        greaterThan(0),
        reason: 'nenhum recorte pode zerar antes do fechamento terminar',
      );
    }

    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('turn-tool-detail-t1')), findsNothing);
    await closeAnimations(tester);
  });

  testWidgets('raciocínio usa a voz serifada editorial', (tester) async {
    const reasoning = AssistantMessage(
      id: 'reasoning',
      phase: ChatPhase.done,
      activityItems: [
        TurnActivity.reasoning(id: 'reasoning-note', text: 'Uma hipótese.'),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(body: AssistantBubble(reasoning)),
      ),
    );
    await tester.pump();

    final label = tester.widget<Text>(find.text('Raciocínio'));
    expect(label.style!.fontFamily, contains('Newsreader'));
    expect(
      find.byKey(const ValueKey('reasoning-timeline-icon')),
      findsOneWidget,
    );

    await closeAnimations(tester);
  });

  testWidgets('toque não cria glow e raciocínio se revela com continuidade', (
    tester,
  ) async {
    const reasoning = AssistantMessage(
      id: 'reasoning-motion',
      phase: ChatPhase.done,
      text: 'Resposta posterior.',
      activityItems: [
        TurnActivity.reasoning(
          id: 'reasoning-motion-note',
          text: 'Uma hipótese em validação.',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(body: AssistantBubble(reasoning)),
      ),
    );
    await tester.pump();

    final label = find.text('Raciocínio');
    final laterContent = find.text('Resposta posterior.');
    final labelTop = tester.getTopLeft(label).dy;
    final laterTop = tester.getTopLeft(laterContent).dy;
    final ink = tester
        .widgetList<InkWell>(
          find.ancestor(of: label, matching: find.byType(InkWell)),
        )
        .firstWhere((candidate) => candidate.onTap != null);
    expect(ink.splashFactory, same(NoSplash.splashFactory));
    expect(ink.highlightColor, Colors.transparent);
    expect(ink.splashColor, Colors.transparent);
    expect(ink.hoverColor, Colors.transparent);
    expect(ink.focusColor, Colors.transparent);

    final gesture = await tester.startGesture(tester.getCenter(label));
    await tester.pump(HermesMotion.toque);
    final pressedSlides = tester
        .widgetList<AnimatedSlide>(
          find.ancestor(of: label, matching: find.byType(AnimatedSlide)),
        )
        .where((slide) => slide.offset != Offset.zero);
    expect(pressedSlides, isNotEmpty);

    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    final detail = find.text('Uma hipótese em validação.');
    final disclosure = find
        .ancestor(of: detail, matching: find.byType(AnimatedBuilder))
        .first;
    expect(disclosure, findsOneWidget);
    final midHeight = tester.getSize(disclosure).height;
    expect(midHeight, greaterThan(0));
    expect(tester.getTopLeft(label).dy, moreOrLessEquals(labelTop, epsilon: 1));
    expect(tester.getTopLeft(laterContent).dy, greaterThan(laterTop));

    await tester.pumpAndSettle();
    final fullHeight = tester.getSize(disclosure).height;
    expect(fullHeight, greaterThan(midHeight));

    await tester.tap(label);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final closingHeight = tester.getSize(disclosure).height;
    expect(closingHeight, greaterThan(0));
    expect(closingHeight, lessThan(fullHeight));
    expect(detail, findsOneWidget);
    expect(tester.getTopLeft(label).dy, moreOrLessEquals(labelTop, epsilon: 1));

    await tester.pumpAndSettle();
    expect(detail, findsNothing);
    await closeAnimations(tester);
  });

  testWidgets('trilho respira só ao redor dos marcadores', (tester) async {
    const twoTools = AssistantMessage(
      id: 'rail',
      phase: ChatPhase.done,
      activityItems: [
        TurnActivity.tool(
          id: 'first',
          tool: ToolCall(name: 'read_file', status: ToolStatus.done),
        ),
        TurnActivity.tool(
          id: 'second',
          tool: ToolCall(name: 'patch', status: ToolStatus.done),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(body: AssistantBubble(twoTools)),
      ),
    );
    await tester.pump();

    final markers = find.byKey(const ValueKey('timeline-marker'));
    final rails = find.byKey(const ValueKey('timeline-rail-canvas'));
    expect(markers, findsNWidgets(2));
    expect(rails, findsNWidgets(2));
    final firstPainter =
        tester.widget<CustomPaint>(rails.at(0)).painter! as TimelineRailPainter;
    final secondPainter =
        tester.widget<CustomPaint>(rails.at(1)).painter! as TimelineRailPainter;
    expect(
      tester.getRect(rails.at(0)).top +
          firstPainter.afterStart -
          tester.getRect(markers.at(0)).bottom,
      closeTo(3.5, 0.01),
    );
    expect(
      tester.getRect(markers.at(1)).top -
          (tester.getRect(rails.at(1)).top + secondPainter.beforeEnd),
      closeTo(3.5, 0.01),
    );
    expect(
      tester.getRect(rails.at(0)).bottom,
      closeTo(tester.getRect(rails.at(1)).top, 0.01),
    );

    await closeAnimations(tester);
  });

  testWidgets('tools padrão recebem ícones semânticos por categoria', (
    tester,
  ) async {
    const tools = AssistantMessage(
      id: 'tool-icons',
      phase: ChatPhase.done,
      activityItems: [
        TurnActivity.tool(
          id: 'terminal',
          tool: ToolCall(name: 'terminal', status: ToolStatus.done),
        ),
        TurnActivity.tool(
          id: 'read',
          tool: ToolCall(name: 'read_file', status: ToolStatus.done),
        ),
        TurnActivity.tool(
          id: 'write',
          tool: ToolCall(name: 'write_file', status: ToolStatus.done),
        ),
        TurnActivity.tool(
          id: 'patch',
          tool: ToolCall(name: 'patch', status: ToolStatus.done),
        ),
        TurnActivity.tool(
          id: 'web',
          tool: ToolCall(name: 'web_search', status: ToolStatus.done),
        ),
        TurnActivity.tool(
          id: 'browser',
          tool: ToolCall(name: 'browser_navigate', status: ToolStatus.done),
        ),
        TurnActivity.tool(
          id: 'vision',
          tool: ToolCall(name: 'vision_analyse', status: ToolStatus.done),
        ),
        TurnActivity.tool(
          id: 'skill',
          tool: ToolCall(name: 'skill_view', status: ToolStatus.done),
        ),
        TurnActivity.tool(
          id: 'other',
          tool: ToolCall(name: 'custom_rpc', status: ToolStatus.done),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(
          body: SingleChildScrollView(child: AssistantBubble(tools)),
        ),
      ),
    );
    await tester.pump();

    Icon icon(String key) =>
        tester.widget<Icon>(find.byKey(ValueKey('tool-kind-icon-$key')).first);

    expect(icon('terminal').icon, Icons.terminal_rounded);
    expect(icon('read-file').icon, Icons.file_open_outlined);
    expect(icon('write-file').icon, Icons.note_add_outlined);
    expect(icon('patch').icon, Icons.difference_outlined);
    expect(icon('web').icon, Icons.travel_explore_outlined);
    expect(
      find.byKey(const ValueKey('tool-kind-icon-web')),
      findsNWidgets(2),
      reason: 'web_search e browser_navigate compartilham a categoria web',
    );
    expect(icon('vision').icon, Icons.image_search_outlined);
    expect(icon('skill').icon, Icons.auto_stories_outlined);
    expect(icon('other').icon, Icons.extension_outlined);

    await closeAnimations(tester);
  });

  testWidgets('conteúdo e chevron formam colunas alinhadas', (tester) async {
    const message = AssistantMessage(
      id: 'tool-line',
      phase: ChatPhase.done,
      activityItems: [
        TurnActivity.reasoning(id: 'reasoning-line', text: 'Uma hipótese.'),
        TurnActivity.tool(
          id: 'terminal-line',
          tool: ToolCall(
            name: 'terminal',
            arg: "python3 - <<'PY' volume = {'peito': 2}",
            output: 'ok',
            duration: '0.24',
            status: ToolStatus.done,
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const MediaQuery(
          data: MediaQueryData(size: Size(320, 700)),
          child: Scaffold(body: AssistantBubble(message)),
        ),
      ),
    );
    await tester.pump();

    final primary = find.byKey(
      const ValueKey('turn-tool-primary-row-terminal-line'),
    );
    final contentColumn = find.byKey(
      const ValueKey('turn-tool-content-column-terminal-line'),
    );
    final chevronColumn = find.byKey(
      const ValueKey('turn-tool-chevron-column-terminal-line'),
    );
    final preview = find.byKey(
      const ValueKey('turn-tool-preview-terminal-line'),
    );
    expect(
      find.descendant(of: primary, matching: find.text('terminal')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: primary, matching: find.text('0.2s')),
      findsOneWidget,
    );
    expect(find.textContaining('OK'), findsNothing);
    expect(
      find.descendant(
        of: chevronColumn,
        matching: find.byIcon(Icons.keyboard_arrow_down),
      ),
      findsOneWidget,
    );
    expect(
      tester.getRect(preview).top,
      greaterThan(tester.getRect(primary).top),
    );
    expect(tester.getRect(preview).left, tester.getRect(primary).left);
    expect(
      tester.getRect(chevronColumn).center.dy,
      closeTo(tester.getRect(contentColumn).center.dy, 0.01),
    );
    final chevrons = find.byIcon(Icons.keyboard_arrow_down);
    expect(chevrons, findsNWidgets(2));
    expect(
      tester.getRect(chevrons.at(0)).right,
      tester.getRect(chevrons.at(1)).right,
      reason: 'raciocínio e tool precisam fechar no mesmo eixo à direita',
    );
    expect(tester.takeException(), isNull);

    await closeAnimations(tester);
  });

  testWidgets('estado relevante compartilha a baseline em tela estreita', (
    tester,
  ) async {
    const narrow = AssistantMessage(
      id: 'baseline',
      phase: ChatPhase.done,
      activityItems: [
        TurnActivity.tool(
          id: 'baseline-tool',
          tool: ToolCall(
            name: 'patch',
            arg: '/mnt/example-vault',
            status: ToolStatus.error,
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const MediaQuery(
          data: MediaQueryData(size: Size(320, 700)),
          child: Scaffold(body: AssistantBubble(narrow)),
        ),
      ),
    );
    await tester.pump();

    final baselineRows = tester
        .widgetList<Row>(
          find.ancestor(of: find.text('ERRO'), matching: find.byType(Row)),
        )
        .where(
          (row) =>
              row.crossAxisAlignment == CrossAxisAlignment.baseline &&
              row.textBaseline == TextBaseline.alphabetic,
        );
    expect(
      baselineRows,
      isNotEmpty,
      reason: 'nome e estado precisam compartilhar a baseline tipográfica',
    );

    await closeAnimations(tester);
  });

  testWidgets('transição de EXEC para conclusão não desloca a linha', (
    tester,
  ) async {
    const running = AssistantMessage(
      id: 'live',
      phase: ChatPhase.writing,
      activityItems: [
        TurnActivity.tool(
          id: 'live-tool',
          tool: ToolCall(
            name: 'terminal',
            arg: 'flutter test',
            status: ToolStatus.running,
          ),
        ),
      ],
    );
    const done = AssistantMessage(
      id: 'live',
      phase: ChatPhase.done,
      activityItems: [
        TurnActivity.tool(
          id: 'live-tool',
          tool: ToolCall(
            name: 'terminal',
            arg: 'flutter test',
            duration: '2.04',
            status: ToolStatus.done,
          ),
        ),
      ],
      text: 'Pronto.',
    );
    const bubbleKey = ValueKey('live-bubble');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(body: AssistantBubble(running, key: bubbleKey)),
      ),
    );
    await tester.pump();
    final row = find.byKey(const ValueKey('turn-tool-toggle-live-tool'));
    final before = tester.getRect(row);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(body: AssistantBubble(done, key: bubbleKey)),
      ),
    );
    await tester.pump(HermesMotion.estado);
    final after = tester.getRect(row);

    expect(after.top, before.top);
    expect(after.height, before.height);
    expect(find.text('2.0s'), findsOneWidget);
    expect(find.textContaining('OK'), findsNothing);

    await closeAnimations(tester);
  });

  testWidgets('texto ampliado empilha metadados e argumento longo não estoura', (
    tester,
  ) async {
    const longTool = ToolCall(
      name: 'execute_code_with_a_long_name',
      arg: 'uma/rota/muito/longa/que/precisa/continuar/legível/no/android.dart',
      output: 'Resultado disponível para inspeção.',
      duration: '12.34',
      status: ToolStatus.done,
    );
    const longMessage = AssistantMessage(
      id: 'long',
      phase: ChatPhase.done,
      activityItems: [TurnActivity.tool(id: 'long-tool', tool: longTool)],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 700),
            textScaler: TextScaler.linear(1.8),
          ),
          child: const Scaffold(body: AssistantBubble(longMessage)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('12.3s'), findsOneWidget);
    expect(find.textContaining('OK'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('turn-tool-toggle-long-tool')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('turn-tool-detail-long-tool')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await closeAnimations(tester);
  });

  testWidgets('redução de movimento mantém o estado vivo sem laço', (
    tester,
  ) async {
    const running = AssistantMessage(
      id: 'reduced',
      phase: ChatPhase.writing,
      activityItems: [
        TurnActivity.tool(
          id: 'reduced-tool',
          tool: ToolCall(
            name: 'terminal',
            arg: 'pwd',
            output: '/workspace',
            status: ToolStatus.running,
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: AssistantBubble(running)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tool-marker-running')), findsOneWidget);
    expect(find.text('EXEC'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('turn-tool-toggle-reduced-tool')),
    );
    await tester.pump();
    final disclosure = find.byKey(
      const ValueKey('turn-tool-detail-transition-reduced-tool'),
    );
    expect(tester.widget(disclosure), isNot(isA<AnimatedBuilder>()));
    expect(
      find.byKey(const ValueKey('turn-tool-detail-reduced-tool')),
      findsOneWidget,
    );

    await closeAnimations(tester);
  });

  testWidgets('modo consolidado continua disponível', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: AssistantBubble(message, chronologicalActivity: false),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('FERRAMENTAS'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('chronological-turn-activity')),
      findsNothing,
    );

    await closeAnimations(tester);
  });

  // A59: os kaomojis são desejados, mas são estado do turno em execução. Eles
  // aparecem enquanto valem e não entram na lista que a conversa reaberta
  // reconstrói.
  testWidgets('o kaomoji aparece nos dois modos e some ao ser limpo', (
    tester,
  ) async {
    const pensando = AssistantMessage(
      id: 'a2',
      phase: ChatPhase.reasoning,
      thinking: '(´･_･`) reasoning...',
    );

    for (final cronologico in [false, true]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: AssistantBubble(
                pensando,
                chronologicalActivity: cronologico,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        find.text('(´･_･`) reasoning...'),
        findsOneWidget,
        reason: cronologico ? 'modo cronológico' : 'modo consolidado',
      );
      final placeholder = tester.widget<Text>(
        find.text('(´･_･`) reasoning...'),
      );
      expect(placeholder.style!.shadows, isNull);
      final tokens = HermesTokens.of(
        tester.element(find.text('(´･_･`) reasoning...')),
      );
      expect(
        placeholder.style!.color,
        Color.lerp(tokens.accent, tokens.dim, 0.28),
      );
      expect(
        find.ancestor(
          of: find.text('(´･_･`) reasoning...'),
          matching: find.byType(ShaderMask),
        ),
        findsOneWidget,
        reason: cronologico
            ? 'modo cronológico precisa do sweep animado'
            : 'modo consolidado precisa do sweep animado',
      );
      expect(find.text('Atividade…'), findsNothing);

      // Limpo pelo gateway: o rótulo volta ao padrão, sem sobra do último
      // estado e sem virar item da timeline.
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: AssistantBubble(
                pensando.copyWith(thinking: ''),
                chronologicalActivity: cronologico,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('(´･_･`) reasoning...'), findsNothing);

      await closeAnimations(tester);
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: AssistantBubble(pensando)),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('(´･_･`) reasoning...'), findsOneWidget);
    expect(find.byType(ShaderMask), findsNothing);
  });

  testWidgets('sheet de Atividade alterna a organização do turno', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        hermesRepositoryProvider.overrideWithValue(FakeHermesRepository()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.build(),
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: TextButton(
                onPressed: () => showActivitySheet(context, ref),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Consolidado'), findsOneWidget);
    expect(find.text('Cronológico'), findsOneWidget);

    await tester.tap(find.text('Cronológico'));
    await tester.pump();
    expect(container.read(appSettingsProvider).chronologicalActivity, isTrue);
  });
}
