# Auditoria de segurança do Hermes Mobile

> [!warning] Registro histórico, não certificação de release
> Os achados abaixo refletem a revisão realizada na data indicada, não o estado
> atual do código ou do histórico Git. Antes de abrir o repositório ou distribuir
> APKs, revalidar cada correção, executar nova varredura de segredos em **todo o
> histórico** e seguir as pendências em [preparação pública](open-source/01-personalization-audit.md).

Data: 22 de agosto de 2026  
Escopo: aplicativo Flutter deste repositório. A configuração efetiva do servidor, firewall e painel administrativo do Tailscale não foi auditada.

## Resumo executivo

O aplicativo está razoavelmente protegido para uso pessoal via Tailscale. Não foram encontradas vulnerabilidades críticas nem credenciais reais expostas no código ou no histórico do Git.

Foram encontrados quatro pontos de prioridade média ou média/baixa:

1. imagens remotas em respostas Markdown são carregadas automaticamente;
2. o build Android de release ainda usa a chave de debug;
3. a primeira chave de host SSH é aceita silenciosamente;
4. HTTP e WebSocket sem TLS são permitidos para qualquer subdomínio `*.ts.net`.

A ordem recomendada de correção é:

1. bloquear o carregamento automático de imagens remotas;
2. tornar o Dashboard estritamente HTTPS/WSS;
3. exigir confirmação da fingerprint no primeiro acesso SSH;
4. configurar assinatura Android de release;
5. endurecer e padronizar o armazenamento seguro.

## Achados prioritários

### 1. Imagens remotas carregadas automaticamente

Prioridade: média.

O renderizador Markdown transforma imagens remotas diretamente em `Image.network`, sem consentimento do usuário:

- `lib/features/chat/widgets/hermes_markdown.dart:271`
- `lib/features/chat/widgets/hermes_markdown.dart:1002`

Uma resposta influenciada por prompt injection ou conteúdo externo pode inserir uma URL de imagem que será requisitada automaticamente pelo celular. Isso pode ser usado para:

- tracking por URL individualizada;
- exposição do endereço IP e de metadados básicos da conexão;
- requisições a serviços HTTPS internos ou acessíveis pela Tailnet;
- acionamento de endpoints que incorretamente realizem ações por `GET`.

O aplicativo não envia automaticamente a chave do Hermes para a URL da imagem, mas a requisição parte de um dispositivo com acesso à Tailnet.

Recomendação:

- mostrar inicialmente um placeholder com a ação “Carregar imagem”;
- exigir um gesto explícito do usuário;
- aceitar somente HTTPS;
- bloquear loopback, endereços privados e `*.ts.net` por padrão;
- usar allowlist explícita quando imagens internas forem necessárias;
- para uma proteção mais forte, carregar imagens por um proxy com política de egress e limites de tamanho.

### 2. Build Android de release assinado com chave de debug

Prioridade: média; alta antes de qualquer distribuição.

O build `release` ainda usa a configuração de assinatura de debug:

- `android/app/build.gradle.kts:28-32`

O aplicativo também mantém o identificador padrão `com.example.hermes_mobile`:

- `android/app/build.gradle.kts:18-19`

Para instalação manual no aparelho do desenvolvedor, o risco imediato é limitado. Para distribuição, CI ou compartilhamento do APK, a chave de debug não fornece uma identidade de release adequada e aumenta o risco de atualização maliciosa caso ela seja obtida.

Recomendação:

- definir um `applicationId` próprio;
- gerar uma keystore exclusiva de release;
- manter keystore e senhas fora do Git;
- carregar as credenciais por propriedades locais ou secrets do CI;
- guardar backup seguro da chave, pois futuras atualizações precisam ser assinadas pela mesma identidade.

### 3. TOFU silencioso na primeira conexão SSH

Prioridade: média.

Quando ainda não existe fingerprint fixada, o callback aceita automaticamente a primeira chave recebida. A fingerprint só é salva depois que a sessão sobe:

- `lib/features/machine/machine_session.dart:180-224`

Mudanças posteriores são corretamente recusadas. Entretanto, no primeiro acesso, uma máquina incorreta ou um redirecionamento de nome pode ser aceito sem confirmação. A chave privada não é transmitida, mas o usuário pode acabar interagindo com um terminal pertencente a outro host.

Recomendação:

- interromper a primeira conexão antes de abrir o shell;
- mostrar fingerprint, algoritmo, hostname e porta;
- exigir confirmação explícita;
- orientar a comparação fora de banda, por exemplo com:

