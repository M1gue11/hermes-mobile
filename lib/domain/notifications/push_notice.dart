import 'dart:convert';
import 'dart:typed_data';

/// Closed provisional envelope. No route, agent action or arbitrary text.
/// Decryption alone never authenticates the issuer.
class PushNotice {
  const PushNotice(this.eventId, this.category, this.summary);
  final String eventId;
  final String category;
  final String summary;

  static const maxBytes = 1024;
  static const maxCodepoints = 512;
  static const summaries = {
    'completion': 'Trabalho concluído',
    'error': 'Aviso operacional',
  };

  static PushNotice? parse(Uint8List bytes, {required bool decrypted}) {
    if (!decrypted || bytes.length > maxBytes) return null;
    try {
      final text = utf8.decode(bytes, allowMalformed: false);
      if (text.runes.length > maxCodepoints) return null;
      final json = jsonDecode(text);
      if (json is! Map<String, dynamic> ||
          json.length != 4 ||
          !json.keys.toSet().containsAll({
            'version',
            'event_id',
            'category',
            'summary',
          }) ||
          json['version'] is! int ||
          json['version'] != 1) {
        return null;
      }
      final id = json['event_id'];
      final category = json['category'];
      final summary = json['summary'];
      if (id is! String ||
          !RegExp(r'^[a-zA-Z0-9_-]{1,64}$').hasMatch(id) ||
          category is! String ||
          !summaries.containsKey(category) ||
          summary != summaries[category]) {
        return null;
      }
      return PushNotice(id, category, summary as String);
    } on FormatException {
      return null;
    }
  }
}

/// Bounded per-process dedupe, scoped by the locally selected registration.
/// This is not a durable delivery ledger or issuer authentication.
abstract interface class GenericPushNotifier {
  void show({required String title, required String body});
}

class PushNoticeReceiver {
  PushNoticeReceiver({required this.notifier});
  final GenericPushNotifier notifier;
  final Set<(String, String)> _seen = {};
  int accepted = 0;
  bool receive(String scope, Uint8List bytes, {required bool decrypted}) {
    final notice = PushNotice.parse(bytes, decrypted: decrypted);
    if (notice == null || !_seen.add((scope, notice.eventId))) return false;
    if (_seen.length > 256) _seen.remove(_seen.first);
    accepted++;
    // Only locally fixed generic text reaches the display abstraction.
    try {
      notifier.show(title: 'Hermes', body: 'Novo aviso operacional');
    } catch (_) {
      /* Display failure must not escape the receiver. */
    }
    return true;
  }
}
