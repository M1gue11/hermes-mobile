import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/hermes_radius.dart';
import '../../../core/theme/hermes_tokens.dart';
import '../../../data/gateway_repository_provider.dart';
import '../../../data/platform/device_agent_file_saver.dart';
import '../../../domain/models/agent_file.dart';
import '../../../domain/models/agent_media.dart';
import '../../../domain/repositories/gateway_repository.dart';

/// A referência mantém a composição da mídia existente. O download só começa
/// por toque e os bytes nunca são entregues a um navegador com credenciais.
class AgentFileReference extends ConsumerStatefulWidget {
  const AgentFileReference({super.key, required this.path});

  final String path;

  @override
  ConsumerState<AgentFileReference> createState() => _AgentFileReferenceState();
}

class _AgentFileReferenceState extends ConsumerState<AgentFileReference> {
  Completer<void>? _cancel;
  int _received = 0;
  int? _total;
  String? _notice;
  bool _saving = false;

  @override
  void dispose() {
    if (_cancel case final cancel? when !cancel.isCompleted) cancel.complete();
    super.dispose();
  }

  Future<void> _download() async {
    if (_cancel != null) return;
    final cancel = Completer<void>();
    setState(() {
      _cancel = cancel;
      _received = 0;
      _total = null;
      _notice = null;
    });
    Directory? temporary;
    try {
      final GatewayRepository gateway;
      try {
        gateway = ref.read(gatewayRepositoryProvider);
      } catch (_) {
        throw const GatewayOperationException(
          'Conecte o Dashboard para baixar o arquivo.',
        );
      }
      final saver = ref.read(agentFileSaverProvider);
      // Android/iOS: diretório temporário privado da aplicação; nada vai ao
      // Downloads antes da escolha explícita no seletor do sistema.
      temporary = await Directory.systemTemp.createTemp('hermes-download-');
      final name = mediaFileName(
        widget.path,
      ).replaceAll(RegExp(r'[\\/\x00-\x1f\x7f]'), '_');
      final destination =
          '${temporary.path}/${name == '.' || name == '..' || name.isEmpty ? 'arquivo' : name}';
      final info = await gateway.downloadAgentFile(
        path: widget.path,
        destination: destination,
        cancelled: cancel.future,
        onProgress: (received, total) {
          if (!mounted || cancel.isCompleted) return;
          // Progresso em blocos de 64 KiB evita reconstruir toda a referência
          // a cada pacote recebido, mantendo o último tamanho preciso.
          if (received == 0 ||
              received == total ||
              received - _received >= 65536) {
            setState(() {
              _received = received;
              _total = total;
            });
          }
        },
      );
      if (!mounted || cancel.isCompleted) return;
      setState(() {
        _received = info.size;
        _saving = true;
      });
      final saved = await saver.save(
        localPath: destination,
        name: mediaFileName(widget.path),
        mimeType: info.mimeType,
      );
      if (mounted) {
        setState(
          () => _notice = saved
              ? 'Salvo · ${_size(info.size)}'
              : 'Salvamento cancelado.',
        );
      }
    } on AgentFileDownloadCancelled {
      if (mounted) setState(() => _notice = 'Download cancelado.');
    } on GatewayAuthenticationRequired {
      if (mounted) {
        setState(() => _notice = 'Entre no Dashboard para baixar o arquivo.');
      }
    } on GatewayOperationException catch (error) {
      if (mounted) setState(() => _notice = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _notice =
              'Não foi possível salvar o arquivo. Confira o espaço e tente de novo.',
        );
      }
    } finally {
      // Abrange falha de rede, cancelamento, saída da tela e seletor fechado.
      try {
        if (temporary != null) await temporary.delete(recursive: true);
      } on FileSystemException {
        // O sistema pode já ter removido o temporário privado.
      }
      if (mounted) {
        setState(() {
          _cancel = null;
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final busy = _cancel != null;
    final note = _saving
        ? 'Escolha onde salvar · ${_size(_received)}'
        : busy
        ? 'Baixando · ${_size(_received)}'
              '${_total == null ? '' : ' de ${_size(_total!)}'}'
        : _notice ?? 'Arquivo no servidor';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      decoration: BoxDecoration(
        color: t.bg2,
        border: Border.all(color: t.line),
        borderRadius: HermesRadius.todos(HermesRadius.bloco),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.insert_drive_file_outlined, size: 17, color: t.dim),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  mediaFileName(widget.path),
                  style: t.mono.copyWith(fontSize: 11.5, color: t.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.path,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: t.mono.copyWith(fontSize: 10, color: t.dim),
          ),
          const SizedBox(height: 6),
          Semantics(
            liveRegion: !busy,
            child: Text(
              note,
              style: t.mono.copyWith(fontSize: 10.5, height: 1.4, color: t.dim),
            ),
          ),
          if (busy && !_saving) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _total != null && _total! > 0
                  ? (_received / _total!).clamp(0, 1)
                  : null,
              semanticsLabel: 'Download do arquivo',
              color: t.accent,
              backgroundColor: t.line,
            ),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: _saving
                  ? null
                  : busy
                  ? () {
                      if (!_cancel!.isCompleted) _cancel!.complete();
                    }
                  : _download,
              icon: Icon(
                busy ? Icons.close_rounded : Icons.file_download_outlined,
                size: 18,
              ),
              label: Text(
                _saving
                    ? 'Salvando…'
                    : busy
                    ? 'Cancelar'
                    : 'Baixar arquivo',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _size(int bytes) => bytes >= 1024 * 1024
    ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB'
    : bytes >= 1024
    ? '${(bytes / 1024).toStringAsFixed(1)} KB'
    : '$bytes B';
