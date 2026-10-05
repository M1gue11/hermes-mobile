import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/data/config/app_settings_store.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('persiste e restaura todas as preferências locais', () async {
    const store = SecureAppSettingsStore();
    await store.save((
      agentGender: 'feminine',
      agentName: 'Cláudia',
      atmosphere: 'jornal',
      chronologicalActivity: true,
      spinner: 'dots',
      textSize: 'maior',
      showActivity: false,
      instructions: 'Seja objetivo.',
    ));

    final restored = await store.read();
    expect(restored?.agentGender, 'feminine');
    expect(restored?.agentName, 'Cláudia');
    expect(restored?.atmosphere, 'jornal');
    expect(restored?.chronologicalActivity, isTrue);
    expect(restored?.spinner, 'dots');
    expect(restored?.textSize, 'maior');
    expect(restored?.showActivity, isFalse);
    expect(restored?.instructions, 'Seja objetivo.');
  });

  test('documento corrompido cai nos padrões sem lançar', () async {
    FlutterSecureStorage.setMockInitialValues({
      SecureAppSettingsStore.storageKey: '{quebrado',
    });

    expect(await const SecureAppSettingsStore().read(), isNull);
  });
}
