import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/hermes_tokens.dart';
import '../../../core/widgets/code_surface.dart';
import '../../../core/widgets/hermes_sheet.dart';
import '../../../domain/models/attachment_envelope.dart';
import '../../settings/agent_persona.dart';

/// O anexo apresentado como anexo, e não como fala.
///
/// O defeito do A24 era a bolha `VOCÊ` mostrar o envelope do runtime em inglês
/// seguido do arquivo inteiro, em itálico, como se tivesse sido digitado. Aqui o
/// turno continua sendo da pessoa (ela mandou mesmo o arquivo, ao contrário do
/// andaime do A23): o que muda é que a máquina vira uma linha de arquivo e o
/// conteúdo fica atrás de um toque, em vez de enterrar a conversa.
///
/// **O desenho não foi inventado aqui.** O mock já desenha uma linha de arquivo,
/// nos "Arquivos de contexto" do sheet de contexto (`design/Hermes.dc.html`):
/// `padding:11px 13px; gap:11px; background:var(--bg2); border:1px solid
/// var(--line); border-radius:12px`, com o ícone em `var(--accent)` a 16px, o
/// nome em mono 12.5 `var(--ink)` cortado com reticências e o tamanho em mono 10
/// `var(--faint)`. É essa linha, com a seta de abrir no lugar do × de remover.
class AttachmentCard extends StatelessWidget {
  const AttachmentCard({
    super.key,
    required this.attachment,
    this.captionMayBeInContent = false,
    this.persona = const AgentPersona(),
  });

  final Attachment attachment;

  /// A legenda digitada pode estar no fim do conteúdo. Ver
  /// [parseAttachmentEnvelope]; a folha diz isso a quem abrir.
  final bool captionMayBeInContent;
  final AgentPersona persona;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        key: const ValueKey('anexo'),
        onTap: () => showAttachmentSheet(
          context,
          attachment: attachment,
          captionMayBeInContent: captionMayBeInContent,
          persona: persona,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: t.bg2,
            border: Border.all(color: t.line),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_icone(attachment.kind), size: 16, color: t.accent),
              const SizedBox(width: 11),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      attachment.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.mono.copyWith(fontSize: 12.5, color: t.ink),
                    ),
                    Text(
                      _linhaDeMetadados(attachment),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.mono.copyWith(fontSize: 10, color: t.faint),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 11),
              Icon(Icons.chevron_right, size: 15, color: t.faint),
            ],
          ),
        ),
      ),
    );
  }
}

/// Abre o que o app sabe do anexo: onde ele está, o que o runtime disse dele e,
/// quando veio embutido, o conteúdo.
Future<void> showAttachmentSheet(
  BuildContext context, {
  required Attachment attachment,
  bool captionMayBeInContent = false,
  AgentPersona persona = const AgentPersona(),
}) {
  return showHermesSheet(
    context,
    title: attachment.name,
    tag: attachmentTypeLabel(attachment),
    child: _AttachmentBody(
      attachment: attachment,
      captionMayBeInContent: captionMayBeInContent,
      persona: persona,
    ),
  );
}

class _AttachmentBody extends StatelessWidget {
  const _AttachmentBody({
    required this.attachment,
    required this.captionMayBeInContent,
    required this.persona,
  });

  final Attachment attachment;
  final bool captionMayBeInContent;
  final AgentPersona persona;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final conteudo = attachment.content;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // O tipo já está na etiqueta do cabeçalho; aqui vai o que ela não diz.
        Text(
          _linhaDaFolha(attachment),
          style: t.mono.copyWith(fontSize: 11, color: t.faint),
        ),

        // A duração da mensagem de voz já saiu na linha acima; repeti-la como
        // "nota do runtime" seria dizer a mesma coisa duas vezes.
        if (attachment.note != null && attachment.kind != AttachmentKind.voice)
          _Secao(
            attachment.kind == AttachmentKind.image
                ? persona.imageNoteLabel
                : 'nota do runtime',
            Text(
              attachment.note!,
              style: t
                  .serifIn(FontWeight.w400, italic: true)
                  .copyWith(fontSize: 14, height: 1.55, color: t.dim),
            ),
          ),

        if (attachment.path != null)
          _Secao(
            'onde está, na máquina do agente',
            SelectableText(
              attachment.path!,
              style: t.mono.copyWith(fontSize: 11, height: 1.5, color: t.dim),
            ),
          ),

