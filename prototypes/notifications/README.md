# Envelope e inbox/outbox offline (protótipo isolado)

**Transporte REAL AUSENTE.** Python stdlib e SQLite apenas; sem HTTP, serviço,
plugin, daemon, scheduler, regra ativa, credencial, token ou integração Telegram.
Não altera a fatia A60 Flutter. **WIP, revisão concluída com P2 bloqueante da CLI**;
15 testes unittest e py_compile passaram (exit 0), mas Claudia reproduziu falha
por injeção antes de criar schema: arquivo novo fica vazio com identidade zero e
o próximo `open_private()` o rejeita como DB alheio. Probe isolado exit 1; falta
publicação/recuperação segura da inicialização sem admitir bancos de terceiros.
O núcleo transacional e smoke de ingest/dedupe/read/ack/restart foram exercitados,
mas a entrega não está aceita para deploy. As duas rodadas corretivas da missão
foram usadas na fatia principal; não houve terceira correção. Nenhuma entrega remota.

`core.py`: `Envelope.parse` valida envelope v1 imutável; `Store.ingest` grava
atomicamente evento, inbox, outbox e auditoria. `claim`, `valid`, `finish` e
`send_claim` são primitivas explícitas para teste de contrato de adapter;
não há worker automático nem adapter real/default. `Adapter` é somente Protocol,
sem no-op que finja sucesso. `PushDTO` leva apenas mensagem fixa “Há um novo aviso”,
event_id estável, categoria e severidade. Nunca título/resumo/source/conversation_id.
IDs de evento e categorias precisam ser opacos e não conter dados privados.

## CLI local

> [!note] Limitação de portabilidade desta missão
> O código da CLI e a verificação de testes ainda fixam a raiz scratch do host
> autorizado desta execução; `${TMPDIR}` no ambiente Hermes aponta para essa raiz.
> A biblioteca SQLite é isolada, mas a CLI/testes não são ainda um pacote portátil:
> outra instalação exigirá parametrizar essa raiz e revisar os testes. Não mudar
> TMPDIR para contornar a restrição nem usar um banco existente de outro produto.

A ação humana de executar a CLI cria o arquivo privado (0600). `--db` é obrigatório,
com caminho absoluto dentro de `${TMPDIR}`, sem symlinks,
hardlinks, `..` ou arquivo público. DB existente sem application_id do protótipo
é rejeitado, não inicializado. Use arquivo exclusivo novo; não use DB do Hermes.
Diretório scratch deve estar sob controle do operador. As verificações de path
não defendem contra atacante local que troca arquivos entre verificação e abertura
SQLite; esse cenário precisa solução de filesystem/serviço antes de produção.

```sh
python prototypes/notifications/cli.py --db ${TMPDIR}/notice-demo.db ingest <<'JSON'
{"version":1,"event_id":"notice-001","dedupe_key":"notice-001","source":"example-producer","destination":"example-inbox","category":"operational","severity":"info","title":"Aviso de exemplo","safe_summary":"Um resultado está disponível.","created_at_ms":1791331200000,"expires_at_ms":null,"sensitivity":"private"}
JSON
python prototypes/notifications/cli.py --db ${TMPDIR}/notice-demo.db list
python prototypes/notifications/cli.py --db ${TMPDIR}/notice-demo.db read notice-001
python prototypes/notifications/cli.py --db ${TMPDIR}/notice-demo.db ack notice-001
python prototypes/notifications/cli.py --db ${TMPDIR}/notice-demo.db expire
python prototypes/notifications/cli.py --db ${TMPDIR}/notice-demo.db status
```

Somente ingest/list/read/ack/expire/status. `list` revela resumo permitido local;
não é endpoint autenticado. Sem expiry (omitido/null) retém indefinidamente;
expiry inteiro absoluto em ms deve ser >= criação. Expirado quando clock >= expiry.
Expiração altera outbox, não apaga inbox/auditoria. `accepted` significa somente
retorno bem-sucedido de adapter explícito e nunca ACK/leitura do usuário.

## Contrato e ameaça

