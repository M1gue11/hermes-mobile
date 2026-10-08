import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/notifications/push_notice.dart';
import 'push_store.dart';
import 'unifiedpush_adapter.dart';

class PushController extends ChangeNotifier {
  PushController({
    required this.adapter,
    required this.store,
    required this.android,
  });
  final PushAdapter adapter;
  final PushStore store;
  final bool android;
  final receiver = PushNoticeReceiver();
  static const backend =
      'Backend pendente — enrollment autenticado ainda não existe';
  Map<String, dynamic> _saved = {};
  Future<void> _tail = Future.value();
  int _pendingMessages = 0;
  bool _suppressed = false;
  bool initialized = false;
  bool startupHealthy = false;
  bool distributorRegistered = false;
  String status = 'Desligado';
  List<String> choices = [];
  bool get optedIn => !_suppressed && _saved['opt_in'] == true;
  bool get hasEndpoint => _saved['endpoint'] is Map;
  String? get selected =>
      _saved['distributor'] is String ? _saved['distributor'] as String : null;

  /// Every callback returns immediately; work is serialized and errors redacted.
  Future<void> _enqueue(Future<void> Function() work) {
    _tail = _tail.then((_) async {
      try {
        await work();
      } catch (_) {
        status = 'Falha — tente novamente';
      }
      notifyListeners();
    });
    return _tail;
  }

  Future<void> get settled => _tail;
  Future<void> _save(Map<String, dynamic> next) async {
    await store.write(next);
    _saved = next;
  }

  bool _ours(String instance) => instance == OfficialPushAdapter.instance;

  Future<void> start({bool background = false}) => _enqueue(() async {
    initialized = false;
    startupHealthy = false;
    if (!android) {
      status = 'Unsupported — somente Android';
      return;
    }
    _saved = await store.read();
    distributorRegistered = await adapter.initialize(
      PushCallbacks(
        endpoint: (endpoint, instance) {
          if (!_ours(instance)) return;
          unawaited(
            _enqueue(() async {
              _saved = await store.read();
              if (!optedIn || selected == null) return;
              // Do not expose URL or key material through state, logs or UI.
              final uri = Uri.tryParse(endpoint.url);
              if (uri == null ||
                  uri.scheme != 'https' ||
                  uri.host.isEmpty ||
                  uri.userInfo.isNotEmpty ||
                  endpoint.pubKeySet == null) {
                status = 'Endpoint inválido';
                return;
              }
              await _save({
                ..._saved,
                'endpoint': {
                  'url': endpoint.url,
                  'pub_key': endpoint.pubKeySet!.pubKey,
                  'auth': endpoint.pubKeySet!.auth,
                  'temporary': endpoint.temporary,
                },
              });
              status = endpoint.temporary
                  ? 'Endpoint temporário — backend pendente'
                  : 'Endpoint recebido — backend pendente';
            }),
          );
        },
        failed: (_, instance) {
          if (_ours(instance)) {
            unawaited(
              _enqueue(() async {
                distributorRegistered = false;
                status =
                    'Registro falhou — ação no distribuidor pode ser necessária';
              }),
            );
          }
        },
        unregistered: (instance) {
          if (_ours(instance)) {
            _suppressed = true;
            distributorRegistered = false;
            status = 'Desregistrado — limpeza local pendente';
            unawaited(
              _enqueue(() async {
                _saved = await store.read();
                await _save(
                  {..._saved, 'opt_in': false}
                    ..remove('endpoint')
                    ..remove('distributor'),
                );
                distributorRegistered = false;
                status = 'Desregistrado';
              }),
            );
          }
        },
        message: (message, instance) {
          if (!_ours(instance) || _suppressed) return;
          // Bound before queueing: never retain an oversized payload in the queue.
          if (!message.decrypted ||
              message.content.length > PushNotice.maxBytes ||
              _pendingMessages >= 32) {
            return;
          }
          _pendingMessages++;
          unawaited(
            _enqueue(() async {
              _saved = await store.read();
              if (!optedIn || selected == null) return;
              receiver.receive(
                selected!,
                message.content,
                decrypted: message.decrypted,
              );
            }).whenComplete(() => _pendingMessages--),
          );
        },
        unavailable: (instance) {
          if (_ours(instance)) {
            unawaited(
              _enqueue(() async {
                status = 'Temporariamente indisponível';
              }),
            );
          }
        },
      ),
    );
    initialized = true;
    if (!optedIn) {
      startupHealthy = true;
      status = 'Desligado';
      return;
    }
    status = 'Escolha um distribuidor';
    if (!background) {
      choices = await adapter.distributors();
      if (selected != null && await adapter.distributor() == selected) {
        distributorRegistered = false;
        status = 'Registro solicitado — backend pendente';
        await adapter.register();
        distributorRegistered = true;
      }
    }
    startupHealthy = true;
  });

  Future<void> enable() => _enqueue(() async {
    if (!android || !initialized) return;
    if (!optedIn && selected != null) {
      status = 'Revogação pendente — desregistre antes de reativar';
      return;
    }
    await _save({..._saved, 'opt_in': true});
    _suppressed = false;
    choices = await adapter.distributors();
    status = 'Escolha um distribuidor';
  });

  Future<void> choose({
    String? distributor,
    bool defaultChoice = false,
  }) => _enqueue(() async {
    if (!android || !initialized || !optedIn) return;
    // Switching requires explicit revocation first; never orphan a registration.
    if (selected != null) {
      status = 'Desative antes de trocar distribuidor';
      return;
    }
    if (defaultChoice) {
      if (!await adapter.useDefault()) {
        status = 'Nenhum distribuidor padrão';
        return;
      }
      distributor = await adapter.distributor();
    } else {
      choices = await adapter.distributors();
      if (distributor == null || !choices.contains(distributor)) {
        status = 'Distribuidor indisponível';
        return;
      }
      await adapter.select(distributor!);
    }
    if (distributor == null) {
      status = 'Escolha um distribuidor';
      return;
    }
    await _save({..._saved, 'distributor': distributor});
    status = 'Registro solicitado — backend pendente';
    await adapter.register();
    distributorRegistered = true;
  });

  Future<void> retryRegistration() => _enqueue(() async {
    if (!android || !initialized || !optedIn || selected == null) return;
    status = 'Registro solicitado — backend pendente';
    await adapter.register();
    distributorRegistered = true;
    startupHealthy = true;
  });

  Future<void> revoke() {
    // Suppress synchronously, including work already waiting in the queue.
    _suppressed = true;
    return _enqueue(() async {
      if (!android || !initialized) return;
      // Persist delivery suppression BEFORE unregister. Keep endpoint on failure.
      await _save({..._saved, 'opt_in': false});
      status = 'Revogação pendente';
      await adapter.unregister();
      await _save(
        {..._saved}
          ..remove('endpoint')
          ..remove('distributor'),
      );
      distributorRegistered = false;
      status = 'Desligado';
    });
  }
}
