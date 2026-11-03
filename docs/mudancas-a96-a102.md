# Mudanças A96 a A102: recursos do runtime Hermes 0.22.5

Período: 2026-11-02. Branch `dev`, sete commits locais (sem push).

Todas as funções novas usam o Dashboard HTTP. Nenhum método TUI novo entrou na
allowlist. As telas novas ficam em Ajustes, exceto as imagens e o Ouvir, que
aparecem no chat, e a busca, que aparece na lista de conversas.

| Item | O que o usuário ganha | Commit |
|---|---|---|
| A96 | Imagens entregues pelo agente com `MEDIA:` aparecem na conversa | `a174cff` |
| A97 | Ajustes > Servidor: saúde, logs e reinício do gateway | `a1099a7` |
| A98 | Ajustes > Uso: tokens e custo por período | `cb4177f` |
| A99 | Busca no conteúdo de todas as conversas, pelo servidor | `b450e31` |
| A100 | Ajustes > Ferramentas: toolsets e servidores MCP | `28fd982` |
| A101 | Ajustes > Acessos: aprovar e revogar quem fala com o agente | `7a580bf` |
| A102 | Ouvir a resposta do agente com a voz do servidor | `3bb352b` |

Ao todo: 63 arquivos, cerca de 11 mil linhas adicionadas (código, testes e
documentação). `flutter analyze` limpo e 790 testes passando.

## A96 - imagens do agente

- O texto `MEDIA:/caminho/arquivo.png` vira uma figura com o nome do arquivo,
  sem o caminho cru. A imagem vem de `/api/media` e entra com fade.
- Tocar abre a imagem em tela cheia: pinça, zoom de 2,5x com toque duplo e
  arrastar para baixo para fechar. A transição usa Hero.
- Arquivos que não são imagem (PDF, por exemplo) aparecem como referência com o
  caminho.
- Os erros do servidor viram avisos claros: fora das pastas de mídia, arquivo
  grande demais, arquivo não encontrado, Dashboard não conectado. Só falhas de
  rede ou do servidor oferecem tentar de novo.
- Durante o streaming, a figura só carrega depois que o bloco termina.

## A97 - servidor, logs e reinício

- Cabeçalho com a fase do gateway (rodando, parado, iniciando), sessões e
  agentes ativos e as plataformas conectadas, com um ponto de status pulsante.
- Prontidão do API Server, item por item, a partir de `/health/detailed`.
- CPU, memória e disco da máquina.
- Logs: escolha do arquivo, filtro por nível, busca e tracebacks agrupados.
  Entradas longas abrem recolhidas.
- Reiniciar gateway: diálogo de confirmação (avisa se há turno em andamento) e
  um trilho que mostra pedido, parada e subida, até "Gateway de volta em N s".
  A conclusão é decidida pelo horário do servidor, não pelo relógio do celular.

## A98 - uso por período

- Períodos de 7, 30 e 90 dias.
- Destaque para o custo, ou para o total de tokens quando o provedor não
  registra custo.
- Barras diárias, com os dias sem uso preenchidos com zero. Tocar ou arrastar
  seleciona um dia e mostra os valores dele. Cada barra é anunciada pelo leitor
  de tela.
- Divisão por modelo, com a participação calculada sobre a soma dos modelos
  (o servidor inclui uso auxiliar, que passaria de 100%).

## A99 - busca no servidor

- Com dois ou mais caracteres na busca da lista de conversas, aparece a seção
  "No conteúdo das conversas", com o trecho encontrado e o termo destacado.
- Conversas já listadas não se repetem. Tocar abre a conversa.

## A100 - ferramentas

- Lista de toolsets e de servidores MCP, com chaves para ligar e desligar. A
  chave muda na hora e volta se o servidor recusar.
- Servidores MCP de plugin aparecem sem chave, porque o servidor não permite
  alterá-los.
- "Testar conexão" mostra as ferramentas encontradas ou o erro.

## A101 - acessos por plataforma

- Pedidos pendentes (Telegram, WhatsApp e afins) com nome e tempo de espera.
- Aprovar, revogar e limpar pendentes, cada um com confirmação.
- Os códigos de pareamento nunca aparecem no app; o servidor não os devolve.

## A102 - ouvir a resposta

- "Ouvir" no rodapé de cada resposta do agente. O estado passa por "gerando
  áudio" e "parar" e volta a "ouvir" no fim.
- O texto vai sem markdown e sem `MEDIA:`, limitado a 4000 caracteres e cortado
  no fim de uma frase.
- Tocar Ouvir noutra resposta para a primeira. Erros aparecem numa mensagem
  curta.
- O botão some quando não há Dashboard conectado.
- **Dependência nova:** `audioplayers` (biblioteca consolidada), para tocar o
  áudio sem gravar arquivo temporário.

## Validação

Feita no emulador Android contra o servidor 0.22.5 do usuário, com dados reais:

- A96: imagem gerada pelo agente exibida, ampliada e fechada.
- A97: status, prontidão, máquina e logs reais.
- A98: uso real de 30 e 90 dias, com seleção de barras.
- A99: busca por "vault" encontrou conversas antigas do Telegram e as abriu.
- A100: lista real de toolsets; o teste do MCP homeassistant devolveu 11
  ferramentas.
- A101: só o estado vazio (não havia pedidos).
- A102: síntese em cerca de 6 s, "parar" durante a reprodução, volta a "ouvir"
  no fim.

**Não executado no servidor real**, por mudar a configuração do usuário:
reiniciar o gateway, ligar ou desligar toolset e MCP e aprovar acessos. Esses
fluxos estão cobertos por testes automatizados e têm roteiro de aceite em
[USER_TESTING.md](loop/USER_TESTING.md).

Ajustes feitos depois de ver no emulador:

- Uso: o destaque "US$ 0" virou total de tokens; a divisão por modelo fechava
  em 111% e agora fecha em 100%.
- Servidor: os chips de filtro de log ocupavam uma linha cada (defeito corrigido
  no componente `HermesChip`); itens de prontidão com o "ok" no meio da linha;
  tracebacks longos agora recolhidos.

## Pendências

- **Decisão:** liberar os métodos TUI `session.usage` e
  `session.context_breakdown` (uso de contexto da conversa, A98) e
  `session.undo` e `session.compress` (desfazer turno e compactar, A99).
- Aceite em aparelho de A96 a A102, conforme
  [USER_TESTING.md](loop/USER_TESTING.md).
- Em aberto: usar `/api/media/proxy` para imagens remotas (FAL); tocar o áudio
  com a tela bloqueada; editar agendamentos (A95); custo do provedor Nous, ainda
  não medido.
- Observado nos logs do servidor: erros repetidos de lock do git nos
  checkpoints do Hermes ("Unable to create ... .lock: File exists").

## Referências

- Contratos medidos: [contrato-0.22.5-medido.md](hermes-api/contrato-0.22.5-medido.md)
- Backlog: [BACKLOG.md](loop/BACKLOG.md)
- Checkpoint: [JOURNAL.md](loop/JOURNAL.md)
