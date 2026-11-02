import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/gateway_repository_provider.dart';
import '../../data/hermes_repository_provider.dart';
import '../../domain/models/server_health.dart';
import '../../domain/repositories/gateway_repository.dart';

/// Estado do gateway pelo Dashboard. Sem pareamento falha com `StateError`.
final gatewayRuntimeProvider = FutureProvider.autoDispose<GatewayRuntime>(
  (ref) => _dashboard(ref).gatewayRuntime(),
);

final hostStatsProvider = FutureProvider.autoDispose<HostStats>(
  (ref) => _dashboard(ref).hostStats(),
);

/// Prontidão do API Server, que não depende do Dashboard.
final serverReadinessProvider = FutureProvider.autoDispose<ServerReadiness>(
  (ref) => ref.watch(hermesRepositoryProvider).readiness(),
);

typedef LogQuery = ({
  GatewayLogFile file,
  GatewayLogLevel level,
  String search,
});

/// Fim do log pedido, do registro mais novo para o mais antigo.
final gatewayLogsProvider = FutureProvider.autoDispose
    .family<List<LogEntry>, LogQuery>((ref, query) async {
      final lines = await _dashboard(ref).logs(
        file: query.file,
        level: query.level,
        search: query.search,
        lines: 300,
      );
      return logEntriesFrom(lines).reversed.toList();
    });

GatewayRepository _dashboard(Ref ref) {
  try {
    return ref.watch(gatewayRepositoryProvider);
  } catch (_) {
    throw StateError('Dashboard não pareado.');
  }
}

/// Intervalo entre consultas enquanto o gateway reinicia. Substituível nos
/// testes.
final restartPollIntervalProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 2),
);

/// Tempo máximo esperando o gateway voltar antes de desistir de acompanhar.
const _restartTimeout = Duration(minutes: 2);

enum RestartStage { idle, requesting, stopping, starting, done, failed }

typedef RestartState = ({RestartStage stage, String? message, Duration? took});

const _idle = (stage: RestartStage.idle, message: null, took: null);

/// Reinício do gateway e acompanhamento até ele responder de novo.
///
/// O pedido só entrega `hermes gateway restart --interrupt` ao sistema. Quem
/// diz que acabou é o `/api/status`: o gateway passa por `stopping` e
/// `starting` e volta a `running` com um estado gravado depois do pedido.
/// Enquanto isso o Dashboard pode recusar ou cair; falha de consulta não
/// interrompe o acompanhamento, só o prazo.
final gatewayRestartProvider =
    NotifierProvider.autoDispose<GatewayRestart, RestartState>(
      GatewayRestart.new,
    );

class GatewayRestart extends Notifier<RestartState> {
  @override
  RestartState build() => _idle;

  bool get busy => switch (state.stage) {
    RestartStage.requesting ||
    RestartStage.stopping ||
    RestartStage.starting => true,
    _ => false,
  };

  Future<void> restart() async {
    if (busy) return;
    final gateway = ref.read(gatewayRepositoryProvider);
    final interval = ref.read(restartPollIntervalProvider);
    final link = ref.keepAlive();
    final relogio = Stopwatch()..start();
    try {
      state = (stage: RestartStage.requesting, message: null, took: null);
      final before = await gateway.gatewayRuntime();
      await gateway.restartGateway();
      state = (stage: RestartStage.stopping, message: null, took: null);

      var sawDown = false;
      while (relogio.elapsed < _restartTimeout) {
        await Future<void>.delayed(interval);
        if (!ref.mounted) return;
        try {
          final action = await gateway.restartStatus();
          if (!action.running && (action.exitCode ?? 0) != 0) {
            state = (
              stage: RestartStage.failed,
              message:
                  'O comando de reinício terminou com o código '
                  '${action.exitCode}.',
              took: null,
            );
            return;
          }
          final now = await gateway.gatewayRuntime();
          if (!ref.mounted) return;
          if (now.phase == GatewayPhase.failed) {
            state = (
              stage: RestartStage.failed,
              message: now.exitReason?.isNotEmpty == true
                  ? 'O gateway não subiu: ${now.exitReason}'
                  : 'O gateway não conseguiu subir de novo.',
              took: null,
            );
            return;
          }
          if (now.phase != GatewayPhase.running) {
            sawDown = true;
            state = (stage: RestartStage.starting, message: null, took: null);
          }
          if (now.settledSince(before, sawDown: sawDown)) {
            state = (
              stage: RestartStage.done,
              message: null,
              took: relogio.elapsed,
            );
            ref
              ..invalidate(gatewayRuntimeProvider)
              ..invalidate(serverReadinessProvider)
              ..invalidate(hostStatsProvider);
            return;
          }
        } on GatewayAuthenticationRequired {
          rethrow;
        } catch (_) {
          // Dashboard ou gateway fora do ar no meio do reinício: é esperado.
          sawDown = true;
        }
      }
      state = (
        stage: RestartStage.failed,
        message:
            'O gateway não respondeu em ${_restartTimeout.inMinutes} minutos. '
            'Confira o log de erros.',
        took: null,
      );
    } on GatewayOperationException catch (error) {
      if (ref.mounted) {
        state = (
          stage: RestartStage.failed,
          message: error.message,
          took: null,
        );
      }
    } on GatewayAuthenticationRequired catch (error) {
      if (ref.mounted) {
        state = (
          stage: RestartStage.failed,
          message: error.message,
          took: null,
        );
      }
    } finally {
      link.close();
    }
  }

  void dismiss() => state = _idle;
}
