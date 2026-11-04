// FillField — docs/05 §6: a `TextField` inline in the question
// (`WidgetSpan`), mono when the blank is in code, no autocorrect or
// suggestions; idle / correct / wrong.
import 'package:flutter/material.dart';

import '../../../app/theme/text.dart';
import '../../../app/theme/tokens.dart';

class FillField extends StatefulWidget {
  const FillField({
    super.key,
    required this.value,
    required this.mono,
    required this.checked,
    required this.correct,
    required this.onChanged,
  });

  final String value;
  final bool mono;
  final bool checked;
  final bool correct;
  final ValueChanged<String> onChanged;

  @override
  State<FillField> createState() => _FillFieldState();
}

class _FillFieldState extends State<FillField> {
  late final _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(FillField old) {
    super.didUpdateWidget(old);
    if (widget.value != _controller.text) _controller.text = widget.value;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.extension<LtaColors>()!;
    final t = theme.extension<LtaText>()!;
    final color = !widget.checked
        ? c.accent
        : (widget.correct ? c.correct : c.incorrect);
    final fill = !widget.checked
        ? c.surface
        : (widget.correct ? c.correctSoft : c.incorrectSoft);
    OutlineInputBorder border(Color col) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(LtaRadius.code),
      borderSide: BorderSide(color: col, width: LtaSize.emphasisBorder),
    );
    return SizedBox(
      width: LtaSize.fillField,
      child: TextField(
        controller: _controller,
        readOnly: widget.checked,
        autocorrect: false,
        enableSuggestions: false,
        smartDashesType: SmartDashesType.disabled,
        smartQuotesType: SmartQuotesType.disabled,
        textCapitalization: TextCapitalization.none,
        style: (widget.mono ? t.code : t.quizOption).copyWith(color: c.ink),
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: fill,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: LtaSpace.s2,
            vertical: LtaSpace.s2,
          ),
          enabledBorder: border(widget.checked ? color : c.line),
          focusedBorder: border(color),
          border: border(c.line),
          suffixIcon: widget.checked
              ? Icon(
                  widget.correct ? Icons.check_rounded : Icons.close_rounded,
                  color: color,
                  size: LtaSize.icon,
                )
              : null,
        ),
      ),
    );
  }
}
