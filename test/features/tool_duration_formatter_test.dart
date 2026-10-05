import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/features/chat/tool_duration_formatter.dart';

void main() {
  test('formata segundos numéricos com uma casa decimal', () {
    expect(formatToolDuration('0.24'), '0.2s');
    expect(formatToolDuration('3'), '3.0s');
    expect(formatToolDuration('1.26s'), '1.3s');
    expect(formatToolDuration('1,25'), '1.3s');
  });

  test('preserva unidade desconhecida e trata ausência', () {
    expect(formatToolDuration('250ms'), '250ms');
    expect(formatToolDuration('  '), isNull);
    expect(formatToolDuration(null), isNull);
  });
}
