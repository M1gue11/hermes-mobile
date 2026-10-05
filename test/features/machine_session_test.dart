import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/data/config/ssh_store.dart';
import 'package:hermes_mobile/domain/models/ssh_target.dart';
import 'package:hermes_mobile/features/machine/machine_session.dart';

/// Armazenamento em memória, para o teste não tocar no KeyStore.
class FakeSshStore implements SshStore {
  SshTarget? target;
  String? privateKey;
  String? fingerprint;
  var apagouFingerprint = 0;

  @override
  Future<SshTarget?> readTarget() async => target;

  @override
  Future<void> saveTarget(SshTarget value) async => target = value;

  @override
  Future<String?> readPrivateKey() async => privateKey;

  @override
  Future<void> savePrivateKey(String pem) async => privateKey = pem;

  @override
  Future<String?> readHostFingerprint() async => fingerprint;

  @override
  Future<void> saveHostFingerprint(String value) async => fingerprint = value;

  @override
  Future<void> forgetHostFingerprint() async {
    apagouFingerprint++;
    fingerprint = null;
  }

  @override
  Future<void> clear() async {
    target = null;
    privateKey = null;
    fingerprint = null;
  }
}

({ProviderContainer container, FakeSshStore store}) montar() {
  final store = FakeSshStore();
  final container = ProviderContainer(
    overrides: [sshStoreProvider.overrideWithValue(store)],
  );
  addTearDown(container.dispose);
  return (container: container, store: store);
}

void main() {
  test('sem chave gerada, a sessão começa em semChave', () {
    final (:container, :store) = montar();
    expect(container.read(machineSessionProvider).stage, MachineStage.semChave);
    expect(store.privateKey, isNull);
  });

  test('gerar chave guarda a privada e devolve só a pública', () async {
    final (:container, :store) = montar();
    await container.read(machineSessionProvider.notifier).gerarChave();
    final state = container.read(machineSessionProvider);

    // A privada existe no armazenamento e é um PEM de OpenSSH.
    expect(store.privateKey, startsWith('-----BEGIN OPENSSH PRIVATE KEY-----'));
    // E **não** vaza para o estado que a tela lê.
    expect(state.publicKeyLine, startsWith('ssh-ed25519 '));
    expect(state.publicKeyLine, isNot(contains('PRIVATE')));
    expect(state.stage, MachineStage.desconectado);
  });

  test('cada geração dá um par novo', () async {
    final (:container, :store) = montar();
    final sessao = container.read(machineSessionProvider.notifier);
    await sessao.gerarChave();
    final primeira = container.read(machineSessionProvider).publicKeyLine;
    await sessao.gerarChave();
    final segunda = container.read(machineSessionProvider).publicKeyLine;
    expect(primeira, isNot(segunda));
  });

  test('trocar de máquina esquece a impressão digital da anterior', () async {
    final (:container, :store) = montar();
    final sessao = container.read(machineSessionProvider.notifier);

    await sessao.salvarAlvo((host: 'hermes-host', port: 22, user: 'operator'));
    store.fingerprint = 'SHA256:antiga';

    await sessao.salvarAlvo((host: 'outra', port: 22, user: 'operator'));

    // A chave fixada vale para **aquela** máquina; carregá-la para outra seria
    // aceitar um host desconhecido em silêncio.
    expect(store.apagouFingerprint, 1);
    expect(container.read(machineSessionProvider).fingerprint, isNull);
  });

  test('salvar o mesmo alvo de novo não descarta o que foi fixado', () async {
    final (:container, :store) = montar();
    final sessao = container.read(machineSessionProvider.notifier);

    await sessao.salvarAlvo((host: 'hermes-host', port: 22, user: 'operator'));
    await sessao.salvarAlvo((
      host: ' hermes-host ',
      port: 22,
      user: 'operator  ',
    ));

    expect(store.apagouFingerprint, 0);
  });

  test('esquecer o host é ato explícito e volta para desconectado', () async {
    final (:container, :store) = montar();
    final sessao = container.read(machineSessionProvider.notifier);
    store.fingerprint = 'SHA256:antiga';

    await sessao.esquecerHost();

    expect(store.apagouFingerprint, 1);
    expect(container.read(machineSessionProvider).fingerprint, isNull);
    expect(
      container.read(machineSessionProvider).stage,
      MachineStage.desconectado,
    );
  });

  test('conectar sem alvo ou sem chave não sai do lugar', () async {
    final (:container, :store) = montar();
    await container.read(machineSessionProvider.notifier).conectar();
    expect(container.read(machineSessionProvider).stage, MachineStage.semChave);
  });
}
