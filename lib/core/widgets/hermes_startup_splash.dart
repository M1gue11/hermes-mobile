import 'dart:math';

import 'package:flutter/material.dart';

/// A assinatura de abertura do Hermes.
///
/// A splash do Android segura a chapa escura enquanto o engine sobe. Assim que
/// o Flutter pode desenhar, este widget continua a mesma cena: o H pontilhado
/// é escrito de cima para baixo e o ponto terracota encerra a marca antes de a
/// tela que já estava carregando aparecer. O conteúdo é montado desde o
/// primeiro quadro, portanto a animação nunca acrescenta tempo ao boot.
class HermesStartupSplash extends StatefulWidget {
  const HermesStartupSplash({
    required this.child,
    super.key,
    this.timelineDuration = const Duration(milliseconds: 1150),
    this.handoffPause = const Duration(milliseconds: 120),
    this.fadeDuration = const Duration(milliseconds: 200),
  });

  final Widget child;
  final Duration timelineDuration;
  final Duration handoffPause;
  final Duration fadeDuration;

  @override
  State<HermesStartupSplash> createState() => _HermesStartupSplashState();
}

class _HermesStartupSplashState extends State<HermesStartupSplash>
    with TickerProviderStateMixin {
  late final AnimationController _timeline;
  late final AnimationController _fade;
  var _dismissed = false;

  @override
  void initState() {
    super.initState();
    _timeline = AnimationController(
      vsync: this,
      duration: widget.timelineDuration,
    );
    _fade = AnimationController(vsync: this, duration: widget.fadeDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _dismissed = true);
        }
      });
    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  bool get _reduceMotion {
    final media = MediaQuery.maybeOf(context);
    final features =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures;
    return (media?.disableAnimations ?? features.disableAnimations) ||
        (media?.accessibleNavigation ?? features.accessibleNavigation);
  }

  Future<void> _play() async {
    if (!mounted) return;
    if (_reduceMotion) {
      _timeline.value = 1;
      _fade.value = 1;
      setState(() => _dismissed = true);
      return;
    }

    await _timeline.forward();
    if (!mounted) return;
    await Future<void>.delayed(widget.handoffPause);
    if (!mounted) return;
    await _fade.forward();
  }

  @override
  void dispose() {
    _timeline.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A splash é a raiz do processo e nasce antes do MaterialApp. Ela precisa
    // fornecer explicitamente os ancestrais mínimos usados pelos widgets do
    // próprio overlay, em vez de depender da árvore que está carregando atrás.
    return Directionality(
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      child: Stack(
        alignment: Alignment.topLeft,
        fit: StackFit.expand,
        children: [
          widget.child,
          if (!_dismissed)
            Positioned.fill(
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: FadeTransition(
                    opacity: ReverseAnimation(_fade),
                    child: _HermesSplashArtwork(animation: _timeline),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HermesSplashArtwork extends StatelessWidget {
  const _HermesSplashArtwork({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF100D09),
      child: Stack(
        alignment: Alignment.topLeft,
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: CustomPaint(painter: const _HermesSplashBackgroundPainter()),
          ),
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, _) => CustomPaint(
                painter: _HermesSplashMarkPainter(progress: animation.value),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Papel profundo e a grade que enquadra a marca. Ele nunca repinta durante a
/// animação; somente os 154 pontos ganham novos pixels a cada quadro.
class _HermesSplashBackgroundPainter extends CustomPainter {
  const _HermesSplashBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final background = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0, -0.42),
        radius: 1.12,
        colors: [Color(0xFF241E16), Color(0xFF171309), Color(0xFF100D09)],
        stops: [0, .62, 1],
      ).createShader(rect);
    canvas.drawRect(rect, background);

    final scale = size.width / 1080;
    final pitch = 27.818 * scale;
    final center = Offset(size.width / 2, size.height * .44);
    final radius = max(size.width * .48, size.height * .24);
    final paint = Paint()..color = const Color(0xFFECE3D2);
    for (var y = pitch / 2; y < size.height; y += pitch) {
      for (var x = pitch / 2; x < size.width; x += pitch) {
        final distance = (Offset(x, y) - center).distance / radius;
        final opacity = .1 * pow((1 - distance).clamp(0.0, 1.0), 1.8);
        if (opacity <= .002) continue;
        paint.color = const Color(
          0xFFECE3D2,
        ).withValues(alpha: opacity.toDouble());
        canvas.drawCircle(Offset(x, y), 2.5 * scale, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HermesSplashBackgroundPainter oldDelegate) =>
      false;
}

class _HermesSplashMarkPainter extends CustomPainter {
  _HermesSplashMarkPainter({required this.progress});

  final double progress;

  static final _SplashMark _mark = _SplashMark.build();
  static const _amber = Color(0xFFD8A24A);
  static const _amberPeak = Color(0xFFF6E6C4);
  static const _amberWarm = Color(0xFFF0C070);
  static const _terracotta = Color(0xFFC36A44);
  static const _dotEase = Cubic(.16, .9, .2, 1);
  static const _accentEase = Cubic(.3, 1.6, .5, 1);

  @override
  void paint(Canvas canvas, Size size) {
    final screenScale = size.width / 1080;
    final artScale = .44 * screenScale;
    final artCenter = Offset(size.width / 2, size.height * .44);
    final time = progress * 1150;
    final settle = min(time / 1100, 1.0);
    final markScale = 1.05 - (.05 * Curves.easeOut.transform(settle));

    for (var index = 0; index < _mark.dots.length; index++) {
      final dot = _mark.dots[index];
      final startedAt = 160 + (index * 4.2);
      final raw = ((time - startedAt) / 300).clamp(0.0, 1.0).toDouble();
      if (raw == 0) continue;
      final entered = _dotEase.transform(raw);
      final point =
          artCenter +
          Offset(
            (dot.x - 512) * artScale * markScale,
            (dot.y - 512) * artScale * markScale +
                ((1 - entered) * 18 * screenScale),
          );
      final dotScale = raw < .58
          ? .3 + ((1.26 - .3) * (raw / .58))
          : 1.26 - (.26 * ((raw - .58) / .42));
      final color = raw < .46
          ? Color.lerp(_amberPeak, _amberWarm, raw / .46)!
          : Color.lerp(_amberWarm, _amber, (raw - .46) / .54)!;
      final paint = Paint()..color = color.withValues(alpha: entered);
      canvas.drawCircle(
        point,
        dot.radius * artScale * markScale * dotScale,
        paint,
      );
    }

    final accentRaw = ((time - 830) / 300).clamp(0.0, 1.0).toDouble();
    if (accentRaw > 0) {
      final accentProgress = _accentEase.transform(accentRaw);
      final accentScale = accentRaw < .58
          ? 1.35 * (accentProgress / .58)
          : 1.35 - (.35 * ((accentRaw - .58) / .42));
      final accent = _mark.accent;
      final point =
          artCenter +
          Offset(
            (accent.x - 512) * artScale * markScale,
            (accent.y - 512) * artScale * markScale,
          );
      canvas.drawCircle(
        point,
        accent.radius * artScale * markScale * accentScale,
        Paint()..color = _terracotta.withValues(alpha: min(accentRaw / .2, 1)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HermesSplashMarkPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _SplashMark {
  const _SplashMark({required this.dots, required this.accent});

  final List<_SplashDot> dots;
  final _SplashDot accent;

  /// A mesma malha e teste de cobertura usados para desenhar o asset mestre.
  /// Mantê-los em código evita que a animação dependa de um SVG ou pacote de
  /// vetores durante a primeira pintura do processo.
  factory _SplashMark.build() {
    const resolution = 23;
    const zoom = 1.18;
    const shear = .1725;
    const spacing = .95;
    const halfWidth = 60.0;
    const serifWidth = 92.0;
    const serifHeight = 24.0;
    const top = 300.0;
    const base = 724.0;
    const middle = 504.0;
    const bar = 27.0;
    final pitch = 612 / (resolution - 1);
    final maxRadius = pitch * .42;
    final left = 512 - (151 * spacing);
    final right = 512 + (151 * spacing);
    final dots = <_SplashDot>[];
    _SplashDot? accent;
    var accentDistance = double.infinity;

    bool inside(
      double x,
      double y,
      double x1,
      double y1,
      double x2,
      double y2,
    ) => x >= x1 && x <= x2 && y >= y1 && y <= y2;

    bool hitsMark(double px, double py) {
      final unzoomedX = 512 + ((px - 512) / zoom);
      final unzoomedY = 512 + ((py - 512) / zoom);
      final x = unzoomedX - (shear * (512 - unzoomedY));
      return inside(
            x,
            unzoomedY,
            left - halfWidth / 2,
            top,
            left + halfWidth / 2,
            base,
          ) ||
          inside(
            x,
            unzoomedY,
            right - halfWidth / 2,
            top,
            right + halfWidth / 2,
            base,
          ) ||
          inside(
            x,
            unzoomedY,
            left - halfWidth / 2,
            middle - bar,
            right + halfWidth / 2,
            middle + bar,
          ) ||
          inside(
            x,
            unzoomedY,
            left - serifWidth / 2,
            top,
            left + serifWidth / 2,
            top + serifHeight,
          ) ||
          inside(
            x,
            unzoomedY,
            right - serifWidth / 2,
            top,
            right + serifWidth / 2,
            top + serifHeight,
          ) ||
          inside(
            x,
            unzoomedY,
            left - serifWidth / 2,
            base - serifHeight,
            left + serifWidth / 2,
            base,
          ) ||
          inside(
            x,
            unzoomedY,
            right - serifWidth / 2,
            base - serifHeight,
            right + serifWidth / 2,
            base,
          );
    }

    for (var row = -11; row <= 11; row++) {
      for (var column = -11; column <= 11; column++) {
        final x = 512 + (column * pitch);
        final y = 512 + (row * pitch);
        final centerDistance = sqrt(pow(x - 512, 2) + pow(y - 512, 2));
        if (centerDistance > 326) continue;

        var coverage = 0;
        for (var sampleY = 0; sampleY < 5; sampleY++) {
          for (var sampleX = 0; sampleX < 5; sampleX++) {
            final px = x + ((((sampleX + .5) / 5) - .5) * pitch);
            final py = y + ((((sampleY + .5) / 5) - .5) * pitch);
            if (hitsMark(px, py)) coverage++;
          }
        }
        final ratio = coverage / 25;
        if (ratio > .07) {
          dots.add(
            _SplashDot(
              x: x,
              y: y,
              radius: max(maxRadius * .34, maxRadius * sqrt(ratio)),
            ),
          );
        } else {
          final distance = sqrt(pow(x - 734, 2) + pow(y - 736, 2));
          if (centerDistance < 330 && distance < accentDistance) {
            accentDistance = distance;
            accent = _SplashDot(x: x, y: y, radius: maxRadius);
          }
        }
      }
    }

    dots.sort((a, b) => a.strokeOrder.compareTo(b.strokeOrder));
    return _SplashMark(dots: dots, accent: accent!);
  }
}

class _SplashDot {
  const _SplashDot({required this.x, required this.y, required this.radius});

  final double x;
  final double y;
  final double radius;

  int get strokeOrder {
    final group = x < 452
        ? 0
        : ((y - 512).abs() < 46 && x < 640)
        ? 1
        : 2;
    return (group * 1000000) + (y * 100).round() + x.round();
  }
}
