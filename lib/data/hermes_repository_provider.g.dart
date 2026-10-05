// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hermes_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider do [HermesRepository]: a "costura" de injeção de dependência.
///
/// O pareamento injeta o adapter HTTP nesta costura antes de montar o app.
/// Testes também a sobrescrevem com um fake determinístico de teste.

@ProviderFor(hermesRepository)
final hermesRepositoryProvider = HermesRepositoryProvider._();

/// Provider do [HermesRepository]: a "costura" de injeção de dependência.
///
/// O pareamento injeta o adapter HTTP nesta costura antes de montar o app.
/// Testes também a sobrescrevem com um fake determinístico de teste.

final class HermesRepositoryProvider
    extends
        $FunctionalProvider<
          HermesRepository,
          HermesRepository,
          HermesRepository
        >
    with $Provider<HermesRepository> {
  /// Provider do [HermesRepository]: a "costura" de injeção de dependência.
  ///
  /// O pareamento injeta o adapter HTTP nesta costura antes de montar o app.
  /// Testes também a sobrescrevem com um fake determinístico de teste.
  HermesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hermesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hermesRepositoryHash();

  @$internal
  @override
  $ProviderElement<HermesRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HermesRepository create(Ref ref) {
    return hermesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HermesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HermesRepository>(value),
    );
  }
}

String _$hermesRepositoryHash() => r'aa9bbe2ed37bb9cd3cf2567ce4d9f34a1c14c1d6';
