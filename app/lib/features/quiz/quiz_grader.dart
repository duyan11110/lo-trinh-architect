// Grading per question type — docs/05 S4 "Tương tác theo loại câu",
// docs/01 §6. Pure functions; no partial credit in V1.
import '../../content/models/models.dart';

/// A blank in a `fill` question: three or more underscores (content uses
/// both `___` and `____`).
final RegExp fillBlank = RegExp(r'_{3,}');

String _norm(String s) => s.trim().toLowerCase();

/// Whether [response] answers [q] correctly.
/// - single / truefalse / scenario: the one chosen id equals `answer[0]`;
/// - multi: the chosen set equals the answer set;
/// - order: the id sequence equals `answer`;
/// - fill: trimmed, lower-cased text equals an accepted answer, or the
///   trimmed text matches `answer_regex`.
bool gradeAnswer(Question q, List<String> response) {
  switch (q.type) {
    case QuestionType.single:
    case QuestionType.truefalse:
    case QuestionType.scenario:
      return response.length == 1 && response.first == q.answer.first;
    case QuestionType.multi:
      final chosen = response.toSet();
      return chosen.length == response.length &&
          chosen.length == q.answer.length &&
          chosen.containsAll(q.answer);
    case QuestionType.order:
      if (response.length != q.answer.length) return false;
      for (var i = 0; i < response.length; i++) {
        if (response[i] != q.answer[i]) return false;
      }
      return true;
    case QuestionType.fill:
      if (response.isEmpty) return false;
      final typed = response.first;
      if (_norm(typed).isEmpty) return false;
      if (q.answer.any((a) => _norm(a) == _norm(typed))) return true;
      final re = q.answerRegex;
      if (re == null) return false;
      try {
        return RegExp(re).hasMatch(typed.trim());
      } on FormatException {
        return false;
      }
  }
}

/// Whether [response] is complete enough to enable "Kiểm tra".
bool canCheck(Question q, List<String> response) => switch (q.type) {
  QuestionType.multi => response.isNotEmpty,
  QuestionType.order => response.length == q.options.length,
  QuestionType.fill => response.isNotEmpty && response.first.trim().isNotEmpty,
  _ => response.length == 1,
};

/// The initial response: `order` starts in JSON order (docs/01 §6: the app
/// shows the steps as listed); every other type starts empty.
List<String> initialResponse(Question q) => q.type == QuestionType.order
    ? [for (final o in q.options) o.id]
    : const [];

/// Option letter shown on the card (`a` → `A`).
String optionLetter(String id) => id.toUpperCase();

/// The answer as shown in "Chưa đúng — đáp án: …" and the result recap.
String answerLabel(Question q, List<String> ids) => switch (q.type) {
  QuestionType.fill => ids.join(' · '),
  QuestionType.order => ids.map(optionLetter).join(' → '),
  _ => ids.map(optionLetter).join(', '),
};
