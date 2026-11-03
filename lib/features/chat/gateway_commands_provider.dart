import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/gateway_command.dart';
import '../../domain/repositories/gateway_repository.dart';
import 'chat_controller.dart';

final gatewayCommandCatalogProvider = FutureProvider.autoDispose
    .family<GatewayCommandCatalog, String>((ref, sessionId) async {
      final chat = ref.read(chatControllerProvider.notifier);
      final turn = await chat.commandSession();
      if (turn.storedSessionId != sessionId) {
        throw const GatewayOperationException(
          'A conversa mudou. Abra os comandos novamente.',
        );
      }
      return turn.commandCatalog();
    });

final gatewayCommandCompletionsProvider = FutureProvider.autoDispose
    .family<GatewaySlashCompletions, ({String sessionId, String text})>((
      ref,
      query,
    ) async {
      final ready = Completer<void>();
      final timer = Timer(const Duration(milliseconds: 220), ready.complete);
      ref.onDispose(() {
        timer.cancel();
        if (!ready.isCompleted) ready.complete();
      });
      await ready.future;
      if (!ref.mounted) return const GatewaySlashCompletions();
      final turn = await ref
          .read(chatControllerProvider.notifier)
          .commandSession();
      if (!ref.mounted || turn.storedSessionId != query.sessionId) {
        return const GatewaySlashCompletions();
      }
      return turn.completeSlash(query.text);
    });

class CommandConfirmationRequired implements Exception {
  const CommandConfirmationRequired(this.command, this.scope);
  final String command;
  final String scope;
}

enum CommandClientAction { none, model, sessions, catalog }

class CommandOutcome {
  const CommandOutcome({
    this.result,
    this.action = CommandClientAction.none,
    this.notice = '',
  });
  final GatewayCommandResult? result;
  final CommandClientAction action;
  final String notice;
}

class CommandRecord {
  const CommandRecord({
    required this.sessionId,
    required this.command,
    required this.output,
    required this.at,
  });
  final String sessionId;
  final String command;
  final String output;
  final DateTime at;
}

class GatewayCommandsState {
  const GatewayCommandsState({
    this.busy = false,
    this.command = '',
    this.history = const [],
    this.uncertainCommand,
  });
  final bool busy;
  final String command;
  final List<CommandRecord> history;
  final String? uncertainCommand;
}

final gatewayCommandsProvider =
    NotifierProvider<GatewayCommands, GatewayCommandsState>(
      GatewayCommands.new,
    );

class GatewayCommands extends Notifier<GatewayCommandsState> {
  @override
  GatewayCommandsState build() => const GatewayCommandsState();

