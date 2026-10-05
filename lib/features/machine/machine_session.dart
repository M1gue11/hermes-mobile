import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:pinenacl/ed25519.dart' as ed25519;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xterm/xterm.dart';

import '../../data/config/ssh_store.dart';
import '../../domain/models/ssh_target.dart';

part 'machine_session.g.dart';

/// Onde a chave, o alvo e a impressão digital moram.
///
/// Provider próprio para o teste poder trocar por um de memória: o
/// `SecureSshStore` fala com o KeyStore do Android e não existe fora do
/// aparelho.
@Riverpod(keepAlive: true)
SshStore sshStore(Ref ref) => const SecureSshStore();

/// Em que ponto a sessão de shell está.
enum MachineStage { semChave, desconectado, conectando, conectado, falhou }

/// O estado que a tela lê.
///
/// [hostKeyChanged] é separado de [erro] porque não é uma falha qualquer: é o
/// aviso de que a máquina do outro lado **não é a mesma** de antes. A tela trata
/// os dois de formas diferentes, e quem decide esquecer a impressão digital
/// antiga é a pessoa, nunca o app.
typedef MachineState = ({
  MachineStage stage,
  SshTarget? target,
  String? publicKeyLine,
  String? fingerprint,
  String? erro,
  bool hostKeyChanged,
});

/// Guarda a chave, o alvo e a sessão viva.
///
/// `keepAlive` de propósito: sair da tela do terminal para ler uma conversa e
/// voltar não pode derrubar o shell nem apagar o que estava na tela.
@Riverpod(keepAlive: true)
class MachineSession extends _$MachineSession {
  late SshStore _store;
  SSHClient? _client;
  SSHSession? _shell;
  StreamSubscription<Uint8List>? _saida;
  StreamSubscription<Uint8List>? _erroPadrao;

  /// O terminal vive fora do estado porque tem buffer: recriá-lo a cada
  /// mudança de estado apagaria a rolagem do que já foi lido.
  late final Terminal terminal = Terminal(maxLines: 5000)
    ..onOutput = _enviar
    ..onResize = _redimensionar;

  @override
  MachineState build() {
    // Lido aqui, e não numa `late final`, porque toda leitura de `ref` depois
    // de o provider ser descartado é erro em tempo de execução.
    _store = ref.read(sshStoreProvider);
    ref.onDispose(_encerrar);
    unawaited(_restaurar());
    return (
      stage: MachineStage.semChave,
      target: null,
      publicKeyLine: null,
      fingerprint: null,
      erro: null,
      hostKeyChanged: false,
    );
  }

  Future<void> _restaurar() async {
    final target = await _store.readTarget();
    final pem = await _store.readPrivateKey();
    final fingerprint = await _store.readHostFingerprint();
    // A restauração é assíncrona e a tela pode ter ido embora no meio dela.
    if (!ref.mounted) return;
    state = (
      stage: pem == null ? MachineStage.semChave : MachineStage.desconectado,
      target: target,
      publicKeyLine: pem == null ? null : _publicaDe(pem),
      fingerprint: fingerprint,
      erro: null,
      hostKeyChanged: false,
    );
  }

  /// A linha pública que corresponde ao PEM guardado.
  ///
  /// Derivada da privada a cada leitura, em vez de guardada ao lado: uma cópia
  /// da pública que saísse de sincronia com a privada mandaria a pessoa colar
  /// no `authorized_keys` uma chave que o app não usa mais.
  String? _publicaDe(String pem) {
    try {
      final par = SSHKeyPair.fromPem(pem).first;
      return authorizedKeysLine(
        'ssh-ed25519',
        par.toPublicKey().encode(),
        'hermes-mobile',
      );
    } catch (_) {
      return null;
    }
  }

  /// Gera o par ed25519 no aparelho.
  ///
  /// A semente vem de `Random.secure()` (via `TweetNaCl.randombytes`). A privada
  /// vai direto para o armazenamento seguro; o que a tela recebe é só a linha
  /// pública, para colar no `authorized_keys`.
  Future<void> gerarChave() async {
    final assinatura = ed25519.SigningKey.generate();
    final par = OpenSSHEd25519KeyPair(
      Uint8List.fromList(assinatura.verifyKey.asTypedList),
      Uint8List.fromList(assinatura.asTypedList),
      'hermes-mobile',
    );
    await _store.savePrivateKey(par.toPem());
    state = (
      stage: MachineStage.desconectado,
      target: state.target,
      publicKeyLine: authorizedKeysLine(
        'ssh-ed25519',
        par.toPublicKey().encode(),
        'hermes-mobile',
      ),
      fingerprint: state.fingerprint,
      erro: null,
      hostKeyChanged: false,
    );
  }

  Future<void> salvarAlvo(SshTarget target) async {
    final normalizado = normalizeSshTarget(target);
    // Trocar de máquina invalida a impressão digital fixada da anterior.
    if (state.target != null && state.target != normalizado) {
      await _store.forgetHostFingerprint();
    }
    await _store.saveTarget(normalizado);
    state = (
      stage: state.stage,
      target: normalizado,
      publicKeyLine: state.publicKeyLine,
      fingerprint: state.target == normalizado ? state.fingerprint : null,
      erro: null,
      hostKeyChanged: false,
    );
  }

