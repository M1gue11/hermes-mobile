import 'package:freezed_annotation/freezed_annotation.dart';

part 'hermes_toolset.freezed.dart';
part 'hermes_toolset.g.dart';

/// Toolset resolvido pelo gateway para a plataforma `api_server`.
@freezed
abstract class HermesToolset with _$HermesToolset {
  const factory HermesToolset({
    required String name,
    @Default('') String label,
    @Default('') String description,
    @Default(false) bool enabled,
    @Default(false) bool configured,
    @Default(<String>[]) List<String> tools,
  }) = _HermesToolset;

  factory HermesToolset.fromJson(Map<String, dynamic> json) =>
      _$HermesToolsetFromJson(json);
}
