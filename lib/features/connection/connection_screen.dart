import 'package:flutter/material.dart';

import '../../core/config/hermes_connection.dart';
import '../../core/theme/hermes_tokens.dart';
import '../../data/config/connection_store.dart';
import '../../data/config/dashboard_session_store.dart';
import '../../data/gateway/dashboard_gateway_repository.dart';
import '../../data/http/http_hermes_repository.dart';
import '../../domain/models/hermes_failure.dart';
import '../../domain/repositories/gateway_repository.dart';
import '../../domain/repositories/hermes_repository.dart';

typedef HermesRepositoryFactory =
    HermesRepository Function(HermesConnection connection);

/// Pareamento inicial e edição segura das duas conexões usadas pelo cliente.
class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({
    super.key,
    required this.store,
    required this.dashboard,
    required this.onConnected,
    this.dashboardStore,
    this.initialConnection,
    this.editing = false,
    this.onForget,
    this.repositoryFactory,
  }) : assert(!editing || initialConnection != null),
       assert(!editing || dashboardStore != null);

  final ConnectionStore store;
  final DashboardSessionStore? dashboardStore;
  final GatewayRepository dashboard;
  final ValueChanged<HermesConnection> onConnected;
  final HermesConnection? initialConnection;
  final bool editing;
  final Future<void> Function()? onForget;
  final HermesRepositoryFactory? repositoryFactory;

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  late final TextEditingController _baseUrl;
  late final TextEditingController _dashboardUrl;
  final _apiKey = TextEditingController();
  final _dashboardUser = TextEditingController();
  final _dashboardPassword = TextEditingController();
  String _savedApiKey = '';
  String _savedDashboardPassword = '';
  bool _loadingSaved = false;
  bool _connecting = false;
  bool _forgetting = false;
  String? _error;

  bool get _busy => _loadingSaved || _connecting || _forgetting;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialConnection;
    _savedApiKey = initial?.apiKey ?? '';
    _baseUrl = TextEditingController(text: initial?.baseUrl ?? '');
    _dashboardUrl = TextEditingController();
    if (widget.editing) {
      _loadingSaved = true;
      _loadSavedDashboard();
    }
  }

  Future<void> _loadSavedDashboard() async {
    try {
      final store = widget.dashboardStore!;
      final credentials = await store.readCredentials();
      final session = await store.read();
      if (!mounted) return;
      _dashboardUrl.text = credentials?.baseUrl ?? session?.baseUrl ?? '';
      _dashboardUser.text = credentials?.username ?? '';
      _savedDashboardPassword = credentials?.password ?? '';
    } catch (_) {
      if (mounted) {
        _error =
            'Não foi possível ler a configuração protegida. Você ainda pode informar novos dados.';
      }
    } finally {
      if (mounted) setState(() => _loadingSaved = false);
    }
  }

  @override
  void dispose() {
    _baseUrl.dispose();
    _dashboardUrl.dispose();
    _apiKey.dispose();
    _dashboardUser.dispose();
    _dashboardPassword.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (_busy) return;
    final apiKey = _apiKey.text.trim().isEmpty ? _savedApiKey : _apiKey.text;
    final password = _dashboardPassword.text.isEmpty
        ? _savedDashboardPassword
        : _dashboardPassword.text;
    final connection = HermesConnection(
      baseUrl: _baseUrl.text,
      apiKey: apiKey,
    ).normalized();
    final validation = connection.validate();
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    if (!DashboardGatewayRepository.supportsBaseUrl(_dashboardUrl.text)) {
      setState(() => _error = DashboardGatewayRepository.invalidBaseUrlMessage);
      return;
    }
    if (_dashboardUser.text.trim().isEmpty || password.isEmpty) {
      setState(() {
        _error = widget.editing
            ? 'Informe o usuário e uma nova senha, ou mantenha a senha protegida já salva.'
            : 'Informe usuário e senha do Dashboard.';
      });
      return;
    }

    setState(() {
      _connecting = true;
      _error = null;
    });

    HermesConnection? previousConnection;
    DashboardSession? previousSession;
    DashboardCredentials? previousCredentials;
    var snapshotsCaptured = false;
    try {
      previousConnection = await widget.store.read();
      final dashboardStore = widget.dashboardStore;
      if (dashboardStore != null) {
        previousSession = await dashboardStore.read();
        previousCredentials = await dashboardStore.readCredentials();
      }
      snapshotsCaptured = true;

      final repository =
          widget.repositoryFactory?.call(connection) ??
          HttpHermesRepository(
            baseUrl: connection.baseUrl,
            apiKey: connection.apiKey,
          );
      await repository.health();
      await repository.capabilities();
      await widget.dashboard.authenticate(
        baseUrl: _dashboardUrl.text,
        username: _dashboardUser.text,
        password: password,
      );
      await widget.store.save(connection);
      _apiKey.clear();
      _dashboardPassword.clear();
      if (!mounted) return;
      if (widget.editing) {
        Navigator.of(context).pop();
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => widget.onConnected(connection),
        );
      } else {
        widget.onConnected(connection);
      }
    } catch (error) {
      if (snapshotsCaptured) {
        await _restorePrevious(
          connection: previousConnection,
          session: previousSession,
          credentials: previousCredentials,
        );
      }
      if (!mounted) return;
      setState(() => _error = _connectionError(error));
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _restorePrevious({
    required HermesConnection? connection,
    required DashboardSession? session,
    required DashboardCredentials? credentials,
  }) async {
    try {
      if (connection == null) {
        await widget.store.clear();
      } else {
        await widget.store.save(connection);
      }
      final dashboardStore = widget.dashboardStore;
      if (dashboardStore == null) return;
      if (session == null) {
        await dashboardStore.clear();
      } else {
        await dashboardStore.save(session);
      }
      if (credentials == null) {
        await dashboardStore.clearCredentials();
      } else {
        await dashboardStore.saveCredentials(credentials);
      }
    } catch (_) {
      // Melhor esforço: a falha original continua sendo a mensagem acionável.
    }
  }

  Future<void> _confirmForget() async {
    final forget = widget.onForget;
    if (forget == null || _busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Esquecer conexões?'),
        content: const Text(
          'URLs, chave da API, login e sessão do Dashboard serão removidos deste aparelho.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Esquecer conexões'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _forgetting = true);
    try {
      await forget();
    } catch (_) {
      if (mounted) {
        setState(() {
          _forgetting = false;
          _error = 'Não foi possível remover as conexões. Tente novamente.';
        });
      }
    }
  }

  String _connectionError(Object error) {
    if (error is GatewayOperationException) return error.message;
    final failure = hermesFailureFrom(error);
    return switch (failure.kind) {
      HermesFailureKind.naoAutenticado =>
        'A chave foi recusada pelo Hermes${failure.reference == null ? '' : ' (${failure.reference})'}.',
      HermesFailureKind.semRede =>
        'Não foi possível alcançar o gateway pelo Tailnet. Confira as URLs e o Tailscale.',
      HermesFailureKind.tempoEsgotado =>
        'Uma das conexões não respondeu a tempo. Confira o Tailscale e tente de novo.',
      _ => '${failure.title}. ${failure.hint}',
    };
  }

  InputDecoration _decoration(
    HermesTokens tokens, {
    String? hint,
    String? helper,
  }) => InputDecoration(
    hintText: hint,
    helperText: helper,
    helperMaxLines: 2,
    filled: true,
    fillColor: tokens.bg2,
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: tokens.line),
      borderRadius: BorderRadius.circular(14),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: tokens.accent),
      borderRadius: BorderRadius.circular(14),
    ),
    disabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: tokens.line),
      borderRadius: BorderRadius.circular(14),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final tokens = HermesTokens.of(context);
    return Scaffold(
      appBar: widget.editing
          ? AppBar(
              title: Text(
                'Conexões',
                style: tokens
                    .serifIn(FontWeight.w500)
                    .copyWith(fontSize: 21, color: tokens.ink),
              ),
              backgroundColor: tokens.bg,
              foregroundColor: tokens.ink,
              elevation: 0,
            )
          : null,
      body: SafeArea(
        top: !widget.editing,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AbsorbPointer(
                absorbing: _busy,
                child: AnimatedOpacity(
                  opacity: _loadingSaved ? 0.55 : 1,
                  duration: const Duration(milliseconds: 160),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.editing
                            ? 'Edite sem interromper o acesso atual'
                            : 'Conectar ao seu gateway',
                        style: tokens
                            .serifIn(FontWeight.w500)
                            .copyWith(
                              fontSize: widget.editing ? 27 : 32,
                              color: tokens.ink,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.editing
                            ? 'Os novos dados só entram em vigor depois que os dois acessos forem validados. Campos secretos vazios mantêm o valor protegido atual.'
                            : 'O acesso funciona apenas pelo seu Tailnet. A chave e o login ficam no armazenamento seguro deste aparelho.',
                        style: tokens.serif.copyWith(
                          fontSize: 15.5,
                          height: 1.45,
                          color: tokens.dim,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _SectionHeading(
                        title: 'Hermes API Server',
                        note: 'Sessões, modelos e fallback de execução',
                      ),
                      const SizedBox(height: 18),
                      _ConnectionField(
                        fieldKey: const ValueKey('connection-base-url'),
                        label: 'URL HTTPS',
                        controller: _baseUrl,
                        enabled: !_busy,
                        keyboardType: TextInputType.url,
                        decoration: _decoration(tokens),
                      ),
                      const SizedBox(height: 18),
                      _ConnectionField(
                        fieldKey: const ValueKey('connection-api-key'),
                        label: 'Chave da API',
                        controller: _apiKey,
                        enabled: !_busy,
                        obscureText: true,
                        decoration: _decoration(
                          tokens,
                          hint: widget.editing && _savedApiKey.isNotEmpty
                              ? 'Mantém a chave atual'
                              : 'Bearer token do Hermes',
                          helper: widget.editing && _savedApiKey.isNotEmpty
                              ? 'Deixe vazio para manter. Digite somente para substituir.'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 30),
                      const _SectionHeading(
                        title: 'Dashboard TUI',
                        note: 'Reasoning, ferramentas e perguntas interativas',
                      ),
                      const SizedBox(height: 18),
                      _ConnectionField(
                        fieldKey: const ValueKey('dashboard-connection-url'),
                        label: 'URL do Dashboard',
                        controller: _dashboardUrl,
                        enabled: !_busy,
                        keyboardType: TextInputType.url,
                        decoration: _decoration(tokens),
                      ),
                      const SizedBox(height: 18),
                      _ConnectionField(
                        fieldKey: const ValueKey('dashboard-connection-user'),
                        label: 'Usuário do Dashboard',
                        controller: _dashboardUser,
                        enabled: !_busy,
                        autofillHints: const [AutofillHints.username],
                        decoration: _decoration(tokens),
                      ),
                      const SizedBox(height: 18),
                      _ConnectionField(
                        fieldKey: const ValueKey(
                          'dashboard-connection-password',
                        ),
                        label: 'Senha do Dashboard',
                        controller: _dashboardPassword,
                        enabled: !_busy,
                        obscureText: true,
                        autofillHints: widget.editing
                            ? const <String>[]
                            : const [AutofillHints.password],
                        decoration: _decoration(
                          tokens,
                          hint:
                              widget.editing &&
                                  _savedDashboardPassword.isNotEmpty
                              ? 'Mantém a senha atual'
                              : null,
                          helper:
                              widget.editing &&
                                  _savedDashboardPassword.isNotEmpty
                              ? 'Deixe vazio para manter. Digite somente para substituir.'
                              : null,
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Semantics(
                          liveRegion: true,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 18,
                                color: tokens.accentInk,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: tokens.serif.copyWith(
                                    fontSize: 14,
                                    height: 1.4,
                                    color: tokens.accentInk,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          key: const ValueKey('save-connections'),
                          onPressed: _busy ? null : _connect,
                          style: FilledButton.styleFrom(
                            backgroundColor: tokens.accent,
                            foregroundColor: tokens.bg,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _connecting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  widget.editing
                                      ? 'Validar e salvar'
                                      : 'Validar os dois acessos',
                                ),
                        ),
                      ),
                      if (widget.editing && widget.onForget != null) ...[
                        const SizedBox(height: 30),
                        Divider(color: tokens.line),
                        const SizedBox(height: 14),
                        Text(
                          'Remover deste aparelho',
                          style: tokens
                              .serifIn(FontWeight.w500)
                              .copyWith(fontSize: 15, color: tokens.ink),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Use apenas se quiser voltar ao pareamento inicial.',
                          style: tokens.serif.copyWith(
                            fontSize: 13,
                            color: tokens.dim,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton.icon(
                          key: const ValueKey('forget-connections'),
                          onPressed: _busy ? null : _confirmForget,
                          icon: Icon(
                            Icons.delete_outline,
                            color: tokens.accentInk,
                          ),
                          label: Text(
                            _forgetting ? 'Removendo…' : 'Esquecer conexões',
                            style: TextStyle(color: tokens.accentInk),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.note});

  final String title;
  final String note;

  @override
  Widget build(BuildContext context) {
    final tokens = HermesTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: tokens
              .serifIn(FontWeight.w500)
              .copyWith(fontSize: 18, color: tokens.ink),
        ),
        const SizedBox(height: 3),
        Text(
          note,
          style: tokens.mono.copyWith(fontSize: 10.5, color: tokens.faint),
        ),
      ],
    );
  }
}

class _ConnectionField extends StatelessWidget {
  const _ConnectionField({
    required this.fieldKey,
    required this.label,
    required this.controller,
    required this.enabled,
    required this.decoration,
    this.keyboardType,
    this.obscureText = false,
    this.autofillHints,
  });

  final Key fieldKey;
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final InputDecoration decoration;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    final tokens = HermesTokens.of(context);
    return Semantics(
      textField: true,
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: tokens.mono.copyWith(fontSize: 11, color: tokens.faint),
          ),
          const SizedBox(height: 8),
          TextField(
            key: fieldKey,
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            obscureText: obscureText,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: autofillHints,
            textInputAction: TextInputAction.next,
            style: tokens.mono.copyWith(fontSize: 13, color: tokens.ink),
            decoration: decoration,
          ),
        ],
      ),
    );
  }
}
