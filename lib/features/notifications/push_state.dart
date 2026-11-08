import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/models/push_device.dart';

part 'push_state.freezed.dart';

enum PushPhase {
  loading,

  /// Desligado por escolha da pessoa.
  off,

  /// Nenhum distribuidor UnifiedPush instalado (o app ntfy, por exemplo).
  needsDistributor,

  /// Mais de um distribuidor e nenhum escolhido.
  choosingDistributor,

  /// Esperando o distribuidor entregar o endpoint ou o servidor aceitá-lo.
  registering,
  active,
  failed,
}

@freezed
abstract class PushSetupState with _$PushSetupState {
  const PushSetupState._();

  const factory PushSetupState({
    @Default(PushPhase.loading) PushPhase phase,

    /// A pessoa ligou as notificações, mesmo que falte distribuidor ou plugin.
    @Default(false) bool enabled,
    @Default(<String>[]) List<String> distributors,
    String? distributor,

    /// Host do endpoint, para a pessoa reconhecer o servidor ntfy.
    String? endpointHost,

    /// O servidor já tem o endpoint atual deste aparelho.
    @Default(false) bool synced,

    /// `null` enquanto não foi possível perguntar ao Dashboard.
    bool? pluginAvailable,
    @Default(false) bool serverEncryption,
    @Default(false) bool permissionDenied,
    String? error,
    @Default(false) bool busy,
    PushTestResult? lastTest,
  }) = _PushSetupState;

  /// Push do servidor ligado de ponta a ponta.
  bool get delivering => phase == PushPhase.active && synced;
}
