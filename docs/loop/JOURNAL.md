# Checkpoint corrente do loop

Este arquivo não é um log append-only. Ele guarda somente o contexto necessário
para retomar a iteração atual. Os contratos duráveis estão na documentação
versionada; o Git registra as mudanças do repositório.

## 2026-09-12 - saneamento do loop

- O backlog agora contém somente trabalho aberto, em validação ou bloqueado.
- `USER_TESTING.md` contém somente os aceites manuais ainda pendentes: A75, A73
  e A74.
- Não houve mudança de comportamento do aplicativo nesta limpeza.

## 2026-09-12 - simplificação de A73 e A74

- A thread passou para ordem cronológica normal; a leitura pausada não recebe
  mais compensações geométricas por `jumpTo`.
- O fim acompanha métricas já calculadas somente enquanto a intenção permanece
  ativa. Envio, retorno explícito e troca de conversa reatam o acompanhamento.
- Tools, raciocínio e `Mostrar mais ferramentas` pausam antes de divulgar e usam
  apenas animação vertical de altura; redução de movimento troca o estado sem
  criar um render animado.
- Testes automatizados e análise estão verdes; o aceite Android de A73/A74 segue
  pendente em `USER_TESTING.md`.

## 2026-11-02 - recursos do runtime 0.22.5 (A96 a A102)

- Entraram imagens `MEDIA:` (A96), Servidor com saúde, logs e reinício (A97),
  Uso por período (A98, parte HTTP), busca no servidor (A99, parte HTTP),
  Ferramentas (A100), Acessos (A101) e ouvir a resposta (A102), todos pelo
  Dashboard HTTP; nenhum método TUI novo.
- Dependência nova: `audioplayers` (A102), biblioteca consolidada, para tocar
  os bytes de `/api/audio/speak` sem arquivo temporário.
- Validado no emulador contra o 0.22.5 com dados reais. Não foram disparadas
  ações que mudam o servidor do usuário: reiniciar gateway, alternar toolset
  ou MCP e aprovar pareamento ficaram para `USER_TESTING.md`.

## 2026-11-02 - operação a partir da conversa (A103)

- Título abre detalhes da sessão; Recursos reúne Skills, Ferramentas/MCP e
  instruções; o menu Hermes abre Acessos, Uso geral, Agendamentos, Servidor e
  Ajustes. Os destinos anteriores em Ajustes permanecem disponíveis.
- Navegação por tela inteira fecha o seletor e retorna diretamente à conversa.
  Regressões cobrem rascunho, leitura, instruções, conexões e texto ampliado.
- Ferramentas explicam que a mudança é do perfil e vale para novas conversas;
  a verificação inicial da API distingue carregamento, falha e indisponibilidade.
- Metadados longos e ações de copiar/ouvir acomodam texto ampliado; as ações
  recebem alvo mínimo de 48 dp. Nenhuma API, dependência ou método TUI novo.
- Brief: [A103_INTERFACE_BRIEF.md](A103_INTERFACE_BRIEF.md). Aceite em aparelho
  permanece em [USER_TESTING.md](USER_TESTING.md).

## 2026-11-02 — comandos na conversa (A80)

- Integração autorizada pelo usuário e conferida no repositório local do Hermes
  Agent, incluindo a tag alvo v0.22.5 (`56b6a31fed`). Foram consumidos somente
  `commands.catalog`, `complete.slash`, `slash.exec` e `command.dispatch`.
- Catálogo em Recursos e autocomplete do servidor no compositor; resultados,
  confirmações de alterações, aliases, prefill, Skills e histórico local por
  conversa. Payload do modelo e invocação visível permanecem separados.
- O listener de comandos é substituído sem esperar a própria limpeza assíncrona;
  trocar de conversa ou sair da rota fecha a conexão sem bloquear a hidratação.
- Smoke real: sugestões e relatório de `/status` no 0.22.5. Alterações do perfil
  não foram disparadas no servidor do usuário. Nenhuma dependência nova.
- Validação: 825 testes aprovados, análise estática limpa e APK debug instalado
  no emulador. Confirmação de `/undo` inspecionada e cancelada sem executar.
- Revisão Impeccable: `ship`, sem pendências materiais. Corrigido o fallback
  de resultado pendente sem texto; regressão confirma estado em andamento na
  folha e no histórico recente, sem anunciar conclusão.
- Contrato e inventário de 104 comandos em `docs/dashboard-api/mobile-commands-0.22.5.md`
  e `mobile-command-inventory-0.22.5.md`; brief em `A80_COMMANDS_BRIEF.md`.

## Estado acionável

- Decisão pendente: autorizar `session.usage` e `session.context_breakdown`
  para contexto estruturado da sessão (A98). Desfazer e compactar foram
  autorizados e implementados pelos comandos confirmados em A80; os métodos
  diretos `session.undo` e `session.compress` seguem fora da allowlist.

- A75: validar clarify batch real no Android, incluindo retry, reconexão e
  multi-seleção.
- A73: validar a expansão ancorada da timeline em tools, raciocínio e no resumo
  de ferramentas, incluindo texto ampliado e movimento reduzido.
- A74: validar acompanhamento e pausa do streaming por intenção em conversa
  real.
- A72: substituir fallbacks visíveis de identidade pela persona configurada,
  preservando nomes técnicos e de produto.
- A65: confirmar o contrato autenticado necessário para corpo integral, edição,
  exclusão e ativação/desativação persistidas de Skills.
- A60, B0, B10, B9 e B11 permanecem posteriores conforme `BACKLOG.md`.
