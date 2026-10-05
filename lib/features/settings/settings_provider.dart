import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/theme/design_scale.dart';
import '../../core/theme/hermes_tokens.dart';
import '../../core/widgets/unicode_spinner.dart';
import '../../data/config/app_settings_store.dart';
import 'agent_persona.dart';

part 'settings_provider.g.dart';

/// Preferências de aparência do app (sheet "Aparência"): atmosfera, tamanho do
/// texto e estilo da marca animada. keepAlive porque valem para o app inteiro.
typedef AppSettingsState = ({
  AgentGender? agentGender,
  String agentName,
  Atmosphere atmosphere,
  bool chronologicalActivity,
  String spinner,
  TextSize textSize,
  bool showActivity,
  String instructions,
});

final appSettingsInitialProvider = Provider<StoredAppSettings?>((ref) => null);

final appSettingsStoreProvider = Provider<AppSettingsStore>(
  (ref) => const SecureAppSettingsStore(),
);

@Riverpod(keepAlive: true)
class AppSettings extends _$AppSettings {
  Future<void> _writeQueue = Future<void>.value();

  /// Nasce em [TextSize.grande], não em `padrao`.
  ///
  /// `padrao` é a fidelidade ao mock, e a fidelidade foi medida contra uma tela
  /// de 390px vista num monitor. No telefone, a meio metro do olho, ela lê
  /// apertada: foi a reclamação de quem usa o app, duas vezes seguidas. Quem
  /// quiser o desenho exato tem a opção a dois toques.
  @override
  AppSettingsState build() {
    final stored = ref.read(appSettingsInitialProvider);
    return (
      agentGender: _nullableEnumByName(AgentGender.values, stored?.agentGender),
      agentName: stored?.agentName?.trim() ?? '',
      atmosphere: _enumByName(
        Atmosphere.values,
        stored?.atmosphere,
        Atmosphere.manuscrito,
      ),
      chronologicalActivity: stored?.chronologicalActivity ?? true,
      spinner: kUnicodeSpinners.containsKey(stored?.spinner)
          ? stored!.spinner!
          : 'helix',
      textSize: _enumByName(TextSize.values, stored?.textSize, TextSize.grande),
      showActivity: stored?.showActivity ?? true,
      instructions: stored?.instructions ?? '',
    );
  }

  void setSpinner(String spinner) {
    if (!kUnicodeSpinners.containsKey(spinner)) return;
    state = _copy(spinner: spinner);
    _persist();
  }

  void setAtmosphere(Atmosphere atmosphere) {
    state = _copy(atmosphere: atmosphere);
    _persist();
  }

  void setTextSize(TextSize textSize) {
    state = _copy(textSize: textSize);
    _persist();
  }

  void setChronologicalActivity(bool chronological) {
    state = _copy(chronologicalActivity: chronological);
    _persist();
  }

  void setShowActivity(bool show) {
    state = _copy(showActivity: show);
    _persist();
  }

  void setInstructions(String instructions) {
    state = _copy(instructions: instructions);
    _persist();
  }

  void setAgentPersona({required String name, AgentGender? gender}) {
    state = _copy(
      agentName: name.trim(),
      agentGender: gender,
      replaceGender: true,
    );
    _persist();
  }

  AppSettingsState _copy({
    String? agentName,
    AgentGender? agentGender,
    bool replaceGender = false,
    Atmosphere? atmosphere,
    bool? chronologicalActivity,
    String? spinner,
    TextSize? textSize,
    bool? showActivity,
    String? instructions,
  }) => (
    agentGender: replaceGender ? agentGender : state.agentGender,
    agentName: agentName ?? state.agentName,
    atmosphere: atmosphere ?? state.atmosphere,
    chronologicalActivity: chronologicalActivity ?? state.chronologicalActivity,
    spinner: spinner ?? state.spinner,
    textSize: textSize ?? state.textSize,
    showActivity: showActivity ?? state.showActivity,
    instructions: instructions ?? state.instructions,
  );

  void _persist() {
    final snapshot = state;
    final stored = (
      agentGender: snapshot.agentGender?.name,
      agentName: snapshot.agentName,
      atmosphere: snapshot.atmosphere.name,
      chronologicalActivity: snapshot.chronologicalActivity,
      spinner: snapshot.spinner,
      textSize: snapshot.textSize.name,
      showActivity: snapshot.showActivity,
      instructions: snapshot.instructions,
    );
    final store = ref.read(appSettingsStoreProvider);
    // A fila garante que dois toques rápidos não terminem com a gravação mais
    // antiga vencendo por completar depois da nova.
    _writeQueue = _writeQueue
        .then((_) => store.save(stored))
        .catchError((_) {});
  }
}

final agentPersonaProvider = Provider<AgentPersona>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return AgentPersona(name: settings.agentName, gender: settings.agentGender);
});

T _enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}

T? _nullableEnumByName<T extends Enum>(List<T> values, String? name) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}
