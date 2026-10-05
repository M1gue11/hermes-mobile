import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/domain/models/tool_preview.dart';

/// A8: o argumento persistido tem de ler igual ao `preview` que o servidor
/// manda ao vivo. Os casos abaixo saíram da leitura de `build_tool_preview` e
/// `summarize_shell_command` em `agent/display.py` da versão `0.19.0`, e das
/// linhas que de fato apareceram no aparelho.
void main() {
  test('terminal mostra o comando, não o objeto de argumentos', () {
    // Era isto na tela do histórico: {"command":"date","workdir":"/home/operator…
    expect(
      toolPreview('terminal', '{"command":"date","workdir":"/home/operator"}'),
      'date',
    );
  });

  test('detalhe completo só é extraído para comando e código', () {
    expect(
      toolDetail(
        'terminal',
        '{"command":"unzip pacote.zip arquivo.md","workdir":"/tmp"}',
      ),
      'unzip pacote.zip arquivo.md',
    );
    expect(
      toolDetail('execute_code', '{"code":"print(1)\\nprint(2)"}'),
      'print(1)\nprint(2)',
    );
    expect(
      toolDetail('browser_type', '{"text":"sk-alguma-chave-secreta"}'),
      isEmpty,
    );
    expect(toolDetail('read_file', '{"path":"segredo.md"}'), isEmpty);
  });

  test('comando composto vira o primeiro mais a contagem', () {
    expect(
      toolPreview('terminal', '{"command":"date && uptime && uname -a"}'),
      'date + 2 commands',
    );
  });

  test('encanamento silencioso não conta como comando', () {
    // `cd` e `export` são preparação, não a ação que o usuário quer ler.
    expect(
      toolPreview('terminal', '{"command":"cd /tmp && export A=1 && ls -la"}'),
      'ls -la',
    );
  });

  test('um comando só depois de limpar redirecionamento', () {
    expect(
      toolPreview('terminal', r'{"command":"ls -la > /tmp/out.txt 2>&1"}'),
      'ls -la',
    );
  });

  test('operador dentro de aspas não divide o comando', () {
    expect(
      toolPreview('terminal', '{"command":"echo \'a && b\'"}'),
      "echo 'a && b'",
    );
  });

  test('read_file mostra o nome do arquivo e o intervalo de linhas', () {
    expect(
      toolPreview(
        'read_file',
        '{"limit":45,"offset":90,"path":"/mnt/example/notas.md"}',
      ),
      'notas.md L90-134',
    );
    expect(
      toolPreview('read_file', '{"path":"/mnt/example/notas.md"}'),
      'notas.md',
    );
  });

  test('todo diz o que está fazendo com a lista', () {
    expect(
      toolPreview('todo', '{"todos":[{"content":"a"},{"content":"b"}]}'),
      'planning 2 task(s)',
    );
    expect(
      toolPreview('todo', '{"merge":true,"todos":[{"content":"a"}]}'),
      'updating 1 task(s)',
    );
    expect(toolPreview('todo', '{"status":"all"}'), 'reading task list');
  });

  test('skill_view mostra o nome, e o arquivo quando houver', () {
    expect(
      toolPreview('skill_view', '{"name":"financas-pessoais"}'),
      'financas-pessoais',
    );
    expect(
      toolPreview('skill_view', '{"name":"financas","file_path":"SKILL.md"}'),
      'financas → SKILL.md',
    );
  });

  test('chave primária por ferramenta, e reserva quando não há tabela', () {
    expect(
      toolPreview('search_files', '{"target":"files","pattern":"*Fina*"}'),
      '*Fina*',
    );
    expect(
      toolPreview('write_file', '{"path":"/tmp/a.md","content":"..."}'),
      '/tmp/a.md',
    );
    expect(toolPreview('ferramenta_nova', '{"query":"algo"}'), 'algo');
  });

  test('browser_type não mostra argumento nenhum', () {
    // O caminho ao vivo passa por `redact_tool_args_for_display`; o `arguments`
    // persistido é o cru. Sem o redator do servidor, o app não arrisca.
    expect(
      toolPreview('browser_type', '{"text":"sk-alguma-chave-secreta"}'),
      '',
    );
  });

  test('argumento vazio ou ilegível não vira ruído', () {
    expect(toolPreview('terminal', ''), '');
    expect(toolPreview('terminal', '{}'), '');
    // JSON quebrado ainda mostra algo, encurtado, em vez de sumir com a linha.
    expect(toolPreview('terminal', 'nao e json'), 'nao e json');
  });

  test('linha longa é cortada, não deixada estourar', () {
    final longo = toolPreview('write_file', '{"path":"${'a' * 400}"}');
    expect(longo.length, 120);
    expect(longo.endsWith('...'), isTrue);
  });
}
