# Ciclo de vida do gateway, medido em `0.20.0`

Medição do comportamento observado no Gateway Hermes `0.20.0`, para responder:
**é possível detectar reinício ou inicialização do gateway?**

Sim, e mais barato do que se supunha. Nenhum valor real de cookie, ticket ou
credencial aparece aqui, e nenhum foi necessário para medir.

## O diagnóstico que a medição derrubou

O item A40 nasceu escrito assim: `GET /health` devolve só `{"status":"ok"}`, sem
versão nem instante de boot, logo o único sinal possível seria a transição de
fora do ar para no ar por sondagem, e o sinal bom dependeria do `WS /api/ws`, que
por sua vez depende da senha do Dashboard.

As duas metades estavam erradas.

## `GET /hermes/health`, sem autenticação

```json
{"status": "ok", "platform": "hermes-agent", "version": "0.20.0"}
```

O modelo `HealthStatus` do app lê apenas `status` e descarta o resto. Já dá para
detectar **atualização de versão**, mas não reinício: uma reinstalação da mesma
versão não muda nada aqui.

## `GET /api/status` do Dashboard, também sem sessão

Responde `200` sem cookie. É este o documento que serve ao A40. Campos medidos,
com o tipo e o valor observado no runtime parado e saudável:

| Campo | Tipo | Valor medido | Serve para |
| --- | --- | --- | --- |
| `gateway_updated_at` | str ISO-8601 | `2026-08-08T22:52:01...+00:00` | **o detector de reinício** |
| `gateway_state` | str | `running` | o estado em si |
| `gateway_running` | bool | `true` | atalho do estado |
| `gateway_exit_reason` | str ou null | `null` | por que caiu, quando caiu |
| `gateway_mode` | str | `single` | modo de execução |
| `gateway_busy` | bool | `false` | há trabalho em curso |
| `gateway_drainable` | bool | `true` | pode drenar antes de parar |
| `restart_drain_timeout` | float | - | janela de drenagem |
| `active_agents` | int | `0` | agentes em execução |
| `active_sessions` | int | `1` | sessões vivas |
| `version` | str | `0.20.0` | atualização de versão |
| `release_date` | str | `2026.8.3` | idem |
| `overall` | str | `ok` | saúde agregada |
| `components` | dict | ver abaixo | saúde por parte |
| `gateway_platforms` | dict | `api_server`, `telegram` | plataformas ligadas |

`components` tem as chaves `dashboard`, `gateway`, `platforms` e `storage`, e
cada uma traz:

```json
{"status": "ok", "recent_unhandled_errors": 0, "last_error_at": null, "selftest": "unknown"}
```

## Por que `gateway_updated_at` é o campo certo

Duas leituras a 4 segundos de distância devolveram **o mesmo** valor. Ou seja,
não é "agora": é o instante da última transição de estado do gateway. Um cliente
que guarda o último valor visto detecta reinício comparando, sem precisar
flagrar a queda entre duas sondagens, que era a limitação do diagnóstico velho.

Combinando os campos dá para distinguir os casos que interessam:

| O que aconteceu | Como se lê |
| --- | --- |
| subiu agora | `gateway_updated_at` mudou e `gateway_running` virou `true` |
| caiu | `gateway_running` virou `false`, com `gateway_exit_reason` dizendo por quê |
| reiniciou entre duas sondagens | `gateway_updated_at` mudou, `gateway_running` continua `true` |
| foi atualizado | `version` ou `release_date` mudou |
| degradou sem cair | `overall` ou algum `components[*].status` saiu de `ok` |

## O que isto muda no A40

- **Não depende da senha do Dashboard**, nem do `WS /api/ws`, nem da trilha B.
  Uma sondagem simples do endpoint de status configurado pode resolver.
- Use o endpoint Dashboard configurado para a instalação e respeite as validações
  de Host e origem definidas pelo servidor.
- O que a medição **não** responde é entrega com o app fechado. Sondar só
  resolve enquanto o app está em execução; notificação com o app morto continua
  sendo serviço em primeiro plano ou push, e continua sendo decisão do usuário.

## Como reproduzir

```sh
curl -s https://<servidor-configurado>/hermes/health
curl -s https://<servidor-configurado>/api/status
```
