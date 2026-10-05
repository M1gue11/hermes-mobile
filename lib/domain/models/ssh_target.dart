import 'dart:convert';
import 'dart:typed_data';

/// A máquina que roda o Hermes, do ponto de vista da sessão de shell.
typedef SshTarget = ({String host, int port, String user});

/// Diz por que o alvo não serve, ou `null` quando serve.
///
/// Mensagem em português e no que fazer, como o resto do app. Ver A7.
String? validateSshTarget(SshTarget target) {
  if (target.host.trim().isEmpty) return 'Informe o nome ou IP da máquina.';
  if (target.host.contains(' ')) return 'O nome da máquina não leva espaço.';
  if (target.user.trim().isEmpty) return 'Informe o usuário do SSH.';
  if (target.user.contains(' ')) return 'O usuário não leva espaço.';
  if (target.port < 1 || target.port > 65535) {
    return 'A porta vai de 1 a 65535.';
  }
  return null;
}

SshTarget normalizeSshTarget(SshTarget target) =>
    (host: target.host.trim(), port: target.port, user: target.user.trim());

/// A linha que vai para o `~/.ssh/authorized_keys` da máquina.
///
/// É a **única** coisa que sai do aparelho: a chave privada nunca é exibida,
/// exportada nem escrita fora do armazenamento seguro.
String authorizedKeysLine(
  String type,
  Uint8List publicKeyBlob,
  String comment,
) {
  final corpo = base64.encode(publicKeyBlob);
  final rotulo = comment.trim();
  return rotulo.isEmpty ? '$type $corpo' : '$type $corpo $rotulo';
}

/// A impressão digital do host, como o OpenSSH imprime.
///
/// O `dartssh2` entrega os bytes já no formato `SHA256:<base64>`, o mesmo que o
/// `ssh` mostra no primeiro acesso, então dá para conferir olhando os dois lado
/// a lado.
String readableFingerprint(Uint8List fingerprint) =>
    utf8.decode(fingerprint, allowMalformed: true);

/// O que fazer com a impressão digital recebida numa conexão.
enum HostKeyVerdict {
  /// Primeiro acesso: nada fixado ainda, então a decisão é de quem conecta.
  primeiraVez,

  /// Confere com o que foi fixado.
  confere,

  /// **Não** confere. A conexão para aqui.
  mudou,
}

/// Compara a impressão digital recebida com a que foi fixada.
///
/// Sem isto, uma sessão de shell dentro da tailnet aceita qualquer máquina que
/// atenda por aquele nome, e essa é a máquina que roda o Hermes.
HostKeyVerdict judgeHostKey(String? fixada, String recebida) {
  if (fixada == null || fixada.isEmpty) return HostKeyVerdict.primeiraVez;
  return fixada == recebida ? HostKeyVerdict.confere : HostKeyVerdict.mudou;
}
