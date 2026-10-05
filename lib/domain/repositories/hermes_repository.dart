import '../models/approval_request.dart';
import '../models/capabilities.dart';
import '../models/health_status.dart';
import '../models/hermes_model.dart';
import '../models/model_options.dart';
import '../models/hermes_skill.dart';
import '../models/hermes_toolset.dart';
import '../models/model_lock.dart';
import '../models/run.dart';
import '../models/run_event.dart';
import '../models/conversation.dart';
import '../models/conversation_page.dart';
import '../models/session_message.dart';

/// O "port" (contrato) para falar com o agente Hermes.
///
/// É uma `abstract interface class`: define O QUE dá pra fazer, sem dizer COMO.
/// A UI e os controllers dependem somente desta interface, nunca de HTTP direto.
abstract interface class HermesRepository {
  /// Boot: o servidor está vivo? (`GET /health`)
  Future<HealthStatus> health();

  /// Boot: quais features o servidor suporta? (`GET /v1/capabilities`)
  /// Decide, por ex., se mostramos o botão cancelar.
  Future<Capabilities> capabilities();

  /// Boot: modelos anunciados para o picker (`GET /v1/models`).
  Future<List<HermesModel>> models();

  /// Inventário e par provider/modelo efetivo (`GET /api/model/options`).
  ///
  /// [refresh] fura o cache de catálogo do servidor e sonda os endpoints
  /// customizados ao vivo. É lento por natureza, então só deve ser usado a partir
  /// de um gesto explícito de "atualizar modelos", nunca no boot.
  Future<ModelOptions> modelOptions({bool refresh = false});

  /// Skills instaladas e efetivamente visíveis para o agente (`GET /v1/skills`).
  Future<List<HermesSkill>> skills();

  /// Toolsets e tools resolvidos pelo API Server (`GET /v1/toolsets`).
  /// A API atual é somente de leitura: controles administrativos dependem das
  /// capabilities anunciadas pelo gateway.
  Future<List<HermesToolset>> toolsets();

  /// Lista uma página de sessões persistidas, com filtro real por origem.
  Future<ConversationPage> conversationPage({
    int limit = 50,
    int offset = 0,
    String? source,
  });

  /// Lê uma sessão com os metadados atuais devolvidos pelo gateway.
  Future<Conversation> getConversation(String sessionId);

  /// Lista sessões persistidas para consumidores que não precisam paginar.
  Future<List<Conversation>> listConversations({int limit = 100});

  /// Cria uma sessão vazia antes da primeira mensagem do chat.
  Future<Conversation> createConversation({
    String? title,
    String? model,
    String? provider,
  });

  /// Lê o histórico persistido de uma sessão.
  Future<List<SessionMessage>> conversationMessages(String sessionId);

  /// Atualiza o título exibido pelo Hermes para a sessão.
  Future<Conversation> updateConversation(String sessionId, {String? title});

  /// Cria uma ramificação persistida com o histórico atual da sessão.
  Future<Conversation> forkConversation(String sessionId, {String? title});

  /// Trava o par provider/modelo da sessão (`POST /api/sessions/{id}/model`).
  ///
  /// Devolve o par que o servidor confirmou, que pode diferir do pedido quando
  /// ele resolve o provider por rota. **Lança** quando o par não é roteável: o
  /// Hermes recusa com `409 model_lock_unavailable` em vez de cair no modelo
  /// global em silêncio, e essa recusa tem de chegar à tela.
  Future<ModelLock> lockConversationModel(String sessionId, ModelLock lock);

  /// Remove uma sessão persistida. A UI deve sempre pedir confirmação antes.
  Future<void> deleteConversation(String sessionId);

  /// Cria uma run (`POST /v1/runs`) e devolve o estado inicial (`run_id`).
  Future<Run> createRun({
    required String input,
    String? sessionId,
    String? instructions,
    String? model,
    List<Map<String, dynamic>>? conversationHistory,
  });

  /// Stream SSE de eventos incrementais da run (`GET /v1/runs/{id}/events`).
  /// Cada [RunEvent] é um delta de raciocínio/texto, progresso de tool ou
  /// mudança de estado. O stream encerra quando a run atinge estado terminal.
  Stream<RunEvent> runEvents(String runId);

  /// Estado atual da run (`GET /v1/runs/{id}`), para reconciliar em reconexão.
  Future<Run> getRun(String runId);

  /// Pede cancelamento (`POST /v1/runs/{id}/stop`): `running` -> `stopping`.
  Future<Run> stopRun(String runId);

  /// Responde a um `approval.request` (`POST /v1/runs/{id}/approval`).
  ///
  /// Enquanto isto não é chamado a thread do agente fica **bloqueada** no
  /// servidor: nada é aprovado por omissão. **Lança** `ApprovalException` quando
  /// o servidor recusa, por exemplo se o pedido já foi respondido por outro
  /// cliente da mesma run.
  Future<void> respondToApproval(String runId, ApprovalChoice choice);
}
