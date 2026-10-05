import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/domain/models/plain_text.dart';

/// A33: o "texto bruto" é o que está **na tela**, não o markdown sem marcação.
void main() {
  test('tira a marcação de ênfase e de título', () {
    expect(markdownToPlainText('# Título'), 'Título');
    expect(markdownToPlainText('### Outro'), 'Outro');
    expect(markdownToPlainText('um **negrito** e um *itálico*'), 'um negrito e um itálico');
    expect(markdownToPlainText('***os dois***'), 'os dois');
    expect(markdownToPlainText('um ~~riscado~~'), 'um riscado');
  });

  test('sublinhado no meio de identificador não é ênfase', () {
    // `run_stop` e `session_id` aparecem o tempo todo numa resposta técnica.
    expect(markdownToPlainText('use run_stop e session_id'), 'use run_stop e session_id');
    expect(markdownToPlainText('um _itálico_ aqui'), 'um itálico aqui');
  });

  test('código inline perde a crase e mantém o conteúdo', () {
    expect(markdownToPlainText('chame `run_stop` agora'), 'chame run_stop agora');
    // O `**` dentro do código é código, não negrito.
    expect(markdownToPlainText('o operador `a**b` existe'), 'o operador a**b existe');
  });

  test('bloco de código sai inteiro, sem a cerca', () {
    const fonte = 'antes\n\n```dart\nvoid main() {\n  print("oi");\n}\n```\n\ndepois';
    expect(
      markdownToPlainText(fonte),
      'antes\n\nvoid main() {\n  print("oi");\n}\n\ndepois',
    );
  });

  test('link leva o endereço junto', () {
    // Na tela o endereço mora no toque; num texto colado ele não se recupera.
    expect(
      markdownToPlainText('veja [a doc](https://x.dev/a)'),
      'veja a doc (https://x.dev/a)',
    );
    expect(
      markdownToPlainText('veja [https://x.dev](https://x.dev)'),
      'veja https://x.dev',
    );
    expect(markdownToPlainText('![gato](https://x.dev/g.png)'), 'gato (https://x.dev/g.png)');
  });

  test('lista, tarefa e filete viram o que está desenhado', () {
    expect(markdownToPlainText('- um\n- dois'), '• um\n• dois');
    expect(markdownToPlainText('- um\n  - aninhado'), '• um\n  • aninhado');
    expect(markdownToPlainText('- [x] feita\n- [ ] pendente'), '☑ feita\n☐ pendente');
    expect(markdownToPlainText('---'), '❦');
    expect(markdownToPlainText('1. primeiro'), '1. primeiro');
  });

  test('citação perde o sinal de maior', () {
    expect(markdownToPlainText('> a regra de ouro'), 'a regra de ouro');
  });

  test('tabela vira colunas separadas por tabulação', () {
    const fonte = '| API | Estado |\n| --- | --- |\n| Runs | servidor |';
    expect(markdownToPlainText(fonte), 'API\tEstado\nRuns\tservidor');
  });

  test('fórmula cola como aparece, não como LaTeX', () {
    // Mesmo conversor da tela (A31): o que se lê é o que se cola.
    expect(
      markdownToPlainText(r'cresce como $O(\log n)$ no total'),
      'cresce como O(log n) no total',
    );
  });

  test('preço continua preço', () {
    expect(markdownToPlainText(r'de R$50 a R$80'), r'de R$50 a R$80');
  });

  test('não sobra linha em branco dupla nem borda', () {
    expect(markdownToPlainText('\n\n# Oi\n\n\n\ntchau\n\n'), 'Oi\n\ntchau');
  });
}
