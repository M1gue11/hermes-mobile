import 'package:flutter/material.dart';

import 'hermes_tokens.dart';

/// Fonte única de verdade do visual do app.
///
/// O design do Hermes é deliberadamente NÃO-Material (estética editorial, corpo
/// em serifa, fundo de papel) e é dark-only: as três [Atmosphere]s substituem o
/// par claro/escuro. Por isso não usamos `ColorScheme.fromSeed` puro; montamos o
/// [ThemeData] a partir dos [HermesTokens] e penduramos os tokens como extensão.
abstract final class AppTheme {
  /// Monta o tema para uma atmosfera (padrão: Manuscrito).
  static ThemeData build([Atmosphere atmosphere = Atmosphere.manuscrito]) {
    final tokens = HermesTokens.forAtmosphere(atmosphere);

    // O Material ainda precisa de um ColorScheme (botões, ripple, cursores...).
    // Derivamos um a partir do accent e sobrescrevemos o que importa com tokens.
    final colorScheme = ColorScheme.fromSeed(
      seedColor: tokens.accent,
      brightness: Brightness.dark,
    ).copyWith(
      primary: tokens.accent,
      onPrimary: tokens.bg,
      secondary: tokens.accentInk,
      surface: tokens.surface,
      onSurface: tokens.ink,
      surfaceContainerHighest: tokens.bg2,
      outline: tokens.faint,
      outlineVariant: tokens.line,
      // Sem overlay de elevação: o Material 3 tinge superfícies elevadas com um
      // tom derivado da seed (puxa pro frio) e "suja" o âmbar quente do design.
      surfaceTint: Colors.transparent,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      // Fundo do app: cor sólida e uniforme (o mesmo tom quente dos sheets).
      scaffoldBackgroundColor: tokens.surface,
      canvasColor: tokens.surface,
    );

    // Corpo padrão em serifa, na cor de tinta primária.
    final textTheme = base.textTheme.apply(
      fontFamily: tokens.serif.fontFamily,
      bodyColor: tokens.ink,
      displayColor: tokens.ink,
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: tokens.ink,
        centerTitle: false,
      ),
      extensions: [tokens],
    );
  }
}
