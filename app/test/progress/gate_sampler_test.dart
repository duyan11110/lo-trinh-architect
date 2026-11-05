// gate_sampler (docs/07 §5.4, §9) and module_quiz_sampler (§5.5) on content
// built in Dart (DECISIONS.md E6) with a seeded Random (E7): ratio by track,
// 3 cross-track scenarios, avoiding the last draw, fixed seed, round-robin
// over modules, "Nên đọc lại".
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lta_app/content/models/models.dart';
import 'package:lta_app/progress/gate_sampler.dart';
import 'package:lta_app/progress/module_quiz_sampler.dart';

import '../fixtures/content_builder.dart';

Question _q(
  String id, {
  String? track,
  String? module,
  QuestionType type = QuestionType.single,
  List<String> skills = const ['skill.one'],
  Bloom bloom = Bloom.understand,
}) {
  final b = buildQuestion(id, type, bloom: bloom);
  return Question(
    id: b.id,
    type: b.type,
    bloom: b.bloom,
    difficulty: b.difficulty,
    skills: skills,
    track: track,
    module: module,
    sectionRef: b.sectionRef,
    context: b.context,
    question: b.question,
    options: b.options,
    answer: b.answer,
    answerRegex: b.answerRegex,
    explanationVi: b.explanationVi,
    explanationEn: b.explanationEn,
  );
}

List<BLesson> _lessons(String prefix, int n) => [
  for (var i = 0; i < n; i++) BLesson('$prefix-$i'),
];

/// Stage 0: foundation 30 main-path lessons over 5 modules, management 6.
final _modules = [
  for (var m = 0; m < 5; m++)
    BModule('foundation', 'm$m', 0, _lessons('f$m', 6)),
  BModule('management', 'team', 0, _lessons('t', 6)),
];

Content _content({List<Skill> skills = const []}) {
  final c = buildContent(_modules);
  return Content(
    meta: c.meta,
    stages: c.stages,
    tracks: c.tracks,
    lessons: c.lessons,
    quizzes: c.quizzes,
    gates: c.gates,
    glossary: c.glossary,
    skills: skills,
  );
}

/// [foundation] questions spread over 5 modules, [management] in one module,
/// [cross] cross-track scenarios (track ''), like the real gate0 bank.
Gate _gate({int foundation = 80, int management = 16, int cross = 6}) {
  var n = 0;
  String id() => 'gate0.q${++n}';
  return Gate(
    gate: 'gate0',
    stage: 0,
    questions: [
      for (var i = 0; i < foundation; i++)
        _q(id(), track: 'foundation', module: 'm${i % 5}'),
      for (var i = 0; i < management; i++)
        _q(id(), track: 'management', module: 'team'),
      for (var i = 0; i < cross; i++)
        _q(id(), track: '', module: '', type: QuestionType.scenario),
    ],
  );
}

