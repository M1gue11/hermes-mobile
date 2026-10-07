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
- Confirmar ponte Android OS ausente: nenhum banner OS, som, solicitação de
  permissão ou cron. Não interpretar ausência em background/terminated como
  falha de uma integração push: essa fase não foi implementada.

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
