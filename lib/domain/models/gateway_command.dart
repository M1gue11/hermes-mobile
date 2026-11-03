/// Wire contract: Hermes v0.22.5, tui_gateway/contracts/tools_commands.py.
/// Command discovery belongs to the server, including plugins and Skills.
class GatewayCommand {
  const GatewayCommand({
    required this.name,
    required this.description,
    this.category = '',
    this.argumentMode,
    this.desktop,
    this.skill = false,
    this.custom = false,
    this.subcommands = const [],
  });

  final String name;
  final String description;
  final String category;
  final String? argumentMode;
  final String? desktop;
  final bool skill;
  final bool custom;
  final List<String> subcommands;

  String? get unavailableReason => switch (name) {
    'quit' ||
    'exit' ||
    'redraw' ||
    'paste' ||
    'copy' => 'Este comando depende da interface do computador.',
    _ when desktop == 'terminal' && name != 'clear' =>
      'Este comando precisa de um terminal no computador.',
    _ => null,
  };

  bool needsConfirmation(String arguments) {
    if (skill) return false;
    if (custom) return true;
    if (const {'model', 'sessions', 'stop'}.contains(name) &&
        arguments.trim().isEmpty) {
      return false;
    }
    if (const {
      'help',
      'commands',
      'status',
      'context',
      'version',
      'whoami',
      'usage',
      'insights',
      'profile',
      'diff',
      'toolsets',
      'platforms',
    }.contains(name)) {
      return arguments.trim().isNotEmpty;
    }
    if (const {'memory', 'skills'}.contains(name)) {
      return !const {'', 'pending', 'diff'}.contains(arguments.trim());
    }
    return true;
  }

  String scope(String arguments) {
    if (custom) {
      return 'Pode executar ações no servidor ou alterar o perfil do Hermes.';
    }
    if (arguments.contains('--global') ||
        const {
          'config',
          'cron',
          'tools',
          'toolsets',
          'reload',
          'update',
          'plugins',
          'personality',
          'memory',
          'skills',
          'profile',
          'login',
          'logout',
        }.contains(name)) {
      return 'Pode alterar o perfil do Hermes e afetar outras conversas.';
    }
    if (name == 'undo') return 'Remove turnos do histórico desta conversa.';
    if (const {'compress', 'compact'}.contains(name)) {
      return 'Resume o contexto desta conversa e pode consumir tokens.';
    }
    if (const {'new', 'reset', 'clear'}.contains(name)) {
      return 'Abre uma nova conversa. A conversa atual permanece no histórico.';
    }
    if (skill) return 'Envia um novo pedido ao agente nesta conversa.';
    return 'Dependendo dos argumentos, este comando pode alterar a conversa ou o perfil do Hermes.';
  }
}

class GatewayCommandCatalog {
  const GatewayCommandCatalog({
    this.commands = const [],
    this.aliases = const {},
    this.warning = '',
    this.hiddenCommands = const {},
  });
  final List<GatewayCommand> commands;
  final Map<String, String> aliases;
  final String warning;
  final Map<String, GatewayCommand> hiddenCommands;

  GatewayCommand? find(String name) {
    final key = name.toLowerCase().replaceFirst(RegExp(r'^/+'), '');
    final canonical = (aliases['/$key'] ?? key)
        .replaceFirst(RegExp(r'^/+'), '')
        .toLowerCase();
    for (final command in commands.reversed) {
      if (command.name == canonical) return command;
    }
    return hiddenCommands[canonical];
  }

