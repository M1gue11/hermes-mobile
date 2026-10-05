import 'package:freezed_annotation/freezed_annotation.dart';

part 'reasoning_config.freezed.dart';

/// Preferência local para exibir resumos de atividade emitidos pelo gateway.
/// Não envia nível de raciocínio nem orçamento, porque a Runs API não expõe
/// esses controles.
@freezed
abstract class ReasoningConfig with _$ReasoningConfig {
  const factory ReasoningConfig({
    @Default(true) bool showActivity,
  }) = _ReasoningConfig;
}
