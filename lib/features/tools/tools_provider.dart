import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/gateway_repository_provider.dart';
import '../../domain/models/server_tools.dart';
import '../../domain/repositories/gateway_repository.dart';

GatewayRepository _dashboard(Ref ref) {
  try {
    return ref.watch(gatewayRepositoryProvider);
  } catch (_) {
    throw StateError('Dashboard não pareado.');
  }
}

/// Toolsets do perfil, em ordem alfabética do rótulo.
final toolsetSettingsProvider =
    FutureProvider.autoDispose<List<ToolsetSetting>>((ref) async {
      final toolsets = await _dashboard(ref).toolsetSettings();
      return List.of(
        toolsets,
      )..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    });

final mcpServersProvider = FutureProvider.autoDispose<List<McpServerSetting>>(
  (ref) => _dashboard(ref).mcpServers(),
);

/// Mutações de toolsets e MCP (A100). Fica viva porque é usada depois de
/// `await` por telas que só a leem.
final serverToolsActionsProvider = Provider<ServerToolsActions>(
  ServerToolsActions.new,
);

class ServerToolsActions {
  ServerToolsActions(this._ref);

  final Ref _ref;

  Future<void> setToolset(String name, {required bool enabled}) async {
    await _ref
        .read(gatewayRepositoryProvider)
        .setToolsetEnabled(name, enabled: enabled);
    _ref.invalidate(toolsetSettingsProvider);
  }

  Future<void> setMcpServer(String name, {required bool enabled}) async {
    await _ref
        .read(gatewayRepositoryProvider)
        .setMcpServerEnabled(name, enabled: enabled);
    _ref.invalidate(mcpServersProvider);
  }

  Future<McpProbe> testMcpServer(String name) =>
      _ref.read(gatewayRepositoryProvider).testMcpServer(name);
}
