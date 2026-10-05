import 'package:flutter/widgets.dart';

/// Vocabulário de movimento do app, tirado de `design/Hermes.dc.html`.
///
/// Existe pelo mesmo motivo que [HermesTokens] existe para cor: sem um lugar
/// único, cada animação nasce com um número avulso e a tela inteira perde a
/// cadência. O protótipo usa **cinco** durações e **cinco** curvas, e é esse
/// conjunto fechado que está aqui. Cada constante cita a regra CSS de origem,
/// para que uma mudança no design seja rastreável até o teste que ela quebra.
///
/// Regra de uso: nunca escreva `Duration(milliseconds: ...)` numa animação de
/// UI. Escolha a constante pelo **papel** do movimento, não pelo número, e leia
/// a duração por [motionOf], que respeita quem pediu menos movimento.
abstract final class HermesMotion {
  /// Resposta ao dedo: pressão de botão, chip, item de lista.
  /// `transition:transform .12s ease` e `transform .13s cubic-bezier(...)`.
  ///
  /// Curta de propósito. Acima disso o toque parece atrasado, porque o dedo já
  /// saiu quando a tela responde.
  static const toque = Duration(milliseconds: 130);

  /// Troca de estado no lugar: cor, borda, opacidade de algo que já está na
  /// tela. `transition:background .2s ease`, `border-color .2s`, `all .2s ease`.
  static const estado = Duration(milliseconds: 200);

  /// Superfície que muda de aparência inteira: fundo, sombra e cor juntos, ou
  /// um indicador deslizando entre posições.
  /// `background .25s ease, color .25s ease, box-shadow .25s ease` e
  /// `left .26s cubic-bezier(.4,0,.2,1)`.
  static const superficie = Duration(milliseconds: 250);

  /// Algo que se abre ou se fecha ocupando espaço novo: seção expansível,
  /// barra que desce, card que se revela.
  /// `grid-template-rows .34s cubic-bezier(.4,0,.2,1)`.
  static const revelar = Duration(milliseconds: 340);

  /// Entrada de conteúdo novo na tela.
  /// `animation:riseIn .5s cubic-bezier(.2,.85,.25,1)`, que é
  /// `opacity 0 -> 1` com `translateY(10px) -> 0`.
  static const entrada = Duration(milliseconds: 500);

  /// A entrada mais longa do desenho, reservada ao texto que o agente escreveu.
  /// `animation:inkIn .65s cubic-bezier(.2,.7,.2,1)`, com desfoque saindo junto:
  /// tinta assentando no papel.
  static const tinta = Duration(milliseconds: 650);

  /// O laço do brilho que percorre um rótulo enquanto algo acontece.
  /// `animation:shimmer 2.1s linear infinite`.
  ///
  /// Laço é outra categoria: não tem começo nem fim, e por isso não passa por
  /// [motionOf] do mesmo jeito. Quem pede menos movimento não deve vê-lo, e aí
  /// a decisão é **não animar**, não animar mais rápido.
  static const brilho = Duration(milliseconds: 2100);

  /// Saída sempre mais rápida que a entrada correspondente.
  ///
  /// Não é enfeite: entrada é aviso e merece ser percebida; saída é conclusão e
  /// atrasá-la só faz esperar. A proporção vem do A34, onde o card de aprovação
  /// entra em 360 ms e recolhe em 180. O CSS do protótipo não distingue os dois
  /// sentidos, então esta é a única regra deste arquivo que não sai de lá.
  static Duration saidaDe(Duration entrada) =>
      Duration(microseconds: entrada.inMicroseconds ~/ 2);

  /// Resposta ao dedo. `cubic-bezier(.2,.8,.2,1)`.
  static const curvaToque = Cubic(0.2, 0.8, 0.2, 1);

  /// Chegada com desaceleração forte, para o que entra vindo de fora.
  /// `cubic-bezier(.22,1,.3,1)`.
  static const curvaChegada = Cubic(0.22, 1, 0.3, 1);

  /// A curva de uso geral do protótipo, para o que se move entre dois lugares
  /// dentro da tela. `cubic-bezier(.4,0,.2,1)`.
  static const curvaPadrao = Cubic(0.4, 0, 0.2, 1);

  /// A curva do `riseIn`. `cubic-bezier(.2,.85,.25,1)`.
  static const curvaSubida = Cubic(0.2, 0.85, 0.25, 1);

  /// A curva do `inkIn`. `cubic-bezier(.2,.7,.2,1)`.
  static const curvaTinta = Cubic(0.2, 0.7, 0.2, 1);
}

/// O sistema pediu menos movimento?
///
/// Duas fontes, e as duas contam: `disableAnimations` é o pedido explícito de
/// reduzir movimento, e `accessibleNavigation` indica leitor de tela ativo, em
/// que uma transição atrasa o anúncio do que mudou. A regra foi estabelecida no
/// A34 e agora vale para o app inteiro, em vez de um widget só.
bool reduceMotionOf(BuildContext context) {
  final media = MediaQuery.maybeOf(context);
  return (media?.disableAnimations ?? false) ||
      (media?.accessibleNavigation ?? false);
}

/// A duração que de fato vale nesta tela.
///
/// Zero quando o sistema pede menos movimento, e aí a troca vira corte
/// instantâneo em vez de sumir: quem reduz movimento continua precisando ver o
/// resultado, só não quer o caminho até ele.
Duration motionOf(BuildContext context, Duration duracao) =>
    reduceMotionOf(context) ? Duration.zero : duracao;
