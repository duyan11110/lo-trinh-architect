import 'package:test/test.dart';

import '../src/errors.dart';
import '../src/rules_quiz.dart';
import '../src/schema_validator.dart';
import 'support.dart';

Map<String, dynamic> _opt(String id, String text, {String? misconception, String? polarity}) => {
      'id': id,
      'vi': '$text (vi)',
      'en': text,
      if (misconception != null) 'misconception': misconception,
      if (polarity != null) 'polarity': polarity,
    };

Map<String, dynamic> _singleQuestion({
  String id = 'design.l1.golden-lesson.q1',
  int sectionRef = 3,
  List<Map<String, dynamic>>? options,
  List<String>? answer,
  Map<String, dynamic>? explanation,
  List<String>? skills,
}) {
  return {
    'id': id,
    'type': 'single',
    'bloom': 'understand',
    'difficulty': 2,
    'skills': skills ?? ['design.test.skill'],
    'section_ref': sectionRef,
    'question': {'vi': 'Câu hỏi mẫu?', 'en': 'A sample question about the fixture?'},
    'options': options ??
        [
          _opt('a', 'A plausible wrong answer of medium length'),
          _opt('b', 'The correct answer of medium length too'),
          _opt('c', 'Another plausible wrong answer here'),
          _opt('d', 'One more wrong answer of similar length'),
        ],
    'answer': answer ?? ['b'],
    'explanation': explanation ??
        {
          'vi': {'correct': 'Giải thích đúng dài đủ 20 ký tự.', 'a': 'Giải thích sai a dài đủ.', 'c': 'Giải thích sai c dài đủ.', 'd': 'Giải thích sai d dài đủ.'},
          'en': {'correct': 'This explains why b is correct in enough detail.', 'a': 'This explains why a is wrong in enough detail.', 'c': 'This explains why c is wrong in enough detail.', 'd': 'This explains why d is wrong in enough detail.'},
        },
  };
}

Map<String, dynamic> quizWith(List<Map<String, dynamic>> questions, {int stage = 1}) => {
      'lesson': 'design.l1.golden-lesson',
      'stage': stage,
      'questions': questions,
    };

List<Map<String, dynamic>> _fiveDistinctQuestions() {
  return [
    _singleQuestion(id: 'design.l1.golden-lesson.q1'),
    _singleQuestion(id: 'design.l1.golden-lesson.q2', options: [
      _opt('a', 'First distinct wrong option about layout'),
      _opt('b', 'Second distinct correct option about layout'),
      _opt('c', 'Third distinct wrong option about layout'),
      _opt('d', 'Fourth distinct wrong option about layout'),
    ]),
    _singleQuestion(id: 'design.l1.golden-lesson.q3', options: [
      _opt('a', 'Alpha choice regarding widget reuse'),
      _opt('b', 'Beta choice regarding widget reuse, correct'),
      _opt('c', 'Gamma choice regarding widget reuse'),
      _opt('d', 'Delta choice regarding widget reuse'),
    ]),
    _singleQuestion(id: 'design.l1.golden-lesson.q4', options: [
      _opt('a', 'Choice one about state management here'),
      _opt('b', 'Choice two about state management, correct'),
      _opt('c', 'Choice three about state management here'),
      _opt('d', 'Choice four about state management here'),
    ]),
    _singleQuestion(id: 'design.l1.golden-lesson.q5', options: [
      _opt('a', 'Option one about the Đơn Hàng screen'),
      _opt('b', 'Option two about the Đơn Hàng screen, right'),
      _opt('c', 'Option three about the Đơn Hàng screen'),
      _opt('d', 'Option four about the Đơn Hàng screen'),
    ]),
  ];
}

