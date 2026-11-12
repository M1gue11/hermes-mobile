import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/features/chat/widgets/hermes_markdown.dart';

const _boundaryKey = ValueKey('ink-raster');

class _Raster {
  const _Raster(this.bytes, this.width, this.height);
  final Uint8List bytes;
  final int width;
  final int height;
}

Future<_Raster> _capture(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundaryKey),
  );
  return (await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final raster = _Raster(
      Uint8List.fromList(data!.buffer.asUint8List()),
      image.width,
      image.height,
    );
    image.dispose();
    return raster;
  }))!;
}

int _changed(_Raster a, _Raster b, List<Rect> regions) {
  var changed = 0;
  for (var y = 0; y < a.height; y++) {
    for (var x = 0; x < a.width; x++) {
      if (!regions.any((r) => r.contains(Offset(x + .5, y + .5)))) continue;
      final i = (y * a.width + x) * 4;
      if (a.bytes[i] != b.bytes[i] ||
          a.bytes[i + 1] != b.bytes[i + 1] ||
          a.bytes[i + 2] != b.bytes[i + 2] ||
          a.bytes[i + 3] != b.bytes[i + 3]) {
        changed++;
      }
    }
  }
  return changed;
}

Future<void> _mount(
  WidgetTester tester, {
  required String text,
  double width = 420,
  double? letterSpacing,
  FontStyle fontStyle = FontStyle.normal,
  bool reducedMotion = false,
  bool accessibleNavigation = false,
  bool tickerEnabled = true,
  required ValueChanged<void Function(String)> exposeUpdate,
}) async {
  late StateSetter update;
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          disableAnimations: reducedMotion,
          accessibleNavigation: accessibleNavigation,
        ),
        child: TickerMode(
          enabled: tickerEnabled,
          child: Scaffold(
            body: RepaintBoundary(
              key: _boundaryKey,
              child: SizedBox(
                width: width,
                height: 240,
                child: ColoredBox(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: StatefulBuilder(
                      builder: (context, setState) {
                        update = setState;
                        return StreamingInk(
                          text: text,
                          layoutSignature: const Object(),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 28,
                                fontFamily: 'Ahem',
                                letterSpacing: letterSpacing,
                                fontStyle: fontStyle,
                              ),
                              text: text,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  exposeUpdate((value) => update(() => text = value));
}

RenderParagraph _paragraph(WidgetTester tester) => tester.allRenderObjects
    .whereType<RenderParagraph>()
    .firstWhere((paragraph) => paragraph.text.toPlainText().isNotEmpty);

List<Rect> _selection(WidgetTester tester, int start, int end) {
  final paragraph = _paragraph(tester);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundaryKey),
  );
  final origin = paragraph.localToGlobal(Offset.zero, ancestor: boundary);
  return paragraph
      .getBoxesForSelection(TextSelection(baseOffset: start, extentOffset: end))
      .map((box) => box.toRect().shift(origin))
      .toList();
}

void main() {
  testWidgets('raster keeps prefix fixed and settles each append batch', (
    tester,
  ) async {
    const prefix = 'STABLE';
    const firstAppend = ' FIRST';
    const secondAppend = ' SECOND';
    late void Function(String) update;
    await _mount(tester, text: prefix, exposeUpdate: (value) => update = value);
    await tester.pump(const Duration(milliseconds: 300));
    update('$prefix$firstAppend');
    await tester.pump();
    final first = await _capture(tester);
    final prefixBoxes = _selection(tester, 0, prefix.length);
    final firstBoxes = _selection(
      tester,
      prefix.length,
      prefix.length + firstAppend.length,
    );

    await tester.pump(const Duration(milliseconds: 80));
    update('$prefix$firstAppend$secondAppend');
    await tester.pump();
    final burst = await _capture(tester);
    final secondBoxes = _selection(
      tester,
      prefix.length + firstAppend.length,
      prefix.length + firstAppend.length + secondAppend.length,
    );
    await tester.pump(const Duration(milliseconds: 140));
    final firstExpired = await _capture(tester);
    await tester.pump(const Duration(milliseconds: 100));
    final settled = await _capture(tester);

    expect(_changed(first, settled, prefixBoxes), 0);
    expect(_changed(first, burst, firstBoxes), greaterThan(0));
    expect(_changed(burst, firstExpired, firstBoxes), greaterThan(0));
    expect(_changed(burst, firstExpired, secondBoxes), greaterThan(0));
    expect(_changed(firstExpired, settled, secondBoxes), greaterThan(0));
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('replacement and grapheme extensions become immediate baseline', (
    tester,
  ) async {
    late void Function(String) update;
    await _mount(
      tester,
      text: 'original',
      exposeUpdate: (value) => update = value,
    );
    await tester.pump(const Duration(milliseconds: 300));
    update('replacement');
    await tester.pump();
    final replacement = await _capture(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      _changed(replacement, await _capture(tester), [
        const Rect.fromLTWH(0, 0, 420, 240),
      ]),
      0,
    );

    update('e');
    await tester.pump();
    update('e\u0301');
    await tester.pump();
    final combining = await _capture(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      _changed(combining, await _capture(tester), [
        const Rect.fromLTWH(0, 0, 420, 240),
      ]),
      0,
    );

    update('👩');
    await tester.pump();
    update('👩‍💻');
    await tester.pump();
    final joined = await _capture(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      _changed(joined, await _capture(tester), [
        const Rect.fromLTWH(0, 0, 420, 240),
      ]),
      0,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('overlapping shaping boxes flush instead of masking old ink', (
    tester,
  ) async {
    late void Function(String) update;
    await _mount(
      tester,
      text: 'W',
      letterSpacing: -20,
      exposeUpdate: (value) => update = value,
    );
    await tester.pump(const Duration(milliseconds: 300));
    update('WW');
    await tester.pump();
    final baseline = await _capture(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      _changed(baseline, await _capture(tester), [
        const Rect.fromLTWH(0, 0, 420, 240),
      ]),
      0,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reduced motion and TickerMode changes flush active ink', (
    tester,
  ) async {
    late void Function(String) update;
    await _mount(tester, text: 'base', exposeUpdate: (value) => update = value);
    await tester.pump(const Duration(milliseconds: 300));
    update('base plus');
    await tester.pump();
    final active = await _capture(tester);
    await _mount(
      tester,
      text: 'base plus',
      reducedMotion: true,
      exposeUpdate: (value) => update = value,
    );
    final reduced = await _capture(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      _changed(reduced, await _capture(tester), [
        const Rect.fromLTWH(0, 0, 420, 240),
      ]),
      0,
    );
    expect(active.bytes, isNot(equals(reduced.bytes)));

    await _mount(
      tester,
      text: 'base plus',
      tickerEnabled: false,
      exposeUpdate: (value) => update = value,
    );
    final paused = await _capture(tester);
    await tester.pump(const Duration(milliseconds: 250));
    expect(
      _changed(paused, await _capture(tester), [
        const Rect.fromLTWH(0, 0, 420, 240),
      ]),
      0,
    );

    await _mount(
      tester,
      text: 'base plus resumed',
      exposeUpdate: (value) => update = value,
    );
    update('base plus resumed now');
    await tester.pump();
    await _mount(
      tester,
      text: 'base plus resumed now',
      tickerEnabled: false,
      exposeUpdate: (value) => update = value,
    );
    final modeFlushed = await _capture(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      _changed(modeFlushed, await _capture(tester), [
        const Rect.fromLTWH(0, 0, 420, 240),
      ]),
      0,
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('italic ink and accessible navigation stay immediate', (
    tester,
  ) async {
    for (final italic in [true, false]) {
      late void Function(String) update;
      await _mount(
        tester,
        text: 'base',
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        accessibleNavigation: !italic,
        exposeUpdate: (value) => update = value,
      );
      update('base with more ink');
      await tester.pump();
      final first = await _capture(tester);
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        _changed(first, await _capture(tester), [
          const Rect.fromLTWH(0, 0, 420, 240),
        ]),
        0,
      );
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('disposing an active renderer leaves no ticker callbacks', (
    tester,
  ) async {
    late void Function(String) update;
    await _mount(
      tester,
      text: 'start',
      exposeUpdate: (value) => update = value,
    );
    await tester.pump(const Duration(milliseconds: 300));
    update('start active tail');
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('wrap and width reset establish an immediate baseline', (
    tester,
  ) async {
    late void Function(String) update;
    const value =
        'prefix with a long appended ending that wraps to another line';
    await _mount(
      tester,
      text: 'prefix',
      exposeUpdate: (value) => update = value,
    );
    await tester.pump(const Duration(milliseconds: 300));
    update(value);
    await tester.pump();
    await _mount(
      tester,
      text: value,
      width: 220,
      exposeUpdate: (value) => update = value,
    );
    final boxes = _selection(tester, 0, value.length);
    expect(boxes.length, greaterThan(1));
    final afterResize = await _capture(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      _changed(afterResize, await _capture(tester), [
        const Rect.fromLTWH(0, 0, 420, 240),
      ]),
      0,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Markdown structural tails keep the instant fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(body: HermesMarkdown('- item', streaming: true)),
      ),
    );
    expect(find.byType(StreamingInk), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
