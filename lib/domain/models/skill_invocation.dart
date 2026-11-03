/// Mirrors apps/shared/src/skill-scaffold.ts in Hermes v0.22.5. The full Skill
/// body is model context; history and older servers can still return it raw.
String? skillInvocationText(String text) {
  const prefix = '[IMPORTANT: The user has invoked the ';
  if (!text.startsWith(prefix)) return null;
  final match = RegExp(
    r'^\[IMPORTANT: The user has invoked the "([^"]+)"',
  ).firstMatch(text);
  if (match == null || match[1]!.trim().isEmpty) return null;
  final name = match[1]!.trim();
  final label = name.startsWith('/') ? name : '/$name';
  String between(String marker, String end, {bool fromEnd = false}) {
    final index = fromEnd ? text.lastIndexOf(marker) : text.indexOf(marker);
    if (index < 0) return '';
    final tail = text.substring(index + marker.length);
    final stop = tail.indexOf(end);
    return (stop < 0 ? tail : tail.substring(0, stop)).trim();
  }

  final instruction = text.contains(' skill bundle,')
      ? between('\nUser instruction: ', '\n\n[Loaded as part of the ')
      : text.contains('The full skill content is loaded below.]')
      ? between(
          'The user has provided the following instruction alongside the skill invocation: ',
          '\n\n[Runtime note:',
          fromEnd: true,
        )
      : '';
  return instruction.isEmpty
      ? label
      : '$label ${instruction.replaceAll(RegExp(r'\s+'), ' ')}';
}
