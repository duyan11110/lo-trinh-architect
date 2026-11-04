// Module quiz draw — docs/07 §5.5: no bank of its own; 12–15 questions from
// the `quizzes` of every lesson in the module, at least one per lesson,
// preferring bloom apply/analyze and questions the learner got wrong before,
// shuffled. Randomness is injected (DECISIONS.md E7).
import 'dart:math';

import '../content/models/models.dart';

abstract final class ModuleQuizSampler {
  static const int minQuestions = 12;
  static const int maxQuestions = 15;

  /// Pass mark: as a lesson quiz (≥ 70%, label "Module ✓").
  static const double passRatio = 0.7;

  /// Lesson quizzes of [module] present in [content], in module order.
  static List<Quiz> quizzesOf(Content content, TrackModule module) => [
    for (final r in module.lessons)
      if (content.quizzes[r.id] case final q? when q.questions.isNotEmpty) q,
  ];

  /// Question id → lesson id, for the questions of [module].
  static Map<String, String> lessonOfQuestion(
    Content content,
    TrackModule module,
  ) => {
    for (final quiz in quizzesOf(content, module))
      for (final q in quiz.questions) q.id: quiz.lesson,
  };

  /// Draws up to [maxQuestions] ids ([wrongBefore]: ids answered wrong in any
  /// earlier attempt).
  static List<String> sample({
    required Content content,
    required TrackModule module,
    required Random random,
    Set<String> wrongBefore = const {},
  }) {
    final quizzes = quizzesOf(content, module);
    final all = [for (final quiz in quizzes) ...quiz.questions];
    final n = min(maxQuestions, all.length);
    int priority(Question q) =>
        (wrongBefore.contains(q.id) ? 2 : 0) +
        (q.bloom == Bloom.apply || q.bloom == Bloom.analyze ? 1 : 0);

    /// Highest priority first; ties in random order.
    List<Question> ranked(List<Question> qs) {
      final shuffled = [...qs]..shuffle(random);
      final keyed = [for (final (i, q) in shuffled.indexed) (q, i)]
        ..sort((a, b) {
          final c = priority(b.$1).compareTo(priority(a.$1));
          return c != 0 ? c : a.$2.compareTo(b.$2);
        });
      return [for (final (q, _) in keyed) q];
    }

    final picked = <Question>[];
    // One per lesson first (a module with > n lessons: the first n lessons
    // in a random order).
    final perLesson = [for (final quiz in quizzes) ranked(quiz.questions)]
      ..shuffle(random);
    for (final qs in perLesson) {
      if (picked.length >= n) break;
      picked.add(qs.first);
    }
    final ids = {for (final q in picked) q.id};
    picked.addAll(
      ranked([for (final q in all) if (!ids.contains(q.id)) q])
          .take(n - picked.length),
    );
    return [for (final q in picked) q.id]..shuffle(random);
  }
}
