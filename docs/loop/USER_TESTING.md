# Validações pendentes em aparelho

Este arquivo contém **somente** roteiros ainda pendentes de aceite em aparelho.
Após validação, registrar o resultado na mudança correspondente, atualizar
[BACKLOG.md](BACKLOG.md) e remover o roteiro daqui. O Git preserva o histórico,
e os aceites consolidados ficam no vault pessoal, em "Histórico e decisões do
loop" do projeto Hermes Mobile.

## [ ] A60: notificações com o app fechado

Pré-requisitos no servidor (decisão do usuário, não automática): copiar
`server/mobile-push` para `~/.hermes/plugins/mobile-push`, rodar
`hermes plugins enable mobile-push` e reiniciar gateway e dashboard. No ntfy
self-hosted com `deny-all`, liberar `ntfy access everyone 'up*' write-only`.

- No celular, instale o app ntfy e aponte o servidor padrão dele para a sua
  instância. Em Ajustes › Notificações, ligue: permitir a notificação, ver
  Distribuidor `ntfy`, o host do seu ntfy, "mobile-push, aparelho registrado" e
  "cifrado até o aparelho".
- "Enviar aviso de teste": o aviso "Notificações ativas" chega em segundos.
- Mande um prompt longo, saia do app e **feche-o** pelos recentes. Ao terminar,
  chega "<persona> respondeu" com o título da conversa; tocar abre a conversa.
- Peça um comando que exija aprovação e feche o app: chega o aviso urgente
  "precisa da sua aprovação". Aprovar pelo desktop ou pelo app apaga o aviso.
- Com a conversa aberta na tela, um turno dela não gera aviso; um turno de
  outra conversa gera.
- Na tela bloqueada, o aviso mostra só o título e o tipo (visibilidade privada).
- Desligue a chave: o aparelho some de `GET /api/plugins/mobile-push/devices`
  e nenhum aviso chega mais.

## [ ] A77: conversa atualizada ao voltar

- Abra uma conversa no celular, saia do app e continue essa mesma conversa pelo
  desktop ou pelo Dashboard web. Volte ao app: a pergunta e a resposta novas
  aparecem sem reabrir a conversa, e a posição de leitura não salta.
- Volte de Skills ou Ferramentas para a conversa: o mesmo vale.
- Sem mudança no servidor, voltar não pisca nem rola a thread.
- Com o cartão de aprovação aberto, ou com uma resposta em andamento, voltar não
  substitui nada na tela.
- Com a rede cortada, voltar mantém o que estava na tela.

## [ ] A89: gravação descartada ao sair

- Comece uma gravação e vá para a tela inicial do Android: o indicador de
  microfone do sistema apaga. Ao voltar, a conversa diz "A gravação foi
  descartada ao sair da conversa."
- Comece uma gravação e abra Recursos › Skills: a gravação é descartada do
  mesmo jeito.
- Comece uma gravação e puxe a cortina de notificações: a gravação continua.
- Primeira gravação depois de instalar: o diálogo de permissão do microfone
  não cancela nada.

## [ ] A91: confirmar a primeira chave SSH

- Em Máquina, toque "Esquecer a chave antiga" se houver uma fixada, e
  conecte. A conexão para em "CONFERIR CHAVE" mostrando `SHA256:...`.
- No servidor, `ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub` deve
  imprimir a mesma impressão. "Cancelar" volta a desconectado sem fixar nada;
  conectar de novo pergunta outra vez.
- "Confiar e conectar" abre o shell; a impressão aparece como fixada e a
  próxima conexão não pergunta mais.
- Deixe a pergunta aberta por mais de 90 s: a conexão é cancelada.
