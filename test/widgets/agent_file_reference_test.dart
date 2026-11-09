import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/hermes_tokens.dart';
import 'package:hermes_mobile/data/gateway_repository_provider.dart';
import 'package:hermes_mobile/data/platform/device_agent_file_saver.dart';
import 'package:hermes_mobile/domain/models/agent_file.dart';
import 'package:hermes_mobile/domain/repositories/agent_file_saver.dart';
import 'package:hermes_mobile/domain/repositories/gateway_repository.dart';
import 'package:hermes_mobile/features/chat/widgets/agent_file_reference.dart';

import '../support/fake_gateway_repository.dart';

const _path = '/srv/relatório.pdf';
final _theme = ThemeData(
  extensions: const [
    HermesTokens(
      bg: Color(0xFF15120E),
      bg2: Color(0xFF1E1913),
      surface: Color(0xFF241E17),
      line: Color(0xFFE9E0CD),
      ink: Color(0xFFECE3D2),
      dim: Color(0xFFA99F8C),
      faint: Color(0xFF6E655A),
      accent: Color(0xFFD8A24A),
      accentInk: Color(0xFFC36A44),
      positive: Color(0xFF5FBF7F),
      codeBg: Color(0xFF100D09),
      codeInline: Color(0xFF100D09),
      cKey: Colors.orange,
      cStr: Colors.green,
      cNum: Colors.orange,
      cFn: Colors.yellow,
      cType: Colors.blue,
      serif: TextStyle(),
      mono: TextStyle(),
    ),
  ],
);

void main() {
  Future<void> mount(
    WidgetTester tester,
    FakeGatewayRepository gateway,
    _Saver saver, {
    double scale = 1,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gatewayRepositoryProvider.overrideWithValue(gateway),
          agentFileSaverProvider.overrideWithValue(saver),
        ],
        child: MaterialApp(
          theme: _theme,
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: const SingleChildScrollView(
                child: AgentFileReference(path: _path),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('downloads only on tap, exports then removes private temporary', (
    tester,
  ) async {
    final gateway = FakeGatewayRepository()
      ..midias[_path] = Uint8List.fromList([1, 2, 3]);
    final saver = _Saver();
    await mount(tester, gateway, saver);
    expect(gateway.arquivosBaixados, isEmpty);
    await tester.runAsync(() async {
      await tester.tap(find.text('Baixar arquivo'));
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pumpAndSettle();
    expect(gateway.arquivosBaixados, [_path]);
    expect(saver.bytes, [1, 2, 3]);
    expect(saver.name, 'relatório.pdf');
    expect(find.text('Salvo · 3 B'), findsOneWidget);
    expect(File(saver.path!).existsSync(), isFalse);
    expect(File(saver.path!).parent.existsSync(), isFalse);
  });

  testWidgets('refusal stays beside filename and can be retried at 180% text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final gateway = FakeGatewayRepository()
      ..downloadHandler =
          ({
            required path,
            required destination,
            required onProgress,
            required cancelled,
          }) async => throw const GatewayOperationException(
            'O servidor não permite baixar este arquivo.',
          );
    final saver = _Saver();
    await mount(tester, gateway, saver, scale: 1.8);
    await tester.runAsync(() async {
      await tester.tap(find.text('Baixar arquivo'));
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pumpAndSettle();
    expect(
      find.text('O servidor não permite baixar este arquivo.'),
      findsOneWidget,
    );
    expect(find.text('Baixar arquivo'), findsOneWidget);
    expect(saver.path, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'leaving cancels in-flight download and deletes its partial file',
    (tester) async {
      final started = Completer<void>();
      final cancelledDownload = Completer<void>();
      String? partial;
      final gateway = FakeGatewayRepository()
        ..downloadHandler =
            ({
              required path,
              required destination,
              required onProgress,
              required cancelled,
            }) async {
              partial = destination;
              File(destination).writeAsBytesSync([1]);
              started.complete();
              await cancelled;
              cancelledDownload.complete();
              throw const AgentFileDownloadCancelled();
            };
      await mount(tester, gateway, _Saver());
      await tester.tap(find.text('Baixar arquivo'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      expect(started.isCompleted, isTrue);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      expect(cancelledDownload.isCompleted, isTrue);
      expect(File(partial!).existsSync(), isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}

class _Saver implements AgentFileSaver {
  String? path;
  String? name;
  List<int>? bytes;
  @override
  Future<bool> save({
    required String localPath,
    required String name,
    required String mimeType,
  }) async {
    path = localPath;
    this.name = name;
    bytes = await File(localPath).readAsBytes();
    return true;
  }
}
