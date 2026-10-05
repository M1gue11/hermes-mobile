# WebSockets fora do OpenAPI

Os WebSockets abaixo não aparecem no snapshot REST OpenAPI. O Mobile não deve inferir seus contratos. A exceção documentada é o gateway TUI `/api/ws`: seu inventário extraído do código está em [`tui-gateway-json-rpc.md`](tui-gateway-json-rpc.md) e ele é a superfície de live chat do Mobile.

| Endpoint | Finalidade conhecida | Decisão mobile |
| --- | --- | --- |
| `WS /api/console` | Console estruturado de comandos. | Não integrar neste momento. |
| `WS /api/pty` | Terminal PTY. | Não integrar. |
| `WS /api/ws` | Gateway JSON-RPC do Chat do Dashboard. | Integrar pela allowlist e pelos limites de estabilidade de [`tui-gateway-json-rpc.md`](tui-gateway-json-rpc.md), não por inferência. |
| `WS /api/pub` | Broadcast interno da aba Chat; exige `channel`. | Não integrar. |
| `WS /api/events` | Broadcast interno da aba Chat; exige `channel`. | Não integrar. |

Em modo autenticado, o primeiro passo é ter a sessão por cookie e então chamar `POST /api/auth/ws-ticket`. O ticket é de uso único. Falhas de autenticação, host ou origin não devem ser contornadas pelo app. Não registrar, persistir ou exemplificar tickets. Para `/api/ws`, use um objeto JSON por frame de texto e aguarde `gateway.ready`; detalhes em [`tui-gateway-json-rpc.md`](tui-gateway-json-rpc.md).
