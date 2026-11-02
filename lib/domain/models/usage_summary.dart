import 'package:freezed_annotation/freezed_annotation.dart';

part 'usage_summary.freezed.dart';

/// Uso de um dia do calendário local do servidor.
@freezed
abstract class UsageDay with _$UsageDay {
  const UsageDay._();

  const factory UsageDay({
    required DateTime day,
    @Default(0) int inputTokens,
    @Default(0) int outputTokens,
    @Default(0) double estimatedCost,
    @Default(0) double actualCost,
    @Default(0) int sessions,
  }) = _UsageDay;

  int get tokens => inputTokens + outputTokens;

  /// Custo cobrado quando o provedor informa; senão, o estimado.
  double get cost => actualCost > 0 ? actualCost : estimatedCost;
}

@freezed
abstract class ModelUsage with _$ModelUsage {
  const ModelUsage._();

  const factory ModelUsage({
    required String model,
    @Default(0) int inputTokens,
    @Default(0) int outputTokens,
    @Default(0) double estimatedCost,
    @Default(0) int sessions,
  }) = _ModelUsage;

  int get tokens => inputTokens + outputTokens;
}

/// Resumo de `GET /api/analytics/usage` do Dashboard.
///
/// Conta sessões iniciadas no período (`started_at`), de todas as origens:
/// Desktop, Telegram, rotinas e o próprio celular.
@freezed
abstract class UsageSummary with _$UsageSummary {
  const UsageSummary._();

  const factory UsageSummary({
    required int periodDays,
    @Default(0) int inputTokens,
    @Default(0) int outputTokens,
    @Default(0) int cacheReadTokens,
    @Default(0) int reasoningTokens,
    @Default(0) double estimatedCost,
    @Default(0) double actualCost,
    @Default(0) int sessions,
    @Default(0) int apiCalls,

    /// Só os dias que tiveram sessão, em ordem.
    @Default(<UsageDay>[]) List<UsageDay> daily,
    @Default(<ModelUsage>[]) List<ModelUsage> byModel,
  }) = _UsageSummary;

  int get tokens => inputTokens + outputTokens;

  bool get empty => sessions == 0 && tokens == 0;

  /// Um dia por dia do período, terminando em [today], com zero onde o
  /// servidor não tem sessão. Sem isso as barras juntariam dias distantes como
  /// se fossem vizinhos.
  List<UsageDay> dailySeries(DateTime today) {
    final fim = DateTime(today.year, today.month, today.day);
    final porDia = {
      for (final day in daily)
        DateTime(day.day.year, day.day.month, day.day.day): day,
    };
    return [
      for (var i = periodDays - 1; i >= 0; i--)
        porDia[DateTime(fim.year, fim.month, fim.day - i)] ??
            UsageDay(day: DateTime(fim.year, fim.month, fim.day - i)),
    ];
  }
}
