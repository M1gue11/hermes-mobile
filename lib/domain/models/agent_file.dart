/// Metadados de um arquivo entregue pelo Dashboard. Bytes ficam em arquivo
/// privado, nunca em estado persistido, logs ou cache compartilhado.
typedef AgentFileInfo = ({int size, String mimeType});

class AgentFileDownloadCancelled implements Exception {
  const AgentFileDownloadCancelled();
}
