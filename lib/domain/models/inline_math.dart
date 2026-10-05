/// Um pedaço de fórmula já convertido para texto legível.
///
/// [variavel] diz se o pedaço é uma letra de variável, que a notação
/// matemática grafa em itálico, ou texto reto como número, operador, parêntese
/// e nome de função (`log`, `sin`). É a mesma distinção que o KaTeX faz no
/// mock, e é ela que faz `O(log n)` parecer fórmula em vez de frase.
typedef MathRun = ({String text, bool variavel});

/// Converte LaTeX simples em pedaços de texto Unicode.
///
/// **Não é um renderizador de LaTeX.** É a fatia que aparece de verdade numa
/// resposta de agente: letras gregas, símbolos, expoentes, índices, frações
/// rasas e nomes de função. O que não estiver na tabela sai como veio, sem a
/// barra invertida, porque um `\oiint` cru continua mais legível que
/// `\oiint` com a barra na cara.
///
/// O mock usa KaTeX (`design/Hermes.dc.html`, `renderMathInElement` com os
/// delimitadores `$$` e `$`). Chegar ao desenho tipográfico do KaTeX exigiria
/// uma biblioteca de layout matemático; isto entrega o texto correto, na fonte
/// certa, sem dependência nova.
List<MathRun> latexRuns(String source) {
  final runs = <MathRun>[];
  void emitir(String texto, {required bool variavel}) {
    if (texto.isEmpty) return;
    if (runs.isNotEmpty && runs.last.variavel == variavel) {
      final anterior = runs.removeLast();
      runs.add((text: anterior.text + texto, variavel: variavel));
      return;
    }
    runs.add((text: texto, variavel: variavel));
  }

  var i = 0;
  while (i < source.length) {
    final c = source[i];

    if (c == '\\') {
      final match = _comando.matchAsPrefix(source, i);
      if (match == null) {
        // `\,` `\;` `\!` e afins: espaçamento fino do LaTeX.
        final proximo = i + 1 < source.length ? source[i + 1] : '';
        emitir(_espacamento[proximo] ?? '', variavel: false);
        i += proximo.isEmpty ? 1 : 2;
        continue;
      }
      final nome = match.group(1)!;
      i = match.end;

      if (nome == 'frac' || nome == 'dfrac' || nome == 'tfrac') {
        final numerador = _grupo(source, i);
        final denominador = _grupo(source, numerador.fim);
        emitir(_entreParenteses(numerador.texto), variavel: false);
        emitir('/', variavel: false);
        emitir(_entreParenteses(denominador.texto), variavel: false);
        i = denominador.fim;
        continue;
      }
      if (nome == 'sqrt') {
        final radicando = _grupo(source, i);
        emitir('√${_entreParenteses(radicando.texto)}', variavel: false);
        i = radicando.fim;
        continue;
      }
      if (nome == 'left' || nome == 'right') continue;
      if (_funcoes.contains(nome)) {
        emitir(nome, variavel: false);
        continue;
      }
      final simbolo = _simbolos[nome];
      // Grega minúscula é variável e vai em itálico, como no KaTeX; símbolo de
      // operação, não.
      emitir(simbolo ?? nome, variavel: simbolo != null && _gregasItalicas.contains(nome));
      continue;
    }

    if (c == '^' || c == '_') {
      final alvo = _grupo(source, i + 1);
      final tabela = c == '^' ? _sobrescrito : _subscrito;
      final convertido = alvo.texto.split('').map((ch) => tabela[ch]).toList();
      if (convertido.every((ch) => ch != null)) {
        emitir(convertido.join(), variavel: false);
      } else {
        emitir('$c${_entreParenteses(alvo.texto)}', variavel: false);
      }
      i = alvo.fim;
      continue;
    }

    if (c == '{' || c == '}') {
      i++;
      continue;
    }

    // Letra solta é variável; o resto é texto reto.
    emitir(c, variavel: _letra.hasMatch(c));
    i++;
  }
  return runs;
}