  Future<CommandOutcome> execute(String raw, {bool confirmed = false}) async {
    final invocation = parseSlashInvocation(raw);
    if (invocation == null) {
      throw const GatewayOperationException(
        'Digite um comando iniciado por /.',
      );
    }
    if (state.busy) {
      throw const GatewayOperationException('Já há um comando em execução.');
    }
    final controller = ref.read(chatControllerProvider.notifier);
    final sessionId = ref.read(chatControllerProvider).sessionId;
    if (sessionId == null) {
      throw const GatewayOperationException(
        'Abra uma conversa para usar comandos.',
      );
    }
    final history = state.history;
    final uncertain = state.uncertainCommand;
    state = GatewayCommandsState(
      busy: true,
      command: raw,
      history: history,
      uncertainCommand: uncertain,
    );
    try {
      final catalog = await ref.read(
        gatewayCommandCatalogProvider(sessionId).future,
      );
      final command =
          catalog.find(invocation.name) ??
          GatewayCommand(name: invocation.name, description: '', custom: true);
      if (command.unavailableReason case final reason?) {
        throw GatewayOperationException(reason);
      }
      if (!confirmed &&
          (command.needsConfirmation(invocation.arguments) ||
              uncertain == raw)) {
        throw CommandConfirmationRequired(
          raw,
          uncertain == raw
              ? 'A confirmação anterior não chegou. A ação pode já ter ocorrido; confira o estado antes de repetir.'
              : command.scope(invocation.arguments),
        );
      }
      _sameSession(sessionId);
      if (!command.custom && !command.skill) {
        if (command.name == 'stop' && invocation.arguments.isEmpty) {
          if (!await controller.stop()) {
            throw const GatewayOperationException(
              'Não há uma execução ativa que possa ser interrompida nesta conversa.',
            );
          }
          _record(sessionId, raw, 'Pedido de interrupção enviado.');
          return const CommandOutcome(notice: 'Pedido de interrupção enviado.');
        }
        if (const {'new', 'reset', 'clear'}.contains(command.name) &&
            invocation.arguments.isEmpty) {
          await controller.newChat();
          _record(sessionId, raw, 'Nova conversa aberta.');
          return const CommandOutcome(notice: 'Nova conversa aberta.');
        }
        if (invocation.arguments.isEmpty) {
          final action = switch (command.name) {
            'model' => CommandClientAction.model,
            'sessions' => CommandClientAction.sessions,
            'commands' => CommandClientAction.catalog,
            _ => CommandClientAction.none,
          };
          if (action != CommandClientAction.none) {
            return CommandOutcome(action: action);
          }
        }
      }
      final turn = await controller.commandSession();
      _sameSession(sessionId);
      var result = await turn.executeCommand(raw);
      var currentInvocation = invocation;
      final visited = <String>{raw};
      while (result.kind == GatewayCommandResultKind.alias) {
        final target = result.target.startsWith('/')
            ? result.target
            : '/${result.target}';
        final next =
            '$target${currentInvocation.arguments.isEmpty ? '' : ' ${currentInvocation.arguments}'}';
        if (visited.length >= 8 || !visited.add(next)) {
          throw const GatewayOperationException(
            'O alias do comando forma um ciclo. Revise-o no Hermes.',
          );
        }
        _sameSession(sessionId);
        currentInvocation = parseSlashInvocation(next) ?? currentInvocation;
        result = await turn.executeCommand(next);
      }
      if (ref.read(chatControllerProvider).sessionId != sessionId &&
          result.kind == GatewayCommandResultKind.output) {
        _record(sessionId, raw, _commandOutput(result));
        return const CommandOutcome(
          notice:
              'O resultado foi guardado nos comandos da conversa de origem.',
        );
      }
      _sameSession(sessionId);
      if (result.kind == GatewayCommandResultKind.send ||
          result.kind == GatewayCommandResultKind.skill) {
        final sent = await controller.send(
          result.message,
          displayText: result.display.isEmpty ? raw : result.display,
        );
        if (!sent) {
          throw const GatewayOperationException(
            'O envio do comando não foi confirmado. Confira a conversa antes de repetir.',
            method: 'prompt.submit',
          );
        }
        _record(
          sessionId,
          raw,
          result.notice.isEmpty ? 'Pedido enviado ao agente.' : result.notice,
        );
        return CommandOutcome(result: result, notice: result.notice);
      }
      final updateNotice = result.status == 'pending'
          ? 'O Hermes ainda está executando esta ação. Confira o estado antes de repetir.'
          : await controller.refreshAfterCommand(sessionId);
      final output = _commandOutput(result);
      _record(
        sessionId,
        raw,
        [
          result.warning,
          output,
          updateNotice ?? '',
        ].where((s) => s.isNotEmpty).join('\n\n'),
      );
      return CommandOutcome(
        result: result,
        notice: [
          result.notice,
          updateNotice ?? '',
        ].where((s) => s.isNotEmpty).join('\n'),
      );
    } on TimeoutException {
      _uncertain(raw, history);
      throw const GatewayOperationException(
        'A confirmação do comando não chegou. Ele pode continuar no servidor; confira o estado antes de repetir.',
      );
    } on GatewayOperationException catch (error) {
      if (error is! GatewayRequestNotSent &&
          error.code == null &&
          error.method != null) {
        _uncertain(raw, history);
      }
      rethrow;
    } finally {
      if (state.busy) {
        state = GatewayCommandsState(
          history: state.history,
          uncertainCommand: state.uncertainCommand,
        );
      }
    }
  }

  void _sameSession(String sessionId) {
    if (ref.read(chatControllerProvider).sessionId != sessionId) {
      throw const GatewayOperationException(
        'A conversa mudou durante o comando. Confira o resultado na conversa de origem.',
      );
    }
  }

  void _uncertain(String raw, List<CommandRecord> history) {
    state = GatewayCommandsState(history: history, uncertainCommand: raw);
  }

  void _record(String sessionId, String command, String output) {
    state = GatewayCommandsState(
      busy: true,
      command: command,
      history: [
        CommandRecord(
          sessionId: sessionId,
          command: command,
          output: output,
          at: DateTime.now(),
        ),
        ...state.history.take(39),
      ],
    );
  }
}

String _commandOutput(GatewayCommandResult result) {
  if (result.kind == GatewayCommandResultKind.prefill) {
    return 'Texto preparado para revisão no campo de mensagem.';
  }
  if (result.output.trim().isNotEmpty) return stripCommandAnsi(result.output);
  return result.status == 'pending'
      ? 'Ação em andamento no Hermes.'
      : 'Comando concluído sem saída de texto.';
}

String stripCommandAnsi(String text) =>
    text.replaceAll(RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]'), '');