        if (conteudo != null)
          _Secao(
            'conteúdo',
            conteudo.isEmpty
                ? Text(
                    'O arquivo chegou vazio.',
                    style: t.serif.copyWith(fontSize: 14, color: t.dim),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (captionMayBeInContent) ...[
                        const _AvisoDaLegenda(),
                        const SizedBox(height: 9),
                      ],
                      CodeSurface(
                        // Largura cheia: a `Stack` da superfície se ajusta ao
                        // maior filho, e sem isto um arquivo de uma linha curta
                        // desenharia uma caixa estreita no meio da folha.
                        child: Container(
                          width: double.infinity,
                          // O mesmo `padding:15px 16px 13px` do bloco de código.
                          padding: const EdgeInsets.fromLTRB(16, 15, 16, 13),
                          // O texto dobra em vez de rolar na horizontal, ao
                          // contrário do bloco de código: aqui é arquivo, e ler
                          // linha de CSV com rolagem lateral dentro de uma folha
                          // que já rola na vertical é pior que ver a linha
                          // dobrada.
                          child: SelectableText(
                            conteudo,
                            style: t.mono.copyWith(
                              fontSize: 12.5,
                              height: 1.62,
                              color: t.ink,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
            acao: conteudo.isEmpty ? null : _Copiar(texto: conteudo),
          ),
      ],
    );
  }
}

/// Uma seção da folha, no formato que o mock usa no sheet de contexto:
/// rótulo em mono 10 com `letter-spacing:.16em`, 11px acima do conteúdo e 22px
/// entre seções.
class _Secao extends StatelessWidget {
  const _Secao(this.rotulo, this.filho, {this.acao});

  final String rotulo;
  final Widget filho;

  /// Gesto que pertence à seção, alinhado à direita do rótulo.
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                rotulo.toUpperCase(),
                style: t.mono.copyWith(
                  fontSize: 10,
                  letterSpacing: 1.6,
                  color: t.faint,
                ),
              ),
              if (acao != null) ...[const Spacer(), acao!],
            ],
          ),
          const SizedBox(height: 11),
          filho,
        ],
      ),
    );
  }
}

/// Por que a legenda pode não ter saído para fora do conteúdo.
///
/// Fica **dentro** da folha, e não no card, porque só interessa a quem foi
/// procurar o texto. No fluxo normal seria ruído em todo anexo.
class _AvisoDaLegenda extends StatelessWidget {
  const _AvisoDaLegenda();

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Row(
      key: const ValueKey('aviso-da-legenda'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 13, color: t.faint),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Se você escreveu algo junto do arquivo, está no fim daqui: sem '
            'marca de fim no arquivo, separar arriscaria atribuir a você uma '
            'linha que é dele.',
            style: t.mono.copyWith(fontSize: 10, height: 1.5, color: t.faint),
          ),
        ),
      ],
    );
  }
}

class _Copiar extends StatelessWidget {
  const _Copiar({required this.texto});
  final String texto;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return InkWell(
      key: const ValueKey('copiar-anexo'),
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: texto));
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Conteúdo copiado')));
      },
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.copy_all_outlined, size: 13, color: t.dim),
            const SizedBox(width: 7),
            Text(
              'COPIAR',
              style: t.mono.copyWith(
                fontSize: 10,
                letterSpacing: 1.6,
                color: t.dim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// O que fica sob o nome, no card: tipo, tamanho e, na voz, a duração.
String _linhaDeMetadados(Attachment anexo) {
  final partes = <String>[attachmentTypeLabel(anexo)];
  if (anexo.bytes != null) partes.add(attachmentSizeLabel(anexo.bytes!));
  if (anexo.kind == AttachmentKind.voice && anexo.note != null) {
    partes.add(anexo.note!);
  }
  return partes.join(' · ');
}

/// A mesma linha, sem repetir a etiqueta que já está no cabeçalho da folha.
String _linhaDaFolha(Attachment anexo) {
  final partes = <String>[anexo.kind.label];
  if (anexo.bytes != null) partes.add(attachmentSizeLabel(anexo.bytes!));
  if (anexo.kind == AttachmentKind.voice && anexo.note != null) {
    partes.add(anexo.note!);
  }
  return partes.join(' · ');
}

IconData _icone(AttachmentKind kind) => switch (kind) {
  AttachmentKind.text => Icons.description_outlined,
  AttachmentKind.document => Icons.picture_as_pdf_outlined,
  AttachmentKind.image => Icons.image_outlined,
  AttachmentKind.audio => Icons.graphic_eq,
  AttachmentKind.video => Icons.movie_outlined,
  AttachmentKind.voice => Icons.mic_none,
  AttachmentKind.file => Icons.insert_drive_file_outlined,
};
