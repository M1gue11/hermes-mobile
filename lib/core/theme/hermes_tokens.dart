import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// As "atmosferas" do app: paletas completas que trocam papel, tinta e cor de
/// destaque de uma vez só (o sheet de Aparência no design).
///
/// Hoje só `manuscrito` está implementada; a estrutura já suporta as outras
/// duas - basta adicionar o `case` correspondente em [HermesTokens.of].
enum Atmosphere {
  manuscrito('Manuscrito', 'Papel âmbar, tinta quente'),
  jornal('Jornal', 'Neutro, vermelho editorial'),
  tecnico('Técnico', 'Azul frio, precisão');

  const Atmosphere(this.label, this.note);

  /// Rótulo e descrição exibidos no sheet de Aparência.
  final String label;
  final String note;
}

/// Tokens de design do Hermes, o análogo Flutter das CSS custom properties
/// (`--bg`, `--accent`, ...) usadas no protótipo do Claude Design.
///
/// É um [ThemeExtension]: uma gaveta de valores customizados pendurada no
/// [ThemeData]. Widgets leem com `Theme.of(context).extension<HermesTokens>()!`
/// (veja o atalho [HermesTokens.of]). Como fica no tema, trocar de atmosfera
/// reflete no app inteiro - e o Flutter sabe animar a transição via [lerp].
@immutable
class HermesTokens extends ThemeExtension<HermesTokens> {
  const HermesTokens({
    required this.bg,
    required this.bg2,
    required this.surface,
    required this.line,
    required this.ink,
    required this.dim,
    required this.faint,
    required this.accent,
    required this.accentInk,
    required this.positive,
    required this.codeBg,
    required this.codeInline,
    required this.cKey,
    required this.cStr,
    required this.cNum,
    required this.cFn,
    required this.cType,
    required this.serif,
    required this.mono,
  });

  // --- fundos e superfícies ---
  final Color bg; // fundo da tela
  final Color bg2; // cartões, campos, chips
  final Color surface; // sheets, elementos elevados
  final Color line; // divisores e bordas sutis (baixa opacidade)

  // --- tinta (texto) ---
  final Color ink; // texto primário
  final Color dim; // texto secundário
  final Color faint; // texto terciário / placeholders

  // --- destaque ---
  final Color accent; // cor da marca (âmbar no Manuscrito)
  final Color accentInk; // variação "quente" p/ acentos de tinta
  final Color positive; // status ok / online (verde)

  // --- código ---
  final Color codeBg; // fundo de bloco de código
  final Color codeInline; // fundo de código inline
  final Color cKey; // syntax: keywords
  final Color cStr; // syntax: strings
  final Color cNum; // syntax: números
  final Color cFn; // syntax: funções/títulos
  final Color cType; // syntax: tipos/classes

  // --- tipografia base (família só; cor/tamanho vêm por cima) ---
  final TextStyle serif; // corpo (Newsreader)
  final TextStyle mono; // meta, labels, código (JetBrains Mono)

  /// Atalho para ler os tokens a partir do contexto.
  static HermesTokens of(BuildContext context) =>
      Theme.of(context).extension<HermesTokens>()!;

  /// A serifa na **face real** do peso e do estilo pedidos.
  ///
  /// Use isto sempre que precisar de algo diferente do regular. Nunca
  /// `serif.copyWith(fontWeight: ...)`: o `google_fonts` registra **uma face
  /// por nome de família**, e o nome carrega a variante. `GoogleFonts.newsreader()`
  /// devolve a família `Newsreader_regular`, com um único arquivo dentro, o de
  /// peso 400 vertical. Pedir 600 ali não acha semibold nenhum, porque não há
  /// semibold registrado sob aquele nome: sobra o 400, ou um engrossamento
  /// sintético do motor.
  ///
  /// Era essa a diferença de peso que aparecia contra o mock. O protótipo
  /// carrega as faces de verdade (`Newsreader:ital,opsz,wght@0,6..72,300..600;
  /// 1,6..72,400;1,6..72,500` no `<link>` do design) e o app pedia peso a uma
  /// família que só tinha o regular.
  TextStyle serifIn(FontWeight weight, {bool italic = false}) =>
      GoogleFonts.newsreader(
        fontWeight: weight,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      );

  /// A mono na face real do peso e do estilo pedidos. Mesma armadilha da
  /// [serifIn]: o itálico do realce de comentário e o peso 500 do cabeçalho de
  /// tabela precisam vir da face certa.
  TextStyle monoIn(FontWeight weight, {bool italic = false}) =>
      GoogleFonts.jetBrainsMono(
        fontWeight: weight,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      );

