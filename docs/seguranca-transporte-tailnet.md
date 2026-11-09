# HTTP e WebSocket sem TLS (A92)

Revisão de 2026-11-09 do item 4 de
[security-audit-2026-08-22.md](security-audit-2026-08-22.md). A decisão do usuário
em 2026-11-08 foi aceitar HTTP/HTTPS em qualquer host ou IP nos dois acessos,
com avisos. Ela substitui a antiga exceção somente para `*.ts.net`.

## Política do cliente

| Superfície | Regra |
| --- | --- |
| API Server | HTTP/HTTPS em qualquer host/IP; aceita prefixo de caminho. |
| Dashboard/TUI | HTTP/WS ou HTTPS/WSS em qualquer host/IP; somente origem, sem caminho, userinfo, query ou fragmento. |
| Android | Cleartext permitido na base de `network_security_config.xml`. |
| iOS | `NSAllowsArbitraryLoads` permite HTTP; compilação/aceite em Mac pendentes. |
| mobile-push | Política própria preservada: endpoint HTTPS, ou HTTP em host privado; envelope WebPush cifrado. |

O formulário mostra **Conexão sem TLS** ao digitar HTTP: chave, senha, cookie e
mensagens podem ser lidos no trajeto sem TLS ou túnel. Host público ou não
identificado como privado recebe aviso reforçado. Ajustes e Captura de turno
mantêm o aviso e identificam as conexões HTTP depois do pareamento.

## Um nome de rede não comprova criptografia

A classificação local de IP privado, loopback, faixa Tailscale e nomes locais ou
`*.ts.net` apenas gradua o texto. Ela não faz DNS nem verifica VPN. Um nome
público pode resolver para IP privado; `*.ts.net` pode pertencer a outra tailnet
ou usar Funnel. HTTP continua recebendo aviso em todos esses casos.

WireGuard protege o trajeto entre nós Tailscale quando esse é o caminho usado.
Isso não autentica o processo na porta de destino nem cifra o trecho dentro do
host entre `tailscaled` e Dashboard. ACLs e o acesso aos nós continuam relevantes.

## Controles preservados

- **TLS:** validação de certificado pelo sistema; nenhum `badCertificateCallback`,
  certificado ignorado ou trust store alterada. Permitir HTTP não autoriza um
  certificado HTTPS inválido.
- **Credencial por origem (A81):** segredo vazio só reaproveita o salvo quando
  esquema, host e porta permanecem; mudar a origem exige chave/senha nova.
- **Sem redirect:** os dois clientes HTTP e o handshake WebSocket bloqueiam 3xx.
  Cookie, Bearer e ticket não seguem para outro destino. O adapter de upgrade
  foi conferido no Dart 3.12.2, com testes de sockets reais.
- **Cookie:** enviado em header somente à origem configurada do Dashboard.
- **Host SSH (A91):** fingerprint confirmado e fixado separadamente.
- **Download (A104):** cookie em header de `/api/files/download`, temporário
  privado e seletor nativo; sem token/ticket passado a outro app e sem contornar
  a política de pastas ou os arquivos sensíveis do servidor.

## Limites

O app não configura VPN, HTTPS ou o servidor. A política de Host e origem do
Dashboard permanece: aceitar um IP no formulário não obriga o servidor a
aceitá-lo. HTTP público sem túnel expõe credenciais e conteúdo; avisos não
substituem criptografia. Nenhuma configuração remota foi alterada.
