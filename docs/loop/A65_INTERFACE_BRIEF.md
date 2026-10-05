# A65 - catálogo de Skills

- **Escopo e modo:** tela inteira de operação, modo `Operate`, Android-first.
- **Pessoa e tarefa:** uma pessoa consulta quais Skills o agente realmente tem
  disponíveis, encontra uma pelo nome, descrição ou categoria e entende o que
  o gateway informa sobre ela sem sair da conversa por engano.
- **Direção:** “índice de caderno”. Cabeçalho de tela, busca sempre acessível e
  uma lista plana ordenada por nome. Cada linha prioriza o identificador técnico,
  resume a função em serifa e mantém categoria como metadado discreto. O detalhe
  abre numa folha secundária e preserva a posição no catálogo.
- **Estados:** skeletons mantêm a geometria da lista durante a leitura; vazio do
  gateway e busca sem resultado explicam saídas diferentes; falha mostra causa,
  referência pública e retry somente quando a falha permite.
- **Limites:** `/v1/skills` expõe somente nome, descrição e categoria. A tela não
  inventa conteúdo de `SKILL.md`, edição, ativação ou marketplace. A limitação é
  informada no detalhe e o Contexto da próxima run passa a viver em Ajustes >
  Conversa.

## Inventário de fidelidade

| Ingrediente | Compromisso | Meio |
|---|---|---|
| Navegação | tela inteira com Back do sistema e gesto preservados | rota empilhada com transição curta do app |
| Busca | filtro local imediato, fácil de limpar e com label semântico | campo de 48 dp, nome/descrição/categoria normalizados |
| Lista | alta escaneabilidade sem cartões empilhados | linhas planas, divisores Fibra e alvo mínimo de 64 dp |
| Identidade | skill reconhecível como recurso técnico | ícone de livro, nome mono e descrição em serifa |
| Detalhe | metadados completos sem perder o catálogo | `HermesSheet` com descrição, categoria e limite da API |
| Loading | forma da lista visível sem spinner isolado | skeletons tonais estáticos |
| Texto ampliado | conteúdo cresce e quebra sem disputar com o chevron | coluna flexível e metadado em linha própria |
| Cor | âmbar orienta ação e foco, não decora toda a lista | cursor, busca ativa e ícone do detalhe |
