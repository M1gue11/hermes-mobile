---
name: Hermes Mobile
description: Um caderno de operações editorial para conduzir o agente Hermes no Android.
colors:
  paper-deep: "#15120E"
  paper-raised: "#1E1913"
  paper-sheet: "#241E17"
  fiber-line: "rgba(233, 224, 205, 0.11)"
  ink-primary: "#ECE3D2"
  ink-secondary: "#A99F8C"
  ink-tertiary: "#6E655A"
  amber-action: "#D8A24A"
  terracotta-alert: "#C36A44"
  green-success: "#5FBF7F"
  code-deep: "#100D09"
typography:
  display:
    fontFamily: "Newsreader, Georgia, serif"
    fontSize: "27px"
    fontWeight: 500
    lineHeight: 1.25
  body:
    fontFamily: "Newsreader, Georgia, serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.6
  label:
    fontFamily: "JetBrains Mono, monospace"
    fontSize: "10.5px"
    fontWeight: 400
    lineHeight: 1.4
    letterSpacing: "0.05em"
rounded:
  block: "11px"
  card: "14px"
  chip: "20px"
  composer: "22px"
  sheet: "26px"
spacing:
  hairline: "4px"
  compact: "8px"
  control: "12px"
  group: "14px"
  section: "22px"
components:
  button-primary:
    backgroundColor: "{colors.amber-action}"
    textColor: "{colors.paper-deep}"
    rounded: "{rounded.chip}"
    height: "48px"
  chip-default:
    backgroundColor: "{colors.paper-raised}"
    textColor: "{colors.ink-secondary}"
    rounded: "{rounded.chip}"
    padding: "6px 11px"
  card-default:
    backgroundColor: "{colors.paper-raised}"
    textColor: "{colors.ink-primary}"
    rounded: "{rounded.card}"
    padding: "12px 14px"
  input-default:
    backgroundColor: "{colors.paper-raised}"
    textColor: "{colors.ink-primary}"
    rounded: "{rounded.composer}"
    height: "48px"
---

# Design System: Hermes Mobile

## Overview

**Creative North Star: "Caderno de Operações"**

O Hermes Mobile trata trabalho técnico como anotações vivas sobre papel escuro:
serifa para conteúdo e compreensão, monoespaçada somente para estado, medida e
código. A interface é editorial e tátil, mas operacional primeiro. Ela aproxima
a capacidade do desktop sem transportar sua densidade de forma literal para o
telefone.

O acabamento vem de hierarquia tipográfica, linhas discretas e respostas curtas
ao toque. O âmbar não decora a tela: marca ação primária, seleção e trabalho em
curso. Complexidade aparece progressivamente e permanece acessível.

**Key Characteristics:**

- papel quente escuro e tinta marfim, sem preto e branco puros;
- conteúdo em Newsreader e metadados reais em JetBrains Mono;
- superfícies tonais, filetes discretos e pouca elevação;
- densidade compacta dentro de grupos e pausas claras entre contextos;
- movimento contido, com redução de movimento respeitada por construção.

## Colors

A paleta Manuscrito usa neutros quentes e reserva cor para significado.

### Primary

- **Âmbar de Ação:** ação principal, seleção, execução e foco operacional.

### Secondary

- **Terracota de Alerta:** falhas, riscos e estados que pedem recuperação.
- **Verde de Conclusão:** sucesso e disponibilidade confirmados.

### Neutral

- **Papel Profundo, Elevado e Folha:** camadas tonais do fundo ao sheet.
- **Tinta Primária, Secundária e Terciária:** três níveis claros de leitura.
- **Fibra:** bordas e trilhos que devem ser percebidos sem formar caixas fortes.

**The Amber Means Action Rule.** Âmbar aparece apenas onde há ação, seleção ou
atividade viva; repetição sem função dilui a marca.

## Typography

**Display Font:** Newsreader (Georgia, serif)
**Body Font:** Newsreader (Georgia, serif)
**Label/Mono Font:** JetBrains Mono (monospace)

**Character:** a serifa dá voz humana e editorial ao conteúdo; a mono transforma
estado técnico em instrumentação precisa, nunca em fantasia visual.

### Hierarchy

- **Display:** títulos de tela e vazios com a face real de peso 500.
- **Title:** títulos de conversa, seções e decisões em serifa de 15 a 23 px.
- **Body:** mensagens e explicações em 16 px, entrelinha próxima de 1.6.
- **Label:** estados, horários e medidas em 9.5 a 11.5 px, com tracking moderado.

**The Two Voices Rule.** Newsreader explica; JetBrains Mono identifica, mede ou
mostra código. Nenhuma terceira voz tipográfica entra na interface.

## Layout

O app é Android-first e parte de uma coluna única. Conteúdo relacionado se
mantém compacto; mudanças de data, turno ou superfície recebem espaço maior.
Controles principais preservam alvo mínimo de 48 dp, mesmo quando o desenho
visível é menor. Texto ampliado pode empilhar metadados em vez de comprimir o
conteúdo, e regiões densas expandem no lugar sem perder o contexto.

## Elevation & Depth

O sistema é plano por padrão. Profundidade vem de fundos tonais, sobreposição de
sheets e contraste de bordas; não há sombra ornamental nem tintura automática
de elevação do Material 3.

**The Tonal Depth Rule.** Uma superfície só muda de camada quando isso explica
hierarquia, foco ou sobreposição.

## Shapes

Raios são escolhidos pelo papel: 11 px para conteúdo pré-formatado, 14 px para
cartões e linhas tocáveis, 20 px para pastilhas, 22 px para a faixa do composer
e 26 px para o topo de sheets. Círculos ficam restritos a ações e indicadores.

## Components

### Buttons

- **Primary:** âmbar com tinta escura e alvo mínimo de 48 dp.
- **Secondary:** papel elevado, filete Fibra e tinta secundária.
- **Pressed:** escala para 0.966 em 130 ms, sem ripple Material.

### Chips

- **Style:** pastilha de papel elevado, mono curta e borda discreta.
- **State:** seleção aproxima a borda do âmbar; o alvo pode crescer sem alterar
  a pastilha visível.

### Cards / Containers

- **Corner Style:** raio por papel, normalmente cartão ou bloco.
- **Background:** camada tonal; borda apenas quando ajuda a separar contexto.
- **Shadow Strategy:** nenhuma em repouso.

### Inputs / Fields

- **Style:** faixa de papel elevado com serifa e raio de composer.
- **Focus:** âmbar indica intenção sem trocar a linguagem do conteúdo.

### Navigation

A navegação mantém títulos editoriais, ações compactas e feedback tátil. Sheets
usam cabeçalho compartilhado, handle discreto e altura máxima de 82% da tela.

### Timeline Operacional

Trilho, ticks, estados e detalhes formam um sistema único. Ordem e estado devem
ser compreensíveis por ícone e texto, sem depender apenas de cor. Somente o item
vivo recebe movimento contínuo; conclusão troca o símbolo no lugar.

## Do's and Don'ts

### Do:

- **Do** use o âmbar para orientar ação e atividade real.
- **Do** revele argumentos, outputs e controles avançados progressivamente.
- **Do** mantenha conteúdo vivo por padrão quando animações forem reduzidas.
- **Do** preserve o dado bruto no domínio e formate medidas na apresentação.

### Don't:

- **Don't** copie densidade ou interação de desktop sem adaptação ao toque.
- **Don't** use mono para parágrafos ou serifa para código e medidas.
- **Don't** dependa só de cor para comunicar execução, sucesso ou erro.
- **Don't** empilhe cartões quando uma sequência ou trilho explica a relação.
