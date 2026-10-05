// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hermes_toolset.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HermesToolset _$HermesToolsetFromJson(Map<String, dynamic> json) =>
    _HermesToolset(
      name: json['name'] as String,
      label: json['label'] as String? ?? '',
      description: json['description'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? false,
      configured: json['configured'] as bool? ?? false,
      tools:
          (json['tools'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const <String>[],
    );

Map<String, dynamic> _$HermesToolsetToJson(_HermesToolset instance) =>
    <String, dynamic>{
      'name': instance.name,
      'label': instance.label,
      'description': instance.description,
      'enabled': instance.enabled,
      'configured': instance.configured,
      'tools': instance.tools,
    };
