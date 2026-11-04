// Test-only content built in Dart (DECISIONS.md E6: the sample file is never
// edited). Enough of the tree for the §5.2 algorithm: stages → modules →
// lessons, with side branches and lessons whose body is absent.
import 'package:lta_app/content/models/models.dart';

class BLesson {
  const BLesson(
    this.slug, {
    this.main = true,
    this.available = true,
    this.prereqs = const [],
  });
  final String slug;
  final bool main;

  /// Lesson ids.
  final List<String> prereqs;

  /// Body present in `content.lessons` (otherwise "sắp có").
  final bool available;
}

class BModule {
  const BModule(this.track, this.id, this.stage, this.lessons);
  final String track;
  final String id;
  final int stage;
  final List<BLesson> lessons;

  String lessonId(BLesson l) => '$track.l1.${l.slug}';
}

I18n _t(String s) => I18n(vi: s, en: s);

Lesson stubLesson(
  String id, {
  required String track,
  required String module,
  int stage = 0,
  int level = 1,
  bool mainPath = true,
  List<String> vocab = const [],
  List<String> prereqs = const [],
  int contentVersion = 1,
}) => Lesson(
  id: id,
  track: track,
  level: level,
  stage: stage,
  module: module,
  mainPath: mainPath,
  durationMin: 10,
  title: _t(id),
  skills: const [],
  prereqs: prereqs,
  related: const [],
  vocab: vocab,
  exampleTag: 'stage-$stage',
  sectionsVi: [LessonSection(n: 1, heading: 'h', md: 'x')],
  sectionsEn: [LessonSection(n: 1, heading: 'h', md: 'x')],
  diagramSvg: null,
  skipNote: null,
  contentVersion: contentVersion,
);

/// Modules are listed in `path.stages` in the given order.
Content buildContent(
  List<BModule> modules, {
  Map<String, Quiz> quizzes = const {},
}) {
  final stageNos = {for (final m in modules) m.stage}.toList()..sort();
  final trackIds = {for (final m in modules) m.track};
  final lessons = <String, Lesson>{};
  for (final m in modules) {
    for (final l in m.lessons) {
      if (!l.available) continue;
      final id = m.lessonId(l);
      lessons[id] = stubLesson(
        id,
        track: m.track,
        module: m.id,
        stage: m.stage,
        mainPath: l.main,
        prereqs: l.prereqs,
      );
    }
  }
  return Content(
    meta: const ContentMeta(
      contentVersion: 1,
      builtAt: '2026-11-05T00:00:00Z',
      versions: {},
      langs: ['vi', 'en'],
    ),
    stages: [
      for (final s in stageNos)
        PathStage(
          stage: s,
          title: _t('Stage $s'),
          gate: 'gate$s',
          outcome: null,
          modules: [
            for (final m in modules)
              if (m.stage == s) '${m.track}/${m.id}',
          ],
        ),
    ],
    tracks: [
      for (final t in trackIds)
        Track(
          id: t,
          title: _t(t),
          description: null,
          levels: [
            TrackLevel(
              level: 1,
              title: _t('L1'),
              modules: [
                for (final m in modules)
                  if (m.track == t)
                    TrackModule(
                      track: t,
                      id: m.id,
                      title: _t(m.id),
                      stage: m.stage,
                      summary: null,
                      lessons: [
                        for (final l in m.lessons)
                          LessonRef(
                            id: m.lessonId(l),
                            title: _t(m.lessonId(l)),
                            mainPath: l.main,
                            durationMin: 10,
                          ),
                      ],
                    ),
              ],
            ),
          ],
        ),
    ],
    lessons: lessons,
    quizzes: quizzes,
    gates: const {},
    glossary: const [],
    skills: const [],
  );
}

/// One question of [type] with explanations for every wrong option.
/// Options are `a`…; [answer] defaults to a valid key for the type.
Question buildQuestion(
  String id,
  QuestionType type, {
  int options = 4,
  List<String>? answer,
  List<bool?>? polarity,
  String? question,
  String? answerRegex,
  int? sectionRef = 4,
  Bloom? bloom,
}) {
  final ids = [for (var i = 0; i < (type == QuestionType.fill ? 0 : options); i++) String.fromCharCode(0x61 + i)];
  final key = answer ??
      switch (type) {
        QuestionType.multi => [ids[0], ids[2]],
        QuestionType.order => ids.reversed.toList(),
        QuestionType.fill => const ['Skip'],
        _ => [ids[1]],
      };
  String expl(String lang) => '$lang explanation that is long enough';
  return Question(
    id: id,
    type: type,
    bloom: bloom ??
        (type == QuestionType.scenario ? Bloom.apply : Bloom.understand),
    difficulty: 2,
    skills: const ['skill.one'],
    track: null,
    module: null,
    sectionRef: sectionRef,
    context: type == QuestionType.scenario
        ? _t('Context: a team of three ships a shop')
        : null,
    question: _t(question ??
        (type == QuestionType.fill
            ? 'Fill the blank: `.OrderBy(p => p.Id).___(offset)`'
            : 'Question $id ${type.name}')),
    options: [
      for (final (i, o) in ids.indexed)
        QuestionOption(
          id: o,
          text: _t('Option $o text'),
          misconception: null,
          polarity: polarity == null ? null : polarity[i],
        ),
    ],
    answer: key,
    answerRegex: answerRegex,
    explanationVi: {
      'correct': 'vi ${expl('correct')}',
      for (final o in ids)
        if (!key.contains(o)) o: 'vi why $o ${expl(o)}',
    },
    explanationEn: {
      'correct': 'en ${expl('correct')}',
      for (final o in ids)
        if (!key.contains(o)) o: 'en why $o ${expl(o)}',
    },
  );
}

/// A one-module, one-lesson content whose lesson has [questions] as quiz.
Content contentWithQuiz(List<Question> questions) {
  const module = BModule('backend', 'web', 0, [BLesson('quiz-lesson')]);
  final lessonId = module.lessonId(module.lessons.single);
  return buildContent(
    const [module],
    quizzes: {lessonId: Quiz(lesson: lessonId, stage: 0, questions: questions)},
  );
}

/// One module of 3 lessons × 6 questions and a 50-question gate0.
Content contentWithGate() {
  const m = BModule('backend', 'web', 0, [BLesson('a'), BLesson('b'), BLesson('c')]);
  final base = buildContent(
    const [m],
    quizzes: {
      for (final l in m.lessons)
        m.lessonId(l): Quiz(
          lesson: m.lessonId(l),
          stage: 0,
          questions: [
            for (var i = 1; i <= 6; i++)
              buildQuestion('${m.lessonId(l)}.q$i', QuestionType.single),
          ],
        ),
    },
  );
  return Content(
    meta: base.meta,
    stages: base.stages,
    tracks: base.tracks,
    lessons: base.lessons,
    quizzes: base.quizzes,
    gates: {
      'gate0': Gate(
        gate: 'gate0',
        stage: 0,
        questions: [
          for (var i = 1; i <= 50; i++) buildQuestion('gate0.q$i', QuestionType.single),
        ],
      ),
    },
    glossary: base.glossary,
    skills: base.skills,
  );
}
