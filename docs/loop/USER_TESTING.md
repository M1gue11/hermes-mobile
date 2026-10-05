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
