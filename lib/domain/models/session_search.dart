import 'conversation.dart';

/// Conversa encontrada pela busca do servidor (`GET /api/sessions/search`).
///
/// [snippet] é o trecho da mensagem que casou, com o termo entre `>>>` e
/// `<<<` (marcas do FTS5 do servidor); para busca por id é a prévia.
typedef SessionSearchHit = ({
  Conversation conversation,
  String snippet,
  String? role,
});

/// Pedaços do trecho, marcando os que casaram com a busca.
List<({String text, bool match})> snippetRuns(String snippet) {
  final runs = <({String text, bool match})>[];
  var resto = snippet.replaceAll(RegExp(r'\s+'), ' ').trim();
  while (resto.isNotEmpty) {
    final abre = resto.indexOf('>>>');
    final fecha = abre < 0 ? -1 : resto.indexOf('<<<', abre + 3);
    if (abre < 0 || fecha < 0) {
      runs.add((text: resto.replaceAll('<<<', ''), match: false));
      break;
    }
    if (abre > 0) runs.add((text: resto.substring(0, abre), match: false));
    runs.add((text: resto.substring(abre + 3, fecha), match: true));
    resto = resto.substring(fecha + 3);
  }
  return [
    for (final run in runs)
      if (run.text.isNotEmpty) run,
  ];
}