```sh
ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
```

- manter o bloqueio atual quando a fingerprint mudar.

### 4. HTTP e WebSocket sem TLS para qualquer `*.ts.net`

Prioridade: média/baixa no cenário atual.

O Dashboard aceita HTTP quando o host termina em `.ts.net`:

- `lib/data/gateway/dashboard_gateway_repository.dart:674-695`

O Android e o iOS permitem tráfego sem TLS para `ts.net` e todos os seus subdomínios:

- `android/app/src/main/res/xml/network_security_config.xml:2-5`
- `ios/Runner/Info.plist:29-40`

O Tailscale cifra o tráfego entre os nós usando WireGuard, portanto isso não equivale a enviar as credenciais abertamente pela rede Wi-Fi. Ainda assim, HTTPS adiciona autenticação do serviço e proteção contra downgrade, erros de configuração e outras falhas dentro do host ou da Tailnet.

Os endereços padrão já usam HTTPS, então a opção mais segura é remover o suporte a HTTP/WS.

Recomendação:

- aceitar somente HTTPS e WSS em builds normais;
- remover as exceções cleartext de Android e iOS;
- desabilitar redirects automáticos em chamadas autenticadas ou validar esquema e host de cada redirect;
- se HTTP for indispensável durante desenvolvimento, restringi-lo a build debug e ao FQDN exato, nunca a todo `*.ts.net`.

Referências:

- [Tailscale: Enabling HTTPS](https://tailscale.com/docs/how-to/set-up-https-certificates)
- [Android: Network security configuration](https://developer.android.com/privacy-and-security/security-config)

## Hardening recomendado

### Padronizar o armazenamento seguro no iOS

Apenas o armazenamento do Dashboard configura explicitamente `KeychainAccessibility.unlocked_this_device`:

- `lib/data/config/dashboard_session_store.dart:21-27`

A chave da API, a chave privada SSH e outros valores usam as opções padrão:

- `lib/data/config/connection_store.dart:13`
- `lib/data/config/ssh_store.dart:28`
- `lib/data/config/active_run_store.dart:76`
- `lib/data/config/app_settings_store.dart:24`
- `lib/data/config/last_conversation_store.dart:25`

Recomendação:

- centralizar uma configuração de armazenamento seguro;
- usar `unlocked_this_device` para credenciais e chave SSH;
- considerar Secure Enclave com presença do usuário para a chave SSH e a chave da API;
- planejar migração dos itens existentes antes de mudar as opções, para evitar perda de acesso aos valores já gravados.

Referência:

- [flutter_secure_storage: configuração e proteção biométrica](https://github.com/juliansteenbakker/flutter_secure_storage/blob/develop/flutter_secure_storage/README.md)

### Evitar persistência permanente da senha do Dashboard

A senha é armazenada para permitir relogin automático:

- `lib/data/config/dashboard_session_store.dart:68-93`

Embora esteja no armazenamento seguro, manter a senha aumenta o impacto de uma eventual extração do dispositivo. O desenho preferível é o servidor emitir um refresh token revogável, com escopo e validade limitados. Se a senha continuar sendo persistida, ela deve ser exclusiva para esse serviço.

### Endurecer deep links

O esquema `hermes://app/chat/...` é exposto por uma Activity exportada:

- `android/app/src/main/AndroidManifest.xml:13`
- `android/app/src/main/AndroidManifest.xml:32-40`

Atualmente o deep link apenas abre uma conversa existente e não aprova ferramentas ou envia mensagens, por isso o risco é baixo.

Antes de adicionar ações mais poderosas:

- migrar para Android App Links e iOS Universal Links verificados;
- não confiar em `title`, `model` ou `provider` vindos de links externos;
- exigir desbloqueio local antes de exibir conteúdo sensível, caso o modelo de ameaça inclua acesso físico ao aparelho.

### Remover identificadores pessoais do código publicado

Os hostnames padrão da Tailnet estão no código:

- `lib/core/config/hermes_connection.dart:8`
- `lib/data/gateway/dashboard_gateway_repository.dart:53`

Eles não são credenciais, mas revelam nomes de máquina e da Tailnet caso o repositório ou APK sejam publicados. Podem ser movidos para configuração de build ou deixados vazios em builds distribuídos.

### Diagnóstico em builds debug

A captura de turno existe somente em debug e não inclui valores textuais por padrão. Há, porém, uma opção explícita para incluir amostras de 80 caracteres:

- `lib/core/diagnostics/turn_capture.dart:92-108`
- `lib/core/diagnostics/turn_capture.dart:479-495`

A redação depende do nome do campo. Um segredo presente dentro de um campo genérico de texto pode aparecer na amostra. Tratar relatórios gerados com amostras como dados sensíveis e revisar antes de colar em issues, chats ou documentação.

## Controles positivos encontrados

- A API principal exige URL HTTPS: `lib/core/config/hermes_connection.dart:13-21`.
- A chave da API, cookies, senha e chave SSH são armazenados por `flutter_secure_storage`.
- Backup do aplicativo Android está desativado: `android/app/src/main/AndroidManifest.xml:6`.
- Uma mudança posterior da chave de host SSH é recusada.
- Links externos aceitam somente HTTP, HTTPS ou `mailto` e exigem confirmação: `lib/features/chat/widgets/hermes_markdown.dart:908-953`.
- Erros de rede são convertidos para objetos públicos sem reutilizar headers ou request options que contenham a chave.
- Aprovações de ferramentas preservam o menor escopo disponível e não transformam uma aprovação em autorização global.
- O relatório de diagnóstico fica restrito a builds debug e não inclui texto por padrão.
- Arquivos anexados possuem limite móvel de 25 MB.

## Verificações executadas

### Análise estática

```text
flutter analyze --no-pub
No issues found! (ran in 60.8s)
```

### Testes

```text
flutter test --no-pub
00:22 +625: All tests passed!
```

### Busca de segredos

Foi feita uma busca por padrões comuns de credenciais e chaves privadas no estado atual e no histórico do Git.

Resultado:

- nenhuma credencial real encontrada;
- os únicos matches foram strings deliberadas em testes de redação e uma chave SSH gerada durante teste;
- nenhum arquivo `.env`, PEM, keystore, certificado privado ou arquivo de credenciais está rastreado.

Essa busca foi baseada em padrões conhecidos e não substitui uma varredura recorrente com ferramenta como Gitleaks ou TruffleHog no CI.

### Dependências

Versões relevantes resolvidas no lockfile:

- `dio 5.10.0`;
- `dartssh2 2.22.5`;
- `flutter_secure_storage 10.3.1`;
- `record 7.1.1`;
- `file_selector 1.1.0`.

Não foram encontrados alertas públicos óbvios aplicáveis a essas versões durante a revisão. Não havia scanner OSV/SCA instalado no ambiente, portanto recomenda-se adicionar uma verificação automatizada de advisories ao CI.

## Checklist da infraestrutura Tailscale

Esses itens não puderam ser comprovados pelo repositório e devem ser verificados no painel e no servidor:

- confirmar que Tailscale Funnel está desativado;
- usar Tailscale Serve ou acesso direto da Tailnet, não exposição pública;
- substituir a política inicial permissiva por Grants de privilégio mínimo;
- permitir apenas o celular necessário como origem;
- permitir apenas o servidor e as portas efetivamente usadas, por exemplo HTTPS do Hermes, HTTPS do Dashboard e SSH;
- habilitar MFA no provedor de identidade;
- habilitar aprovação de dispositivos ou Tailnet Lock, observando que os dois recursos são mutuamente exclusivos;
- revisar e remover dispositivos antigos;
- manter clientes Tailscale atualizados e configurar expiração adequada das chaves;
- confirmar que os serviços não estão expostos por interface pública, LAN ou redirecionamento de porta;
- usar chaves e senhas exclusivas para o Hermes e rotacioná-las se houver suspeita de comprometimento.

Referências:

- [Tailscale: Best practices to secure your tailnet](https://tailscale.com/docs/reference/best-practices/security)
- [Tailscale: Grants e ACLs](https://tailscale.com/docs/features/access-control/acls)
- [Tailscale Funnel](https://tailscale.com/docs/features/tailscale-funnel)
- [Tailscale Tailnet Lock](https://tailscale.com/docs/features/tailnet-lock)

## Conclusão

No cenário atual — um único aparelho, API autenticada, HTTPS como padrão e acesso pela Tailnet — não há evidência de comprometimento imediato. O maior risco prático dentro do aplicativo é conteúdo produzido pelo agente causar requisições automáticas por meio de imagens Markdown. Os demais achados são principalmente defesa em profundidade e se tornam mais importantes caso o APK seja distribuído, outros dispositivos entrem na Tailnet ou o servidor passe a atender mais usuários.
