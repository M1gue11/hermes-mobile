# Validações pendentes em aparelho

Este arquivo contém **somente** roteiros ainda pendentes de aceite em aparelho.
Após validação, registrar o resultado na mudança correspondente, atualizar
[BACKLOG.md](BACKLOG.md) e remover o roteiro daqui. O Git preserva o histórico.

## [ ] A60 — EXCLUSIVO da branch feat/notifications-night-20261007

Baseline `08833d0`; não executar como roteiro da main nem tratar como aceito.
Aceite Android pendente. Branch WIP com P2 de retomada documentado em
[HANDOFF.md](HANDOFF.md); os testes automatizados não são aceite em aparelho.

- Regressão bloqueante conhecida: falha ao interromper/acompanhamento, ocultar e
  voltar com `running:false` e histórico vazio. Não deveria afirmar “A execução
  falhou” sem status remoto, mas a versão atual afirma. Não marcar esse caso como
  aceito; após correção exigir aviso provisório/resultado desconhecido substituível
  por conclusão/cancelamento/falha realmente conhecidos.

- Foreground, conversa visível: Ajustes → Notificações mostra inbox local,
  preferências por categoria e persona configurada. Emitir show neutro pelo
  produtor já existente com id/key reais; texto com Markdown/URL deve continuar
  texto simples. Não pode abrir URL, executar ação ou virar mensagem assistant.
- Emitir show duplicado com id/seq disponíveis, depois show novo na mesma key:
  não duplica; substituição fica não lida. Marcar lida, abrir conversa e remover
  funcionam. Destino deve ser a conversa durável capturada, inclusive ID com
  caracteres escapáveis; título/prompt/payload não escolhem destino.
- Clear repetido remove só aquela key na conversa correta, mesmo com custom
  silenciado. Mesma key em outra conversa permanece. Testar TTL 0/curto e TTL
  inválido (negativo, fracionário, enorme): expira com timer ou é rejeitado com
  segurança, sem crash/overflow e sem manter timer da entrada substituída.
- Iniciar/finalizar/falhar/interromper execução e retomar snapshot terminal:
  cópia genérica correta, sem duplicata final nem erro bruto. Final rápido antes
  de 750 ms não deixa progresso atrasado. Cancelamento local aceito gera aviso
  “Interrupção solicitada”; estado terminal posterior substitui o aviso, sem
  afirmar interrupção antes da confirmação remota.
- Subagents paralelos com IDs reais recebem agregados distintos; sem ID há um
  agregado por turno. Spawn/start/thinking/tool/progress/complete usam frases
  genéricas. Não aparecem goal/summary/text/tool_preview ou percentual inventado.
  Background.complete não mostra seu text. Final cancela pending correspondente.
- Silenciar cada categoria antes/depois de agendar progress: efeito imediato,
  reativar não libera pending antigo. Avisos já recebidos permanecem até remoção.
- Trocar conversa durante throttle e ocultar a rota: nenhum aviso pending ou
  callback antigo aparece ligado à nova sessão. Desconectar/reconectar: dedupe
  do mesmo turno preservado, nenhum prompt/decisão reenviado, nenhuma sessão
  adicional aberta apenas para notificações.
- Background: listeners locais são fechados; não esperar entrega contínua.
  Ao voltar, conferir terminal conhecido por snapshot/histórico sem perder chat.
  Show/clear emitidos durante ausência não têm replay garantido.
- Terminated: inbox/preferências se perdem; ao abrir, inbox vazia e categorias
  ligadas. Não esperar push nem recuperação durável de avisos perdidos.
- Offline: inbox recebida permanece somente enquanto processo vive, TTL local
  continua; nada promete entrega/retry/replay offline. Reconnect usa fluxo atual.
- Privacidade: captura de turno com sampleText ligado continua metadata somente
  para notification/subagent/background.complete. Usar fixtures neutras; não
  capturar tools args/results, prompts, reasoning ou credenciais na nova inbox.
- Confirmar gate pré-enrollment: nenhum banner OS ou solicitação automática
  de permissão. O sink oficial existe, mas permanece bloqueado pelo controller
  enquanto enrollment autenticado está pendente.

## [ ] A75 — clarify batch no Android

- Abra uma conversa que peça quatro esclarecimentos; mesmo sem mensagens na
  thread, todas as perguntas devem aparecer e o composer deve dizer que aguarda
  decisão.
- Responda uma escolha, uma resposta livre e uma multi-seleção. Cada envio deve
  travar somente aquela pergunta; a multi-seleção deve manter todas as escolhas
  marcadas.
- Desconecte/reconecte após responder uma pergunta: ela deve permanecer concluída,
  sem opção de envio, e as pendentes devem continuar disponíveis.
- Force uma falha de rede ao responder e confirme que texto/seleção permanecem
  visíveis para retry.

## [ ] A73 — expansão estável da timeline

