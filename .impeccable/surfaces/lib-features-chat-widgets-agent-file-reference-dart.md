---
version: 1
slug: "lib-features-chat-widgets-agent-file-reference-dart"
primary_target: "lib/features/chat/widgets/agent_file_reference.dart"
related_targets: ["lib/features/chat/widgets/agent_media_figure.dart"]
---

# A104 — arquivo salvável na conversa

- **Modo e escopo:** extensão local em `Operate`, Android-first. Quem recebe
  um `MEDIA` não-imagem identifica o arquivo e o salva sem sair da conversa.
- **THESIS:** a entrega do agente oferece uma ação de salvamento no próprio
  bloco de referência.
- **OWN-WORLD:** herda o Caderno de Operações: paleta quente, metadados em
  JetBrains Mono, ação em serifa, fundo `t.bg2`, filete `t.line` e raio de bloco
  existente. Nenhum token ou regra global novo.
- **STORY:** identificar nome e caminho; tocar em **Baixar arquivo**; acompanhar
  bytes recebidos, total quando informado e progresso; escolher o destino no
  seletor nativo; ler **Salvo** ou o motivo da recusa/falha. Durante a
  transferência, **Cancelar** ocupa o lugar da ação. Ao escolher o destino,
  o bloco informa o salvamento em andamento e desabilita a ação.
- **FIRST VIEWPORT:** bloco inline com ícone e nome no topo, caminho e estado
  abaixo, progresso durante a transferência e ação à direita no rodapé.
  O nome pode quebrar linhas com texto ampliado; o caminho permanece limitado
  a duas linhas. O controle preserva alvo mínimo de 48 dp.
- **FORM:** extensão da referência de mídia existente, sem novo conceito,
  sorteio de composição ou alteração da apresentação de imagens.
- **Limites:** o download começa por toque. Cancelamento e recusas permanecem
  explícitos no bloco; uma transferência concluída só recebe confirmação de
  salvamento após a resposta do seletor nativo.

## Evidência e revisão — 2026-11-09

Implementação em `agent_file_reference.dart`, integrada por
`agent_media_figure.dart`. Revisão independente: disposição `ship`, sem
`material_fixes`. Capturas em `build/loop-review/`: `normal.png`, `progress.png`,
`saved.png`, `narrow-large.png` (largura estreita e texto a 180%) e
`save-picker-fixed.png` (seletor nativo).

Estas decisões são locais à A104. PRODUCT.md, DESIGN.md e
`.impeccable/design.json` permanecem como referências globais existentes.
