import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xterm/xterm.dart';

import '../../core/theme/hermes_tokens.dart';
import '../../core/widgets/paper_texture.dart';
import '../../domain/models/ssh_target.dart';
import 'machine_session.dart';

/// Sessão de shell na máquina que roda o Hermes.
///
/// Uma tela só, com três caras conforme o estágio: parear a chave, configurar o
/// alvo e o terminal. Não são três telas porque o caminho é linear e voltar
/// para trocar o usuário não deveria custar navegação.
class MachineScreen extends ConsumerWidget {
  const MachineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = HermesTokens.of(context);
    final state = ref.watch(machineSessionProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const Positioned.fill(child: PaperTexture()),
          SafeArea(
            child: Column(
              children: [
                _TopBar(state: state),
                Expanded(
                  child: switch (state.stage) {
                    MachineStage.conectado => const _TerminalPane(),
                    _ => _SetupPane(state: state),
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: t.bg,
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.state});

  final MachineState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = HermesTokens.of(context);
    final conectado = state.stage == MachineStage.conectado;
    final rotulo = switch (state.stage) {
      MachineStage.semChave => 'SEM CHAVE',
      MachineStage.desconectado => 'DESCONECTADO',
      MachineStage.conectando => 'CONECTANDO',
      MachineStage.conectado => 'CONECTADO',
      MachineStage.falhou => 'FALHOU',
    };

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.line)),
      ),
      padding: const EdgeInsets.fromLTRB(6, 8, 12, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(Icons.chevron_left, color: t.ink),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.target?.host ?? 'Máquina',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t
                      .serifIn(FontWeight.w500)
                      .copyWith(fontSize: 16.5, color: t.ink),
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: conectado ? t.positive : t.faint,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      rotulo,
                      style: t.mono.copyWith(
                        fontSize: 10,
                        letterSpacing: 1.2,
                        color: t.faint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (conectado)
            TextButton(
              onPressed: () =>
                  ref.read(machineSessionProvider.notifier).desconectar(),
              child: Text(
                'ENCERRAR',
                style: t.mono.copyWith(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  color: t.accentInk,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Terminal de verdade, com a barra de teclas que o teclado do celular não tem.
class _TerminalPane extends ConsumerWidget {
  const _TerminalPane();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = HermesTokens.of(context);
    final terminal = ref.read(machineSessionProvider.notifier).terminal;

    return Column(
      children: [
        Expanded(
          child: TerminalView(
            terminal,
            key: const ValueKey('terminal-view'),
            autofocus: true,
            padding: const EdgeInsets.all(10),
            backgroundOpacity: 0,
            theme: _tema(t),
            textStyle: TerminalStyle(
              fontSize: 12.5,
              fontFamily: t.mono.fontFamily ?? 'monospace',
            ),
          ),
        ),
        _KeyBar(terminal: terminal),
      ],
    );
  }

  /// A paleta do terminal sai dos tokens do app: o realce de sintaxe do design
  /// já mapeia as cores ANSI que importam.
  TerminalTheme _tema(HermesTokens t) => TerminalTheme(
    cursor: t.accent,
    selection: t.accent.withValues(alpha: 0.3),
    foreground: t.ink,
    background: t.bg,
    black: t.bg,
    red: t.accentInk,
    green: t.positive,
    yellow: t.cNum,
    blue: t.cType,
    magenta: t.cKey,
    cyan: t.cStr,
    white: t.ink,
    brightBlack: t.faint,
    brightRed: t.accentInk,
    brightGreen: t.positive,
    brightYellow: t.cFn,
    brightBlue: t.cType,
    brightMagenta: t.cKey,
    brightCyan: t.cStr,
    brightWhite: t.ink,
    searchHitBackground: t.accent,
    searchHitBackgroundCurrent: t.accentInk,
    searchHitForeground: t.bg,
  );
}

/// As teclas que faltam num teclado de celular.
///
/// Sem `esc`, `tab`, `ctrl` e as setas não há `vim`, autocompletar, histórico
/// nem `Ctrl+C`, e aí o terminal vira enfeite. `ctrl` é pegajosa: fica armada
/// até a próxima tecla, porque não dá para pressionar duas ao mesmo tempo com
/// um dedo só.
class _KeyBar extends StatefulWidget {
  const _KeyBar({required this.terminal});

  final Terminal terminal;

  @override
  State<_KeyBar> createState() => _KeyBarState();
}

class _KeyBarState extends State<_KeyBar> {
  bool _ctrl = false;

  void _enviar(String texto) {
    widget.terminal.textInput(texto);
    if (_ctrl) setState(() => _ctrl = false);
  }

  void _tecla(TerminalKey tecla) {
    widget.terminal.keyInput(tecla, ctrl: _ctrl);
    if (_ctrl) setState(() => _ctrl = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.line)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _Tecla(label: 'esc', onTap: () => _tecla(TerminalKey.escape)),
            _Tecla(label: 'tab', onTap: () => _tecla(TerminalKey.tab)),
            _Tecla(
              label: 'ctrl',
              armada: _ctrl,
              onTap: () => setState(() => _ctrl = !_ctrl),
            ),
            _Tecla(label: '↑', onTap: () => _tecla(TerminalKey.arrowUp)),
            _Tecla(label: '↓', onTap: () => _tecla(TerminalKey.arrowDown)),
            _Tecla(label: '←', onTap: () => _tecla(TerminalKey.arrowLeft)),
            _Tecla(label: '→', onTap: () => _tecla(TerminalKey.arrowRight)),
            _Tecla(label: '|', onTap: () => _enviar('|')),
            _Tecla(label: '/', onTap: () => _enviar('/')),
            _Tecla(label: '~', onTap: () => _enviar('~')),
            _Tecla(label: '-', onTap: () => _enviar('-')),
          ],
        ),
      ),
    );
  }
}

class _Tecla extends StatelessWidget {
  const _Tecla({required this.label, required this.onTap, this.armada = false});

  final String label;
  final VoidCallback onTap;
  final bool armada;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          constraints: const BoxConstraints(minWidth: 40),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: armada ? t.accent.withValues(alpha: 0.18) : t.bg2,
            border: Border.all(color: armada ? t.accent : t.line),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: Text(
              label,
              style: t.mono.copyWith(
                fontSize: 12,
                color: armada ? t.accent : t.dim,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Parear a chave e apontar a máquina.
class _SetupPane extends ConsumerStatefulWidget {
  const _SetupPane({required this.state});

  final MachineState state;

  @override
  ConsumerState<_SetupPane> createState() => _SetupPaneState();
}

class _SetupPaneState extends ConsumerState<_SetupPane> {
  late final _host = TextEditingController(
    text: widget.state.target?.host ?? '',
  );
  late final _user = TextEditingController(
    text: widget.state.target?.user ?? '',
  );
  late final _port = TextEditingController(
    text: '${widget.state.target?.port ?? 22}',
  );
  String? _erroDeAlvo;

  @override
  void dispose() {
    _host.dispose();
    _user.dispose();
    _port.dispose();
    super.dispose();
  }

  Future<void> _conectar() async {
    final alvo = normalizeSshTarget((
      host: _host.text,
      port: int.tryParse(_port.text.trim()) ?? 0,
      user: _user.text,
    ));
    final erro = validateSshTarget(alvo);
    setState(() => _erroDeAlvo = erro);
    if (erro != null) return;

    final sessao = ref.read(machineSessionProvider.notifier);
    await sessao.salvarAlvo(alvo);
    await sessao.conectar();
  }

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final state = widget.state;
    final temChave = state.publicKeyLine != null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      children: [
        _Secao(titulo: 'Chave deste aparelho'),
        const SizedBox(height: 10),
        if (!temChave) ...[
          Text(
            'O par é gerado aqui. A privada fica no armazenamento seguro do '
            'aparelho e não é exibida, exportada nem enviada a lugar nenhum.',
            style: t.serif.copyWith(fontSize: 14.5, height: 1.5, color: t.dim),
          ),
          const SizedBox(height: 14),
          _Botao(
            key: const ValueKey('gerar-chave'),
            label: 'Gerar chave',
            destaque: true,
            onTap: () => ref.read(machineSessionProvider.notifier).gerarChave(),
          ),
        ] else ...[
          Text(
            'Cole esta linha no ~/.ssh/authorized_keys do usuário na máquina.',
            style: t.serif.copyWith(fontSize: 14.5, height: 1.5, color: t.dim),
          ),
          const SizedBox(height: 10),
          Container(
            key: const ValueKey('chave-publica'),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: t.codeBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SelectableText(
              state.publicKeyLine!,
              style: t.mono.copyWith(fontSize: 11, height: 1.5, color: t.ink),
            ),
          ),
          const SizedBox(height: 8),
          _Botao(
            label: 'Copiar chave pública',
            onTap: () async {
              await Clipboard.setData(
                ClipboardData(text: state.publicKeyLine!),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chave pública copiada')),
                );
              }
            },
          ),
        ],

        const SizedBox(height: 26),
        _Secao(titulo: 'Máquina'),
        const SizedBox(height: 10),
        _Campo(label: 'Host', controller: _host, hint: 'servidor.local'),
        const SizedBox(height: 10),
        _Campo(label: 'Usuário', controller: _user, hint: 'usuario'),
        const SizedBox(height: 10),
        _Campo(
          label: 'Porta',
          controller: _port,
          hint: '22',
          teclado: TextInputType.number,
        ),
        if (_erroDeAlvo != null) ...[
          const SizedBox(height: 10),
          Text(
            _erroDeAlvo!,
            style: t.serif.copyWith(fontSize: 14, color: t.accentInk),
          ),
        ],

        if (state.fingerprint != null) ...[
          const SizedBox(height: 20),
          _Secao(titulo: 'Impressão digital fixada'),
          const SizedBox(height: 8),
          SelectableText(
            state.fingerprint!,
            style: t.mono.copyWith(fontSize: 10.5, color: t.faint),
          ),
        ],

        if (state.erro != null) ...[
          const SizedBox(height: 20),
          Container(
            key: const ValueKey('falha-da-maquina'),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              border: Border.all(color: t.accentInk),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.erro!,
                  style: t.serif.copyWith(
                    fontSize: 14.5,
                    height: 1.5,
                    color: t.ink,
                  ),
                ),
                if (state.hostKeyChanged) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Isto acontece quando a máquina foi reinstalada, e também '
                    'quando outra máquina atende por esse nome. Só esqueça a '
                    'chave antiga depois de conferir por fora qual é o caso.',
                    style: t.serif.copyWith(
                      fontSize: 13.5,
                      height: 1.5,
                      color: t.dim,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Botao(
                    key: const ValueKey('esquecer-host'),
                    label: 'Esquecer a chave antiga',
                    onTap: () => ref
                        .read(machineSessionProvider.notifier)
                        .esquecerHost(),
                  ),
                ],
              ],
            ),
          ),
        ],

        const SizedBox(height: 26),
        if (temChave)
          _Botao(
            key: const ValueKey('conectar-maquina'),
            label: state.stage == MachineStage.conectando
                ? 'Conectando…'
                : 'Conectar',
            destaque: true,
            onTap: state.stage == MachineStage.conectando ? null : _conectar,
          ),
      ],
    );
  }
}

