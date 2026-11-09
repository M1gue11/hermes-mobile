import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/agent_file_saver.dart';

final agentFileSaverProvider = Provider<AgentFileSaver>(
  (ref) => DeviceAgentFileSaver(),
);

class DeviceAgentFileSaver implements AgentFileSaver {
  static const _channel = MethodChannel('hermes_mobile/files');

  @override
  Future<bool> save({
    required String localPath,
    required String name,
    required String mimeType,
  }) async =>
      await _channel.invokeMethod<bool>('save', {
        'path': localPath,
        'name': name,
        'mimeType': mimeType,
      }) ??
      false;
}
