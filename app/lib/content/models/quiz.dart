// `quizzes`, `gates` and the shared question shape (schemas/content.schema.json
// `$defs/question`). Rendering/grading is M3; M1 only loads them.
import 'package:flutter/foundation.dart';

import 'i18n.dart';

enum QuestionType {
  single,
  multi,
  truefalse,
  order,
  fill,
  scenario;

  static QuestionType parse(String s) => QuestionType.values.firstWhere(
    (t) => t.name == s,
    orElse: () => throw FormatException('content.json: question type "$s"'),
  );
}

enum Bloom {
  remember,
  understand,
  apply,
  analyze,
  evaluate;

  static Bloom parse(String s) => Bloom.values.firstWhere(
    (t) => t.name == s,
    orElse: () => throw FormatException('content.json: bloom "$s"'),
  );
}

@immutable
class Quiz {
  const Quiz({required this.lesson, required this.stage, required this.questions});

  factory Quiz.fromJson(Object? json) {
    final m = asMap(json, 'quizzes{}');
    return Quiz(
      lesson: m.str('lesson'),
      stage: m.integer('stage'),
      questions: m.list('questions', Question.fromJson),
    );
  }

  final String lesson;
  final int stage;
  final List<Question> questions;
}

@immutable
class Gate {
  const Gate({required this.gate, required this.stage, required this.questions});

  factory Gate.fromJson(Object? json) {
    final m = asMap(json, 'gates{}');
    return Gate(
      gate: m.str('gate'),
      stage: m.integer('stage'),
      questions: m.list('questions', Question.fromJson),
    );
  }

  final String gate;
  final int stage;
  final List<Question> questions;
}

@immutable
class Question {
  const Question({
    required this.id,
    required this.type,
    required this.bloom,
    required this.difficulty,
    required this.skills,
    required this.track,
    required this.module,
    required this.sectionRef,
    required this.context,
    required this.question,
    required this.options,
    required this.answer,
    required this.answerRegex,
    required this.explanationVi,
    required this.explanationEn,
  });

  factory Question.fromJson(Object? json) {
    final m = asMap(json, 'question');
    final expl = asMap(m['explanation'], 'explanation');
    Map<String, String> lang(String l) =>
        Map.unmodifiable(asMap(expl[l], 'explanation.$l').cast<String, String>());
    return Question(
      id: m.str('id'),
      type: QuestionType.parse(m.str('type')),
      bloom: Bloom.parse(m.str('bloom')),
      difficulty: m.integer('difficulty'),
      skills: m.strings('skills'),
      track: m.strOrNull('track'),
      module: m.strOrNull('module'),
      sectionRef: m.intOrNull('section_ref'),
      context: m.i18nOrNull('context'),
      question: m.i18n('question'),
      options: m.containsKey('options')
          ? m.list('options', QuestionOption.fromJson)
          : const [],
      answer: m.strings('answer'),
      answerRegex: m.strOrNull('answer_regex'),
      explanationVi: lang('vi'),
      explanationEn: lang('en'),
    );
  }

  final String id;
  final QuestionType type;
  final Bloom bloom;
  final int difficulty;
  final List<String> skills;
  final String? track;
  final String? module;
  final int? sectionRef;
  final I18n? context;
  final I18n question;
  final List<QuestionOption> options;

  /// Option ids (`a`…`f`) or, for `fill`, accepted strings.
  final List<String> answer;
  final String? answerRegex;

  /// `correct` plus one entry per wrong option id.
  final Map<String, String> explanationVi;
  final Map<String, String> explanationEn;

  Map<String, String> explanation(ContentLang lang) =>
      lang == ContentLang.vi ? explanationVi : explanationEn;
}

@immutable
class QuestionOption {
  const QuestionOption({
    required this.id,
    required this.text,
    required this.misconception,
    required this.polarity,
  });

  factory QuestionOption.fromJson(Object? json) {
    final m = asMap(json, 'option');
    final p = m.strOrNull('polarity');
    return QuestionOption(
      id: m.str('id'),
      text: I18n(vi: m.str('vi'), en: m.str('en')),
      misconception: m.strOrNull('misconception'),
      polarity: p == null ? null : p == 'true',
    );
  }

  final String id;
  final I18n text;
  final String? misconception;

  /// `truefalse` only: whether the statement is true.
  final bool? polarity;
}
