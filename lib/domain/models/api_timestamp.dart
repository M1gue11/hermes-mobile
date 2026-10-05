/// Converte timestamps do API Server, que podem ser ISO-8601 ou epoch numérico.
DateTime? apiTimestampFromJson(Object? value) {
  if (value is String) return DateTime.tryParse(value)?.toUtc();
  if (value is! num || !value.isFinite) return null;

  // Epochs em milissegundos são muito maiores que os em segundos atuais.
  final milliseconds = value.abs() >= 100000000000
      ? (value).round()
      : (value * 1000).round();
  return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
}

String? apiTimestampToJson(DateTime? value) => value?.toUtc().toIso8601String();
