import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/domain/models/ssh_target.dart';

void main() {
  group('validateSshTarget', () {
    test('alvo completo passa', () {
      expect(
        validateSshTarget((host: 'hermes-host', port: 22, user: 'operator')),
        isNull,
      );
    });

    test('a falta diz o que falta, em português', () {
      expect(
        validateSshTarget((host: '', port: 22, user: 'operator')),
        'Informe o nome ou IP da máquina.',
      );
      expect(
        validateSshTarget((host: 'hermes-host', port: 22, user: '  ')),
        'Informe o usuário do SSH.',
      );
      expect(
        validateSshTarget((host: 'hermes-host', port: 0, user: 'operator')),
        'A porta vai de 1 a 65535.',
      );
      expect(
        validateSshTarget((host: 'mi guel', port: 22, user: 'operator')),
        'O nome da máquina não leva espaço.',
      );
    });

    test('espaço nas pontas some antes de valer', () {
      final alvo = normalizeSshTarget((
        host: '  hermes-host ',
        port: 22,
        user: ' operator  ',
      ));
      expect(alvo.host, 'hermes-host');
      expect(alvo.user, 'operator');
      expect(validateSshTarget(alvo), isNull);
    });
  });

  group('authorizedKeysLine', () {
    test('monta a linha no formato que o OpenSSH lê', () {
      final blob = Uint8List.fromList([1, 2, 3, 4]);
      expect(
        authorizedKeysLine('ssh-ed25519', blob, 'hermes-mobile'),
        'ssh-ed25519 ${base64.encode(blob)} hermes-mobile',
      );
    });

    test('sem comentário, a linha continua válida', () {
      final blob = Uint8List.fromList([9]);
      expect(
        authorizedKeysLine('ssh-ed25519', blob, '  '),
        'ssh-ed25519 ${base64.encode(blob)}',
      );
    });
  });

  group('judgeHostKey', () {
    const recebida = 'SHA256:abcdef';

    test('sem nada fixado, é primeiro acesso', () {
      expect(judgeHostKey(null, recebida), HostKeyVerdict.primeiraVez);
      expect(judgeHostKey('', recebida), HostKeyVerdict.primeiraVez);
    });

    test('igual ao que foi fixado, confere', () {
      expect(judgeHostKey(recebida, recebida), HostKeyVerdict.confere);
    });

    test('diferente do fixado, a conexão para', () {
      // Sem esta comparação, uma sessão de shell dentro da tailnet aceita
      // qualquer máquina que atenda por aquele nome, e essa é a máquina que
      // roda o Hermes.
      expect(judgeHostKey(recebida, 'SHA256:outra'), HostKeyVerdict.mudou);
    });
  });

  test('a impressão digital sai como o OpenSSH imprime', () {
    final bytes = Uint8List.fromList(utf8.encode('SHA256:abc/def+gh'));
    expect(readableFingerprint(bytes), 'SHA256:abc/def+gh');
  });
}
