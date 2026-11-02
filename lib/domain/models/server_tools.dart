import 'package:freezed_annotation/freezed_annotation.dart';

part 'server_tools.freezed.dart';

/// Toolset configurável do perfil, de `GET /api/tools/toolsets`.
///
/// Ligar ou desligar grava `platform_toolsets` da plataforma [platform]
/// (`cli` para quase todos), que é a lista que as sessões do TUI, e portanto
/// do app, usam ao criar o agente. Vale para as próximas conversas.
@freezed
abstract class ToolsetSetting with _$ToolsetSetting {
  const factory ToolsetSetting({
    required String name,
    required String label,
    @Default('') String description,
    @Default(false) bool enabled,

    /// As credenciais que o toolset pede estão presentes.
    @Default(true) bool configured,
    @Default(0) int toolCount,
    @Default('cli') String platform,
  }) = _ToolsetSetting;
}

/// Servidor MCP configurado, de `GET /api/mcp/servers`.
///
/// O app guarda só o que precisa para ligar, desligar e testar: comando,
/// argumentos, URL e variáveis ficam no servidor.
@freezed
abstract class McpServerSetting with _$McpServerSetting {
  const McpServerSetting._();

  const factory McpServerSetting({
    required String name,

    /// `stdio`, `http` ou `unknown`.
    @Default('unknown') String transport,

    /// `oauth`, `header` ou nulo.
    String? auth,
    @Default(true) bool enabled,

    /// Plugin que fornece o servidor; esses não podem ser alterados.
    String? plugin,
  }) = _McpServerSetting;

  bool get editable => plugin == null;
}

/// Resultado de `POST /api/mcp/servers/{name}/test`: conectar, listar as
/// ferramentas e desconectar.
@freezed
abstract class McpProbe with _$McpProbe {
  const factory McpProbe({
    required bool ok,
    String? error,
    @Default(<String>[]) List<String> tools,
  }) = _McpProbe;
}
