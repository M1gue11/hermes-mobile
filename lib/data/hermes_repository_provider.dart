import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/repositories/hermes_repository.dart';

part 'hermes_repository_provider.g.dart';

/// Provider do [HermesRepository]: a "costura" de injeção de dependência.
///
/// O pareamento injeta o adapter HTTP nesta costura antes de montar o app.
/// Testes também a sobrescrevem com um fake determinístico de teste.
@Riverpod(keepAlive: true)
HermesRepository hermesRepository(Ref ref) => throw StateError(
      'HermesRepository precisa ser fornecido após o pareamento.',
    );
