---
name: hermes-app-dev
description: Guia de desenvolvimento do app Flutter hermes_mobile (Dart), organizado em camadas domain/data/features, Riverpod para estado e injeção, Freezed para modelos e APIs Hermes. Use ao adicionar funcionalidades, telas, modelos, chamadas de API ou animações; ao decidir onde arquivos devem morar; ou ao revisar arquitetura Flutter.
user_invocable: true
---

# Skill: hermes-app-dev

Playbook único para desenvolver o app Flutter `hermes_mobile`. Todo código novo segue isto; código fora do padrão deve ser refatorado.

## O que é o projeto

App mobile (Android + iOS) que é um cliente do agente Hermes. A API Server,
documentada em `docs/hermes-api/`, e o Dashboard/Gateway TUI são superfícies
distintas, com autenticação própria. O chat ao vivo usa o TUI Gateway quando
disponível; Runs/SSE é fallback de capacidade menor, conforme o contrato em
`docs/dashboard-api/`.

> **Design:** `design/Hermes.dc.html`, quando presente, é uma referência visual.
> Consulte-a para hierarquia e tokens, sem copiar código para Flutter.

> **Nota histórica:** a pasta `docs/` chegou a ter ARCHITECTURE/CONVENTIONS/ADRs/recipes
> herdados de um template React/monorepo (Vite/Expo/TanStack/Zod) - foram removidos por
> não se aplicarem ao Flutter. Os princípios relevantes já estão traduzidos abaixo e no
> restante desta skill. `docs/` hoje só contém `hermes-api/` (a doc real do backend).

## Stack

| Papel | Ferramenta | Análogo React dos docs |
|---|---|---|
| Estado + injeção de dependência | Riverpod (codegen: `riverpod_generator`) | TanStack Query + Zustand + DI |
| HTTP e streaming SSE | `dio` | fetch wrapper |
| Models imutáveis (fromJson/copyWith/==) | `freezed` + `json_serializable` | Zod + tipos derivados |
| Rotas / deep links | `go_router` | TanStack Router |
| Fontes (Newsreader, JetBrains Mono) | `google_fonts` | @font-face |
| Codegen | `build_runner` | tsc/codegen |
| Testes | `flutter_test` | Vitest |

## Arquitetura: dependências só apontam para baixo

```
lib/features/<feature>/   Widgets (só layout) + controller Riverpod   ← presentation
        │
        ▼
lib/domain/repositories/  abstract interface class (o "port")          ← contrato
        ▲                                                                (data implementa)
        │  implementado por
lib/data/                 impl HTTP (dio+SSE) e impl Mock               ← dados
        │
        ▼
lib/domain/models/        classes freezed, Dart puro                    ← domínio
```

- `lib/core/`: infra transversal: `theme/` (tokens em ThemeData), `network/` (cliente
  Hermes), `router/`, `config`.
- **Regra de ouro:** `lib/domain/` é Dart PURO: proibido `import 'package:flutter/...'`.
  Isso o mantém testável e independente de UI (o `@repo/core` dos docs).

## Convenções (traduzidas dos docs para Flutter/Dart)

- **Widgets são apresentacionais:** recebem dados e emitem callbacks. Sem lógica de
  negócio, sem chamada de API dentro do widget. Lógica mora no controller Riverpod.
- **Evite `StatefulWidget`.** O estado mora em providers Riverpod; a tela é
  `ConsumerWidget` e lê o estado com `ref.watch(...)`. `StatefulWidget` só para estado
  puramente de UI efêmero (ex.: controller de `TextField`, animação local).
- **Models sempre com freezed.** Nunca escreva `fromJson`/`copyWith`/`==` à mão.
- **Nomes:** arquivos `snake_case.dart`; um recurso de domínio no singular
  (`run.dart`, não `runs.dart`). Teste ao lado: `run.dart` → `run_test.dart`.
- **Acesso ao servidor só via repositório.** Nada de `dio`/`http` dentro de widget ou
  controller: passa pelo `HermesRepository`.
- **Sem cores/tamanhos hard-coded na UI.** Use os tokens do design via
  `HermesTokens.of(context)` (accent, ink, dim, faint, serif, mono... em
  `core/theme/hermes_tokens.dart`) e `Theme.of(context)` para o Material. O app é
  dark-only; as atmosferas (Manuscrito/Jornal/Técnico) substituem light/dark.
- **Sem travessão U+2014** em arquivos: o lint local (Crashacter) trata como erro.
  Use `:` ou `-`.
- **Commits:** conventional commits (`feat:`, `fix:`, `refactor:`, `docs:`, `chore:`).

## Receita: adicionar uma feature (domain → data → UI)

Sempre nesta ordem (domínio -> dados -> UI):

