import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/features/chat/markdown_showcase_screen.dart';

void main() {
  testWidgets('carrega a fixture no renderer real', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: MarkdownShowcaseScreen(
          loadMarkdown: () async => '# Título\n\nCorpo da fixture.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Showcase Markdown'), findsOneWidget);
    expect(find.text('Título'), findsOneWidget);
    expect(find.text('Corpo da fixture.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('markdown-showcase-document')),
      findsOneWidget,
    );
  });

  testWidgets('oferece recuperação quando a fixture falha', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: MarkdownShowcaseScreen(
          loadMarkdown: () async {
            attempts++;
            if (attempts == 1) throw StateError('fixture ausente');
            return 'Recuperado';
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível carregar o showcase.'), findsOneWidget);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(find.text('Recuperado'), findsOneWidget);
    expect(attempts, 2);
  });
}
