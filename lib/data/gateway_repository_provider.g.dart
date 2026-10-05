// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gateway_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(gatewayRepository)
final gatewayRepositoryProvider = GatewayRepositoryProvider._();

final class GatewayRepositoryProvider
    extends
        $FunctionalProvider<
          GatewayRepository,
          GatewayRepository,
          GatewayRepository
        >
    with $Provider<GatewayRepository> {
  GatewayRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gatewayRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gatewayRepositoryHash();

  @$internal
  @override
  $ProviderElement<GatewayRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GatewayRepository create(Ref ref) {
    return gatewayRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GatewayRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GatewayRepository>(value),
    );
  }
}

String _$gatewayRepositoryHash() => r'79f5bce206aa4b6095d5c727c59db12c74c21dc0';

@ProviderFor(attachmentSource)
final attachmentSourceProvider = AttachmentSourceProvider._();

final class AttachmentSourceProvider
    extends
        $FunctionalProvider<
          AttachmentSource,
          AttachmentSource,
          AttachmentSource
        >
    with $Provider<AttachmentSource> {
  AttachmentSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'attachmentSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$attachmentSourceHash();

  @$internal
  @override
  $ProviderElement<AttachmentSource> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AttachmentSource create(Ref ref) {
    return attachmentSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AttachmentSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AttachmentSource>(value),
    );
  }
}

String _$attachmentSourceHash() => r'8a5b01df945613165f6f7299e78e009432c258b7';
