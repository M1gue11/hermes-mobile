// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'boot_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Faz a sequência de boot recomendada pela doc: `/health` + `/v1/capabilities`
/// + recursos efetivos. É um FutureProvider: a UI trata loading/erro/dados.

@ProviderFor(bootState)
final bootStateProvider = BootStateProvider._();

/// Faz a sequência de boot recomendada pela doc: `/health` + `/v1/capabilities`
/// + recursos efetivos. É um FutureProvider: a UI trata loading/erro/dados.

final class BootStateProvider
    extends
        $FunctionalProvider<
          AsyncValue<BootState>,
          BootState,
          async.FutureOr<BootState>
        >
    with $FutureModifier<BootState>, $FutureProvider<BootState> {
  /// Faz a sequência de boot recomendada pela doc: `/health` + `/v1/capabilities`
  /// + recursos efetivos. É um FutureProvider: a UI trata loading/erro/dados.
  BootStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bootStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bootStateHash();

  @$internal
  @override
  $FutureProviderElement<BootState> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  async.FutureOr<BootState> create(Ref ref) {
    return bootState(ref);
  }
}

String _$bootStateHash() => r'b78f1f42ba14a735692eaaa053b9324e78678fec';
