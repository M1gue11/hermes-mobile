# Validações pendentes em aparelho

Este arquivo contém **somente** roteiros ainda pendentes de aceite em aparelho.
Após validação, registrar o resultado na mudança correspondente, atualizar
[BACKLOG.md](BACKLOG.md) e remover o roteiro daqui. O Git preserva o histórico,
e os aceites consolidados ficam no vault pessoal, em "Histórico e decisões do
loop" do projeto Hermes Mobile.

## [ ] A104: baixar arquivo entregue na conversa

- Receba um `MEDIA:` não-imagem que esteja em uma pasta permitida no servidor.
  Toque **Baixar arquivo**: veja bytes/progresso e, ao terminar, o seletor do
  sistema com o nome correto. Salve em Downloads e confira o conteúdo.
- Cancele um download em curso e feche o seletor sem salvar: estados distintos
  de cancelamento, sem confirmação falsa de salvamento. Sair da conversa no
  meio da transferência cancela e descarta o parcial.
- Arquivo removido ou fora das pastas permitidas: veja o motivo da recusa no
  próprio bloco; nenhuma página de login/erro deve virar arquivo salvo.
- Desligue a rede durante a transferência e tente de novo depois de reconectar.
  O Android já salvou um arquivo sintético no emulador; falta sucesso com um
  arquivo permitido no runtime real (o smoke encontrou apenas duas recusas).
- iOS: compilar em Mac e conferir exportação/cancelamento no seletor Arquivos.

## [ ] A78: selecionar vários arquivos

- Com texto já digitado, abra Anexar e selecione vários arquivos numa só vez.
  Todos aparecem na tira e a legenda permanece.
- Inclua um arquivo maior que 25 MB: o aviso identifica o nome dele, e os
  menores entram. Repita ultrapassando 10 anexos e 50 MB no total.
- Cancele o seletor: anexos anteriores e texto permanecem; o envio volta a
  ficar disponível. Voz com texto digitado ainda depende de A105.

## [ ] A79: recusa do Parar visível

- Durante um turno, corte a rede e toque **Parar a resposta**. A falha aparece
  no aviso flutuante e a resposta não ganha estado de erro por esse motivo.
- Reconecte: a resposta pode continuar chegando. Repita com `/stop`.

## [ ] A92: HTTP com avisos de transporte

- Em Conexões, digite HTTP com IP privado e com host público: ambos mostram
  **Conexão sem TLS**, e o público tem aviso reforçado. Trocar para HTTPS
  remove o aviso do formulário. A conexão não é bloqueada por ser HTTP.
- Configure um servidor HTTP cujo Host header aceite o endereço escolhido.
  Ajustes e Captura de turno continuam mostrando **Conexão sem TLS** depois
  de salvar, fechar e reabrir o app; o aviso identifica API Server/Dashboard.
- Troque origem de uma URL e deixe o segredo vazio: o app ainda exige a nova
  chave/senha. HTTPS com certificado inválido continua recusado.
- iOS: compilar em Mac e verificar HTTP por IP e HTTPS com certificado válido.

## [ ] A60: aceites restantes de notificações

Plugin instalado em 2026-11-09. Já confirmados por Miguel no Android:
recebimento do teste; conclusão de turno e pergunta `clarify` também com o app
fora de foreground/fechado. Não repetir esses passos como se faltasse instalação;
revalidá-los somente se houver mudança relevante. Falha, limpeza por resolução,
deep link, tela bloqueada e revogação não são automaticamente aprovados por isso.

Pré-requisitos para reproduzir em outra instalação: instalar e habilitar
`server/mobile-push`, verificar ativação tanto no gateway quanto no Dashboard e
configurar o distribuidor. No ntfy `deny-all`, publicação e assinatura são
permissões diferentes: escrita anônima limitada a `up*` só com autorização do
operador, leitura autenticada por conta dedicada. Não liberar leitura anônima
nem copiar senha para logs/documentação.

- Confirme o app ntfy apontando para a instância configurada, o aparelho
  registrado e a indicação de criptografia no Hermes Mobile.
- Gere uma falha terminal controlada em ambiente de teste: o aviso corresponde
  à falha remota, não à desconexão do observador nem a falha do botão Parar.
- Abra pelo toque uma notificação de conversa já recebida: a conversa correta
  abre sem enviar prompt nem executar ação.
- Peça operação de teste que exija aprovação, sem provocar mudança perigosa, e
  feche o app: chega aviso urgente. Resolver por outro cliente apaga **aquele**
  aviso. Teste também a limpeza do aviso de `clarify`; não pedir/registrar senha
  de sudo apenas para produzir uma notificação.
- Com a conversa aberta na tela, um turno dela não gera aviso; um turno de
  outra conversa gera.
- Na tela bloqueada, confira apresentação privada sem conteúdo sensível e
  registre versão Android/One UI. Esse teste ainda não foi confirmado.
- Desligue a chave: o aparelho some de `GET /api/plugins/mobile-push/devices`
  e nenhum aviso chega mais; reativar deve reinscrever sem duplicação.
- Registre swipe nos recentes separadamente de **Force stop**, e perda de
  rede/Tailscale/retomada separadamente da entrega online já observada.

Lifecycle dos serviços e cartão de acompanhamento ainda **não estão na APK**;
matriz para implementação futura em
[NOTIFICATION_EVENTS_AND_LIVE_RUN.md](NOTIFICATION_EVENTS_AND_LIVE_RUN.md).

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
