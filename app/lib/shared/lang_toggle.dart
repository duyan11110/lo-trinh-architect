// LangToggle — VI|EN in the app bars of S3 and S4 (docs/05 S3, S4).
import 'package:flutter/material.dart';

import '../app/theme/tokens.dart';
import '../content/models/models.dart';
import '../l10n/app_localizations.dart';

class LangToggle extends StatelessWidget {
  const LangToggle({super.key, required this.lang, required this.onChanged});

  final ContentLang lang;
  final ValueChanged<ContentLang> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final c = Theme.of(context).extension<LtaColors>()!;
    final style = Theme.of(context).textTheme.labelLarge!;
    Widget option(ContentLang value, String label) {
      final selected = value == lang;
      return Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(LtaRadius.button),
          onTap: selected ? null : () => onChanged(value),
          child: Container(
            constraints: const BoxConstraints(
              minWidth: LtaSize.minTap,
              minHeight: LtaSize.minTap,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: style.copyWith(
                color: selected ? c.accent : c.muted,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        option(ContentLang.vi, l.langVi),
        option(ContentLang.en, l.langEn),
      ],
    );
  }
}