void main() {
  test('Q01: quiz.lesson does not match the lesson id', () {
    final quiz = {...quizWith(_fiveDistinctQuestions()), 'lesson': 'design.l1.wrong'};
    final out = IssueCollector();
    validateQuiz('design.l1.golden-lesson', quiz, SchemaValidator(realRepo()), out, QuizValidationContext());
    expect(out.issues.any((i) => i.rule == 'Q01'), isTrue);
  });

  test('Q02: fewer than 5 questions in a lesson quiz', () {
    final quiz = quizWith(_fiveDistinctQuestions().take(3).toList());
    final out = IssueCollector();
    validateQuiz('design.l1.golden-lesson', quiz, SchemaValidator(realRepo()), out, QuizValidationContext());
    expect(out.issues.any((i) => i.rule == 'Q02'), isTrue);
  });

  test('Q04: section_ref missing', () {
    final q = _singleQuestion();
    q.remove('section_ref');
    final quiz = quizWith([q, ..._fiveDistinctQuestions().skip(1)]);
    final out = IssueCollector();
    validateQuiz('design.l1.golden-lesson', quiz, SchemaValidator(realRepo()), out, QuizValidationContext());
    expect(out.issues.any((i) => i.rule == 'Q04'), isTrue);
  });

  test('Q04: section_ref out of range', () {
    final q = _singleQuestion(sectionRef: 99);
    final quiz = quizWith([q, ..._fiveDistinctQuestions().skip(1)]);
    final out = IssueCollector();
    validateQuiz('design.l1.golden-lesson', quiz, SchemaValidator(realRepo()), out, QuizValidationContext());
    expect(out.issues.any((i) => i.rule == 'Q04'), isTrue);
  });

  test('Q05: wrong option missing its explanation entry', () {
    final q = _singleQuestion(explanation: {
      'vi': {'correct': 'Giải thích đúng dài đủ 20 ký tự.'},
      'en': {'correct': 'This explains why b is correct in enough detail.'},
    });
    final quiz = quizWith([q, ..._fiveDistinctQuestions().skip(1)]);
    final out = IssueCollector();
    validateQuiz('design.l1.golden-lesson', quiz, SchemaValidator(realRepo()), out, QuizValidationContext());
    expect(out.issues.any((i) => i.rule == 'Q05'), isTrue);
  });

  test('Q06: misconception does not match outline or mục 6', () {
    final q = _singleQuestion(options: [
      _opt('a', 'A plausible wrong answer', misconception: 'Something totally unrelated to this fixture at all'),
      _opt('b', 'The correct answer here'),
      _opt('c', 'Another wrong answer here'),
      _opt('d', 'One more wrong answer'),
    ]);
    final fixture = buildGoldenTree();
    final quiz = quizWith([q, ..._fiveDistinctQuestions().skip(1)]);
    final out = IssueCollector();
    validateQuiz('design.l1.golden-lesson', quiz, SchemaValidator(realRepo()), out,
        QuizValidationContext(lesson: fixture.golden));
    expect(out.issues.any((i) => i.rule == 'Q06'), isTrue);
  });

  test('Q06: misconception matching outline.misconceptions passes', () {
    final q = _singleQuestion(options: [
      _opt('a', 'A plausible wrong answer', misconception: 'm1'),
      _opt('b', 'The correct answer here'),
      _opt('c', 'Another wrong answer here'),
      _opt('d', 'One more wrong answer'),
    ]);
    final fixture = buildGoldenTree(); // golden.misconceptions default = ['m1','m2']
    final quiz = quizWith([q, ..._fiveDistinctQuestions().skip(1)]);
    final out = IssueCollector();
    validateQuiz('design.l1.golden-lesson', quiz, SchemaValidator(realRepo()), out,
        QuizValidationContext(lesson: fixture.golden));
    expect(out.issues.any((i) => i.rule == 'Q06'), isFalse);
  });

  test('Q07: option contains "all of the above"', () {
    final q = _singleQuestion(options: [
      _opt('a', 'A plausible wrong answer'),
      _opt('b', 'The correct answer here'),
      _opt('c', 'All of the above, basically'),
      _opt('d', 'One more wrong answer'),
    ]);
    final quiz = quizWith([q, ..._fiveDistinctQuestions().skip(1)]);
    final out = IssueCollector();
    validateQuiz('design.l1.golden-lesson', quiz, SchemaValidator(realRepo()), out, QuizValidationContext());
    expect(out.issues.any((i) => i.rule == 'Q07'), isTrue);
  });

  test('Q08: correct answer length reveals itself', () {
    final q = _singleQuestion(options: [
      _opt('a', 'no'),
      _opt('b', 'This is a very very very very very very very very long correct answer that stands out'),
      _opt('c', 'no'),
      _opt('d', 'no'),
    ]);
    final quiz = quizWith([q, ..._fiveDistinctQuestions().skip(1)]);
    final out = IssueCollector();
    validateQuiz('design.l1.golden-lesson', quiz, SchemaValidator(realRepo()), out, QuizValidationContext());
    expect(out.issues.any((i) => i.rule == 'Q08'), isTrue);
  });

  test('Q09: truefalse polarity/text pattern violated', () {
    final q = {
      'id': 'design.l1.golden-lesson.q1',
      'type': 'truefalse',
      'bloom': 'understand',
      'difficulty': 2,
      'skills': ['design.test.skill'],
      'section_ref': 3,
      'question': {'vi': 'Đúng hay sai?', 'en': 'True or false?'},
      'options': [
        _opt('a', 'Wrong prefix here, should start with True because', polarity: 'true'),
        _opt('b', 'True, because this is the second true option', polarity: 'true'),
        _opt('c', 'False, because this is a false option', polarity: 'false'),
        _opt('d', 'False, because this is another false option', polarity: 'false'),
      ],
      'answer': ['c'],
      'explanation': {
        'vi': {'correct': 'Giải thích đúng dài đủ 20 ký tự.'},
        'en': {'correct': 'This explains why c is correct in enough detail.'},
      },
    };
    final quiz = quizWith([q, ..._fiveDistinctQuestions().skip(1)]);
    final out = IssueCollector();
    validateQuiz('design.l1.golden-lesson', quiz, SchemaValidator(realRepo()), out, QuizValidationContext());
    expect(out.issues.any((i) => i.rule == 'Q09'), isTrue);
  });

  test('Q10: scenario context word count out of range', () {
    final q = {
      'id': 'design.l1.golden-lesson.q1',
      'type': 'scenario',
      'bloom': 'apply',
      'difficulty': 3,
      'skills': ['design.test.skill'],
      'section_ref': 3,
      'context': {'vi': 'x', 'en': 'Too short context.'},
      'question': {'vi': 'Câu hỏi tình huống?', 'en': 'Scenario question?'},
      'options': [
        _opt('a', 'Option a for the scenario question'),
        _opt('b', 'Option b for the scenario question, correct'),
        _opt('c', 'Option c for the scenario question'),
        _opt('d', 'Option d for the scenario question'),
      ],
      'answer': ['b'],
      'explanation': {
        'vi': {'correct': 'Giải thích đúng dài đủ 20 ký tự.'},
        'en': {'correct': 'This explains why b is correct in enough detail.'},
      },
    };
    final quiz = quizWith([q, ..._fiveDistinctQuestions().skip(1)]);
    final out = IssueCollector();
    validateQuiz('design.l1.golden-lesson', quiz, SchemaValidator(realRepo()), out, QuizValidationContext());
    expect(out.issues.any((i) => i.rule == 'Q10'), isTrue);
  });

  test('Q11: fill question missing "___"', () {
    final q = {
      'id': 'design.l1.golden-lesson.q1',
      'type': 'fill',
      'bloom': 'remember',
      'difficulty': 1,
      'skills': ['design.test.skill'],
      'section_ref': 3,
      'question': {'vi': 'Điền vào chỗ trống', 'en': 'Fill in the blank without one'},
      'answer': ['widget'],
      'explanation': {
        'vi': {'correct': 'Giải thích đúng dài đủ 20 ký tự.'},
        'en': {'correct': 'This explains the fill-in answer in enough detail.'},
      },
    };
    final quiz = quizWith([q, ..._fiveDistinctQuestions().skip(1)]);
    final out = IssueCollector();
    validateQuiz('design.l1.golden-lesson', quiz, SchemaValidator(realRepo()), out, QuizValidationContext());
    expect(out.issues.any((i) => i.rule == 'Q11'), isTrue);
  });

  test('Q12: two questions are near-duplicates (Jaccard > 0.7)', () {
    final q1 = _singleQuestion(id: 'design.l1.golden-lesson.q1');
    final q2 = _singleQuestion(id: 'design.l1.golden-lesson.q2');
    // same "question.en" text as q1 -> Jaccard 1.0
    final quiz = quizWith([q1, q2, ..._fiveDistinctQuestions().skip(2)]);
    final out = IssueCollector();
    validateQuiz('design.l1.golden-lesson', quiz, SchemaValidator(realRepo()), out, QuizValidationContext());
    expect(out.issues.any((i) => i.rule == 'Q12'), isTrue);
  });

  test('Q13: question skill not a subset of the lesson skills', () {
    final fixture = buildGoldenTree();
    final q = _singleQuestion(skills: ['design.other.skill']);
    final quiz = quizWith([q, ..._fiveDistinctQuestions().skip(1)]);
    final out = IssueCollector();
    validateQuiz('design.l1.golden-lesson', quiz, SchemaValidator(realRepo()), out,
        QuizValidationContext(lesson: fixture.golden));
    expect(out.issues.any((i) => i.rule == 'Q13'), isTrue);
  });

  test('Q03: bloom distribution far off the stage table', () {
    // Stage 1 table: remember 15%, understand 40%, apply 35%, analyze/evaluate 10%.
    // All 5 questions "remember" is wildly over the expected ~1 question.
    final fixture = buildGoldenTree(); // stage 1
    final questions = _fiveDistinctQuestions().map((q) => {...q, 'bloom': 'remember'}).toList();
    final quiz = quizWith(questions, stage: 1);
    final out = IssueCollector();
    validateQuiz('design.l1.golden-lesson', quiz, SchemaValidator(realRepo()), out,
        QuizValidationContext(lesson: fixture.golden));
    expect(out.issues.any((i) => i.rule == 'Q03'), isTrue);
  });

  test('Q14: gate bank has too few cross-track scenario questions', () {
    final questions = List.generate(10, (i) {
      final q = _singleQuestion(id: 'gate1.q${i + 1}', skills: ['design.test.skill', 'design.other.skill']);
      return q;
    });
    final quiz = {'gate': 'gate1', 'stage': 1, 'questions': questions};
    final out = IssueCollector();
    validateQuiz('gate1', quiz, SchemaValidator(realRepo()), out,
        QuizValidationContext(isGate: true, gateStage: 1));
    expect(out.issues.any((i) => i.rule == 'Q14'), isTrue);
  });

  test('Q15: order options already match the answer sequence', () {
    final q = {
      'id': 'design.l1.golden-lesson.q1',
      'type': 'order',
      'bloom': 'remember',
      'difficulty': 1,
      'skills': ['design.test.skill'],
      'section_ref': 3,
      'question': {'vi': 'Sắp xếp', 'en': 'Put these in order'},
      'options': [
        _opt('a', 'Step one of the sequence'),
        _opt('b', 'Step two of the sequence'),
        _opt('c', 'Step three of the sequence'),
      ],
      'answer': ['a', 'b', 'c'],
      'explanation': {
        'vi': {'correct': 'Giải thích đúng dài đủ 20 ký tự.'},
        'en': {'correct': 'This explains the correct order in enough detail.'},
      },
    };
    final quiz = quizWith([q, ..._fiveDistinctQuestions().skip(1)]);
    final out = IssueCollector();
    validateQuiz('design.l1.golden-lesson', quiz, SchemaValidator(realRepo()), out, QuizValidationContext());
    expect(out.issues.any((i) => i.rule == 'Q15'), isTrue);
  });
}
