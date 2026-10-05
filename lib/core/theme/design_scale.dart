import 'package:flutter/material.dart';

/// Largura, em px lógicos, da tela que o mock do Claude Design desenha.
///
/// `design/Hermes.dc.html` fixa a moldura do telefone em `width:390px`. Todo
/// tamanho de fonte do design está escrito em px absolutos **sobre essa tela**,
/// então cada número só significa alguma coisa em relação a 390: o
/// `font-size:33px` do título da lista quer dizer "8,5% da largura", não "33".
const double designCanvasWidth = 390.0;

/// Fator que leva um tamanho escrito no mock para a tela de verdade.
///
/// Por que existe: copiar os px do design direto para um aparelho mais largo
/// entrega o mesmo número nominal numa tela maior, ou seja, tipo
/// proporcionalmente **menor**. Medido no emulador (1344 px a 480 dpi, logo
/// `1344 / 3 = 448` px lógicos), tudo saía 13% menor em relação à tela do que no
/// mock: o título `Conversas` ocupa 8,46% da largura no design e 7,37% aqui.
/// Foi exatamente essa a queixa, e ela aparecia em toda tela que copiou px do
/// design sem converter.
///
/// [minimo] é 1.0 porque numa tela mais estreita que a do mock encolher o texto
/// pioraria a leitura em vez de aproximar do design. [maximo] segura o outro
/// extremo: num tablet a resposta certa é limitar a medida do texto, não inflar
/// a fonte.
double designScale(
  double larguraDaTela, {
  double referencia = designCanvasWidth,
  double minimo = 1.0,
  double maximo = 1.3,
}) {
  if (!larguraDaTela.isFinite || larguraDaTela <= 0 || referencia <= 0) {
    return minimo;
  }
  final bruto = larguraDaTela / referencia;
  if (bruto < minimo) return minimo;
  if (bruto > maximo) return maximo;
  return bruto;
}

/// Tamanho do texto escolhido em Aparência.
///
/// O [designScale] iguala a proporção do mock, e essa é a referência do
/// desenho. Mas "igual ao mock" não é o mesmo que "confortável de ler no meu
/// aparelho": o mock é uma tela de 390px vista num monitor, e o telefone fica a
/// meio metro do olho. Este ajuste multiplica por cima da conversão, então
/// [TextSize.padrao] continua sendo a fidelidade ao design e os demais são
/// escolha de quem lê.
enum TextSize {
  padrao('Padrão', 'Fiel ao desenho', 1.0),
  grande('Grande', 'Um pouco maior', 1.15),
  maior('Maior', 'Leitura folgada', 1.32),
  maximo('Máximo', 'Para longe do olho', 1.5);

  const TextSize(this.label, this.note, this.factor);

  /// Rótulo e descrição no sheet de Aparência.
  final String label;
  final String note;

  /// Multiplicador aplicado sobre o [designScale].
  final double factor;
}

/// O fator desta tela.
///
/// Serve para o que o [DesignTextScaler] não alcança: entrelinha em `em`,
/// espaçamento de letra, recuo de lista e qualquer medida que o design escreve
/// em função do corpo do texto. Tamanho de fonte **não** passa por aqui, senão
/// escalaria duas vezes.
double designScaleOf(BuildContext context) =>
    designScale(MediaQuery.sizeOf(context).width);

/// [TextScaler] que aplica o fator do design **por cima** do escalonamento do
/// sistema.
///
/// Trocar o escalonador do sistema por um valor fixo apagaria o tamanho de
/// fonte que a pessoa escolheu no aparelho, que é ajuste de acessibilidade.
/// Aqui os dois se compõem: o do design leva o mock para esta tela, o do
/// sistema leva dali para o tamanho pedido.
@immutable
class DesignTextScaler extends TextScaler {
  const DesignTextScaler({required this.sistema, required this.fator});

  /// O escalonador que veio do sistema operacional.
  final TextScaler sistema;

  /// A razão entre esta tela e a tela do mock. Ver [designScale].
  final double fator;

  @override
  double scale(double fontSize) => sistema.scale(fontSize * fator);

  /// Estimativa, como manda o contrato do [TextScaler]: escalonador não linear
  /// não tem um fator único.
  @override
  double get textScaleFactor => scale(_amostra) / _amostra;

  static const double _amostra = 14.0;

  @override
  bool operator ==(Object other) =>
      other is DesignTextScaler &&
      other.sistema == sistema &&
      other.fator == fator;

  @override
  int get hashCode => Object.hash(sistema, fator);

  @override
  String toString() => 'design ${fator}x sobre $sistema';
}

/// Instala o [DesignTextScaler] na subárvore.
///
/// Fica no `builder` do [MaterialApp] para alcançar também diálogos, snackbars
/// e sheets, que nascem fora da árvore das rotas.
class DesignTypography extends StatelessWidget {
  const DesignTypography({
    super.key,
    required this.child,
    this.size = TextSize.padrao,
  });

  final Widget child;

  /// Escolha de quem lê, aplicada por cima da conversão do canvas.
  final TextSize size;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        textScaler: DesignTextScaler(
          sistema: media.textScaler,
          fator: designScale(media.size.width) * size.factor,
        ),
      ),
      child: child,
    );
  }
}
