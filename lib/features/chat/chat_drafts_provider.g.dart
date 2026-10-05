// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_drafts_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Rascunhos efêmeros separados pela sessão durável da conversa.
///
/// O provider fica vivo enquanto o processo do app existir, mas não grava em
/// disco. A tela escreve com `ref.read`, portanto cada tecla não notifica nem
/// reconstrói a thread de mensagens.

@ProviderFor(ChatDrafts)
final chatDraftsProvider = ChatDraftsProvider._();

/// Rascunhos efêmeros separados pela sessão durável da conversa.
///
/// O provider fica vivo enquanto o processo do app existir, mas não grava em
/// disco. A tela escreve com `ref.read`, portanto cada tecla não notifica nem
/// reconstrói a thread de mensagens.
final class ChatDraftsProvider
    extends $NotifierProvider<ChatDrafts, Map<String, String>> {
  /// Rascunhos efêmeros separados pela sessão durável da conversa.
  ///
  /// O provider fica vivo enquanto o processo do app existir, mas não grava em
  /// disco. A tela escreve com `ref.read`, portanto cada tecla não notifica nem
  /// reconstrói a thread de mensagens.
  ChatDraftsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatDraftsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatDraftsHash();

  @$internal
  @override
  ChatDrafts create() => ChatDrafts();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, String>>(value),
    );
  }
}

String _$chatDraftsHash() => r'df86ccf9bbed74ca627b2e9d53da830d1756b42a';

/// Rascunhos efêmeros separados pela sessão durável da conversa.
///
/// O provider fica vivo enquanto o processo do app existir, mas não grava em
/// disco. A tela escreve com `ref.read`, portanto cada tecla não notifica nem
/// reconstrói a thread de mensagens.

abstract class _$ChatDrafts extends $Notifier<Map<String, String>> {
  Map<String, String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Map<String, String>, Map<String, String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, String>, Map<String, String>>,
              Map<String, String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
