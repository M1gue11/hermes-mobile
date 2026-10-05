import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/config/hermes_connection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/design_scale.dart';
import 'core/widgets/hermes_startup_splash.dart';
import 'core/widgets/paper_texture.dart';
import 'data/config/app_settings_store.dart';
import 'data/config/connection_store.dart';
import 'data/config/dashboard_session_store.dart';
import 'data/gateway/dashboard_gateway_repository.dart';
import 'data/gateway_repository_provider.dart';
import 'data/hermes_repository_provider.dart';
import 'data/http/http_hermes_repository.dart';
import 'data/platform/device_attachment_source.dart';
import 'domain/repositories/hermes_repository.dart';
import 'features/chat/launch_provider.dart';
import 'features/connection/connection_screen.dart';
import 'features/settings/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  StoredAppSettings? settings;
  try {
    settings = await const SecureAppSettingsStore().read();
  } catch (_) {
    // Preferência corrompida ou KeyStore temporariamente indisponível não pode
    // impedir o pareamento nem a abertura do app; cada campo tem seu padrão.
  }
  runApp(
    HermesStartupSplash(child: HermesConnectionGate(initialSettings: settings)),
  );
}

/// Converte os px do mock para esta tela antes de qualquer rota, diálogo ou
/// sheet ser construído. Ver [DesignTypography].
///
/// Antes do pareamento não há [ProviderScope], então a tela de conexão fica no
/// tamanho do desenho; a escolha de Aparência entra depois, em [HermesApp].
Widget _comTipografiaDoDesign(BuildContext context, Widget? child) =>
    DesignTypography(child: child ?? const SizedBox.shrink());

/// Restaura o pareamento seguro antes de montar o cliente conectado ao gateway.
///
/// Antes do primeiro pareamento, a única tela acessível é a de conexão. Depois
/// de validar `/health` e `/v1/capabilities`, o repositório HTTP é injetado na
/// árvore por [ProviderScope], sem vazar a chave em código ou logs.
class HermesConnectionGate extends StatefulWidget {
  const HermesConnectionGate({super.key, this.store, this.initialSettings});

  final ConnectionStore? store;
  final StoredAppSettings? initialSettings;

  @override
  State<HermesConnectionGate> createState() => _HermesConnectionGateState();
}

