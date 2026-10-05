/// Formata a duração de uma ferramenta apenas para apresentação.
///
/// O domínio preserva a string recebida do gateway. Aqui, valores numéricos em
/// segundos ganham uma casa decimal; unidades desconhecidas continuam legíveis
/// em vez de serem reinterpretadas.
String? formatToolDuration(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return null;

  final numeric = value.endsWith('s')
      ? value.substring(0, value.length - 1).trim()
      : value;
  final seconds = double.tryParse(numeric.replaceFirst(',', '.'));
  if (seconds != null && seconds.isFinite) {
    return '${seconds.toStringAsFixed(1)}s';
  }

  return value;
}
