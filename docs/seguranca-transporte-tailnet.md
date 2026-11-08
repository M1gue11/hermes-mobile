# HTTP e WebSocket sem TLS em `*.ts.net` (A92)

Revisão de 2026-11-08 do item 4 de
[security-audit-2026-08-22.md](security-audit-2026-08-22.md). Este documento
descreve a exceção, o que ela expõe e o que já a limita. Remover a exceção é uma
decisão do usuário, porque a instalação atual usa o Dashboard em
`http://<host>.ts.net:9119`.

## O que existe hoje

| Superfície | Regra |
| --- | --- |
| API Server (`/v1/*`) | Só HTTPS (`HermesConnection.validate`). |
| Dashboard e WebSocket do TUI | HTTPS, ou HTTP/WS se o host termina em `.ts.net` (`DashboardGatewayRepository._normalizeBaseUrl`). |
| Android | `network_security_config.xml` libera texto em claro para `ts.net` e todos os subdomínios. |
| iOS | `Info.plist` libera `NSExceptionAllowsInsecureHTTPLoads` para `ts.net` com subdomínios. |
| Plugin `mobile-push` | Endpoint HTTPS, ou HTTP em host privado (Tailscale, LAN, `localhost`). O conteúdo vai cifrado com WebPush de qualquer forma. |

## O que a criptografia do Tailscale cobre, e o que não cobre

O WireGuard cifra o tráfego **entre dois nós da tailnet**. Um `http://` para
um nome MagicDNS que resolve para um IP `100.x` atravessa esse túnel, e quem
está na Wi-Fi do café não lê a senha nem o cookie. Isso não equivale a TLS do
servidor:

1. **A exceção é por nome, não por caminho.** `*.ts.net` inclui nomes de
   **qualquer** tailnet, inclusive máquinas compartilhadas por terceiros e
   endpoints públicos do Tailscale Funnel. Um nome `ts.net` que resolve pelo DNS
   público (Funnel) chega pela internet aberta, fora do WireGuard. O app aceita
   HTTP para ele do mesmo jeito.
2. **Não autentica o serviço.** O WireGuard prova que o pacote veio do nó X;
   não prova que quem responde na porta 9119 é o Dashboard. Um processo local
   no host, ou outro serviço que ocupe a porta, recebe as credenciais.
3. **O trecho dentro do host é em claro.** Do `tailscaled` até o processo do
   Dashboard, a senha e o cookie trafegam sem proteção.
4. **Depende da política da tailnet.** ACLs permissivas, chave de nó vazada ou
   nó compartilhado ampliam quem consegue falar com o host.

## Controles que já limitam o risco

- **Credencial presa à origem (A81):** chave e senha salvas só são
  reaproveitadas no mesmo esquema, host e porta; trocar o host exige digitar
  de novo.
- **Sem redirect em chamada autenticada (A92):** os dois clientes HTTP não
  seguem 3xx. Um redirect para outro host não leva a chave Bearer nem o cookie.
  As rotas `/api/` do Dashboard nunca redirecionam (respondem 401 JSON) e o
  `password-login` responde JSON, então nada depende disso.
- **Cookie por origem:** o cookie da sessão só é enviado para a `baseUrl` em
  que foi obtido.
- **Chave de host SSH fixada e confirmada (A91):** a sessão Máquina não aceita
  em silêncio uma máquina nova nem uma chave trocada.
- **Push cifrado ponta a ponta:** o envelope do `mobile-push` vai em WebPush
  `aes128gcm`; HTTP no ntfy não expõe o conteúdo.

## Recomendação (decisão pendente do usuário)

1. Servir o Dashboard em HTTPS pela própria tailnet:
   `tailscale serve --bg --https=443 http://localhost:9119` (o certificado do
   `*.ts.net` é emitido e renovado pelo Tailscale). Isso exige HTTPS habilitado
   no painel da tailnet.
2. Atualizar a conexão no app para `https://<host>.ts.net`.
3. Depois disso, trocar a exceção de `ts.net` pelo FQDN exato do host em build
   debug e removê-la do release, no Android e no iOS, e aceitar só HTTPS/WSS no
   `_normalizeBaseUrl`.

Os passos 1 e 2 mudam o servidor e a configuração do usuário; o passo 3 sem os
anteriores derruba o acesso ao Dashboard. Por isso o loop não aplica nenhum
deles sozinho.
