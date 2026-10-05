# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users

O usuário pode usar o app no celular para acompanhar, retomar e operar o agente
Hermes sem depender de estar diante do computador.

## Product Purpose

Hermes Mobile é o cliente móvel do agente Hermes. O objetivo é aproximar-se ao
máximo das capacidades disponíveis no desktop, com adaptações quando uma função
for inadequada, desnecessária ou desproporcional no celular.

Sucesso significa conseguir encontrar uma conversa, entender seu estado,
retomá-la e conduzir o trabalho do agente com segurança a partir do Android.

## Positioning

O app não é apenas um visualizador remoto nem um chat genérico. Ele leva para o
celular a operação real do Hermes, incluindo conversas persistentes, streaming,
raciocínio e ferramentas, aprovações, anexos, modelos, Skills, conexões e acesso
à máquina, respeitando as limitações próprias de uma interface móvel.

## Operating Context

- Uso em aparelhos Android, com compatibilidade iOS a validar.
- Conexão com o Hermes API Server e com o Dashboard TUI configurados pelo usuário.
- Continuidade entre celular e desktop: conversas e execuções podem existir ou
  mudar fora do aparelho e precisam ser retomadas sem perda.
- A interface deve funcionar com listas curtas e longas, conversas ativas,
  falhas de rede, paginação e reinicialização do app.

## Capabilities and Constraints

- Android é a plataforma prioritária. Compatibilidade com iOS pode ser
  preservada, mas não exige acabamento equivalente nesta etapa.
- Paridade funcional com o desktop é uma direção de produto, não uma obrigação
  de copiar literalmente cada superfície ou interação.
- Segredos nunca podem aparecer em logs, testes, screenshots ou documentação.
- Dependência nova, serviço externo, infraestrutura de push, método TUI fora da
  allowlist ou afastamento relevante da referência visual exigem decisão do
  usuário.
- `design/Hermes.dc.html` é referência visual, não código a ser copiado.

## Brand Commitments

- O produto se chama Hermes Mobile; Hermes também identifica o produto e o
  runtime, independentemente da persona configurável do agente.
- A identidade existente é editorial e tátil, com tipografia serifada, detalhes
  monoespaçados, textura de papel e movimento contido.
- A voz da interface pode acompanhar a persona configurada sem renomear
  conceitos técnicos ou o produto.

## Evidence on Hand

- Referência visual principal em `design/Hermes.dc.html`.
- Contratos medidos e documentação das integrações em `docs/dashboard-api/` e
  `docs/hermes-api/`.
- Backlog, critérios de aceite e decisões correntes em `docs/loop/`.

## Product Principles

- Aproximar a capacidade do desktop sem sacrificar clareza e ergonomia móvel.
- Fazer a ação principal de cada tela dominar a hierarquia.
- Preservar continuidade e dados durante streaming, retomada e falhas de rede.
- Revelar complexidade progressivamente, mantendo funções avançadas acessíveis.
- Tratar segurança e transparência de transporte como parte visível do produto.

## Accessibility & Inclusion

Alvos de toque, texto ampliado, contraste, redução de movimento e semântica de
leitor de tela fazem parte dos critérios de saída das mudanças de interface.
