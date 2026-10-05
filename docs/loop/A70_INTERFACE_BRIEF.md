# A70 - timeline operacional

- **Escopo e modo:** componente da conversa, modo `Operate`, Android-first.
- **Pessoa e tarefa:** o usuário acompanha um turno real e precisa entender, em
  poucos segundos, a ordem entre raciocínio e ferramentas, o que está em curso,
  o que terminou, o que falhou e onde abrir evidência técnica.
- **Direção aprovada por delegação:** “diário costurado”. Um trilho único liga
  somente o primeiro ao último evento; cada estado tem geometria, texto e cor próprios.
  A linha pausa 3,5 dp antes e depois da silhueta de cada marcador, sem outros
  furos entre eventos. Raciocínio tem ícone próprio.
  O item vivo é o único com movimento contínuo e troca de símbolo no lugar ao
  concluir, sem deslocar o conteúdo.
- **Hierarquia:** a linha da ferramenta tem duas colunas. À esquerda, ícone e
  nome ficam sobre o argumento, ambos partindo do mesmo eixo; à direita, uma
  faixa estreita centraliza o chevron na altura das duas linhas e alinha seu
  glifo à borda direita comum a todos os eventos. Sucesso é
  comunicado pelo marcador do trilho, sem `OK` redundante; só execução, erro e
  duração aparecem como metadados. Detalhe abre no fluxo, indentado pelo trilho,
  separando argumentos e saída; abraça conteúdo curto e só rola ao alcançar o
  limite, sempre ocupando toda a largura horizontal da coluna. JSON válido é
  identado e realçado. O modo cronológico vira padrão; o
  consolidado permanece como opção compacta usando o mesmo item visual e
  formatter.
- **Limites:** preservar o conteúdo final como protagonista; não inventar
  progresso que o gateway não envia; não transformar eventos em cartões; não
  depender apenas de cor; não alterar o valor bruto da duração no domínio.

## Inventário de fidelidade

| Ingrediente | Compromisso | Meio |
|---|---|---|
| Trilho | filete sem sobra nas pontas, contínuo entre respiros de 3,5 dp | um `CustomPainter` por evento, sem emendas internas |
| Ticks | raciocínio, nota, execução, sucesso e erro com silhuetas distintas | Material Icons + geometria Flutter |
| Linha de evento | conteúdo em duas faixas com o mesmo eixo; chevron isolado, centralizado verticalmente e alinhado à direita | coluna fluida + faixa fixa de 28 dp, sem proporção rígida |
| Categoria da tool | terminal, leitura, escrita, patch, web/browser, visão e skill reconhecíveis antes da leitura | Material Icons discretos + fallback genérico |
| Estado vivo | movimento contido no tick e feixe luminoso cruzando um âmbar suavizado da esquerda para a direita | base misturada com tinta secundária + `ShimmerEffect` horizontal de 2,1 s; estático com redução de movimento |
| Detalhes | largura total, altura pelo conteúdo, teto rolável e JSON formatado/realçado | `CodeSurface` + `HermesSyntaxHighlighter` |
| Divulgação | altura, tinta, deslocamento curto e chevron em uma transição | `_TimelineDisclosure` compartilhado |
| Toque | resposta sem splash, glow ou preenchimento retangular | tinta + deslocamento; foco por filete; brilho fica restrito ao placeholder vivo |
| Modos | cronológico padrão e consolidado compacto | mesmo componente, composição diferente |
| Texto ampliado | preview vive separado; nome trunca e metadados relevantes não quebram | composição em duas colunas + `TextScaler` |
| Alto contraste | forma e semântica comunicam conclusão; execução e erro mantêm rótulo | marcador + texto contextual + semântica |

As composições são norte de hierarquia e topologia, não especificação literal.
Não entram navegação inventada, marcadores gigantes, sombras ou tamanho de
detalhe que prejudique a conversa real.
