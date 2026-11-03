# Validações pendentes em aparelho

Este arquivo contém **somente** roteiros ainda pendentes de aceite em aparelho.
Após validação, registrar o resultado na mudança correspondente, atualizar
[BACKLOG.md](BACKLOG.md) e remover o roteiro daqui. O Git preserva o histórico.

## [ ] A80 — comandos do gateway na conversa

- Em uma conversa, digite `/sta`, selecione `/status` e envie: conferir o
  relatório real, copiar o resultado e reabri-lo por Recursos > Comandos.
- Consulte o catálogo, busque uma Skill e prepare argumentos multilinha; a
  seleção deve inserir texto para revisão, sem executar nem apagar o rascunho.
- Execute uma Skill curta numa conversa de teste: um único turno, mostrando a
  invocação humana, sem expor o corpo expandido ou duplicá-lo no histórico.
- Numa conversa descartável, cancele a confirmação de `/undo` e confira que
  nada mudou; depois confirme e verifique histórico truncado e texto preparado,
  sem reenvio automático. Validar `/compress` apenas nessa conversa de teste.
- Durante uma resposta, `/status` deve consultar sem interromper; `/stop` deve
  interromper essa resposta pelo canal real.
- Simule perda de rede durante um comando: nenhuma segunda execução automática;
  preserve a invocação e confira o estado antes de autorizar repetição.
- Com fonte ampliada, conferir sugestões, catálogo, argumentos com emoji,
  confirmação longa e resultados. Terminal indisponível deve estar explicado.
- Sem Dashboard, oferecer conexão; não enviar slash administrativo como prompt.

## [ ] A103 — operação a partir da conversa

- Com um rascunho e a leitura acima do fim, abra Recursos > Skills ou
  Ferramentas e volte: preservar texto e posição, sem menu aberto por baixo.
- Abra as instruções por Recursos, salve uma orientação e volte para Recursos;
  confira que ela é aplicada ao próximo turno sem apagar o rascunho.
- Pelo menu do topo, abra Acessos, Uso geral, Agendamentos e Servidor. Voltar
  deve levar diretamente à conversa; reiniciar, aprovar e revogar continuam
  protegidos pelas confirmações das telas existentes.
- Toque no título para consultar tokens/custos registrados da sessão. Uso geral
  deve permanecer identificado como agregado de todas as conversas.
- Em Ajustes do aplicativo, confirme que Conexões continua disponível.
- Com texto do sistema ampliado e um modelo de nome longo, confira as pastilhas,
  menus, metadados e ações de copiar/ouvir, sem transbordamentos ou alvos pequenos.

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

## [ ] A96 - imagens do agente

- Peça ao agente uma captura ou imagem salva em `HERMES_HOME/images` e
  entregue com `MEDIA:`: a figura aparece com o nome do arquivo, sem o caminho
  cru no texto. Toque nela, amplie com pinça e toque duplo e feche arrastando.
- Peça um PDF entregue com `MEDIA:`: aparece como referência com o caminho.
- Peça `MEDIA:` de uma imagem fora das pastas de mídia (por exemplo `/tmp`): a
  referência diz que o servidor só mostra as pastas de mídia, sem botão de
  tentar de novo.
- Saia do Dashboard e reabra a conversa: a referência pede para entrar no
  Dashboard e o resto da mensagem continua legível.

## [ ] A97 - servidor e reinício

- Em Ajustes > Servidor, confira que a fase, as sessões e as plataformas batem
  com `hermes status` no servidor.
- Com nenhum turno em andamento, toque em Reiniciar gateway e confirme: o
  trilho passa por pedido, parada e subida e termina em "Gateway de volta em
  N s". Volte ao chat e envie uma mensagem: ela é respondida.
- Repita com um turno em andamento: o diálogo avisa que ele será
  interrompido.
- Em Logs, alterne Erros e "Só erros", busque um termo conhecido e expanda um
  traceback longo.

## [ ] A98 - uso por período

- Em Ajustes > Uso, compare os totais de 30 dias com a página de análise do
  Dashboard web.
- Toque e arraste sobre as barras: a linha de cima acompanha o dia tocado.
- Com leitor de tela ligado, cada barra anuncia dia e tokens.

## [ ] A99 - busca no servidor

- Na lista de conversas, busque um termo que só aparece dentro de uma
  conversa antiga: a seção "No conteúdo das conversas" mostra o trecho com o
  termo destacado, e tocar abre a conversa certa.
- Busque o título de uma conversa já carregada: ela não aparece repetida na
  seção do servidor.

## [ ] A100 - ferramentas

- Em Ajustes > Ferramentas, desligue um toolset pouco usado, abra uma
  conversa nova e confirme que o agente não oferece aquelas ferramentas;
  religue.
- Desligue e religue um servidor MCP; confira em `config.yaml` que só
  `enabled` mudou.
- Toque em Testar conexão num servidor parado: o erro aparece em terracota,
  sem fechar a tela.

## [ ] A101 - acessos por plataforma

- De uma conta de teste, mande mensagem ao bot do Telegram sem estar na
  allowlist: o pedido aparece em Ajustes > Acessos com o nome e "há N min".
- Aprove: o diálogo diz que a pessoa poderá conversar com o agente pelo
  Telegram. Confirme e mande outra mensagem pela conta de teste: o agente
  responde.
- Revogue o acesso e confirme que a conta de teste volta a receber código.

## [ ] A102 - ouvir a resposta

- Toque em Ouvir numa resposta curta: aparece "gerando áudio", depois "parar"
  enquanto a voz toca, e volta para "ouvir" no fim.
- Toque em Ouvir noutra resposta durante a reprodução: a primeira para e a
  segunda começa.
- Com o TTS desligado no servidor, Ouvir mostra a causa e volta ao repouso.
