import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/chat/chat_list_screen.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/chat/deep_linked_chat_screen.dart';
import '../../features/chat/markdown_showcase_screen.dart';
import '../../features/debug/turn_capture_screen.dart';
import '../../features/machine/machine_screen.dart';
import '../../features/skills/skills_screen.dart';
import '../theme/hermes_motion.dart';
import 'hermes_route_observer.dart';

/// Configuração de rotas do app: o análogo do TanStack Router.
///
/// `/`         -> lista de conversas
/// `/chat`     -> conversa (entra deslizando da direita, como o painel do design)
/// `/maquina`  -> sessão de shell na máquina que roda o Hermes (A32)
/// Monta o roteador do app.
///
/// Com [abrirNoChat], a conversa já **nasce** empilhada sobre a lista, em vez
/// de entrar depois por navegação. A diferença é visível: empurrar a rota
/// depois do primeiro quadro mostrava a lista e só então deslizava o chat por
/// cima sozinho, que foi o efeito estranho medido pelo usuário em 2026-08-15.
/// Rota inicial não anima, e a lista continua embaixo para o voltar funcionar
/// como em qualquer outra abertura de conversa.
GoRouter buildAppRouter({
  WidgetBuilder? connectionSettingsBuilder,
  bool abrirNoChat = false,
  String? initialLocation,
}) => GoRouter(
  initialLocation: initialLocation ?? (abrirNoChat ? '/chat' : '/'),
  overridePlatformDefaultLocation: true,
  observers: [hermesRouteObserver],
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) =>
          ChatListScreen(canEditConnections: connectionSettingsBuilder != null),
      routes: [
        // Filha de `/`, e não irmã: assim a lista está **sempre** embaixo do
        // chat, tanto quando a pessoa toca numa conversa quanto quando o app
        // nasce dentro dela. Rota inicial não anima, então nascer em `/chat`
        // não mostra a lista antes; e o voltar continua tendo para onde ir.
        GoRoute(
          path: 'chat',
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            // `revelar`, e não `entrada`: meio segundo para trocar de tela
            // deixa a navegação lenta, e o que entra aqui é a tela inteira,
            // não conteúdo chegando dentro dela.
            transitionDuration: motionOf(context, HermesMotion.revelar),
            reverseTransitionDuration: motionOf(
              context,
              HermesMotion.saidaDe(HermesMotion.revelar),
            ),
            child: const ChatScreen(),
            transitionsBuilder: (context, animation, secondary, child) {
              final slide =
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: HermesMotion.curvaChegada,
                    ),
                  );
              return SlideTransition(position: slide, child: child);
            },
          ),
        ),
        GoRoute(
          path: 'chat/:conversationId',
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            transitionDuration: motionOf(context, HermesMotion.revelar),
            reverseTransitionDuration: motionOf(
              context,
              HermesMotion.saidaDe(HermesMotion.revelar),
            ),
            child: DeepLinkedChatScreen(
              conversationId: state.pathParameters['conversationId']!,
              title: state.uri.queryParameters['title'],
              model: state.uri.queryParameters['model'],
              provider: state.uri.queryParameters['provider'],
            ),
            transitionsBuilder: (context, animation, secondary, child) {
              final slide =
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: HermesMotion.curvaChegada,
                    ),
                  );
              return SlideTransition(position: slide, child: child);
            },
          ),
        ),
      ],
    ),
    if (connectionSettingsBuilder != null)
      GoRoute(
        path: '/settings/connections',
        builder: (context, state) => connectionSettingsBuilder(context),
      ),
    if (kDebugMode) ...[
      GoRoute(
        path: '/debug/markdown-showcase',
        builder: (context, state) => const MarkdownShowcaseScreen(),
      ),
      GoRoute(
        path: '/debug/captura-de-turno',
        builder: (context, state) => const TurnCaptureScreen(),
      ),
    ],
    GoRoute(
      path: '/maquina',
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        // `revelar`, e não `entrada`: meio segundo para trocar de tela deixa a
        // navegação lenta, e o que entra aqui é a tela inteira, não conteúdo
        // chegando dentro dela.
        transitionDuration: motionOf(context, HermesMotion.revelar),
        reverseTransitionDuration: motionOf(
          context,
          HermesMotion.saidaDe(HermesMotion.revelar),
        ),
        child: const MachineScreen(),
        // Sobe de baixo, e não desliza da direita: não é outra conversa, é
        // outro lugar.
        transitionsBuilder: (context, animation, secondary, child) {
          final slide =
              Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: HermesMotion.curvaChegada,
                ),
              );
          return SlideTransition(position: slide, child: child);
        },
      ),
    ),
    GoRoute(
      path: '/skills',
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        transitionDuration: motionOf(context, HermesMotion.revelar),
        reverseTransitionDuration: motionOf(
          context,
          HermesMotion.saidaDe(HermesMotion.revelar),
        ),
        child: const SkillsScreen(),
        transitionsBuilder: (context, animation, secondary, child) {
          final slide =
              Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: HermesMotion.curvaChegada,
                ),
              );
          return SlideTransition(position: slide, child: child);
        },
      ),
    ),
  ],
);

/// Normaliza tanto a rota Flutter (`/chat/id`) quanto o esquema Android
/// (`hermes://app/chat/id`) para uma localização que o GoRouter reconhece.
///
/// Outros hosts e caminhos são ignorados: uma URI externa não pode mudar a
/// abertura normal do app só por usar o mesmo esquema por acidente.
String? conversationDeepLinkLocation(Uri? uri) {
  if (uri == null) return null;
  if (uri.hasScheme && (uri.scheme != 'hermes' || uri.host != 'app')) {
    return null;
  }
  final segments = uri.pathSegments;
  if (segments.length != 2 || segments.first != 'chat') return null;
  final id = segments.last.trim();
  if (id.isEmpty) return null;

  final path = '/chat/${Uri.encodeComponent(id)}';
  return uri.hasQuery ? '$path?${uri.query}' : path;
}
