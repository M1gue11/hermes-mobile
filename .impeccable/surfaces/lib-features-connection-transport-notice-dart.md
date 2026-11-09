---
version: 1
slug: "lib-features-connection-transport-notice-dart"
primary_target: "lib/features/connection/transport_notice.dart"
related_targets: ["lib/features/connection/connection_screen.dart","lib/features/chat/widgets/gateway_login_sheet.dart","lib/features/chat/widgets/sheets.dart","lib/features/debug/turn_capture_screen.dart"]
---

# A92 — transparência do transporte HTTP

- **Modo e escopo:** extensão local em `Operate`, Android-first. Quem configura
  ou usa as conexões precisa reconhecer quando credenciais e mensagens trafegam
  em HTTP e avaliar a proteção do trajeto.
- **THESIS:** informar a ausência de TLS no contexto da conexão, sem bloquear
  o uso nem afirmar que o nome do host comprova uma VPN.
- **OWN-WORLD:** herda a paleta quente e a linguagem do Caderno de Operações.
  Ícone em âmbar, título em tinta principal e explicação em tinta secundária;
  ambos os textos usam a serifa existente. Nenhum token ou regra global novo.
- **STORY:** editar a URL; ler o aviso reativo **Conexão sem TLS** se ela usa
  HTTP; entender a exposição de chave, senha, cookie e mensagens e o papel de
  Tailscale ou outra VPN. Host público ou rede não verificada recebe reforço
  textual. HTTPS não exibe o aviso. Em Ajustes e no diagnóstico, o aviso
  persistente identifica API Server, Dashboard ou ambos e orienta revisar
  Conexões.
- **FIRST VIEWPORT:** nos formulários de conexão e login adicional, aviso
  imediatamente abaixo da URL relevante. Em Ajustes, precede as ações; no
  diagnóstico, fica abaixo da barra superior. Ícone à esquerda e coluna de
  título e parágrafo à direita, sem ação ou confirmação adicional.
- **FORM:** extensão das superfícies existentes, sem novo conceito, sorteio
  de composição ou mudança no fluxo de conexão.

## Evidência e limites — 2026-11-09

Revisão independente: disposição `ship`, sem `material_fixes`. Capturas em
`build/loop-review/`: `a92-form-http.png`, `a92-settings.png` e
`a92-diagnostic.png`, a 448 dp e texto a 100%. O login adicional foi verificado
somente no código; texto ampliado e outras larguras não estão certificados por
estas capturas.

O harness inicializou o tema antes do binding e as capturas mostram fallback
sans. Isso não define a tipografia do produto: `_Notice` usa `t.serif` sem
override; `a92-settings-production.png` confirma Newsreader carregada no app
normal. Não há captura direta do aviso HTTP no app real, pois as conexões reais
usam HTTPS e corretamente não o exibem.

Estas decisões são locais à A92. PRODUCT.md, DESIGN.md e
`.impeccable/design.json` permanecem como referências globais existentes.
