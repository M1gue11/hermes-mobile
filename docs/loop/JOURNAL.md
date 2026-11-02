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

## Estado acionável

- Decisão do usuário: autorizar `session.usage`, `session.context_breakdown`
  (contexto da sessão, A98), `session.undo` e `session.compress` (A99), hoje
  fora da allowlist de métodos TUI.

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
