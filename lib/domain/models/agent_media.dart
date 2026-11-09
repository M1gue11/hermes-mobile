/// Diretiva `MEDIA:<caminho>` com que o agente entrega um arquivo do servidor.
///
/// O caminho é absoluto na máquina do gateway: `/…`, `~/…` ou `C:\…`. Exigir
/// isso é o que separa uma entrega de verdade de um texto que só fala da
/// diretiva (`MEDIA:<path>`). Pontuação, aspas e ênfase coladas ao fim ficam de
/// fora, como no `MEDIA_TAG_CLEANUP_RE` do gateway: `**MEDIA:/a.png**.` entrega
/// `/a.png`.
const mediaDirectivePattern =
    // Uma diretiva sozinha na linha pode carregar nomes com espaços. Em
    // prosa inline, espaços exigem aspas para não engolir o texto seguinte.
    r'^MEDIA:[ \t]*((?:/|~/|[A-Za-z]:[\\/])'
    r'''[^\r\n<>"'`]*[^\s<>"'`.,;:!?)\]}*_])[ \t]*$|'''
    r'''MEDIA:[ \t]*"((?:/|~/|[A-Za-z]:[\\/])[^"\r\n]+)"|'''
    r"MEDIA:[ \t]*'((?:/|~/|[A-Za-z]:[\\/])[^'\r\n]+)'|"
    r'MEDIA:[ \t]*((?:/|~/|[A-Za-z]:[\\/])'
    r'''(?:[^\s<>"'`]*[^\s<>"'`.,;:!?)\]}*_])?)''';

final _mediaDirective = RegExp(mediaDirectivePattern, multiLine: true);

String mediaPathFromMatch(Match match) {
  for (var index = 1; index <= match.groupCount; index++) {
    if (match[index] case final path?) {
      return path.trim();
    }
  }
  throw StateError('Diretiva de mídia sem caminho.');
}

/// Caminhos entregues em [text], na ordem em que aparecem.
List<String> mediaPathsIn(String text) => [
  for (final match in _mediaDirective.allMatches(text))
    mediaPathFromMatch(match),
];

/// Último segmento do caminho, aceitando separadores POSIX e Windows.
String mediaFileName(String path) {
  final segments = path.split(RegExp(r'[\\/]'))
    ..removeWhere((segment) => segment.isEmpty);
  return segments.isEmpty ? path : segments.last;
}

/// Extensões que o `GET /api/media` serve **e** que o Android decodifica.
///
/// O servidor também serve `.svg` e `.ico`, mas o Flutter não desenha SVG sem
/// dependência nova e não decodifica ICO; esses ficam como referência.
const _inlineImageExtensions = {'png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp'};

bool isInlineImagePath(String path) {
  final name = mediaFileName(path);
  final dot = name.lastIndexOf('.');
  if (dot <= 0) return false;
  return _inlineImageExtensions.contains(name.substring(dot + 1).toLowerCase());
}
