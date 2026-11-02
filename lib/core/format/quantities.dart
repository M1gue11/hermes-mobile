/// Contagem curta em pt-BR: 38.200 vira 38,2 mil.
String compactCount(num value) {
  final v = value.round();
  if (v < 1000) return '$v';
  if (v < 1000000) return '${_umaCasa(v / 1000)} mil';
  if (v < 1000000000) return '${_umaCasa(v / 1000000)} mi';
  return '${_umaCasa(v / 1000000000)} bi';
}

/// Valor em dólar como o servidor registra, com vírgula decimal. Abaixo de um
/// centavo não vira "US$ 0,00", que esconderia que houve gasto.
String usdLabel(double value) {
  if (value <= 0) return r'US$ 0';
  if (value < 0.01) return r'< US$ 0,01';
  return 'US\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
}

String _umaCasa(double value) {
  final texto = value >= 100
      ? value.round().toString()
      : value.toStringAsFixed(1).replaceAll('.', ',');
  return texto.endsWith(',0') ? texto.substring(0, texto.length - 2) : texto;
}
