// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment_composer_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AttachmentComposerController)
final attachmentComposerControllerProvider =
    AttachmentComposerControllerProvider._();

final class AttachmentComposerControllerProvider
    extends
        $NotifierProvider<
          AttachmentComposerController,
          AttachmentComposerState
        > {
  AttachmentComposerControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'attachmentComposerControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$attachmentComposerControllerHash();

  @$internal
  @override
  AttachmentComposerController create() => AttachmentComposerController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AttachmentComposerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AttachmentComposerState>(value),
    );
  }
}

String _$attachmentComposerControllerHash() =>
    r'2064efbb32031b0b7948bf80ca73700a25f0bc42';

abstract class _$AttachmentComposerController
    extends $Notifier<AttachmentComposerState> {
  AttachmentComposerState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AttachmentComposerState, AttachmentComposerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AttachmentComposerState, AttachmentComposerState>,
              AttachmentComposerState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
