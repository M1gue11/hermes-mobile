// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_actions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Ações mutáveis de sessão. Mantém REST fora dos widgets e atualiza a lista.

@ProviderFor(ConversationActions)
final conversationActionsProvider = ConversationActionsProvider._();

/// Ações mutáveis de sessão. Mantém REST fora dos widgets e atualiza a lista.
final class ConversationActionsProvider
    extends $AsyncNotifierProvider<ConversationActions, void> {
  /// Ações mutáveis de sessão. Mantém REST fora dos widgets e atualiza a lista.
  ConversationActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'conversationActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$conversationActionsHash();

  @$internal
  @override
  ConversationActions create() => ConversationActions();
}

String _$conversationActionsHash() =>
    r'6361f7866a75403e69440801f12952761eae9e72';

/// Ações mutáveis de sessão. Mantém REST fora dos widgets e atualiza a lista.

abstract class _$ConversationActions extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
