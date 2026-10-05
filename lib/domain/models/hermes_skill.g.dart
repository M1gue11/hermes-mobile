// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hermes_skill.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HermesSkill _$HermesSkillFromJson(Map<String, dynamic> json) => _HermesSkill(
  name: json['name'] as String,
  description: json['description'] as String? ?? '',
  category: json['category'] as String?,
);

Map<String, dynamic> _$HermesSkillToJson(_HermesSkill instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'category': instance.category,
    };
