import 'package:flutter/widgets.dart';

/// Os arredondamentos do app, tirados de `design/Hermes.dc.html`.
///
/// Existe pelo mesmo motivo que [HermesTokens] existe para cor e [HermesMotion]
/// para tempo: sem um lugar único, cada superfície nasce com um raio avulso.
/// Quando isto foi escrito o app tinha **doze** raios diferentes (3, 5, 6, 8,
/// 10, 11, 12, 13, 14, 20, 22 e 26) e o desenho tem cinco, cada um com papel.
/// Duas faixas empilhadas na mesma barra saíam com 12 e 22, e era isso que
/// fazia a barra de mensagem parecer montada aos pedaços.
///
/// Regra de uso: escolha pelo **papel** da superfície, não pelo número.
abstract final class HermesRadius {
  /// Conteúdo pré-formatado: bloco de código e imagem dentro da resposta.
  /// `.hmd pre` e `.hmd img`: `border-radius:11px`.
  static const bloco = Radius.circular(11);

  /// Cartão ou linha de opção: o que se toca numa lista ou numa sheet.
  /// As linhas das sheets do protótipo: `borderRadius:'14px'`.
  static const cartao = Radius.circular(14);

  /// Pastilha: rótulo curto com borda, alto o bastante para ser uma cápsula.
  /// `.chip`: `padding:6px 11px;border-radius:20px`.
  static const pastilha = Radius.circular(20);

  /// Faixa da barra de mensagem: uma superfície da altura de um controle.
  /// O campo do composer no protótipo: `border-radius:22px`.
  ///
  /// **Toda** faixa empilhada na barra usa este, e é o que faz campo, gravação
  /// e aviso lerem como a mesma coisa em estados diferentes.
  static const capsula = Radius.circular(22);

  /// O topo do bottom sheet. `sheetStyle`:
  /// `borderTopLeftRadius:'26px'`.
  static const folha = Radius.circular(26);

  static BorderRadius todos(Radius raio) => BorderRadius.all(raio);
}
