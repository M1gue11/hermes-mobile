# Validações pendentes em aparelho

Este arquivo contém **somente** roteiros ainda pendentes de aceite em aparelho.
Após validação, registrar o resultado na mudança correspondente, atualizar
[BACKLOG.md](BACKLOG.md) e remover o roteiro daqui. O Git preserva o histórico.

## [ ] A75 — clarify batch no Android

- Abra uma conversa que peça quatro esclarecimentos; mesmo sem mensagens na
  thread, todas as perguntas devem aparecer e o composer deve dizer que aguarda
  decisão.
- Responda uma escolha, uma resposta livre e uma multi-seleção. Cada envio deve
  travar somente aquela pergunta; a multi-seleção deve manter todas as escolhas
  marcadas.
- Desconecte/reconecte após responder uma pergunta: ela deve permanecer concluída,
  sem opção de envio, e as pendentes devem continuar disponíveis.
- Force uma falha de rede ao responder e confirme que texto/seleção permanecem
  visíveis para retry.

## [ ] B12/B13 — streaming e retomada TUI 0.21.6

- Produzir separadamente um turno com `message.interim` e sinal de
  `tool.output_risk`: sem duplicação de comentário nem exposição de findings.
- Validar aprovação pendente durante reconexão, ring expirado e restart real
  do backend. Fixtures locais cobrem o contrato; esses aceites de runtime
  ainda não foram executados na build atual. Limites do snapshot e evidência
  do replay já validado estão na
  [auditoria](../dashboard-api/mobile-streaming-audit-0.21.6.md).

## [ ] A73 — expansão estável da timeline

- Abra uma tool: o cabeçalho deve permanecer no mesmo ponto da tela e revelar
  argumentos e saída abaixo dele.
- Um segundo toque durante a transição recolhe a mesma tool sem exigir scroll.
- Raciocínio e `Mostrar mais ferramentas` seguem a mesma regra de ancoragem.
- O conteúdo posterior desce/sobe com a divulgação, sem sobreposição, salto ou
  perda do ponto de leitura.
- Repita com texto a 180% e com “remover animações” ativo.

## [ ] A74 — acompanhamento do streaming por intenção

- Sem gesto do usuário, a resposta acompanha o fim do primeiro ao último token.
- Qualquer gesto de rolagem, mesmo curto, congela imediatamente o trecho visível.
- Novos tokens, mensagens e aprovações não deslocam a leitura pausada.
- Voltar manualmente ao rodapé não reativa o acompanhamento.
- O retorno ao fim, um novo envio e a troca de conversa reatam o acompanhamento
  explicitamente.
- A interação deve permanecer estável, sem puxões ou stuttering perceptível.

## [ ] A72 - persona de ponta a ponta

- Em Ajustes, configure uma persona com outro nome e gênero.
- Abra uma conversa nova: o rótulo acima de "No que estamos trabalhando?" deve
  mostrar o nome configurado, sem `HERMES AGENT`.
- Envie uma mensagem sem escolher modelo: cabeçalho, chip e bolha devem dizer
  `PADRÃO` ou o modelo efetivo, nunca `HERMES` ao lado do nome da persona.
- Repita com o campo de nome vazio: o padrão `HERMES AGENT` volta.

## [ ] A65 - gestão de Skills pelo Dashboard

- Com o Dashboard logado, abra Skills: o subtítulo diz
  `DASHBOARD · LEITURA E EDIÇÃO` e as desativadas aparecem com `DESATIVADA`.
- Abra uma Skill: o `SKILL.md` integral aparece. Desligue a chave e confira no
  Dashboard web que ela ficou desativada; religue.
- Toque no lápis, altere o texto e tente voltar pelo gesto do sistema: o app
  pede confirmação. Salve: o detalhe mostra o texto novo.
- Apague a linha `name:` do frontmatter e salve: o editor continua aberto com a
  causa devolvida pelo Dashboard.
- Com o editor aberto, altere a mesma Skill pelo Dashboard web e salve no app:
  aparece o aviso de que o `SKILL.md` mudou no servidor.
- Saia do Dashboard (sem sessão): o catálogo volta a
  `API SERVER · SOMENTE LEITURA`, sem lápis nem chave.

## [ ] A95 - agendamentos

- Em Ajustes, abra Agendamentos: as rotinas do servidor aparecem, ativas antes
  das pausadas, com a próxima execução no horário local.
- Crie uma rotina com agenda `every 30m` e um pedido curto: ela aparece na
  lista. Tente uma agenda inválida (`every xyz`): o formulário fica aberto com
  a causa devolvida pelo servidor.
- Abra a rotina e toque em Executar agora: a lista passa a mostrar
  "Rodando agora" e, ao terminar, a última execução.
- Pause e retome; confira no `hermes cron list` do servidor que o estado bate.
- Exclua a rotina de teste confirmando no diálogo.
