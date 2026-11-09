abstract interface class AgentFileSaver {
  /// Abre o seletor de destino do sistema. `false` significa cancelamento.
  Future<bool> save({
    required String localPath,
    required String name,
    required String mimeType,
  });
}
