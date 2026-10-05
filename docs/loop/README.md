# Loop de desenvolvimento do Hermes Mobile

Este diretório reúne o estado acionável e os roteiros de validação do cliente.
Os contratos medidos estão em [`../dashboard-api/`](../dashboard-api/) e
[`../hermes-api/`](../hermes-api/). Um contrato observado depende da versão
indicada: confirme a versão alvo antes de assumir compatibilidade.

## Leia nesta ordem

1. [HANDOFF.md](HANDOFF.md): checkpoint e invariantes de integração.
2. [BACKLOG.md](BACKLOG.md): fila ativa e critérios de aceite.
3. [USER_TESTING.md](USER_TESTING.md): validações ainda pendentes em aparelho.
4. [SMOKE.md](SMOKE.md): roteiro reutilizável de emulador/aparelho.
5. [PRODUCT_INTERFACE_PLAN.md](PRODUCT_INTERFACE_PLAN.md): prioridades de produto.

## Gate de uma mudança

1. Execute `flutter analyze` e `flutter test` conforme o escopo.
2. Mudanças de interface exigem inspeção em emulador ou aparelho e atenção a
   estados de carregamento, vazio, erro, texto ampliado e acessibilidade.
3. Mudanças de rede exigem smoke na versão compatível do runtime, sem depender
   apenas de mocks.
4. Rode `git diff --check` e atualize o backlog e os roteiros pendentes.
5. Documente divergências técnicas no contrato afetado e registre testes
   executados e limitações na mudança correspondente.

Não inclua senha, chave Bearer, cookie, ticket WebSocket, chave SSH privada ou
dados de sessão em terminal, log, teste, captura ou documentação. Credenciais
são preenchidas no aparelho e permanecem no armazenamento seguro do sistema.
Mudanças de dependência, serviço externo, infraestrutura de push ou métodos
TUI não documentados exigem revisão explícita de escopo e segurança.
