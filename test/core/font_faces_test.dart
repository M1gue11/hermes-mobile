import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/hermes_tokens.dart';

/// A29: peso e itálico têm de vir de uma **face real**.
///
/// O `google_fonts` registra uma face por nome de família, e o nome carrega a
/// variante. Pedir peso numa família que só tem a regular não acha nada, e é
/// isso que deixava o app mais leve que o mock do design.
void main() {
  // `testWidgets`, e não `test`, porque resolver uma face dispara a busca do
  // arquivo pelo `ServicesBinding`. O que se examina aqui é o **nome da
  // família** que cada face recebe, decidido localmente; o arquivo em si não
  // chega no ambiente de teste, e é o binding de widget que absorve isso.
  TestWidgetsFlutterBinding.ensureInitialized();
  HermesTokens tokens() => HermesTokens.forAtmosphere(Atmosphere.manuscrito);

  testWidgets('cada peso da serifa é uma família própria', (tester) async {
    final t = tokens();
    final regular = t.serif.fontFamily;
    expect(t.serifIn(FontWeight.w500).fontFamily, isNot(regular));
    expect(t.serifIn(FontWeight.w600).fontFamily, isNot(regular));
    expect(
      t.serifIn(FontWeight.w500).fontFamily,
      isNot(t.serifIn(FontWeight.w600).fontFamily),
    );
  });

  testWidgets('o itálico é outra face, não uma inclinação da regular', (tester) async {
    final t = tokens();
    expect(
      t.serifIn(FontWeight.w400, italic: true).fontFamily,
      isNot(t.serif.fontFamily),
    );
    expect(
      t.monoIn(FontWeight.w400, italic: true).fontFamily,
      isNot(t.mono.fontFamily),
    );
  });

  testWidgets('a armadilha: copyWith de peso não troca de face', (tester) async {
    // Este é o defeito, escrito como teste para que ninguém o reintroduza sem
    // ver por quê. O `copyWith` muda o número pedido e mantém a família que só
    // contém a regular, então o motor cai no peso 400 ou engrossa sozinho.
    final t = tokens();
    final falso = t.serif.copyWith(fontWeight: FontWeight.w600);
    expect(falso.fontFamily, t.serif.fontFamily);
    expect(falso.fontFamily, isNot(t.serifIn(FontWeight.w600).fontFamily));
  });

  testWidgets('a face pedida carrega o próprio peso e estilo', (tester) async {
    final t = tokens();
    final semibold = t.serifIn(FontWeight.w600);
    expect(semibold.fontWeight, FontWeight.w600);
    expect(semibold.fontStyle, FontStyle.normal);

    final italico = t.serifIn(FontWeight.w500, italic: true);
    expect(italico.fontWeight, FontWeight.w500);
    expect(italico.fontStyle, FontStyle.italic);
  });
}
