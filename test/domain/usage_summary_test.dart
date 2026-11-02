import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/domain/models/usage_summary.dart';

void main() {
  test('série diária cobre o período inteiro com zero nos dias vazios', () {
    final usage = UsageSummary(
      periodDays: 7,
      daily: [
        UsageDay(day: DateTime(2026, 10, 28), inputTokens: 10),
        UsageDay(day: DateTime(2026, 11, 2), inputTokens: 5, outputTokens: 2),
      ],
    );

    final series = usage.dailySeries(DateTime(2026, 11, 2, 18, 30));

    expect(series, hasLength(7));
    expect(series.first.day, DateTime(2026, 10, 27));
    expect(series.last.day, DateTime(2026, 11, 2));
    expect([for (final d in series) d.tokens], [0, 10, 0, 0, 0, 0, 7]);
  });

  test('custo do dia prefere o cobrado ao estimado', () {
    expect(
      UsageDay(day: DateTime(2026), estimatedCost: 1, actualCost: 0.8).cost,
      0.8,
    );
    expect(UsageDay(day: DateTime(2026), estimatedCost: 1).cost, 1);
  });
}
