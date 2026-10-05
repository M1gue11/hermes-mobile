import 'package:freezed_annotation/freezed_annotation.dart';

part 'health_status.freezed.dart';
part 'health_status.g.dart';

/// Resposta de `GET /health` (`{"status": "ok"}`). Usado no boot para o
/// indicador online/offline.
@freezed
abstract class HealthStatus with _$HealthStatus {
  const HealthStatus._();

  const factory HealthStatus({@Default('unknown') String status}) =
      _HealthStatus;

  factory HealthStatus.fromJson(Map<String, dynamic> json) =>
      _$HealthStatusFromJson(json);

  bool get online => status == 'ok';
}
