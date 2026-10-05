import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Spinners Unicode em braille - porta fiel do gerador `UA` do protótipo
/// (design/Hermes.dc.html). Cada spinner é uma lista de frames (strings de
/// caracteres braille U+2800..U+28FF) tocados num intervalo próprio.
///
/// A marca do Hermes aparece animada ao final de cada resposta (e no empty
/// state / lista). O usuário pode escolher o estilo no sheet de Aparência.
class SpinnerDef {
  const SpinnerDef(this.interval, this.frames);
  final int interval; // ms entre frames
  final List<String> frames;
}

/// Mapa nome -> definição, em ordem de inserção (usado na grade de Aparência).
/// `helix` é o padrão.
final Map<String, SpinnerDef> kUnicodeSpinners = _buildSpinners();

// --- gerador (porta do UA em JS) -------------------------------------------

// [linha, colunaOffset, bit] no padrão de pontos do braille.
const List<List<int>> _bits = [
  [0, 0, 1],
  [1, 0, 2],
  [2, 0, 4],
  [0, 1, 8],
  [1, 1, 16],
  [2, 1, 32],
  [3, 0, 64],
  [3, 1, 128],
];

/// Converte uma grade 4x4 (g[linha][coluna]) em 2 caracteres braille.
String _toB(List<List<int>> g) {
  final buf = StringBuffer();
  for (var c = 0; c < 4; c += 2) {
    var code = 0;
    for (var i = 0; i < 8; i++) {
      final b = _bits[i];
      if (g[b[0]][c + b[1]] != 0) code |= b[2];
    }
    buf.writeCharCode(0x2800 + code);
  }
  return buf.toString();
}

/// Gera [n] frames, cada um com uma grade 4x4 zerada passada a [fn].
List<String> _f(int n, void Function(List<List<int>> g, int f) fn) {
  final frames = <String>[];
  for (var f = 0; f < n; f++) {
    final g = List.generate(4, (_) => List.filled(4, 0));
    fn(g, f);
    frames.add(_toB(g));
  }
  return frames;
}

/// PRNG determinístico (fract(sin(i*k)*k2)), idêntico ao do design.
double _rnd(num i) {
  final x = math.sin(i * 12.9898) * 43758.5453;
  return x - x.floorToDouble();
}

/// Janelas deslizantes de tamanho [n] sobre [seq]+[seq].
List<String> _win(String seq, int n) {
  final frames = <String>[];
  final doubled = seq + seq;
  for (var i = 0; i < seq.length; i++) {
    frames.add(doubled.substring(i, i + n));
  }
  return frames;
}

int _clamp(num v) => math.max(0, math.min(3, v.round()));

