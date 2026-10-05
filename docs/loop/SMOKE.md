# Roteiro de smoke no emulador

Este arquivo guarda somente procedimentos reutilizáveis e o percurso mínimo da
build atual. Aceites manuais específicos ficam em [USER_TESTING.md](USER_TESTING.md).
Registre resultados de aceites no backlog e na mudança correspondente.

## Instalar a build atual

```powershell
flutter build apk --debug
adb -s emulator-5554 install -r build\app\outputs\flutter-apk\app-debug.apk
adb -s emulator-5554 shell am start -n com.example.hermes_mobile/.MainActivity
```

Prefira `flutter build apk` com `install -r` a `flutter run`, pois o processo em
segundo plano não informa de modo confiável se compilou. Use `--release` quando
estiver avaliando tipografia ou desempenho e `--debug` para desenvolvimento.

Para conferir que a instalação nova pegou:

```powershell
Get-ChildItem build\app\outputs\flutter-apk\ | Select-Object Name,LastWriteTime
```

O pareamento sobrevive a `install -r`, porque a conexão fica no
`flutter_secure_storage` e os dados do app são preservados. Se a tela de conexão
aparecer, pare e peça ao usuário para preencher a chave no aparelho.

## Capturar tela

```powershell
adb -s emulator-5554 shell screencap -p /sdcard/shot.png
adb -s emulator-5554 pull /sdcard/shot.png <destino>.png
```

Use esse par, e não `adb exec-out screencap -p > arquivo.png`: o redirecionamento
do PowerShell pode tratar a saída como texto e corromper o PNG.

## Interagir

```powershell
adb -s emulator-5554 shell input tap <x> <y>
adb -s emulator-5554 shell input swipe 670 1800 670 500 120
adb -s emulator-5554 shell input swipe 670 600 670 1900 130
adb -s emulator-5554 shell "dumpsys activity activities | grep topResumedActivity"
```

Uma imagem lida pode vir reduzida; ajuste as coordenadas ao tamanho efetivo
antes de usar `tap`. `input text`
não aceita espaço: use `%s`. Depois de digitar, dispense o Gboard antes da
captura com `keyevent 4`, lembrando que na conversa isso também pode voltar para
a lista.

## Percurso mínimo

1. A lista abre com `GATEWAY · ONLINE` e sessões reais, quando houver conexão.
2. Filtros e abertura de conversa não exibem bolhas vazias nem uma sessão vazia
   duplicada.
3. Uma conversa longa abre no fim; envio, streaming e cancelamento preservam a
   ordem e o conteúdo visível.
4. Renomear, excluir e voltar para a lista persistem depois de reabrir a rota.
5. Executar somente os casos afetados da fila em [USER_TESTING.md](USER_TESTING.md)
   e registrar o resultado no backlog antes de remover o roteiro aceito.

## Segurança

Nunca use `adb input text` para senha, chave, cookie ou ticket. Segredos não
entram em terminal, log, screenshot, teste ou documentação. O usuário deve
preencher qualquer credencial no aparelho.
