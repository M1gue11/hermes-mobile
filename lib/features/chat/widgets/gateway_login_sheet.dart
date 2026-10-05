import 'package:flutter/material.dart';

import '../../../core/theme/hermes_tokens.dart';
import '../../../core/widgets/hermes_sheet.dart';
import '../../../domain/repositories/gateway_repository.dart';

Future<bool> showGatewayLoginSheet(
  BuildContext context, {
  required Future<void> Function({
    required String baseUrl,
    required String username,
    required String password,
  })
  authenticate,
}) async {
  var authenticated = false;
  await showHermesSheet(
    context,
    title: 'Autorizar anexos',
    tag: 'Dashboard',
    child: _GatewayLoginForm(
      authenticate: authenticate,
      onAuthenticated: () {
        authenticated = true;
        Navigator.of(context).pop();
      },
    ),
  );
  return authenticated;
}

class _GatewayLoginForm extends StatefulWidget {
  const _GatewayLoginForm({
    required this.authenticate,
    required this.onAuthenticated,
  });

  final Future<void> Function({
    required String baseUrl,
    required String username,
    required String password,
  })
  authenticate;
  final VoidCallback onAuthenticated;

  @override
  State<_GatewayLoginForm> createState() => _GatewayLoginFormState();
}

class _GatewayLoginFormState extends State<_GatewayLoginForm> {
  final _url = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  var _loading = false;
  String? _error;

  @override
  void dispose() {
    _url.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_username.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Informe usuário e senha do Dashboard.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.authenticate(
        baseUrl: _url.text,
        username: _username.text,
        password: _password.text,
      );
      if (mounted) widget.onAuthenticated();
    } on GatewayOperationException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível autorizar o Dashboard.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    InputDecoration decoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: t.mono.copyWith(fontSize: 12, color: t.faint),
      filled: true,
      fillColor: t.bg2,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: t.line),
        borderRadius: BorderRadius.circular(13),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: t.accent),
        borderRadius: BorderRadius.circular(13),
      ),
    );

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'O arquivo sai deste aparelho somente depois da sua confirmação. '
            'O login fica protegido pelo armazenamento seguro do aparelho e '
            'renova a sessão do Dashboard sem pedir a senha novamente.',
            style: t.serif.copyWith(fontSize: 15, height: 1.4, color: t.dim),
          ),
          const SizedBox(height: 18),
          TextField(
            key: const ValueKey('dashboard-url'),
            controller: _url,
            keyboardType: TextInputType.url,
            autocorrect: false,
            enableSuggestions: false,
            style: t.mono.copyWith(fontSize: 12, color: t.ink),
            decoration: decoration('HTTPS ou HTTP em *.ts.net'),
          ),
          const SizedBox(height: 11),
          TextField(
            key: const ValueKey('dashboard-username'),
            controller: _username,
            autofillHints: const [AutofillHints.username],
            textInputAction: TextInputAction.next,
            autocorrect: false,
            enableSuggestions: false,
            style: t.mono.copyWith(fontSize: 12, color: t.ink),
            decoration: decoration('Usuário'),
          ),
          const SizedBox(height: 11),
          TextField(
            key: const ValueKey('dashboard-password'),
            controller: _password,
            autofillHints: const [AutofillHints.password],
            obscureText: true,
            onSubmitted: (_) => _loading ? null : _submit(),
            style: t.mono.copyWith(fontSize: 12, color: t.ink),
            decoration: decoration('Senha'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 11),
            Text(
              _error!,
              key: const ValueKey('dashboard-login-error'),
              style: t.serif.copyWith(fontSize: 14, color: t.accentInk),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton(
            key: const ValueKey('dashboard-login-submit'),
            onPressed: _loading ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: t.accent,
              foregroundColor: t.bg,
              minimumSize: const Size.fromHeight(48),
            ),
            child: _loading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: t.bg,
                    ),
                  )
                : const Text('Autorizar envio'),
          ),
        ],
      ),
    );
  }
}
