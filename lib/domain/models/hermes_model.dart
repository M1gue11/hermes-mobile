import 'package:freezed_annotation/freezed_annotation.dart';

part 'hermes_model.freezed.dart';
part 'hermes_model.g.dart';

/// Um modelo anunciado por `GET /v1/models`.
@freezed
abstract class HermesModel with _$HermesModel {
  const factory HermesModel({
    required String id,
    @JsonKey(name: 'owned_by') String? ownedBy,
    int? created,
  }) = _HermesModel;

  factory HermesModel.fromJson(Map<String, dynamic> json) =>
      _$HermesModelFromJson(json);
}
