import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/repositories/attachment_source.dart';
import '../domain/repositories/gateway_repository.dart';

part 'gateway_repository_provider.g.dart';

@Riverpod(keepAlive: true)
GatewayRepository gatewayRepository(Ref ref) => throw StateError(
  'GatewayRepository precisa ser fornecido após o pareamento.',
);

@Riverpod(keepAlive: true)
AttachmentSource attachmentSource(Ref ref) =>
    throw StateError('AttachmentSource precisa ser fornecido pela plataforma.');