Campos desconhecidos são rejeitados, incluindo actions/urls/prompt/reasoning e
argumentos/resultados de tools. Inteiros não aceitam bool, timestamps até 2^63-1,
identificadores preservados exatamente até 256 codepoints, título até 160 e
resumo até 1000. Controles e caracteres Unicode de categoria C são rejeitados.
Severidade: info/success/warning/error; sensitivity: public/private. Conversation_id
opcional explícito até 256, somente dado, sem deep link executável ou actions.
Não armazene conteúdo rico, segredos ou logs. `safe_summary` é fornecido pelo
produtor responsável por selecionar texto permitido: não existe redaction infalível.
Sensitivity é declaração do produtor, não mecanismo de autorização ou criptografia.

Dedupe usa `(source,destination,dedupe_key)`. Replay exato por event_id retorna o
original sem mutação; dedupe semântico pode ter outro event_id, mas todos os demais
campos devem coincidir e retorna o ID original. Conflito rejeita a transação.
SQLite parametrizado, BEGIN IMMEDIATE e constraints garantem atomicidade; tokens
novos por claim protegem conclusão contra worker antigo. Attempts persistidos,
retry exponencial limitado e max_attempts incluem claims perdidos por crash.
Clock em ms é injetável; produção precisará política para clock regressivo.

Send ocorre fora da transação, depois da outbox durável e validação do claim.
Expiry e fim de lease são verificados novamente na conclusão. Uma chamada externa
já iniciada pode terminar após expiry/lease: não pode ser cancelada atomicamente
por SQLite. Recuperação de crash antes/depois de send pode reenviar o mesmo ID.
Contrato é at-least-once com tentativas limitadas, sem promessa exactly-once;
adapter remoto futuro deve deduplicar event_id. Auditoria append-only contém
ID opaco, tipo e clock, sem payload/erro bruto. Triggers protegem mutações via API
SQL comum, não contra administrador que altera o schema/arquivo.

## Verificação

```sh
TMPDIR=${TMPDIR} python -m unittest discover -s prototypes/notifications -p 'test_*.py' -v
python -m py_compile prototypes/notifications/core.py prototypes/notifications/cli.py prototypes/notifications/test_core.py
git diff --check
```

Fixtures neutras apenas em tempfile sob TMPDIR herdado. Adapters **FAKE DE TESTE**
que retornam aceito provam contrato local, não push. Testes incluem schema,
dedupe/conflitos, rollback, restart/crash, leases/fencing entre duas conexões,
expiry/retry/falhas, separação read/ack/audit e CLI. Nada substitui testes Flutter
ou testes físicos foreground/background/app encerrado/offline.

## Comparação prática, sem ativação

| Opção | Dependências e limites |
| --- | --- |
| WS live / MethodChannel local | WS precisa conexão; MethodChannel precisa engine/processo local disponível. Sozinhos não acordam app morto. |
| FCM Android | Google, registro do dispositivo e permission Android 13 para notificações. |
| APNs iOS | Provider, device token, HTTP/2, TLS e cadeia de confiança Apple. |
| UnifiedPush Android | Distribuidor instalado e backend (selfhost possível); exige operar bateria, rede e Doze. |

Fontes oficiais fornecidas pela Claudia, não consultadas em rede nesta execução:
[FCM Android](https://firebase.google.com/docs/cloud-messaging/android/client),
[APNs](https://developer.apple.com/documentation/usernotifications/setting-up-a-remote-notification-server),
[UnifiedPush](https://unifiedpush.org/users/intro/).
Todas precisam de inbox sync autenticado e testes físicos para confiabilidade.
Provider accepted != delivered != read. Sem alegações de preço/custo.

Antes de qualquer deploy/serviço: decidir autenticação, origem confiável,
pareamento/enrollment e revogação de dispositivo, TLS, transporte, proteção do DB,
retention e comportamento dos clocks. Regras propostas por agente dependeriam de
confirmação humana explícita e revogação; não são implementadas aqui. OS,
permissões, Gateway, agendadores e Telegram permanecem intocados.
