import 'dart:async';
import 'package:flutter/material.dart';
import 'push_controller.dart';
import 'push_runtime.dart';

class PushControls extends StatefulWidget {
  const PushControls({super.key, this.controller});
  final PushController? controller;

  @override
  State<PushControls> createState() => _PushControlsState();
}

class _PushControlsState extends State<PushControls> {
  late final PushController pushRuntime;

  @override
  void initState() {
    super.initState();
    pushRuntime = widget.controller ?? _defaultRuntime;
    unawaited(startPushForeground(pushRuntime));
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: pushRuntime,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('UnifiedPush experimental'),
        const Text(
          'Backend pendente — enrollment autenticado ainda não existe',
        ),
        const Text(
          'Aviso Android genérico bloqueado até enrollment autenticado; '
          'sem prontidão de backend.',
        ),
        Text(
          pushRuntime.android
              ? pushRuntime.status
              : 'Unsupported — somente Android',
        ),
        if (pushRuntime.android && !pushRuntime.initialized)
          const Text('Inicializando receptor…'),
        SwitchListTile(
          title: const Text('Receber envelopes operacionais'),
          value: pushRuntime.optedIn,
          onChanged: pushRuntime.android && pushRuntime.initialized
              ? (value) {
                  if (value) {
                    pushRuntime.enable();
                  } else {
                    pushRuntime.revoke();
                  }
                }
              : null,
        ),
        if (pushRuntime.hasEndpoint)
          const Text('Endpoint armazenado com segurança — backend pendente'),
        if (pushRuntime.optedIn && pushRuntime.selected == null) ...[
          TextButton(
            onPressed: () => pushRuntime.choose(defaultChoice: true),
            child: const Text('Usar distribuidor padrão do sistema'),
          ),
          for (final choice in pushRuntime.choices)
            TextButton(
              onPressed: () => pushRuntime.choose(distributor: choice),
              child: Text(choice),
            ),
        ],
        if (pushRuntime.optedIn &&
            pushRuntime.selected != null &&
            !pushRuntime.distributorRegistered)
          TextButton(
            onPressed: () => pushRuntime.retryRegistration(),
            child: const Text('Tentar registro novamente'),
          ),
        if (pushRuntime.android && pushRuntime.initialized)
          TextButton(
            onPressed: () => pushRuntime.revoke(),
            child: const Text('Revogar / tentar desregistrar novamente'),
          ),
      ],
    ),
  );
}

final _defaultRuntime = pushRuntime;
