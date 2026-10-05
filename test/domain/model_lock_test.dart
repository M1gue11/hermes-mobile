import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/domain/models/model_lock.dart';

/// A21.2: contrato de `POST /api/sessions/{id}/model`, medido em
/// `_handle_session_model_lock` (`gateway/platforms/api_server.py:3611`) e nos
/// auxiliares `_session_runtime_request_from_body` e `_runtime_lock_error`.
void main() {
  group('ModelLock', () {
    test('o corpo não manda require_model_lock, que o handler força', () {
      const lock = ModelLock(model: 'hermes-4-70b', provider: 'nous');
      expect(lock.toRequest(), {'model': 'hermes-4-70b', 'provider': 'nous'});
    });

    test('provider ausente ou vazio sai do corpo', () {
      expect(const ModelLock(model: 'hermes-agent').toRequest(), {'model': 'hermes-agent'});
      expect(
        const ModelLock(model: 'hermes-agent', provider: '').toRequest(),
        {'model': 'hermes-agent'},
      );
    });

    test('lê o par que o servidor confirmou no runtime', () {
      final lock = ModelLock.fromRuntime(const {
        'provider': 'openai-codex',
        'model': 'gpt-5.6-terra',
        'model_lock': 'accepted',
      });
      expect(lock.model, 'gpt-5.6-terra');
      expect(lock.provider, 'openai-codex');
      expect(lock.label, 'openai-codex/gpt-5.6-terra');
    });

    test('rótulo sem provider é só o modelo', () {
      expect(const ModelLock(model: 'hermes-agent').label, 'hermes-agent');
    });
  });

  group('modelLockFailureFrom', () {
    test('409 e model_lock_unavailable são a recusa de rota', () {
      // O handler responde 409 com esse código e a mensagem "refusing silent
      // global fallback": ele prefere recusar a cair no modelo global.
      expect(
        modelLockFailureFrom(statusCode: 409, code: 'model_lock_unavailable'),
        ModelLockFailure.naoRoteavel,
      );
      // O código vale mesmo se o status vier diferente, e vice-versa.
      expect(
        modelLockFailureFrom(statusCode: 500, code: 'model_lock_unavailable'),
        ModelLockFailure.naoRoteavel,
      );
      expect(modelLockFailureFrom(statusCode: 409), ModelLockFailure.naoRoteavel);
    });

    test('os demais códigos do handler', () {
      expect(
        modelLockFailureFrom(statusCode: 400, code: 'missing_model'),
        ModelLockFailure.semModelo,
      );
      expect(modelLockFailureFrom(statusCode: 404), ModelLockFailure.sessaoInexistente);
      expect(
        modelLockFailureFrom(statusCode: 500, code: 'model_lock_persistence_failed'),
        ModelLockFailure.falhaDoServidor,
      );
      expect(modelLockFailureFrom(), ModelLockFailure.falhaDoServidor);
    });
  });

  group('mensagem da recusa', () {
    test('a recusa de rota explica que não houve troca silenciosa', () {
      final texto = modelLockFailureMessage(
        ModelLockFailure.naoRoteavel,
        const ModelLock(model: 'claude-opus-5', provider: 'anthropic'),
      );
      expect(texto, contains('anthropic/claude-opus-5'));
      expect(texto, contains('recusou'));
    });

    test('a exceção do domínio carrega a mensagem pronta', () {
      const recusa = ModelLockException(
        failure: ModelLockFailure.naoRoteavel,
        requested: ModelLock(model: 'x', provider: 'y'),
      );
      expect(recusa.message, contains('y/x'));
      expect(recusa.toString(), contains('naoRoteavel'));
    });
  });
}