void main() {
  final content = _content();

  Map<String, int> countByTrack(Gate gate, List<String> ids) {
    final byId = {for (final q in gate.questions) q.id: q};
    final out = <String, int>{};
    for (final id in ids) {
      final t = gateTrackOf(byId[id]!) ?? 'cross';
      out[t] = (out[t] ?? 0) + 1;
    }
    return out;
  }

  group('GateSampler', () {
    test('35 distinct questions from the bank', () {
      final gate = _gate();
      final ids = GateSampler.sample(content: content, gate: gate, random: Random(1));
      expect(ids, hasLength(35));
      expect(ids.toSet(), hasLength(35));
      expect(ids.every({for (final q in gate.questions) q.id}.contains), isTrue);
    });

    test('3 cross-track scenarios, the rest by main-path lesson ratio', () {
      final gate = _gate();
      final ids = GateSampler.sample(content: content, gate: gate, random: Random(2));
      // (35 − 3) × 30/36 = 26.67 → 27; × 6/36 = 5.33 → 5.
      expect(countByTrack(gate, ids), {'cross': 3, 'foundation': 27, 'management': 5});
    });

    test('fewer than 3 cross scenarios: all of them, tracks fill the rest', () {
      final gate = _gate(cross: 2);
      final ids = GateSampler.sample(content: content, gate: gate, random: Random(3));
      final counts = countByTrack(gate, ids);
      expect(counts['cross'], 2);
      expect(counts['foundation']! + counts['management']!, 33);
      expect(ids, hasLength(35));
    });

    test('same seed → same draw; another seed → another draw', () {
      final gate = _gate();
      List<String> draw(int seed) =>
          GateSampler.sample(content: content, gate: gate, random: Random(seed));
      expect(draw(42), draw(42));
      expect(draw(42), isNot(draw(43)));
    });

    test('the last attempt is excluded when ≥ N others remain', () {
      final gate = _gate();
      final first = GateSampler.sample(content: content, gate: gate, random: Random(5));
      final second = GateSampler.sample(
        content: content,
        gate: gate,
        random: Random(6),
        lastUsed: first,
      );
      expect(second.toSet().intersection(first.toSet()), isEmpty);
    });

    test('small bank: every unused question comes before a repeat', () {
      final gate = _gate(foundation: 30, management: 6, cross: 4); // 40
      final first = GateSampler.sample(content: content, gate: gate, random: Random(7));
      final unused = {for (final q in gate.questions) q.id}.difference(first.toSet());
      expect(unused, hasLength(5));
      final second = GateSampler.sample(
        content: content,
        gate: gate,
        random: Random(8),
        lastUsed: first,
      );
      expect(second, hasLength(35));
      expect(second.toSet().containsAll(unused), isTrue);
    });

    test('a track is spread round-robin over its modules', () {
      final gate = _gate();
      final byId = {for (final q in gate.questions) q.id: q};
      final ids = GateSampler.sample(content: content, gate: gate, random: Random(9));
      final perModule = <String, int>{};
      for (final id in ids) {
        final q = byId[id]!;
        if (q.track == 'foundation') {
          perModule[q.module!] = (perModule[q.module!] ?? 0) + 1;
        }
      }
      // 27 over 5 modules → 5 or 6 each.
      expect(perModule.keys, hasLength(5));
      expect(perModule.values.every((v) => v == 5 || v == 6), isTrue);
    });

    test('a bank smaller than N is drawn whole', () {
      final gate = _gate(foundation: 10, management: 2, cross: 1);
      final ids = GateSampler.sample(content: content, gate: gate, random: Random(1));
      expect(ids.toSet(), {for (final q in gate.questions) q.id});
    });

    test('allocate rounds to the total and moves overflow past a cap', () {
      expect(GateSampler.allocate(32, {'a': 30, 'b': 6}, {'a': 99, 'b': 99}), {
        'a': 27,
        'b': 5,
      });
      expect(GateSampler.allocate(32, {'a': 30, 'b': 6}, {'a': 20, 'b': 99}), {
        'a': 20,
        'b': 12,
      });
      expect(GateSampler.allocate(10, {'a': 1, 'b': 1, 'c': 1}, {'a': 9, 'b': 9, 'c': 9})
          .values
          .fold<int>(0, (s, v) => s + v), 10);
    });

    test('Nên đọc lại: lessons with ≥ 2 wrong questions, else top 3', () {
      final ids = [for (final r in buildMainPathIds()) r];
      final c = _content(
        skills: [
          Skill(id: 's1', title: const I18n(vi: 's1', en: 's1'), track: 'foundation', prereqs: const [], lessons: [ids[0]]),
          Skill(id: 's2', title: const I18n(vi: 's2', en: 's2'), track: 'foundation', prereqs: const [], lessons: [ids[1], ids[2]]),
          Skill(id: 's3', title: const I18n(vi: 's3', en: 's3'), track: 'foundation', prereqs: const [], lessons: [ids[3]]),
          Skill(id: 's4', title: const I18n(vi: 's4', en: 's4'), track: 'foundation', prereqs: const [], lessons: [ids[4]]),
        ],
      );
      final twice = GateSampler.rereadLessons(c, [
        _q('g.q1', skills: ['s1', 's2']),
        _q('g.q2', skills: ['s2']),
        _q('g.q3', skills: ['s3']),
      ]);
      expect(twice, [ids[1], ids[2]]);
      final top = GateSampler.rereadLessons(c, [
        _q('g.q1', skills: ['s4']),
        _q('g.q2', skills: ['s3']),
        _q('g.q3', skills: ['s1']),
        _q('g.q4', skills: ['s2']),
      ]);
      expect(top, [ids[0], ids[1], ids[2]], reason: 'path order breaks ties');
    });
  });

  group('ModuleQuizSampler', () {
    BModule module(int lessons) => BModule('backend', 'web', 0, _lessons('w', lessons));

    Content withQuizzes(BModule m, int perLesson) {
      final quizzes = <String, Quiz>{
        for (final l in m.lessons)
          m.lessonId(l): Quiz(
            lesson: m.lessonId(l),
            stage: 0,
            questions: [
              for (var i = 1; i <= perLesson; i++)
                _q(
                  '${m.lessonId(l)}.q$i',
                  bloom: i == 1 ? Bloom.apply : Bloom.remember,
                ),
            ],
          ),
      };
      return buildContent([m], quizzes: quizzes);
    }

    test('15 questions, every lesson at least once, apply first', () {
      final m = module(5);
      final c = withQuizzes(m, 6);
      final tm = c.module('backend/web')!;
      final ids = ModuleQuizSampler.sample(content: c, module: tm, random: Random(1));
      expect(ids, hasLength(ModuleQuizSampler.maxQuestions));
      expect(ids.toSet(), hasLength(ids.length));
      for (final l in m.lessons) {
        expect(ids.any((id) => id.startsWith('${m.lessonId(l)}.')), isTrue);
        expect(ids, contains('${m.lessonId(l)}.q1'), reason: 'bloom apply');
      }
    });

    test('questions answered wrong before are preferred', () {
      final m = module(2);
      final c = withQuizzes(m, 10);
      final tm = c.module('backend/web')!;
      final wrong = {for (var i = 5; i <= 10; i++) '${m.lessonId(m.lessons.first)}.q$i'};
      final ids = ModuleQuizSampler.sample(
        content: c,
        module: tm,
        random: Random(2),
        wrongBefore: wrong,
      );
      expect(ids.toSet().containsAll(wrong), isTrue);
    });

    test('a small module gives every question; seed is reproducible', () {
      final m = module(2);
      final c = withQuizzes(m, 4);
      final tm = c.module('backend/web')!;
      final a = ModuleQuizSampler.sample(content: c, module: tm, random: Random(3));
      expect(a, hasLength(8));
      expect(ModuleQuizSampler.sample(content: c, module: tm, random: Random(3)), a);
    });
  });
}

/// Main-path lesson ids of [_modules] in path order.
List<String> buildMainPathIds() => [
  for (final m in _modules)
    for (final l in m.lessons) m.lessonId(l),
];
