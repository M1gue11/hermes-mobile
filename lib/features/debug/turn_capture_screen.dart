import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/diagnostics/turn_capture.dart';
import '../../core/theme/hermes_tokens.dart';
import '../../core/widgets/paper_texture.dart';
import '../../data/gateway_repository_provider.dart';

/// Superfície de desenvolvimento que fecha o diagnóstico de A58/A59.
///
/// A rota e a entrada nos ajustes só existem em build debug. O relatório sai
/// redigido por construção: só nome de evento, nome de campo, id encurtado,
/// ordem e tamanho. A amostra de texto é um gesto explícito, e mesmo com ela
/// ligada campo com cara de credencial continua `<redigido>`.
class TurnCaptureScreen extends ConsumerStatefulWidget {
  const TurnCaptureScreen({super.key, this.capture});

  /// Injetável para o teste de widget; em produção é o singleton de debug.
  final TurnCapture? capture;

  @override
  ConsumerState<TurnCaptureScreen> createState() => _TurnCaptureScreenState();
}

class _TurnCaptureScreenState extends ConsumerState<TurnCaptureScreen> {
  var _probing = false;
  TurnCapture get _capture => widget.capture ?? turnCapture;

  @override
  void initState() {
    super.initState();
    _capture.addListener(_onCaptureChanged);
  }

  @override
  void dispose() {
    _capture.removeListener(_onCaptureChanged);
    super.dispose();
  }

  void _onCaptureChanged() {
    if (mounted) setState(() {});
  }

  /// Abre um socket só, chama leitura antes de `session.resume` e guarda o
  /// desfecho de cada passo. É isto que separa "o gateway inteiro caiu" de
  /// "só o resume recusa", que no app produzem o mesmo sintoma.
  Future<void> _probe() async {
    if (_probing) return;
    setState(() => _probing = true);
    try {
      final steps = await ref
          .read(gatewayRepositoryProvider)
          .probeGateway(storedSessionId: _capture.lastSessionId);
      _capture.setProbe(steps.map((step) => step.toString()));
    } catch (error) {
      _capture.setProbe(['ERRO sonda  ${error.runtimeType}']);
    } finally {
      if (mounted) setState(() => _probing = false);
    }
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _capture.report()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Relatório redigido copiado.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = HermesTokens.of(context);
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: PaperTexture()),
          SafeArea(
            child: Column(
              children: [
                _CaptureBar(onBack: context.pop),
                if (_capture.lastFallbackReason case final motivo?)
                  _FallbackWarning(motivo),
                _Controls(
                  capture: _capture,
                  probing: _probing,
                  onArm: (value) => _capture.arm(value),
                  onSample: (value) => _capture.setSampleText(value),
                  onClear: _capture.clear,
                  onCopy: _capture.hasCapture || _capture.probe.isNotEmpty
                      ? _copy
                      : null,
                  onProbe: _probing ? null : _probe,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    child: SelectableText(
                      _capture.report(),
                      style: tokens.mono.copyWith(
                        fontSize: 11,
                        height: 1.5,
                        color: tokens.ink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptureBar extends StatelessWidget {
  const _CaptureBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final tokens = HermesTokens.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tokens.line)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            color: tokens.ink,
            tooltip: 'Voltar',
          ),
          Expanded(
            child: Text(
              'Captura de turno',
              style: tokens.monoIn(FontWeight.w500).copyWith(
                fontSize: 13,
                color: tokens.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A67: o último turno não correu pelo Dashboard TUI, e diz por quê.
///
/// Aparece mesmo sem captura armada. A queda ser silenciosa foi exatamente o
/// que fez o TUI passar semanas sem nunca ter sido exercitado no aparelho, com
/// a Runs API respondendo no lugar dele e ninguém percebendo.
class _FallbackWarning extends StatelessWidget {
  const _FallbackWarning(this.motivo);

  final String motivo;

  @override
  Widget build(BuildContext context) {
    final tokens = HermesTokens.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: tokens.accent.withValues(alpha: 0.08),
        border: Border(bottom: BorderSide(color: tokens.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.swap_horiz, size: 15, color: tokens.accent),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'O último turno caiu para a Runs API: $motivo',
              style: tokens.mono.copyWith(
                fontSize: 11,
                height: 1.45,
                color: tokens.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.capture,
    required this.probing,
    required this.onArm,
    required this.onSample,
    required this.onClear,
    required this.onCopy,
    required this.onProbe,
  });

  final TurnCapture capture;
  final bool probing;
  final ValueChanged<bool> onArm;
  final ValueChanged<bool> onSample;
  final VoidCallback onClear;
  final VoidCallback? onCopy;
  final VoidCallback? onProbe;

  @override
  Widget build(BuildContext context) {
    final tokens = HermesTokens.of(context);
    final status = capture.capturing
        ? 'Observando o turno em curso'
        : capture.armed
        ? 'Armada: envie uma pergunta na conversa'
        : capture.hasCapture
        ? 'Captura pronta para leitura'
        : 'Desligada';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tokens.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Toggle(
            label: 'Capturar o próximo turno',
            note: status,
            value: capture.armed || capture.capturing,
            onChanged: capture.capturing ? null : onArm,
          ),
          _Toggle(
            label: 'Incluir amostra de 80 caracteres',
            note: 'Sem isto, só nomes, ids, ordem e tamanhos saem daqui',
            value: capture.sampleText,
            onChanged: onSample,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: onProbe,
                child: Text(probing ? 'Sondando…' : 'Sondar gateway'),
              ),
              TextButton(
                onPressed: onCopy,
                child: const Text('Copiar relatório'),
              ),
              TextButton(
                onPressed: capture.hasCapture ? onClear : null,
                child: const Text('Limpar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.note,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String note;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = HermesTokens.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: tokens.serif.copyWith(fontSize: 14, color: tokens.ink),
              ),
              Text(
                note,
                style: tokens.mono.copyWith(fontSize: 10, color: tokens.dim),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
