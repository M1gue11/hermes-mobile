import 'package:flutter/material.dart';

import '../theme/hermes_motion.dart';
import '../theme/hermes_radius.dart';
import '../theme/hermes_tokens.dart';

/// Moldura comum dos bottom sheets: handle + cabeçalho + conteúdo rolável.
///
/// Mora no `core` porque deixou de ser exclusiva das folhas do chat: o card de
/// anexo do A24 abre o conteúdo do arquivo na mesma moldura. Duas molduras
/// parecidas seriam duas ideias de sheet no mesmo app.
Future<void> showHermesSheet(
  BuildContext context, {
  required String title,
  required String tag,
  required Widget child,
  String? backTooltip,
}) {
  final t = HermesTokens.of(context);
  final reducedMotion = reduceMotionOf(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: t.surface,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    sheetAnimationStyle: reducedMotion
        ? AnimationStyle.noAnimation
        : AnimationStyle(
            curve: HermesMotion.curvaChegada,
            duration: HermesMotion.revelar,
            reverseCurve: HermesMotion.curvaPadrao,
            reverseDuration: HermesMotion.saidaDe(HermesMotion.revelar),
          ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: HermesRadius.folha),
    ),
    builder: (context) {
      final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
      final expandedHeader = MediaQuery.textScalerOf(context).scale(1) >= 1.4;
      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.82,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(top: 9, bottom: 4),
                decoration: BoxDecoration(
                  color: t.faint,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (backTooltip != null) ...[
                      IconButton(
                        key: const ValueKey('hermes-sheet-back'),
                        tooltip: backTooltip,
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: t.dim,
                        ),
                      ),
                      const SizedBox(width: 2),
                    ],
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            key: const ValueKey('hermes-sheet-title'),
                            header: true,
                            child: Text(
                              title,
                              maxLines: expandedHeader ? null : 1,
                              overflow: expandedHeader
                                  ? TextOverflow.visible
                                  : TextOverflow.ellipsis,
                              style: t
                                  .serifIn(FontWeight.w500)
                                  .copyWith(fontSize: 23, color: t.ink),
                            ),
                          ),
                          if (expandedHeader && tag.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            _SheetTag(tag: tag),
                          ],
                        ],
                      ),
                    ),
                    if (!expandedHeader && tag.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      _SheetTag(tag: tag),
                    ],
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 34),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _SheetTag extends StatelessWidget {
  const _SheetTag({required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Text(
      tag.toUpperCase(),
      key: const ValueKey('hermes-sheet-tag'),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: t.mono.copyWith(fontSize: 10.5, letterSpacing: 1.4, color: t.dim),
    );
  }
}