- Abra uma tool: o cabeçalho deve permanecer no mesmo ponto da tela e revelar
  argumentos e saída abaixo dele.
- Um segundo toque durante a transição recolhe a mesma tool sem exigir scroll.
- Raciocínio e `Mostrar mais ferramentas` seguem a mesma regra de ancoragem.
- O conteúdo posterior desce/sobe com a divulgação, sem sobreposição, salto ou
  perda do ponto de leitura.
- Repita com texto a 180% e com “remover animações” ativo.

## [ ] A74 — acompanhamento do streaming por intenção

- Sem gesto do usuário, a resposta acompanha o fim do primeiro ao último token.
- Qualquer gesto de rolagem, mesmo curto, congela imediatamente o trecho visível.
- Novos tokens, mensagens e aprovações não deslocam a leitura pausada.
- Voltar manualmente ao rodapé não reativa o acompanhamento.
- O retorno ao fim, um novo envio e a troca de conversa reatam o acompanhamento
  explicitamente.
- A interação deve permanecer estável, sem puxões ou stuttering perceptível.

## [ ] Fatia feat/unifiedpush-client-20261007 — P2 e contrato push pendente

Este roteiro não autoriza envio, instalação de APK ou alteração do backend.
Antes do aceite, reexecutar as regressões Flutter desta branch e verificar erro
local neutro de stop, ocultar/retomar idle com histórico vazio: aviso permanece
“Não foi possível acompanhar a execução”, substituível por terminal remoto.
Nenhum prompt deve ser reenviado; bolha mantém o lifecycle existente.

Resolução offline **SUPERADO** com os pacotes oficiais Android/interface; receptor
experimental implementado. Enrollment, ACL, banner/APK e aparelho permanecem
pendentes. O main padrão agora despacha --unifiedpush-bg ao bootstrap headless
antes da UI; foreground restaura o receptor Android no startup, com opt-in
desligado por padrão e início compartilhado/idempotente com a sheet. A ponte OS usa flutter_local_notifications **22.3.1** (pin exato),
resolvido offline no cache oficial. initialize/canal/consulta/show usam contexto
do engine, sem Activity ou pedido de permissão. A execução Android não foi validada. Mensagens pré-enrollment não alcançam o sink; nenhuma permissão
OS é solicitada. Os cenários abaixo NÃO foram executados
em aparelho nesta entrega. Evidências em
[RESULT-UNIFIEDPUSH-BOOTSTRAP.md](../../RESULT-UNIFIEDPUSH-BOOTSTRAP.md):

- Foreground: opt-in explícito; fora de Android, unsupported; ausência/seleção do
  distribuidor exige ação humana. Sem permissão OS automática. Registro deve
  mostrar “Backend pendente — enrollment autenticado ainda não existe”.
- Background e tela bloqueada: callback headless sem UI/chat/conexão; somente
  confirmar bloqueio de mensagens pré-enrollment mesmo com decrypted=true.
  Banner genérico só será testável após enrollment/ACL e consentimento OS explícito; sem
  conteúdo rico, chaves ou endpoints. Abertura não executa comando nem inventa rota pendente.
- Swipe em recentes: medir recepção com o distribuidor escolhido e comportamento
  do fabricante; não confundir swipe com force-stop nem prometer entrega.
- Offline: medir indisponibilidade temporária, retomada e dedupe; nenhuma mensagem
  perdida deve ser anunciada como entregue apenas por registro no distribuidor.
- Force-stop: declarar a limitação Android; não prometer despertar até reabertura
  humana do app. Confirmar recuperação segura depois da reabertura.
- Segundo distribuidor: teste futuro de seleção/troca/revogação e mesmos limites.
  ntfy é só distribuidor selecionável, sem ACL ou enrollment configurados aqui.

### Inventário da ponte Android (2026-10-08)

- flutter_local_notifications **22.3.1**, SDK ^3.10 / Flutter >=3.38.1;
  app mantém Dart ^3.12.2. unifiedpush_android **3.5.0**,
  unifiedpush_platform_interface **4.0.0**, flutter_secure_storage **10.3.1**.
- Dependências transitivas novas no lock: interface local notifications 12.2.0,
  Linux 8.0.1, Windows 3.1.1, Web 1.0.0, timezone 0.11.1, dbus 0.7.15,
  petitparser 7.0.2 e xml 7.0.1. O sink do app continua exclusivamente Android.
- Canal hermes_operational_v1, ícone ic_stat_hermes, id 1; texto somente
  Hermes / Novo aviso operacional; payload omitido (string vazia no canal oficial).
  Nenhum tap/action executa comando ou recebe envelope. Falhas são redigidas.
- Testes de boundary em messenger oficial não validam engine, permissão nativa,
  banner ou aparelho. Java/SDK Android ausentes: APK não tentado. Enrollment, ACL,
  opt-in/consentimento OS e os roteiros pendentes de aparelho continuam obrigatórios.
