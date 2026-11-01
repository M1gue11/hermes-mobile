import 'dart:async' as async;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/hermes_repository_provider.dart';
import '../../domain/models/capabilities.dart';
import '../../domain/models/health_status.dart';
import '../../domain/models/hermes_failure.dart';
import '../../domain/models/hermes_model.dart';
import '../../domain/models/hermes_toolset.dart';

part 'boot_provider.g.dart';

/// Estado de boot do app (record): servidor online? quais modelos? o que suporta?
/// Alimenta o indicador "Gateway · online", o model picker e o botão cancelar.
///
/// Skills ficam fora: o catálogo tem provider próprio, e uma falha nele não
/// pode derrubar o seletor de modelos nem o indicador do gateway.
typedef BootState = ({
  bool online,
  List<HermesModel> models,
  List<HermesToolset> toolsets,
  Capabilities capabilities,
});

/// Faz a sequência de boot recomendada pela doc: `/health` + `/v1/capabilities`
/// + recursos efetivos. É um FutureProvider: a UI trata loading/erro/dados.
@riverpod
Future<BootState> bootState(Ref ref) async {
  final repo = ref.watch(hermesRepositoryProvider);

  final HealthStatus health;
  final Capabilities capabilities;
  final List<HermesModel> models;
  final List<HermesToolset> toolsets;
  try {
    (health, capabilities, models, toolsets) = await (
      repo.health(),
      repo.capabilities(),
      repo.models(),
      repo.toolsets(),
    ).wait;
  } on ParallelWaitError catch (erro) {
    // O `.wait` de record embrulha as causas num `ParallelWaitError`, e sem
    // desembrulhar a tela diria "resposta inesperada" para uma simples queda de
    // rede. Aqui vale a **primeira** causa: as chamadas vão para o mesmo
    // servidor, então quando uma cai por falta de alcance as outras caem pelo
    // mesmo motivo. Ver A7.
    //
    // O `AsyncError` tem de ser o do `dart:async`: o `riverpod_annotation`
    // exporta um homônimo, e com ele este cast falhava e toda falha de boot
    // virava "resposta inesperada".
    final (a, b, c, d) =
        erro.errors
            as (
              async.AsyncError?,
              async.AsyncError?,
              async.AsyncError?,
              async.AsyncError?,
            );
    final primeira = [
      a,
      b,
      c,
      d,
    ].firstWhere((item) => item != null, orElse: () => null);
    throw hermesFailureFrom(primeira?.error);
  }
  return (
    online: health.online,
    models: models,
    toolsets: toolsets,
    capabilities: capabilities,
  );
}
