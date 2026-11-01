// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jobs_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Rotinas agendadas do agente (A95), das que rodam ou vão rodar primeiro
/// para as pausadas e encerradas.

@ProviderFor(cronJobs)
final cronJobsProvider = CronJobsProvider._();

/// Rotinas agendadas do agente (A95), das que rodam ou vão rodar primeiro
/// para as pausadas e encerradas.

final class CronJobsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CronJob>>,
          List<CronJob>,
          FutureOr<List<CronJob>>
        >
    with $FutureModifier<List<CronJob>>, $FutureProvider<List<CronJob>> {
  /// Rotinas agendadas do agente (A95), das que rodam ou vão rodar primeiro
  /// para as pausadas e encerradas.
  CronJobsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cronJobsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cronJobsHash();

  @$internal
  @override
  $FutureProviderElement<List<CronJob>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CronJob>> create(Ref ref) {
    return cronJobs(ref);
  }
}

String _$cronJobsHash() => r'e7b645824cbcf803434b53b159b2b05520b5a770';

/// Mutações de rotinas. Mantém REST fora dos widgets e atualiza a lista.

@ProviderFor(CronJobActions)
final cronJobActionsProvider = CronJobActionsProvider._();

/// Mutações de rotinas. Mantém REST fora dos widgets e atualiza a lista.
final class CronJobActionsProvider
    extends $AsyncNotifierProvider<CronJobActions, void> {
  /// Mutações de rotinas. Mantém REST fora dos widgets e atualiza a lista.
  CronJobActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cronJobActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cronJobActionsHash();

  @$internal
  @override
  CronJobActions create() => CronJobActions();
}

String _$cronJobActionsHash() => r'e5c8843caeb9ddfa2c8b8647e7e6a79026784ad9';

/// Mutações de rotinas. Mantém REST fora dos widgets e atualiza a lista.

abstract class _$CronJobActions extends $AsyncNotifier<void> {
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
