// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hermes_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HermesModel _$HermesModelFromJson(Map<String, dynamic> json) => _HermesModel(
  id: json['id'] as String,
  ownedBy: json['owned_by'] as String?,
  created: (json['created'] as num?)?.toInt(),
);

Map<String, dynamic> _$HermesModelToJson(_HermesModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'owned_by': instance.ownedBy,
      'created': instance.created,
    };
