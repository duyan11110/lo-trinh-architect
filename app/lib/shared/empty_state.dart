// EmptyState — docs/05 §6: text and at most one button, no illustration.
import 'package:flutter/material.dart';

import '../app/theme/tokens.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, this.title, required this.body, this.action});

  final String? title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.extension<LtaColors>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LtaSpace.s6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(title!, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: LtaSpace.s2),
          ],
          Text(
            body,
            style: theme.textTheme.bodyMedium!.copyWith(color: c.ink2),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[
            const SizedBox(height: LtaSpace.s4),
            Center(child: action),
          ],
        ],
      ),
    );
  }
}
