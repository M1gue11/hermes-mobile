// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'machine_session.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Onde a chave, o alvo e a impressão digital moram.
///
/// Provider próprio para o teste poder trocar por um de memória: o
/// `SecureSshStore` fala com o KeyStore do Android e não existe fora do
/// aparelho.

@ProviderFor(sshStore)
final sshStoreProvider = SshStoreProvider._();

/// Onde a chave, o alvo e a impressão digital moram.
///
/// Provider próprio para o teste poder trocar por um de memória: o
/// `SecureSshStore` fala com o KeyStore do Android e não existe fora do
/// aparelho.

final class SshStoreProvider
    extends $FunctionalProvider<SshStore, SshStore, SshStore>
    with $Provider<SshStore> {
  /// Onde a chave, o alvo e a impressão digital moram.
  ///
  /// Provider próprio para o teste poder trocar por um de memória: o
  /// `SecureSshStore` fala com o KeyStore do Android e não existe fora do
  /// aparelho.
  SshStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sshStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sshStoreHash();

  @$internal
  @override
  $ProviderElement<SshStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SshStore create(Ref ref) {
    return sshStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SshStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SshStore>(value),
    );
  }
}

String _$sshStoreHash() => r'2ed248df2a15960d3a35ed33226881bd616d6998';

/// Guarda a chave, o alvo e a sessão viva.
///
/// `keepAlive` de propósito: sair da tela do terminal para ler uma conversa e
/// voltar não pode derrubar o shell nem apagar o que estava na tela.

@ProviderFor(MachineSession)
final machineSessionProvider = MachineSessionProvider._();

/// Guarda a chave, o alvo e a sessão viva.
///
/// `keepAlive` de propósito: sair da tela do terminal para ler uma conversa e
/// voltar não pode derrubar o shell nem apagar o que estava na tela.
final class MachineSessionProvider
    extends $NotifierProvider<MachineSession, MachineState> {
  /// Guarda a chave, o alvo e a sessão viva.
  ///
  /// `keepAlive` de propósito: sair da tela do terminal para ler uma conversa e
  /// voltar não pode derrubar o shell nem apagar o que estava na tela.
  MachineSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'machineSessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$machineSessionHash();

  @$internal
  @override
  MachineSession create() => MachineSession();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MachineState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MachineState>(value),
    );
  }
}

String _$machineSessionHash() => r'1e46c71b8e07177846b599f4559e88997f2b898e';

/// Guarda a chave, o alvo e a sessão viva.
///
/// `keepAlive` de propósito: sair da tela do terminal para ler uma conversa e
/// voltar não pode derrubar o shell nem apagar o que estava na tela.

abstract class _$MachineSession extends $Notifier<MachineState> {
  MachineState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MachineState, MachineState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MachineState, MachineState>,
              MachineState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
