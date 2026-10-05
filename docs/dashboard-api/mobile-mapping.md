# Mapeamento para o Hermes Mobile

Esta matriz registra decisões de integração e risco para as APIs do Dashboard.
Ela não amplia permissões só porque uma rota aparece no inventário. O endpoint e
o transporte são configurados para cada instalação; HTTP sem TLS só é adequado
quando a rede e a política do servidor o permitem.

| Rotas / categoria | Decisão | Justificativa | Auth / risco |
| --- | --- | --- | --- |
| `/api/auth/providers` | candidata | Pode informar a tela de bootstrap, se a arquitetura de login remoto for aprovada. | Exceção pública do gate; inventário de provedores não substitui um fluxo mobile de identidade. |
| `/auth/password-login` | adotada para anexos | Bootstrap da sessão do Dashboard usado por arquivo e voz. | URL, usuário, senha e cookies somente no armazenamento seguro; credencial recusada é removida. |
| `/api/auth/me` | candidata condicional | Somente para estado da sessão do Dashboard; não representa a identidade do API Server. | Depende do cookie da sessão; 401 usa envelope do Dashboard. |
| `/api/auth/ws-ticket` | necessária internamente | Necessária para o transport `WS /api/ws` após sessão cookie válida. | Ticket de uso único e TTL curto; nunca expor, persistir ou reutilizar. |
| `/api/audio/transcribe` | adotada para voz | Transcreve a gravação local; somente o texto segue como fala do usuário. | Sessão cookie, limite local de 25 MB e timeout longo; áudio não vira anexo no prompt. |
| `/auth/logout` | candidata futura | Habilitar somente depois da arquitetura de sessão do Dashboard estar aprovada. | Invalida a sessão cookie; ainda não habilitar. |
| `/api/status` | candidata | Diagnóstico mínimo e allowlist explícita; avaliar utilidade e exposição antes de exibir. | Sem sessão pelo gate nesta implantação; formato de resposta pode estar vazio no OpenAPI. |
| `/api/model/options?explicit_only=true` | candidata | Pode apoiar seletor curado de modelos do Dashboard, caso o produto aceite a dependência de `:9119`. | Exige sessão; catálogo é contextual a profile/provedores. Não confundir com o contrato OpenAI-compatible. |
| Sessões e histórico | gateway TUI por allowlist | Usar `WS /api/ws` para fidelidade ao Desktop, conforme o contrato MVP observado. | Sessão cookie do Dashboard e ticket efêmero; somente métodos allowlisted. |
| Skills e toolsets | usar API Server existente | Descoberta existente em `GET /v1/skills` e `GET /v1/toolsets`. | Bearer em `:8642`; não usar os CRUDs administrativos do Dashboard. |
| Chat e streaming | gateway TUI por allowlist | `WS /api/ws` preserva texto, tools, reasoning e prompts interativos do Desktop. | O ticket é interno e de uso único; `:8642` permanece alternativa de compatibilidade/Runs, não substituto de reasoning nativo. |
| `file.attach` | adotado para anexos | Prepara somente o arquivo escolhido no aparelho e devolve `ref_text`. | Limite local de 25 MB, confirmação explícita e `session_id` live. |
| Demais arquivos e filesystem | não integrar | Acesso amplo ao host do Desktop exige análise própria de escopo e autorização. | Alto risco de dados e execução remota. |
| Terminal e shell | não integrar | Execução e leitura de terminal no host permanecem fora do escopo. | Alto risco de execução remota e dados. |
| Git e worktrees | não integrar | Operações alteram repositórios no host do Dashboard. | Alto impacto operacional. |
| Configuração, env e providers | não integrar | Inclui configuração e possíveis segredos/validação de provedores. | Risco de credenciais e alteração de ambiente. |
| Credenciais e pool | não integrar | Gestão de material sensível não pertence ao cliente mobile. | Risco crítico. |
| Gateway, operações e update | não integrar | Controle do processo/host é administrativo. | Risco crítico de disponibilidade. |
| Profiles | não integrar | Profiles são configuração do host e podem afetar identidade/modelos. | Exige decisão explícita de produto e autorização. |
| Cron | não integrar | Agendamento e disparos são administrativos; `/api/cron/fire` usa JWT próprio. | Não é rota de app mobile. |
| MCP | não integrar | Instalação, autenticação e ativação de integrações externas. | Risco de execução e credenciais. |
| Pairing e mensageria | não integrar | Vincula canais e plataformas externas. | Risco de identidade e entrega de mensagens. |
| Webhooks | não integrar | Administração de saídas para serviços externos. | Risco de exfiltração e efeitos externos. |
| Backup, import e export | não integrar | Movimentam dados e estado operacional. | Risco alto de integridade e vazamento. |
| Plugins, analytics, memória e ferramentas administrativas | não integrar | Não há decisão de produto nem contrato mobile suficiente. | Em geral exigem sessão e podem afetar dados/host. |

## Divergência resolvida

O inventário de providers não usa mais um `Dio` separado em `:3000`.
[`HttpHermesRepository`](../../lib/data/http/http_hermes_repository.dart) chama
`/api/model/options` na mesma API Server autenticada do pareamento. A sessão do
Dashboard continua separada e serve somente às operações adotadas acima.
