# Arquitetura de notificações do Hermes Mobile

Este documento explora o Mobile como destino e console de avisos operacionais.
Gatilhos podem residir em agendadores, serviços e scripts configurados pelo
operador; a escolha de transportes e migração depende de cada instalação.

## Fronteira confirmada

```text
cron/systemd/agente
       │ evento operacional normalizado
       ▼
dispatcher + outbox durável
       ├── transporte existente (fallback opcional)
       ├── push Android/iOS
       └── inbox autenticado do Hermes Mobile
```

O Dashboard/TUI Gateway oferece sinais **live** autenticados por sessão e ticket
WebSocket, incluindo `notification.show`, `notification.clear` e
`background.complete`. Eles servem para apresentação in-app enquanto há conexão.
Não garantem entrega em background, app encerrado, offline ou reinstalado.

O `delivery_ledger` do Hermes registra tentativas de respostas finais do agente
para plataformas. Ele não é uma fila genérica para eventos operacionais ou
dispositivos Mobile.

## Camada complementar necessária

| Componente | Responsabilidade |
| --- | --- |
| Envelope de evento | `event_id`, `dedupe_key`, origem, categoria, severidade, título, resumo seguro, criação, TTL, política e deep link. |
| Dispatcher | Receber eventos dos scripts sem envio direto exclusivo ao Telegram. |
| Outbox transacional | Persistir antes da entrega; controlar tentativas, expiração, deduplicação, destino e resultado. JSONL pode permanecer como auditoria. |
| Inbox autenticado | Recuperar eventos depois de perda de push/rede; leitura e acknowledgement não apagam a auditoria. |
| Registro de dispositivos | Vincular e revogar tokens push após pareamento autenticado. |
| Push/notificação local | Entregar em Android/iOS em foreground, background ou app encerrado. |
| Preferências e regras | Categoria, prioridade, quiet hours e digest; regras propostas pelo agente exigem confirmação explícita. |
| Adaptador de transporte existente | Fallback reversível durante a migração, sem mudar produtores. |

## Limites de segurança e privacidade

- O agente só pode **propor** regra; o usuário confirma origem, condição, horário,
  prioridade, destino, expiração e quiet hours.
- Push em tela bloqueada carrega apenas título e resumo mínimos. O detalhe vive no
  inbox autenticado.
- Nunca incluir prompts, cookies, tickets WebSocket, segredos, argumentos de
  tools ou logs brutos em push, inbox, teste ou documentação.
- A escolha de FCM, APNs ou outro relay é uma decisão explícita. Tailnet/WebSocket
  isoladamente não prometem entrega confiável com o app encerrado.
- `notification.clear` deve cancelar pela chave de modo idempotente.

## Sequência de implementação

1. Diagnosticar a saúde dos produtores: transporte não corrige evento que não foi
   produzido.
2. Normalizar eventos operacionais no dispatcher neutro.
3. Implementar outbox e inbox antes de prometer push.
4. Registrar dispositivos e validar foreground, background, app encerrado e
   offline.
5. Entregar Mobile e transporte existente em paralelo usando `event_id` e `dedupe_key`.
6. Migrar categorias de evento somente após validação real; rollback reativa
   apenas o adaptador existente.

## Decisão de 2026-11-08

```text
on_session_end / on_human_input_*  (hooks do Hermes)
       │ envelope mínimo {v, id, kind, session_id, title?, input?, request_id?}
       ▼
plugin server/mobile-push ── WebPush aes128gcm com a chave do aparelho
       │ POST no endpoint UnifiedPush
       ▼
ntfy self-hosted ──► app ntfy (distribuidor) ──► Hermes Mobile
                                                  ├ app aberto: PushController
                                                  └ app fechado: main --unifiedpush-bg
```

- Transporte: UnifiedPush, com o app ntfy como distribuidor. Sem Firebase. O
  iOS fica de fora: UnifiedPush não existe lá.
- Registro de dispositivos: `PUT/DELETE /api/plugins/mobile-push/devices/{id}`,
  atrás do login do Dashboard. O id é aleatório e gerado no aparelho; endpoint
  e chaves ficam no armazenamento seguro. Um endpoint que responde 404/410 sai
  do registro sozinho.
- Privacidade: o envelope nunca leva prompt, resposta, comando ou argumento. O
  título da conversa é opcional (`include_title`). A notificação usa
  visibilidade privada na tela bloqueada.
- Dedupe: o id do aviso no Android vem do *slot* (`turn:<sessão>`,
  `input:<pedido>`), com hash estável entre o app aberto e o isolate de
  background. O `input.resolved` apaga o aviso do mesmo pedido.
- Ainda **não** existe outbox durável nem inbox: o plugin tenta duas vezes, e
  quem ficou offline perde o aviso. O cache do ntfy (12 h por padrão) cobre
  quedas curtas do aparelho. Inbox e regras propostas pelo agente continuam
  como fase posterior.

## Escopo do repositório

A primeira fase do cliente deve traduzir sinais live permitidos em modelos de
domínio seguros, sem alegar durabilidade. Serviço externo, infraestrutura de push
ou extensão do Gateway exigem decisão explícita do usuário. A direção é manter o
núcleo Hermes responsável por chat, sessões e sinais live; a entrega operacional
durável vive em serviço complementar ou plugin autenticado.