  /// Constrói a paleta de uma [Atmosphere]. As fontes vêm do google_fonts.
  static HermesTokens forAtmosphere(Atmosphere atmosphere) {
    // Bases de fonte reutilizadas por todas as atmosferas.
    final serif = GoogleFonts.newsreader();
    final mono = GoogleFonts.jetBrainsMono();

    switch (atmosphere) {
      case Atmosphere.manuscrito:
        return HermesTokens(
          bg: const Color(0xFF15120E),
          bg2: const Color(0xFF1E1913),
          surface: const Color(0xFF241E17),
          line: const Color.fromRGBO(233, 224, 205, 0.11),
          ink: const Color(0xFFECE3D2),
          dim: const Color(0xFFA99F8C),
          faint: const Color(0xFF6E655A),
          accent: const Color(0xFFD8A24A),
          accentInk: const Color(0xFFC36A44),
          positive: const Color(0xFF5FBF7F),
          codeBg: const Color(0xFF100D09),
          codeInline: const Color.fromRGBO(216, 162, 74, 0.11),
          cKey: const Color(0xFFD98E5E),
          cStr: const Color(0xFFA8B37A),
          cNum: const Color(0xFFD8A24A),
          cFn: const Color(0xFFE6CC86),
          cType: const Color(0xFF9BB6A0),
          serif: serif,
          mono: mono,
        );
      // Jornal e Técnico ainda não implementados: caem no Manuscrito por ora.
      // Os valores estão documentados em design/Hermes.dc.html (método theme()).
      case Atmosphere.jornal:
      case Atmosphere.tecnico:
        return forAtmosphere(Atmosphere.manuscrito);
    }
  }

  @override
  HermesTokens copyWith({
    Color? bg,
    Color? bg2,
    Color? surface,
    Color? line,
    Color? ink,
    Color? dim,
    Color? faint,
    Color? accent,
    Color? accentInk,
    Color? positive,
    Color? codeBg,
    Color? codeInline,
    Color? cKey,
    Color? cStr,
    Color? cNum,
    Color? cFn,
    Color? cType,
    TextStyle? serif,
    TextStyle? mono,
  }) {
    return HermesTokens(
      bg: bg ?? this.bg,
      bg2: bg2 ?? this.bg2,
      surface: surface ?? this.surface,
      line: line ?? this.line,
      ink: ink ?? this.ink,
      dim: dim ?? this.dim,
      faint: faint ?? this.faint,
      accent: accent ?? this.accent,
      accentInk: accentInk ?? this.accentInk,
      positive: positive ?? this.positive,
      codeBg: codeBg ?? this.codeBg,
      codeInline: codeInline ?? this.codeInline,
      cKey: cKey ?? this.cKey,
      cStr: cStr ?? this.cStr,
      cNum: cNum ?? this.cNum,
      cFn: cFn ?? this.cFn,
      cType: cType ?? this.cType,
      serif: serif ?? this.serif,
      mono: mono ?? this.mono,
    );
  }

  /// Interpola dois conjuntos de tokens - o Flutter usa isto para animar uma
  /// troca de atmosfera suavemente. Cores fazem lerp; fontes trocam na metade.
  @override
  HermesTokens lerp(covariant ThemeExtension<HermesTokens>? other, double t) {
    if (other is! HermesTokens) return this;
    return HermesTokens(
      bg: Color.lerp(bg, other.bg, t)!,
      bg2: Color.lerp(bg2, other.bg2, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      line: Color.lerp(line, other.line, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      dim: Color.lerp(dim, other.dim, t)!,
      faint: Color.lerp(faint, other.faint, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentInk: Color.lerp(accentInk, other.accentInk, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      codeBg: Color.lerp(codeBg, other.codeBg, t)!,
      codeInline: Color.lerp(codeInline, other.codeInline, t)!,
      cKey: Color.lerp(cKey, other.cKey, t)!,
      cStr: Color.lerp(cStr, other.cStr, t)!,
      cNum: Color.lerp(cNum, other.cNum, t)!,
      cFn: Color.lerp(cFn, other.cFn, t)!,
      cType: Color.lerp(cType, other.cType, t)!,
      serif: t < 0.5 ? serif : other.serif,
      mono: t < 0.5 ? mono : other.mono,
    );
  }

  /// Igualdade por valor, e não por identidade.
  ///
  /// Isto não é cosmético. `HermesMarkdown` guarda o widget já construído de
  /// cada bloco de resposta decidido e usa os tokens como parte da chave: sem
  /// igualdade por valor, qualquer reconstrução do `ThemeData` produziria um
  /// objeto novo, a chave mudaria e o cache inteiro seria jogado fora sem que
  /// uma única cor tivesse mudado. Um dark-only com uma atmosfera só nunca
  /// mostraria diferença na tela, apenas gastaria o parse de novo.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HermesTokens &&
        other.bg == bg &&
        other.bg2 == bg2 &&
        other.surface == surface &&
        other.line == line &&
        other.ink == ink &&
        other.dim == dim &&
        other.faint == faint &&
        other.accent == accent &&
        other.accentInk == accentInk &&
        other.positive == positive &&
        other.codeBg == codeBg &&
        other.codeInline == codeInline &&
        other.cKey == cKey &&
        other.cStr == cStr &&
        other.cNum == cNum &&
        other.cFn == cFn &&
        other.cType == cType &&
        other.serif == serif &&
        other.mono == mono;
  }

  @override
  int get hashCode => Object.hashAll([
    bg,
    bg2,
    surface,
    line,
    ink,
    dim,
    faint,
    accent,
    accentInk,
    positive,
    codeBg,
    codeInline,
    cKey,
    cStr,
    cNum,
    cFn,
    cType,
    serif,
    mono,
  ]);
}
