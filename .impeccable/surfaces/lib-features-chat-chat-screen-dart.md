---
version: 1
slug: "lib-features-chat-chat-screen-dart"
primary_target: "lib/features/chat/chat_screen.dart"
related_targets: ["lib/features/chat/widgets/chat_action_sheets.dart","lib/features/chat/widgets/sheets.dart","lib/core/widgets/hermes_chip.dart","test/features/chat_navigation_test.dart"]
---

# A103 — operar o Hermes a partir da conversa

- **Escopo e modo:** extensão local da conversa existente, `Operate`, Android-first.
  Preservar a identidade de DESIGN.md, a timeline e os contratos do runtime.
  Nenhum sistema visual ou token novo foi estabelecido; PRODUCT.md, DESIGN.md e
  `.impeccable/design.json` permanecem inalterados.
- **Público e tarefa:** quem já conversa com o Hermes prepara o próximo turno e
  acessa sua administração sem voltar à lista de conversas, distinguindo ações
  da sessão e configurações do perfil.
- **Direção aprovada e implementada:** título com chevron abre Detalhes da
  conversa; a lupa mantém a busca local; o menu de operação substitui o acesso
  direto a Skills. A faixa do compositor oferece Modelo, Recursos e Máquina.
  Recursos reúne Skills, Ferramentas e MCP e Instruções do próximo turno.
  O menu Hermes abre Acessos, Uso geral, Agendamentos, Servidor e Ajustes do
  aplicativo. O gesto memorável é operar o Hermes sem abandonar a conversa.
- **Navegação e continuidade:** fechar o seletor antes de abrir uma tela inteira,
  para Voltar retornar diretamente à conversa com rascunho e posição de leitura
  preservados. Instruções abre sobre Recursos e volta para ele. Os acessos
  anteriores continuam disponíveis em Ajustes.
- **Leitura e toque:** pastilhas do compositor quebram em linhas com texto
  ampliado, têm alvo mínimo de 48 dp e limitam nomes de modelo longos com
  reticências. Ações de copiar e ouvir têm alvos mínimos de 48 × 48 dp e se
  distribuem em linhas; metadados longos de modelo são truncados para caber.
- **Verdade do produto:** Detalhes apresenta dados registrados da sessão,
  incluindo tokens e custo estimado quando disponível; Uso geral agrega
  conversas, origens e períodos. Mudanças em Ferramentas e MCP valem para novas
  sessões do perfil; a sessão aberta mantém as ferramentas já carregadas.
  O cabeçalho informa a verificação da API, com consulta pendente e falha, sem
  afirmar disponibilidade do Dashboard ou monitoramento contínuo.
- **Fora deste recorte:** badges e avisos atualizados de pedidos de acesso,
  monitoramento contínuo e busca global dentro do chat. A interface de descoberta
  e execução de comandos slash do gateway, incluindo desfazer e comprimir a
  sessão, fica adiada em A80; isso não afirma limitação da interpretação de
  texto digitado pelo runtime. Não liberar métodos TUI, alterar APIs ou adicionar
  dependências.
- **Validação registrada:** `flutter analyze` sem problemas; suíte completa com
  800 testes aprovados, incluindo 10 novos; APK debug compilado e instalado.
  Capturas nativas de emulador revisadas em escala normal:
  `build/a103-review/final-{chat,resources,operations,details}.png`; a 200%:
  `build/a103-review/large-{chat,resources,operations,operations-bottom}.png`.
  Parecer final do revisor: `disposition: ship`; `material_fixes: none`.
- **Pendente:** aceite manual em aparelho físico conforme `USER_TESTING.md`;
  A103 permanece `[~]` no backlog até esse aceite. A revisão no emulador não
  constitui aceite em aparelho físico. Não restam decisões visuais neste recorte.
