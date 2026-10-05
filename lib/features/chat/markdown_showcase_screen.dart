import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/hermes_tokens.dart';
import '../../core/widgets/paper_texture.dart';
import 'widgets/hermes_markdown.dart';

const markdownShowcaseAsset =
    'assets/dev/obsidian_markdown_renderer_showcase.md';

typedef MarkdownShowcaseLoader = Future<String> Function();

/// Superfície de desenvolvimento para comparar o renderer real com o Obsidian.
///
/// A rota e sua entrada nos ajustes só existem em builds debug. A fixture é
/// local para que a mesma amostra possa ser reproduzida no emulador sem rede,
/// sem depender do filesystem do computador e sem criar conversa no gateway.
class MarkdownShowcaseScreen extends StatefulWidget {
  const MarkdownShowcaseScreen({super.key, this.loadMarkdown});

  final MarkdownShowcaseLoader? loadMarkdown;

  @override
  State<MarkdownShowcaseScreen> createState() => _MarkdownShowcaseScreenState();
}

class _MarkdownShowcaseScreenState extends State<MarkdownShowcaseScreen> {
  late Future<String> _markdown;

  @override
  void initState() {
    super.initState();
    _markdown = _load();
  }

  Future<String> _load() =>
      widget.loadMarkdown?.call() ??
      rootBundle.loadString(markdownShowcaseAsset);

  void _retry() {
    final nextLoad = _load();
    setState(() {
      _markdown = nextLoad;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = HermesTokens.of(context);
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: PaperTexture()),
          SafeArea(
            child: Column(
              children: [
                _ShowcaseBar(onBack: context.pop),
                Expanded(
                  child: FutureBuilder<String>(
                    future: _markdown,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return _LoadFailure(onRetry: _retry);
                      }
                      final markdown = snapshot.data;
                      if (markdown == null) {
                        return Center(
                          child: SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: tokens.accentInk,
                            ),
                          ),
                        );
                      }
                      return Scrollbar(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 48),
                          child: Semantics(
                            key: const ValueKey('markdown-showcase-document'),
                            label: 'Showcase Markdown do Obsidian',
                            child: HermesMarkdown(markdown),
                          ),
                        ),
                      );
                    },
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

class _ShowcaseBar extends StatelessWidget {
  const _ShowcaseBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final tokens = HermesTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tokens.line)),
      ),
      child: SizedBox(
        height: 68,
        child: Row(
          children: [
            IconButton(
              tooltip: 'Voltar',
              onPressed: onBack,
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: tokens.ink),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Showcase Markdown',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tokens
                        .serifIn(FontWeight.w500)
                        .copyWith(fontSize: 18, color: tokens.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'FIXTURE LOCAL · OBSIDIAN',
                    style: tokens.mono.copyWith(
                      fontSize: 9,
                      letterSpacing: 1.25,
                      color: tokens.faint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = HermesTokens.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined, color: tokens.accentInk, size: 28),
            const SizedBox(height: 12),
            Text(
              'Não foi possível carregar o showcase.',
              textAlign: TextAlign.center,
              style: tokens.serif.copyWith(fontSize: 16, color: tokens.ink),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
