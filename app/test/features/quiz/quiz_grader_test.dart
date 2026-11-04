// Grading rules per type (docs/05 S4, docs/01 §6).
import 'package:flutter_test/flutter_test.dart';
import 'package:lta_app/content/models/models.dart';
import 'package:lta_app/features/quiz/question_widgets/question_view.dart';
import 'package:lta_app/features/quiz/quiz_grader.dart';

import '../../fixtures/content_builder.dart';

void main() {
  Question q(QuestionType t, {List<String>? answer, String? regex}) =>
      buildQuestion('t.q1', t, answer: answer, answerRegex: regex);

  test('single / truefalse / scenario compare answer[0]', () {
    for (final t in [
      QuestionType.single,
      QuestionType.truefalse,
      QuestionType.scenario,
    ]) {
      expect(gradeAnswer(q(t), ['b']), isTrue);
      expect(gradeAnswer(q(t), ['a']), isFalse);
      expect(gradeAnswer(q(t), []), isFalse);
    }
  });

  test('multi: set equality, no partial credit', () {
    final m = q(QuestionType.multi);
    expect(gradeAnswer(m, ['c', 'a']), isTrue);
    expect(gradeAnswer(m, ['a']), isFalse);
    expect(gradeAnswer(m, ['a', 'c', 'd']), isFalse);
  });

  test('order: exact sequence; starts in JSON order', () {
    final o = q(QuestionType.order);
    expect(initialResponse(o), ['a', 'b', 'c', 'd']);
    expect(gradeAnswer(o, ['d', 'c', 'b', 'a']), isTrue);
    expect(gradeAnswer(o, ['a', 'b', 'c', 'd']), isFalse);
    expect(answerLabel(o, o.answer), 'D → C → B → A');
  });

  test('fill: trim + lower against answer[], or answer_regex', () {
    final f = q(QuestionType.fill, answer: ['AddOpenApi', 'AddOpenApi()']);
    expect(gradeAnswer(f, ['  addopenapi ']), isTrue);
    expect(gradeAnswer(f, ['AddOpenApi()']), isTrue);
    expect(gradeAnswer(f, ['AddSwagger']), isFalse);
    expect(gradeAnswer(f, ['   ']), isFalse);
    final r = q(QuestionType.fill, answer: ['>'], regex: r'^\s*>\s*$');
    expect(gradeAnswer(r, [' > ']), isTrue);
    expect(gradeAnswer(r, ['>=']), isFalse);
    final bad = q(QuestionType.fill, answer: ['x'], regex: '(');
    expect(gradeAnswer(bad, ['y']), isFalse);
  });

  test('canCheck per type', () {
    expect(canCheck(q(QuestionType.single), []), isFalse);
    expect(canCheck(q(QuestionType.multi), ['a']), isTrue);
    expect(canCheck(q(QuestionType.order), ['a', 'b', 'c', 'd']), isTrue);
    expect(canCheck(q(QuestionType.fill), [' ']), isFalse);
  });

  test('fill blank: three or more underscores', () {
    expect(fillBlank.hasMatch('x.___(y)'), isTrue);
    expect(fillBlank.hasMatch('x.____(y)'), isTrue);
    expect(fillBlank.hasMatch('snake_case'), isFalse);
  });

  test('truefalse prefix strip keeps text without a prefix', () {
    expect(stripPolarityPrefix('True, because the client'), 'the client');
    expect(
      stripPolarityPrefix('Sai, vì `204` không có thân'),
      '`204` không có thân',
    );
    expect(stripPolarityPrefix('Plain statement'), 'Plain statement');
  });
}
