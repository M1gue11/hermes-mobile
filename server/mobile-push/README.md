# mobile-push

Plugin do Hermes Agent que avisa o Hermes Mobile por push quando:

- um turno termina, falha ou é interrompido (interrupção vem desligada);
- o agente fica esperando você: aprovação de comando, pergunta (`clarify`) ou
  senha de sudo. Quando o pedido é respondido em qualquer lugar, um segundo push
  apaga o aviso no celular.

O push chega com o app fechado. O caminho é UnifiedPush: o app ntfy instalado no
celular é o distribuidor, e o seu servidor ntfy repassa a mensagem.

## O que sai do servidor

Só este envelope:

```json
{"v":1,"id":"…","kind":"turn.completed","session_id":"…","title":"…","ts":1730000000}
```

`kind` é `turn.completed`, `turn.failed`, `turn.interrupted`,
`input.requested` (com `input` = `approval` | `clarify` | `sudo` e
`request_id`) ou `input.resolved`. Prompt, resposta, comando e argumento de
ferramenta nunca entram. O título pode ser desligado (`include_title`).

O envelope vai cifrado (WebPush `aes128gcm`, RFC 8291) com a chave que o
próprio aparelho gerou. O servidor ntfy só vê bytes opacos. Sem
`cryptography`, que já é dependência do Hermes, o envelope iria em JSON puro.

## Instalação

1. Copie esta pasta para `~/.hermes/plugins/mobile-push/` no host do Hermes.
2. `hermes plugins enable mobile-push`
3. Reinicie o gateway e o dashboard (as rotas do dashboard só montam na
   partida).
4. No Hermes Mobile, abra **Ajustes → Notificações** e ative.

Requer Hermes 0.22.5 ou mais novo.

## ntfy self-hosted

O app ntfy registra endpoints UnifiedPush no **servidor padrão** dele. Em
Configurações do app ntfy, aponte o servidor padrão para a sua instância antes
de ativar no Hermes Mobile.

Se a instância usa `auth-default-access: deny-all`, libere escrita anônima nos
tópicos UnifiedPush (o nome deles é aleatório e funciona como segredo):

```sh
ntfy access everyone 'up*' write-only
```

O endpoint precisa ser `https`. `http` só é aceito para host privado: Tailscale
(`100.64.0.0/10`, `*.ts.net`), LAN, `localhost` ou `*.local`.

## Rotas

Montadas pelo dashboard em `/api/plugins/mobile-push/`, atrás do login:

| Método | Caminho | Uso |
| --- | --- | --- |
| `GET` | `/devices` | aparelhos registrados (sem chaves, só o host do endpoint) |
| `PUT` | `/devices/{id}` | registra ou renova `{endpoint, label, p256dh, auth}` |
| `DELETE` | `/devices/{id}` | remove |
| `POST` | `/devices/{id}/test` | manda um push `kind: test` e devolve o status HTTP |

O registro fica em `$HERMES_HOME/mobile-push/devices.json` (modo 600), com no
máximo 8 aparelhos. Um endpoint que responde 404 ou 410 é removido sozinho.

## Configuração

Em `config.yaml`, sob `plugins.entries.mobile-push.settings`, ou na página do
plugin no app desktop:

| Chave | Padrão |
| --- | --- |
| `notify_completed` | `true` |
| `notify_failed` | `true` |
| `notify_interrupted` | `false` |
| `notify_input` | `true` |
| `include_title` | `true` |
| `skip_platforms` | `[cron, subagent]` |

## Testes

```sh
uv run --no-project --with cryptography --with fastapi --with httpx \
  python -m unittest discover -s tests
```

## Créditos

A seleção de eventos (um aviso por `turn_id`, liga/desliga por evento,
plataformas ignoradas) segue o
[hermes-signal-notify](https://github.com/dbrosnan/hermes-signal-notify),
MIT License, Copyright (c) 2026 Drew Brosnan.
