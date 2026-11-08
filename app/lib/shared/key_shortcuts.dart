// Single-key shortcuts — docs/05 §2 and S3/S4 (`j/k`, `n`, `q`, `l`, `/`,
// `1–6`, `Enter`). Keys are ignored while a text field has focus so typing
// in a `fill` answer or the search box never triggers them; a focused
// button still handles its own `Enter`/`Space` first.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class KeyShortcuts extends StatelessWidget {
  const KeyShortcuts({super.key, required this.bindings, required this.child});

  /// Activator → action. Plain characters use [CharacterActivator] so the
  /// layout's character is matched, not the physical key.
  final Map<ShortcutActivator, VoidCallback> bindings;
  final Widget child;

  static bool _editing() {
    final ctx = FocusManager.instance.primaryFocus?.context;
    if (ctx == null) return false;
    return ctx.widget is EditableText ||
        ctx.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is KeyUpEvent || _editing()) return KeyEventResult.ignored;
    for (final MapEntry(key: activator, value: action) in bindings.entries) {
      if (activator.accepts(event, HardwareKeyboard.instance)) {
        action();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) =>
      Focus(autofocus: true, onKeyEvent: _onKey, child: child);
}