/// Lê o próximo grupo a partir de [inicio]: `{...}` inteiro ou um caractere.
({String texto, int fim}) _grupo(String source, int inicio) {
  if (inicio >= source.length) return (texto: '', fim: inicio);
  if (source[inicio] != '{') {
    return (texto: source[inicio], fim: inicio + 1);
  }
  var nivel = 0;
  for (var i = inicio; i < source.length; i++) {
    if (source[i] == '{') nivel++;
    if (source[i] == '}') {
      nivel--;
      if (nivel == 0) return (texto: source.substring(inicio + 1, i), fim: i + 1);
    }
  }
  return (texto: source.substring(inicio + 1), fim: source.length);
}

String _entreParenteses(String valor) =>
    valor.length <= 1 ? valor : '($valor)';

final RegExp _comando = RegExp(r'\\([A-Za-z]+)');
final RegExp _letra = RegExp('[A-Za-z]');

/// Espaçamento fino do LaTeX. `\,` e `\:` viram espaço fino de verdade
/// (U+2009), `\!` é espaço negativo e some, `\ ` é espaço comum.
const Map<String, String> _espacamento = {
  ',': ' ',
  ':': ' ',
  ';': ' ',
  '!': '',
  ' ': ' ',
};

/// Nomes de função: o KaTeX grafa em texto reto, não em itálico.
const Set<String> _funcoes = {
  'log', 'ln', 'lg', 'exp', 'sin', 'cos', 'tan', 'cot', 'sec', 'csc',
  'arcsin', 'arccos', 'arctan', 'sinh', 'cosh', 'tanh',
  'max', 'min', 'lim', 'sup', 'inf', 'det', 'dim', 'deg', 'arg', 'gcd',
  'mod', 'bmod', 'Pr', 'ker', 'hom',
};

/// Gregas minúsculas entram como variável; as maiúsculas e os operadores não.
const Set<String> _gregasItalicas = {
  'alpha', 'beta', 'gamma', 'delta', 'epsilon', 'varepsilon', 'zeta', 'eta',
  'theta', 'vartheta', 'iota', 'kappa', 'lambda', 'mu', 'nu', 'xi', 'pi',
  'rho', 'sigma', 'tau', 'upsilon', 'phi', 'varphi', 'chi', 'psi', 'omega',
};

const Map<String, String> _simbolos = {
  'alpha': 'α', 'beta': 'β', 'gamma': 'γ', 'delta': 'δ', 'epsilon': 'ε',
  'varepsilon': 'ε', 'zeta': 'ζ', 'eta': 'η', 'theta': 'θ', 'vartheta': 'ϑ',
  'iota': 'ι', 'kappa': 'κ', 'lambda': 'λ', 'mu': 'μ', 'nu': 'ν', 'xi': 'ξ',
  'pi': 'π', 'rho': 'ρ', 'sigma': 'σ', 'tau': 'τ', 'upsilon': 'υ', 'phi': 'φ',
  'varphi': 'φ', 'chi': 'χ', 'psi': 'ψ', 'omega': 'ω',
  'Gamma': 'Γ', 'Delta': 'Δ', 'Theta': 'Θ', 'Lambda': 'Λ', 'Xi': 'Ξ',
  'Pi': 'Π', 'Sigma': 'Σ', 'Upsilon': 'Υ', 'Phi': 'Φ', 'Psi': 'Ψ',
  'Omega': 'Ω',
  'times': '×', 'div': '÷', 'cdot': '·', 'pm': '±', 'mp': '∓',
  'leq': '≤', 'le': '≤', 'geq': '≥', 'ge': '≥', 'neq': '≠', 'ne': '≠',
  'approx': '≈', 'equiv': '≡', 'sim': '∼', 'propto': '∝',
  'infty': '∞', 'partial': '∂', 'nabla': '∇', 'sum': '∑', 'prod': '∏',
  'int': '∫', 'oint': '∮', 'forall': '∀', 'exists': '∃', 'emptyset': '∅',
  'in': '∈', 'notin': '∉', 'subset': '⊂', 'subseteq': '⊆', 'supset': '⊃',
  'cup': '∪', 'cap': '∩', 'setminus': '∖',
  'rightarrow': '→', 'to': '→', 'leftarrow': '←', 'leftrightarrow': '↔',
  'Rightarrow': '⇒', 'Leftarrow': '⇐', 'Leftrightarrow': '⇔', 'mapsto': '↦',
  'ldots': '…', 'cdots': '⋯', 'dots': '…', 'angle': '∠', 'perp': '⊥',
  'land': '∧', 'lor': '∨', 'neg': '¬', 'oplus': '⊕', 'otimes': '⊗',
  'sqrt': '√', 'degree': '°', 'circ': '∘', 'star': '⋆', 'bullet': '∙',
};

