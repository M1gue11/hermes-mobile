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

## Estado acionável

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