1. **Modele o domínio**: `lib/domain/models/<x>.dart` com `@freezed`. Regras puras
   como métodos/funções, com `<x>_test.dart`.
2. **Defina o port** (se novo): `lib/domain/repositories/<x>_repository.dart`:
   `abstract interface class XRepository`.
3. **Implemente os adapters** em `lib/data/`: primeiro um **mock** (`MockX...`) que
   funciona sem servidor, depois o real (dio/SSE). Ambos cumprem o mesmo port.
4. **Exponha via Riverpod**: um provider retorna o repositório (a costura de DI). A UI
   consome via `ref.watch`. Troque mock↔real com `override` no `ProviderScope` em
   `main.dart`, a "composition root".
5. **Construa a UI**: `lib/features/<x>/<x>_screen.dart` (ConsumerWidget) +
   `<x>_controller.dart` (Notifier). Adicione a rota em `core/router/app_router.dart`.

**Construa sempre contra o mock primeiro**, depois vire para HTTP por override. Isso é
o coração da inversão de dependência: a UI nunca sabe se está falando com mock ou rede.

## Fluxo da Runs API (o alvo do app)

1. `POST /v1/runs` `{input, session_id, instructions}` → `{run_id, status}`.
2. Guardar `run_id` no estado da conversa.
3. Abrir SSE `GET /v1/runs/{run_id}/events` (com header `Authorization`; num app nativo
   NÃO há a limitação de EventSource do browser). Renderizar eventos incrementais.
4. Em reconexão/reload: `GET /v1/runs/{run_id}` para reconciliar estado.
5. Cancelar: `POST /v1/runs/{run_id}/stop` → estado `stopping` → `cancelled`/`completed`.
6. Boot do app: `GET /health` (online?) e `GET /v1/capabilities` (mostrar botão cancelar,
   approval etc.). Detalhes em `docs/hermes-api/04-runs-streaming.md` e `03-openai-compatible.md`.

**Regra de UX (dos docs):** texto final do assistant é separado da timeline de progresso
de ferramentas. Não persista `tool.progress` como mensagem do assistant.

## Fluxo de trabalho com codegen

Freezed e Riverpod geram código. Ao criar/editar um model ou provider anotado, rode:

```
dart run build_runner watch -d
```

Deixe rodando em segundo plano: regenera os arquivos `.g.dart`/`.freezed.dart` a cada
save. (Para uma geração única: `dart run build_runner build -d`.) Os arquivos gerados
não são editados à mão e podem entrar no `.gitignore` ou não, conforme a decisão do projeto.

## Antes de dar por pronto

- `flutter analyze` sem erros.
- `flutter test` passando (adicione/atualize testes de domínio e de widget).
- Se mexeu em runtime visível, veja rodando no emulador (hot reload: salvar = atualiza).

## Skills relacionadas neste repo

- **flutter-animations**: animações (rico neste app): sistema nativo (implícitas,
  explícitas, Hero, staggered, física, curves) + pacote `flutter_animate` (efeitos
  declarativos `.animate()`, a camada preferida para polish). Consulte ao animar
  qualquer coisa. `flutter_animate` já está no `pubspec.yaml`.
- **flutter-adaptive-ui**: layout responsivo (telefone/tablet, retrato/paisagem,
  constraints). Escopo atual é mobile, então use o núcleo (widgets pequenos `const`,
  breakpoints, `MediaQuery.sizeOf`/`LayoutBuilder`), não as partes de desktop/web.

## Orientações de integração

O app integra-se ao Hermes API Server e ao Dashboard/Gateway TUI. As APIs REST,
Runs/SSE e o WebSocket do TUI têm contratos e autenticação distintos. Consulte
`docs/hermes-api/` e `docs/dashboard-api/` antes de alterar transporte, eventos
ou métodos permitidos; não infira suporte a partir de um snapshot antigo.

Segredos e dados de sessão não devem ser registrados em logs, testes, screenshots
ou documentação. Use placeholders e fixtures neutras em exemplos.

O pareamento seleciona repositórios reais via overrides no bootstrap; fakes de
teste não devem substituir essa composição em runtime. Retomada de turnos deve
preservar a timeline mais completa e nunca reenviar automaticamente prompts ou
respostas interativas. Dados internos de execução não viram fala do usuário;
envelopes de anexos não viram bolhas de conteúdo inferido. Siga os invariantes em
`docs/loop/HANDOFF.md` e os contratos do gateway antes de mudar esses fluxos.

## Fluxo de trabalho

Acompanhe os itens de desenvolvimento registrados em `docs/loop/BACKLOG.md`.
Antes de concluir mudanças, execute `flutter analyze` e `flutter test`; para
alterações visuais, valide os estados relevantes em emulador ou dispositivo.