  /// Esquece a impressão digital fixada. Ato explícito da pessoa, depois de ela
  /// conferir por fora que a máquina mudou de chave por um motivo conhecido.
  Future<void> esquecerHost() async {
    await _store.forgetHostFingerprint();
    state = (
      stage: MachineStage.desconectado,
      target: state.target,
      publicKeyLine: state.publicKeyLine,
      fingerprint: null,
      erro: null,
      hostKeyChanged: false,
    );
  }

  Future<void> conectar() async {
    final target = state.target;
    final pem = await _store.readPrivateKey();
    if (target == null || pem == null) return;
    if (state.stage == MachineStage.conectando ||
        state.stage == MachineStage.conectado) {
      return;
    }

    _falhaAtual = null;
    state = _com(stage: MachineStage.conectando, erro: null);

    final fixada = await _store.readHostFingerprint();
    String? recebida;

    try {
      final socket = await SSHSocket.connect(
        target.host,
        target.port,
        timeout: const Duration(seconds: 12),
      );
      final client = SSHClient(
        socket,
        username: target.user,
        identities: SSHKeyPair.fromPem(pem),
        onVerifyHostKey: (type, fingerprint) {
          recebida = readableFingerprint(fingerprint);
          final veredito = judgeHostKey(fixada, recebida!);
          if (veredito == HostKeyVerdict.mudou) {
            _falhaAtual = _FalhaDeHost(recebida!);
            return false;
          }
          return true;
        },
      );
      _client = client;

      final shell = await client.shell(
        pty: SSHPtyConfig(
          width: terminal.viewWidth,
          height: terminal.viewHeight,
        ),
      );
      if (!ref.mounted) {
        shell.close();
        await _fechar();
        return;
      }
      _shell = shell;
      _saida = shell.stdout.listen(_escrever);
      _erroPadrao = shell.stderr.listen(_escrever);
      unawaited(shell.done.then((_) => _quedaDaSessao()));

      // Só fixa depois de a sessão subir: fixar uma chave de uma conexão que
      // não completou seria gravar a palavra de quem talvez nem seja o host.
      if (fixada == null && recebida != null) {
        await _store.saveHostFingerprint(recebida!);
      }

      state = (
        stage: MachineStage.conectado,
        target: target,
        publicKeyLine: state.publicKeyLine,
        fingerprint: fixada ?? recebida,
        erro: null,
        hostKeyChanged: false,
      );
    } catch (erro) {
      await _fechar();
      if (!ref.mounted) return;
      final falha = _falhaAtual;
      state = (
        stage: MachineStage.falhou,
        target: target,
        publicKeyLine: state.publicKeyLine,
        fingerprint: fixada,
        erro: falha?.mensagem ?? _legivel(erro),
        hostKeyChanged: falha != null,
      );
    }
  }

  Future<void> desconectar() async {
    await _fechar();
    state = _com(stage: MachineStage.desconectado, erro: null);
  }

  _FalhaDeHost? _falhaAtual;

  void _escrever(Uint8List dados) =>
      terminal.write(utf8.decode(dados, allowMalformed: true));

  void _enviar(String dados) =>
      _shell?.stdin.add(Uint8List.fromList(utf8.encode(dados)));

  void _redimensionar(int largura, int altura, int px, int py) =>
      _shell?.resizeTerminal(largura, altura, px, py);

  void _quedaDaSessao() {
    if (!ref.mounted || state.stage != MachineStage.conectado) return;
    state = _com(
      stage: MachineStage.desconectado,
      erro: 'A sessão terminou.',
    );
  }

  Future<void> _fechar() async {
    await _saida?.cancel();
    await _erroPadrao?.cancel();
    _saida = null;
    _erroPadrao = null;
    _shell?.close();
    _shell = null;
    _client?.close();
    _client = null;
  }

  void _encerrar() {
    unawaited(_fechar());
    terminal.onOutput = null;
    terminal.onResize = null;
  }

  MachineState _com({required MachineStage stage, String? erro}) => (
    stage: stage,
    target: state.target,
    publicKeyLine: state.publicKeyLine,
    fingerprint: state.fingerprint,
    erro: erro,
    hostKeyChanged: false,
  );
}

/// A chave do host mudou. Carrega a nova impressão digital para a tela mostrar.
class _FalhaDeHost {
  const _FalhaDeHost(this.recebida);
  final String recebida;

  String get mensagem =>
      'A chave da máquina mudou. A conexão foi recusada.\n'
      'Recebida agora: $recebida';
}

/// Traduz a falha para o que houve e o que fazer, sem despejar `toString`.
String _legivel(Object erro) {
  if (erro is SSHAuthFailError || erro is SSHAuthAbortError) {
    return 'A máquina recusou a chave. Confira se a linha pública está no '
        '~/.ssh/authorized_keys do usuário informado.';
  }
  if (erro is TimeoutException) {
    return 'A máquina não respondeu a tempo. Confira se o aparelho está na '
        'tailnet e se o SSH está no ar.';
  }
  if (erro is SSHStateError || erro is SSHError) {
    return 'A sessão foi recusada pela máquina.';
  }
  return 'Não foi possível alcançar a máquina. Confira o nome, a porta e a '
      'tailnet.';
}
