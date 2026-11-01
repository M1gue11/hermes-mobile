import 'package:freezed_annotation/freezed_annotation.dart';

part 'hermes_skill.freezed.dart';
part 'hermes_skill.g.dart';

/// Metadados de uma skill visível ao agente.
///
/// [enabled] só existe quando o catálogo veio do Dashboard, que lista também
/// as desativadas. O API Server lista apenas as ativas e não informa o estado.
@freezed
abstract class HermesSkill with _$HermesSkill {
  const factory HermesSkill({
    required String name,
    @Default('') String description,
    String? category,
    bool? enabled,
  }) = _HermesSkill;

  factory HermesSkill.fromJson(Map<String, dynamic> json) => _$HermesSkillFromJson(json);
}
