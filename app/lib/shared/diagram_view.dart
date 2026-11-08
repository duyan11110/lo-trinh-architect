// DiagramView — docs/05 §6, docs/07 §6. Themed SVG on `surface2`; tap →
// full screen with pinch zoom; missing SVG → "Sơ đồ chưa render", no crash.
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app/theme/tokens.dart';
import '../content/svg_theming.dart';
import '../l10n/app_localizations.dart';

final _svgCache = SvgThemeCache();

class DiagramView extends StatelessWidget {
  const DiagramView({super.key, required this.lessonId, required this.svg});

  final String lessonId;
  final String? svg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.extension<LtaColors>()!;
    final decoration = BoxDecoration(
      color: c.surface2,
      borderRadius: BorderRadius.circular(LtaRadius.card),
      border: Border.all(color: c.line, width: LtaSize.border),
    );
    final raw = svg;
    if (raw == null || raw.trim().isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(LtaSpace.s6),
        decoration: decoration,
        alignment: Alignment.center,
        child: Text(
          L.of(context).diagramMissing,
          style: theme.textTheme.bodyMedium!.copyWith(color: c.muted),
        ),
      );
    }
    final themed = _svgCache.get(lessonId, theme.brightness, raw, c);
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => DiagramFullScreen(svg: themed),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(LtaSpace.s3),
        decoration: decoration,
        child: SvgPicture.string(themed),
      ),
    );
  }
}

class DiagramFullScreen extends StatelessWidget {
  const DiagramFullScreen({super.key, required this.svg});

  final String svg;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: L.of(context).diagramClose,
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: InteractiveViewer(
        maxScale: LtaSize.diagramMaxScale,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(LtaSpace.s4),
            child: SvgPicture.string(svg),
          ),
        ),
      ),
    );
  }
}