class _Secao extends StatelessWidget {
  const _Secao({required this.titulo});
  final String titulo;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Text(
      titulo.toUpperCase(),
      style: t.mono.copyWith(fontSize: 10, letterSpacing: 1.8, color: t.faint),
    );
  }
}

class _Campo extends StatelessWidget {
  const _Campo({
    required this.label,
    required this.controller,
    required this.hint,
    this.teclado,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? teclado;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: t.mono.copyWith(fontSize: 11, color: t.dim),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: t.bg2,
              border: Border.all(color: t.line),
              borderRadius: BorderRadius.circular(11),
            ),
            child: TextField(
              controller: controller,
              keyboardType: teclado,
              autocorrect: false,
              enableSuggestions: false,
              style: t.mono.copyWith(fontSize: 13, color: t.ink),
              cursorColor: t.accent,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: t.mono.copyWith(fontSize: 13, color: t.faint),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Botao extends StatelessWidget {
  const _Botao({
    super.key,
    required this.label,
    required this.onTap,
    this.destaque = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final ativo = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: destaque && ativo ? t.accent : Colors.transparent,
            border: Border.all(color: destaque && ativo ? t.accent : t.line),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Center(
            child: Text(
              label,
              style: t.serif.copyWith(
                fontSize: 15,
                color: destaque && ativo ? t.bg : (ativo ? t.ink : t.faint),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
