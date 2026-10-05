import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/hermes_repository_provider.dart';
import '../../domain/models/conversation.dart';
import '../../domain/models/conversation_page.dart';

/// Estado da lista paginada de sessões persistidas do gateway.
class ConversationFeedState {
  const ConversationFeedState({
    required this.items,
    required this.hasMore,
    required this.knownSources,
    this.selectedSource,
    this.loadingMore = false,
    this.loadMoreError,
  });

  final List<Conversation> items;
  final bool hasMore;
  final List<String> knownSources;
  final String? selectedSource;
  final bool loadingMore;
  final Object? loadMoreError;

  ConversationFeedState copyWith({
    List<Conversation>? items,
    bool? hasMore,
    List<String>? knownSources,
    String? selectedSource,
    bool clearSelectedSource = false,
    bool? loadingMore,
    Object? loadMoreError,
    bool clearLoadMoreError = false,
  }) {
    return ConversationFeedState(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      knownSources: knownSources ?? this.knownSources,
      selectedSource: clearSelectedSource
          ? null
          : selectedSource ?? this.selectedSource,
      loadingMore: loadingMore ?? this.loadingMore,
      loadMoreError: clearLoadMoreError
          ? null
          : loadMoreError ?? this.loadMoreError,
    );
  }
}

/// Feed real: pagina no gateway e reaplica o filtro de origem no servidor.
final conversationFeedProvider =
    AsyncNotifierProvider<ConversationFeed, ConversationFeedState>(
      ConversationFeed.new,
    );

class ConversationFeed extends AsyncNotifier<ConversationFeedState> {
  static const _pageSize = 50;

  @override
  Future<ConversationFeedState> build() => _firstPage();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_firstPage);
  }

  Future<void> selectSource(String? source) async {
    final current = state.maybeWhen(data: (value) => value, orElse: () => null);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _firstPage(
        source: source,
        previousSources: current?.knownSources ?? const <String>[],
      ),
    );
  }

  Future<void> loadMore() async {
    final current = state.maybeWhen(data: (value) => value, orElse: () => null);
    if (current == null || current.loadingMore || !current.hasMore) return;

    state = AsyncData(
      current.copyWith(loadingMore: true, clearLoadMoreError: true),
    );
    try {
      final page = await _page(
        offset: current.items.length,
        source: current.selectedSource,
      );
      final merged = _dedupe([...current.items, ...page.items]);
      state = AsyncData(
        current.copyWith(
          items: merged,
          hasMore: page.hasMore,
          knownSources: _mergeSources(current.knownSources, page.items),
          loadingMore: false,
          clearLoadMoreError: true,
        ),
      );
    } catch (error) {
      state = AsyncData(
        current.copyWith(loadingMore: false, loadMoreError: error),
      );
    }
  }

  Future<ConversationFeedState> _firstPage({
    String? source,
    List<String> previousSources = const <String>[],
  }) async {
    final page = await _page(source: source);
    return ConversationFeedState(
      items: page.items,
      hasMore: page.hasMore,
      knownSources: _mergeSources(previousSources, page.items),
      selectedSource: source,
    );
  }

  Future<ConversationPage> _page({int offset = 0, String? source}) {
    return ref
        .read(hermesRepositoryProvider)
        .conversationPage(limit: _pageSize, offset: offset, source: source);
  }

  List<Conversation> _dedupe(List<Conversation> values) {
    final ids = <String>{};
    return [
      for (final item in values)
        if (ids.add(item.id)) item,
    ];
  }

  List<String> _mergeSources(List<String> existing, List<Conversation> values) {
    final sources = <String>{...existing};
    for (final value in values) {
      final source = value.source?.trim();
      if (source != null && source.isNotEmpty) sources.add(source);
    }
    final sorted = sources.toList()..sort();
    return sorted;
  }
}

/// Compatibilidade para consumidores que só precisam da primeira página.
final conversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  return (await ref.watch(conversationFeedProvider.future)).items;
});
