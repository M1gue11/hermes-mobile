/// Aviso pronto para o sistema mostrar. [payload] é o deep link que o toque
/// abre; [urgent] usa o canal de quem espera resposta.
typedef LocalNotice = ({
  int id,
  String title,
  String body,
  String? payload,
  bool urgent,
});

abstract interface class LocalNotifier {
  /// Payloads tocados com o app aberto. Se o toque abriu o app, o payload
  /// vem por [launchPayload].
  Stream<String> get taps;

  /// Idempotente; [show] e [cancel] chamam sozinhos quando preciso.
  Future<void> initialize();

  Future<String?> launchPayload();

  /// Pede a permissão de notificação quando o sistema exige (Android 13+).
  Future<bool> requestPermission();

  Future<bool> permitted();

  Future<void> show(LocalNotice notice);

  Future<void> cancel(int id);
}