  factory GatewayCommandCatalog.fromJson(Map<String, dynamic> json) {
    if (json['pairs'] is! List) {
      throw const FormatException('Missing command pairs');
    }
    final category = <String, String>{};
    if (json['categories'] case final List groups) {
      for (final group in groups.whereType<Map>()) {
        for (final pair
            in (group['pairs'] as List? ?? const []).whereType<List>()) {
          if (pair.isNotEmpty && pair.first is String) {
            category[pair.first as String] = '${group['name'] ?? ''}';
          }
        }
      }
    }
    final metadata = json['commands'] is Map
        ? json['commands'] as Map
        : const {};
    final skills = json['skills'] is Map ? json['skills'] as Map : const {};
    final plugins = json['plugin_commands'] is Map
        ? json['plugin_commands'] as Map
        : const {};
    final subs = json['sub'] is Map ? json['sub'] as Map : const {};
    final entries = <String, GatewayCommand>{};
    for (final pair in (json['pairs'] as List).whereType<List>()) {
      if (pair.length < 2 || pair[0] is! String || pair[1] is! String) continue;
      final key = pair[0] as String;
      final name = key.replaceFirst(RegExp(r'^/+'), '').toLowerCase();
      final meta = metadata[key] is Map ? metadata[key] as Map : const {};
      final group = category[key] ?? (skills.containsKey(key) ? 'Skills' : '');
      entries[name] = GatewayCommand(
        name: name,
        description: pair[1] as String,
        category: group,
        argumentMode: meta['argument_mode'] as String?,
        desktop: meta['desktop'] as String?,
        skill: skills.containsKey(key),
        custom:
            plugins.containsKey(name) ||
            const {'User commands', 'Plugin commands'}.contains(group),
        subcommands:
            (subs[key] is List
                    ? subs[key] as List
                    : subs[name] is List
                    ? subs[name] as List
                    : const [])
                .whereType<String>()
                .toList(),
      );
    }
    final aliases = <String, String>{};
    if (json['canon'] case final Map map) {
      for (final entry in map.entries) {
        if (entry.key is String && entry.value is String) {
          aliases[(entry.key as String).toLowerCase()] = entry.value as String;
        }
      }
    }
    final hidden = <String, GatewayCommand>{};
    for (final key in metadata.keys.whereType<String>()) {
      final name = key.replaceFirst(RegExp(r'^/+'), '').toLowerCase();
      if (entries.containsKey(name)) continue;
      final meta = metadata[key];
      if (meta is Map) {
        hidden[name] = GatewayCommand(
          name: name,
          description: '',
          argumentMode: meta['argument_mode'] as String?,
          desktop: meta['desktop'] as String?,
          custom: plugins.containsKey(name),
        );
      }
    }
    return GatewayCommandCatalog(
      commands: entries.values.toList(),
      aliases: aliases,
      hiddenCommands: hidden,
      warning: json['warning'] is String ? json['warning'] as String : '',
    );
  }
}

typedef SlashInvocation = ({String name, String arguments});

/// A path (/usr/local) or prose containing / is not a command. Preserve pasted
/// multiline argument contents; only surrounding whitespace is removed.
SlashInvocation? parseSlashInvocation(String text) {
  if (!RegExp(r'^/[^\s/]*(?:\s|$)').hasMatch(text)) return null;
  final match = RegExp(r'^/([^\s/]+)([\s\S]*)$').firstMatch(text);
  return match == null
      ? null
      : (name: match[1]!.toLowerCase(), arguments: match[2]!.trim());
}

enum GatewayCommandResultKind { output, alias, send, skill, prefill }

class GatewayCommandResult {
  const GatewayCommandResult({
    required this.kind,
    this.output = '',
    this.message = '',
    this.display = '',
    this.target = '',
    this.notice = '',
    this.warning = '',
    this.status = '',
  });
  final GatewayCommandResultKind kind;
  final String output;
  final String message;
  final String display;
  final String target;
  final String notice;
  final String warning;
  final String status;

  factory GatewayCommandResult.fromJson(Map<String, dynamic> json) {
    String value(String key) => json[key] is String ? json[key] as String : '';
    final kind = switch (json['type']) {
      'alias' => GatewayCommandResultKind.alias,
      'send' => GatewayCommandResultKind.send,
      'skill' => GatewayCommandResultKind.skill,
      'prefill' => GatewayCommandResultKind.prefill,
      'exec' || 'plugin' => GatewayCommandResultKind.output,
      null when json['output'] is String => GatewayCommandResultKind.output,
      _ => throw const FormatException('Unknown command result'),
    };
    if ((kind == GatewayCommandResultKind.alias &&
            value('target').trim().isEmpty) ||
        (const {
              GatewayCommandResultKind.send,
              GatewayCommandResultKind.skill,
              GatewayCommandResultKind.prefill,
            }.contains(kind) &&
            value('message').trim().isEmpty)) {
      throw const FormatException('Incomplete command directive');
    }
    return GatewayCommandResult(
      kind: kind,
      output: value('output'),
      message: value('message'),
      display: value('display'),
      target: value('target'),
      notice: value('notice'),
      warning: value('warning'),
      status: value('status'),
    );
  }
}

class GatewaySlashCompletions {
  const GatewaySlashCompletions({this.items = const [], this.replaceFrom = 1});
  final List<({String text, String description})> items;
  final int replaceFrom;
  factory GatewaySlashCompletions.fromJson(Map<String, dynamic> json) {
    if (json['items'] is! List) {
      throw const FormatException('Missing completions');
    }
    return GatewaySlashCompletions(
      replaceFrom: json['replace_from'] is int
          ? json['replace_from'] as int
          : 1,
      items: [
        for (final row in (json['items'] as List).whereType<Map>())
          if (row['text'] is String)
            (
              text: row['text'] as String,
              description: row['meta'] is String ? row['meta'] as String : '',
            ),
      ],
    );
  }
}