const Map<String, String> _sobrescrito = {
  '0': '⁰', '1': '¹', '2': '²', '3': '³', '4': '⁴', '5': '⁵', '6': '⁶',
  '7': '⁷', '8': '⁸', '9': '⁹', '+': '⁺', '-': '⁻', '=': '⁼', '(': '⁽',
  ')': '⁾', 'n': 'ⁿ', 'i': 'ⁱ', 'a': 'ᵃ', 'b': 'ᵇ', 'c': 'ᶜ', 'd': 'ᵈ',
  'e': 'ᵉ', 'k': 'ᵏ', 'm': 'ᵐ', 'p': 'ᵖ', 't': 'ᵗ', 'x': 'ˣ', 'y': 'ʸ',
  'T': 'ᵀ',
};

const Map<String, String> _subscrito = {
  '0': '₀', '1': '₁', '2': '₂', '3': '₃', '4': '₄', '5': '₅', '6': '₆',
  '7': '₇', '8': '₈', '9': '₉', '+': '₊', '-': '₋', '=': '₌', '(': '₍',
  ')': '₎', 'a': 'ₐ', 'e': 'ₑ', 'h': 'ₕ', 'i': 'ᵢ', 'j': 'ⱼ', 'k': 'ₖ',
  'l': 'ₗ', 'm': 'ₘ', 'n': 'ₙ', 'o': 'ₒ', 'p': 'ₚ', 'r': 'ᵣ', 's': 'ₛ',
  't': 'ₜ', 'u': 'ᵤ', 'v': 'ᵥ', 'x': 'ₓ',
};

/// Trecho de fórmula reconhecido dentro de um texto markdown.
typedef MathSpan = ({int inicio, int fim, String latex, bool display});

/// Acha os trechos `$...$` e `$$...$$` que são **mesmo** fórmula.
///
/// O `$` também é cifrão, e uma frase como "de R$50 a R$80" tem dois deles.
/// Por isso um trecho só conta como fórmula quando traz marca de LaTeX: uma
/// barra invertida, um expoente ou um índice, ou quando vem em `$$`. É uma
/// troca deliberada: perde `$a+b$`, que ninguém escreve, e não transforma preço
/// em fórmula, que acontece toda hora.
List<MathSpan> mathSpans(String source) {
  final achados = <MathSpan>[];
  var i = 0;
  while (i < source.length) {
    if (source[i] != r'$' || (i > 0 && source[i - 1] == r'\')) {
      i++;
      continue;
    }
    final display = i + 1 < source.length && source[i + 1] == r'$';
    final abertura = display ? i + 2 : i + 1;
    final fechamento = display ? source.indexOf(r'$$', abertura) : _fimInline(source, abertura);
    if (fechamento < 0) {
      i++;
      continue;
    }
    final latex = source.substring(abertura, fechamento);
    final fim = display ? fechamento + 2 : fechamento + 1;
    if (_pareceFormula(latex, display: display)) {
      achados.add((inicio: i, fim: fim, latex: latex, display: display));
      i = fim;
      continue;
    }
    i++;
  }
  return achados;
}

int _fimInline(String source, int inicio) {
  for (var i = inicio; i < source.length; i++) {
    if (source[i] == '\n') return -1;
    if (source[i] == r'$' && source[i - 1] != r'\') return i;
  }
  return -1;
}

bool _pareceFormula(String latex, {required bool display}) {
  if (latex.trim().isEmpty || latex.length > 400) return false;
  // Cifrão colado no espaço à direita é preço, não abertura de fórmula.
  if (latex.startsWith(' ') || latex.endsWith(' ')) return false;
  if (display) return true;
  return latex.contains(r'\') || latex.contains('^') || latex.contains('_');
}
