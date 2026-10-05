import 'package:freezed_annotation/freezed_annotation.dart';

part 'hermes_skill.freezed.dart';
part 'hermes_skill.g.dart';

/// Metadados de uma skill efetivamente visível ao agente do API Server.
@freezed
abstract class HermesSkill with _$HermesSkill {
  const factory HermesSkill({
    required String name,
    @Default('') String description,
    String? category,
  }) = _HermesSkill;

  factory HermesSkill.fromJson(Map<String, dynamic> json) => _$HermesSkillFromJson(json);
}