class _HermesConnectionGateState extends State<HermesConnectionGate> {
  late final ConnectionStore _store;
  late final DashboardSessionStore _dashboardStore;
  late DashboardGatewayRepository _dashboardRepository;
  HermesConnection? _connection;
  var _connectionRevision = 0;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? const SecureConnectionStore();
    _dashboardStore = const SecureDashboardSessionStore();
    _dashboardRepository = DashboardGatewayRepository(store: _dashboardStore);
    _restoreConnection();
  }

  Future<void> _restoreConnection() async {
    final connection = await _store.read();
    if (mounted) {
      setState(() {
        _connection = connection;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    final connection = _connection;
    if (connection == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        builder: _comTipografiaDoDesign,
        home: ConnectionScreen(
          store: _store,
          dashboardStore: _dashboardStore,
          dashboard: _dashboardRepository,
          onConnected: (value) => setState(() => _connection = value),
        ),
      );
    }

    return ProviderScope(
      key: ValueKey((connection.baseUrl, _connectionRevision)),
      // Sem isto o Riverpod 3 **re-tenta sozinho** todo provider que falha, com
      // backoff e sem fim. Medido no emulador com a rede cortada: a lista de
      // conversas ficava girando para sempre, porque cada falha virava uma nova
      // tentativa e a tela nunca saía de "carregando". O usuário via um spinner
      // eterno em vez da causa.
      //
      // A tela agora diz o que houve e oferece "Tentar novamente" quando tentar
      // de novo pode dar certo. Repetir por conta própria, escondendo a falha,
      // é o oposto disso. Ver A7.
      retry: (contagem, erro) => null,
      overrides: [
        appSettingsInitialProvider.overrideWithValue(widget.initialSettings),
        hermesRepositoryProvider.overrideWithValue(_httpRepository(connection)),
        gatewayRepositoryProvider.overrideWithValue(_dashboardRepository),
        attachmentSourceProvider.overrideWithValue(DeviceAttachmentSource()),
      ],
      child: HermesApp(
        forceConversationList: _connectionRevision > 0,
        connectionSettingsBuilder: (context) => ConnectionScreen(
          store: _store,
          dashboardStore: _dashboardStore,
          dashboard: _dashboardRepository,
          initialConnection: connection,
          editing: true,
          onConnected: _applyEditedConnection,
          onForget: _forgetConnections,
        ),
      ),
    );
  }

  void _applyEditedConnection(HermesConnection connection) {
    if (!mounted) return;
    setState(() {
      _connection = connection;
      _dashboardRepository = DashboardGatewayRepository(store: _dashboardStore);
      _connectionRevision++;
    });
  }

  Future<void> _forgetConnections() async {
    await _store.clear();
    await _dashboardStore.clear();
    await _dashboardStore.clearCredentials();
    if (mounted) setState(() => _connection = null);
  }

  HermesRepository _httpRepository(HermesConnection connection) =>
      HttpHermesRepository(
        baseUrl: connection.baseUrl,
        apiKey: connection.apiKey,
      );
}

class HermesApp extends ConsumerStatefulWidget {
  const HermesApp({
    super.key,
    this.connectionSettingsBuilder,
    this.forceConversationList = false,
    this.initialUri,
  });

  final WidgetBuilder? connectionSettingsBuilder;
  final bool forceConversationList;
  final Uri? initialUri;

  @override
  ConsumerState<HermesApp> createState() => _HermesAppState();
}

class _HermesAppState extends ConsumerState<HermesApp> {
  /// Criado **uma vez**, depois que a abertura decidiu para onde o app nasce.
  ///
  /// Uma vez porque o roteador guarda a pilha de navegação: reconstruí-lo a
  /// cada `build` jogava a pessoa de volta para a rota inicial toda vez que a
  /// atmosfera ou o tamanho do texto mudassem.
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    unawaited(_decidirAbertura());
  }

  /// A64. A decisão precisa vir **antes** da primeira rota, e não depois do
  /// primeiro quadro: empurrar o chat depois mostrava a lista e só então
  /// deslizava a conversa por cima sozinha.
  Future<void> _decidirAbertura() async {
    var abrirNoChat = false;
    String? initialLocation;
    try {
      final platformUri = Uri.tryParse(
        WidgetsBinding.instance.platformDispatcher.defaultRouteName,
      );
      initialLocation = widget.forceConversationList
          ? null
          : conversationDeepLinkLocation(widget.initialUri ?? platformUri);
      if (initialLocation == null) {
        abrirNoChat =
            !widget.forceConversationList &&
            await ref.read(chatLaunchProvider).resolve() ==
                ChatLaunchOutcome.abrirChat;
      }
    } catch (_) {
      // Uma conveniência não pode deixar o app sem tela. Qualquer coisa que
      // escape aqui vira "começa na lista", que é sempre alcançável e mostra a
      // própria falha; ficar no papel em branco seria a pior saída possível.
    }
    if (!mounted) return;
    setState(() {
      _router = buildAppRouter(
        connectionSettingsBuilder: widget.connectionSettingsBuilder,
        abrirNoChat: abrirNoChat,
        initialLocation: initialLocation,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final atmosphere = ref.watch(
      appSettingsProvider.select((s) => s.atmosphere),
    );
    final textSize = ref.watch(appSettingsProvider.select((s) => s.textSize));
    final theme = AppTheme.build(atmosphere);

    Widget aplicarTipografia(BuildContext context, Widget? child) =>
        DesignTypography(
          size: textSize,
          child: child ?? const SizedBox.shrink(),
        );

    final router = _router;
    if (router == null) {
      // Papel e nada mais. A decisão é local e dura um piscar; qualquer coisa
      // que apareça aqui vira um lampejo, que é justamente o que se está
      // removendo.
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        builder: aplicarTipografia,
        home: const Scaffold(body: PaperTexture()),
      );
    }

    return MaterialApp.router(
      title: 'Hermes',
      debugShowCheckedModeBanner: false,
      theme: theme,
      builder: aplicarTipografia,
      routerConfig: router,
    );
  }
}