Map<String, SpinnerDef> _buildSpinners() {
  final s = <String, SpinnerDef>{};

  s['braille'] = SpinnerDef(80, '⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'.split(''));
  s['braillewave'] = SpinnerDef(100, _win('⠁⠂⠄⡀⢀⠠⠐⠈', 4));
  s['dna'] = SpinnerDef(80, _win('⠋⠉⠙⠚⠒⠂⠒⠲⠴⠦⠖⠒', 4));
  s['scan'] = SpinnerDef(70, _f(8, (g, f) {
    final p = f < 4 ? f : 7 - f;
    for (var r = 0; r < 4; r++) {
      g[r][p] = 1;
    }
  }));
  s['rain'] = SpinnerDef(100, _f(12, (g, f) {
    for (var c = 0; c < 4; c++) {
      final o = (_rnd(c + 1) * 12).floor();
      var r = (f + o) % 6;
      if (r < 4) g[r][c] = 1;
      r = (f + o + 3) % 7;
      if (r < 4) g[r][c] = 1;
    }
  }));
  s['scanline'] = SpinnerDef(120, _f(6, (g, f) {
    final p = f < 4 ? f : 7 - f;
    for (var c = 0; c < 4; c++) {
      g[p][c] = 1;
    }
  }));
  s['pulse'] = SpinnerDef(180, _f(5, (g, f) {
    final st = [0, 1, 2, 1, 0][f];
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        final d = math.max((r - 1.5).abs(), (c - 1.5).abs());
        if ((st == 0 && d < 1) || (st == 1 && d > 1) || st == 2) g[r][c] = 1;
      }
    }
  }));
  s['snake'] = SpinnerDef(80, _f(16, (g, f) {
    final ord = <List<int>>[];
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        ord.add([r, r % 2 != 0 ? 3 - c : c]);
      }
    }
    for (var k = 0; k < 4; k++) {
      final p = ord[(f - k + 16) % 16];
      g[p[0]][p[1]] = 1;
    }
  }));
  s['sparkle'] = SpinnerDef(150, _f(6, (g, f) {
    for (var i = 0; i < 16; i++) {
      if (_rnd(f * 16 + i + 31) < 0.28) g[i ~/ 4][i % 4] = 1;
    }
  }));
  s['cascade'] = SpinnerDef(60, _f(12, (g, f) {
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        if (((f - r - c) % 12 + 12) % 12 < 5) g[r][c] = 1;
      }
    }
  }));
  s['columns'] = SpinnerDef(60, _f(26, (g, f) {
    for (var c = 0; c < 4; c++) {
      final h = (2 + 1.9 * math.sin(6.283 * f / 13 + c * 1.7)).round();
      for (var r = 0; r < 4; r++) {
        if (r >= 4 - h) g[r][c] = 1;
      }
    }
  }));
  s['orbit'] = SpinnerDef(100, _f(8, (g, f) {
    const ring = [
      [0, 1], [0, 2], [1, 3], [2, 3], [3, 2], [3, 1], [2, 0], [1, 0],
    ];
    for (var k = 0; k < 3; k++) {
      final p = ring[(f - k + 8) % 8];
      g[p[0]][p[1]] = 1;
    }
  }));
  s['breathe'] = SpinnerDef(100, _f(17, (g, f) {
    final st = [0, 0, 1, 1, 1, 2, 2, 2, 2, 2, 2, 1, 1, 1, 0, 0, 0][f];
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        final d = math.max((r - 1.5).abs(), (c - 1.5).abs());
        if ((st == 1 && d < 1) || st == 2) g[r][c] = 1;
      }
    }
  }));
  s['waverows'] = SpinnerDef(90, _f(16, (g, f) {
    for (var c = 0; c < 4; c++) {
      final r = _clamp(1.5 + 1.4 * math.sin(6.283 * f / 16 + c * 0.8));
      g[r][c] = 1;
    }
  }));
  s['checkerboard'] = SpinnerDef(250, _f(4, (g, f) {
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        if ((r + c + f) % 2 == 0) g[r][c] = 1;
      }
    }
  }));
  s['helix'] = SpinnerDef(80, _f(16, (g, f) {
    for (var c = 0; c < 4; c++) {
      final a = 6.283 * f / 16 + c * 0.9;
      g[_clamp(1.5 + 1.4 * math.sin(a))][c] = 1;
      g[_clamp(1.5 + 1.4 * math.sin(a + 3.1416))][c] = 1;
    }
  }));
  s['fillsweep'] = SpinnerDef(100, _f(11, (g, f) {
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        final lit = f <= 4 ? c < f : (f <= 9 ? c >= f - 5 : false);
        if (lit) g[r][c] = 1;
      }
    }
  }));
  s['diagswipe'] = SpinnerDef(60, _f(16, (g, f) {
    final k = f < 8 ? f : 15 - f;
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        final d = r + c;
        if (d == k || d == k - 1) g[r][c] = 1;
      }
    }
  }));

  return s;
}

/// Renderiza um spinner braille animado. Se [active] for false, congela no
/// primeiro frame (sem timer).
class UnicodeSpinner extends StatefulWidget {
  const UnicodeSpinner({
    super.key,
    this.name = 'helix',
    this.size = 24,
    this.active = true,
    this.color,
    this.glow,
  });

  final String name;
  final double size;
  final bool active;
  final Color? color;

  /// Cor do brilho (text-shadow) atrás do glifo. Null = sem brilho.
  final Color? glow;

  @override
  State<UnicodeSpinner> createState() => _UnicodeSpinnerState();
}

class _UnicodeSpinnerState extends State<UnicodeSpinner> {
  Timer? _timer;
  int _frame = 0;

  SpinnerDef get _def => kUnicodeSpinners[widget.name] ?? kUnicodeSpinners['helix']!;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  @override
  void didUpdateWidget(UnicodeSpinner old) {
    super.didUpdateWidget(old);
    if (old.name != widget.name || old.active != widget.active) {
      _timer?.cancel();
      _frame = 0;
      _arm();
    }
  }

  void _arm() {
    if (!widget.active) return;
    _timer = Timer.periodic(Duration(milliseconds: _def.interval), (_) {
      if (mounted) setState(() => _frame++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final def = _def;
    final txt = widget.active
        ? def.frames[_frame % def.frames.length]
        : def.frames.first;
    final wide = txt.length > 1;
    final s = widget.size;
    final color = widget.color ?? DefaultTextStyle.of(context).style.color;

    return SizedBox(
      width: s,
      height: s,
      child: OverflowBox(
        alignment: Alignment.center,
        minWidth: 0,
        maxWidth: double.infinity,
        child: Text(
          txt,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          style: TextStyle(
            fontFamily: 'monospace',
            fontFamilyFallback: const ['JetBrains Mono', 'Courier'],
            fontWeight: FontWeight.w700,
            fontSize: wide ? s * 0.72 : s * 1.02,
            height: 1,
            letterSpacing: wide ? -0.06 * s : 0,
            color: color,
            shadows: (widget.active && widget.glow != null)
                ? [Shadow(color: widget.glow!, blurRadius: (s * 0.45).roundToDouble())]
                : null,
          ),
        ),
      ),
    );
  }
}
