/// CLI orchestration for `tools/validate`. See tools/SPEC.md.
library validate_runner;

import 'dart:io';

import 'code_source.dart';
import 'content_tree.dart';
import 'errors.dart';
import 'repo.dart';
import 'rules_lesson.dart';
import 'rules_meta.dart';
import 'rules_parity.dart';
import 'rules_path.dart';
import 'rules_quiz.dart';
import 'rules_review.dart';
import 'rules_structure.dart';
import 'schema_validator.dart';
import 'yaml_json.dart';

class ValidateArgs {
  String? lessonId;
  String? filePath;
  String? moduleArg;
  int? stageArg;
  bool structureOnly = false;
  bool noRepo = false;
  String? repoDir;
  String? parityId;
  bool orderMode = false;
  int? manifestStage;
}

ValidateArgs parseValidateArgs(List<String> argv) {
  final a = ValidateArgs();
  int i = 0;
  while (i < argv.length) {
    final arg = argv[i];
    switch (arg) {
      case '--file':
        a.filePath = argv[++i];
        break;
      case '--module':
        a.moduleArg = argv[++i];
        break;
      case '--stage':
        a.stageArg = int.parse(argv[++i]);
        break;
      case '--structure-only':
        a.structureOnly = true;
        break;
      case '--no-repo':
        a.noRepo = true;
        break;
      case '--repo-dir':
        a.repoDir = argv[++i];
        break;
      case '--parity':
        a.parityId = argv[++i];
        break;
      case '--order':
        a.orderMode = true;
        break;
      case '--manifest':
        a.manifestStage = int.parse(argv[++i]);
        break;
      default:
        if (!arg.startsWith('--')) {
          a.lessonId = arg;
        }
        break;
    }
    i++;
  }
  return a;
}

class LessonFiles {
  final String base;
  LessonFiles(this.base);
  String get enMd => '$base.en.md';
  String get viMd => '$base.vi.md';
  String get metaJson => '$base.meta.json';
  String get quizJson => '$base.quiz.json';
  String get reviewJson => '$base.review.json';
}

LessonFiles lessonFiles(Repo repo, LessonEntry lesson) {
  final base = repo.path('content/tracks/${lesson.track}/${lesson.moduleId}/${lesson.id}');
  return LessonFiles(base);
}

int runValidate(List<String> argv) {
  final repo = Repo.find();
  final sv = SchemaValidator(repo);
  final tree = ContentTree.load(repo);
  final out = IssueCollector();
  final args = parseValidateArgs(argv);

  if (args.orderMode) {
    for (final l in tree.lessonsInGlobalOrder) {
      print('${l.globalOrder}\t${l.id}');
    }
    return 0;
  }
  if (args.manifestStage != null) {
    for (final line in manifestForStage(tree, args.manifestStage!)) {
      print(line);
    }
    return 0;
  }

  if (args.filePath != null) {
    _validateFileMode(repo, args, out);
    out.printAll();
    return out.hasErrors ? 1 : 0;
  }

  if (args.parityId != null) {
    _validateParityMode(repo, tree, args.parityId!, out);
    out.printAll();
    return out.hasErrors ? 1 : 0;
  }

  if (args.structureOnly) {
    checkS01TrackSchemas(tree, sv, out);
    checkS03ModulePresence(tree, out, stageFilter: args.stageArg);
    checkS04Prereqs(tree, out, stageFilter: args.stageArg);
    checkS05Skills(tree, out, stageFilter: args.stageArg);
    checkS06Vocab(tree, out, stageFilter: args.stageArg);
    checkS08Related(tree, out, stageFilter: args.stageArg);
    validatePath(tree, sv, out);
    out.printAll();
    return out.hasErrors ? 1 : 0;
  }

  checkS01TrackSchemas(tree, sv, out);
  checkS02DuplicateIds(tree, out);
  checkS03ModulePresence(tree, out, stageFilter: args.stageArg);
  checkS04Prereqs(tree, out, stageFilter: args.stageArg);
  checkS05Skills(tree, out, stageFilter: args.stageArg);
  checkS06Vocab(tree, out, stageFilter: args.stageArg);
  checkS07ExampleFiles(tree, repo, out, repoDir: args.repoDir, noRepo: args.noRepo, stageFilter: args.stageArg);
  checkS08Related(tree, out, stageFilter: args.stageArg);

  List<LessonEntry> targets;
  if (args.lessonId != null) {
    final l = tree.lesson(args.lessonId!);
    if (l == null) {
      out.error(args.lessonId!, 'S02', 'lesson id không tồn tại trong content tree');
      out.printAll();
      return 1;
    }
    targets = [l];
  } else if (args.moduleArg != null) {
    final module = tree.modulesByKey[args.moduleArg!];
    if (module == null) {
      out.error(args.moduleArg!, 'S03', 'module không tồn tại trong track.yaml');
      out.printAll();
      return 1;
    }
    targets = module.lessons;
  } else if (args.stageArg != null) {
    targets = tree.lessonsById.values.where((l) => l.stage == args.stageArg).toList();
  } else {
    targets = tree.lessonsById.values.toList();
  }

  for (final lesson in targets) {
    _validateLessonFull(repo, tree, sv, lesson, out, repoDir: args.repoDir, noRepo: args.noRepo);
  }

  out.printAll();
  return out.hasErrors ? 1 : 0;
}

void _validateLessonFull(
  Repo repo,
  ContentTree tree,
  SchemaValidator sv,
  LessonEntry lesson,
  IssueCollector out, {
  String? repoDir,
  bool noRepo = false,
}) {
  final files = lessonFiles(repo, lesson);
  if (!File(files.enMd).existsSync()) {
    out.error(lesson.id, 'L01', '.en.md không tồn tại tại ${files.enMd}');
    return;
  }
  final fmDoc = parseFrontmatter(files.enMd);
  final codeSource = CodeSource(gitRepoPath: repo.path('examples/don-hang'), repoDir: repoDir);
  final input = LessonValidationInput(
    id: lesson.id,
    frontmatter: fmDoc.frontmatter,
    body: fmDoc.body,
    tree: tree,
    codeSource: codeSource,
    noRepo: noRepo,
  );
  validateLesson(input, sv, out);

  final status = fmDoc.frontmatter['status'] as String? ?? 'draft';

  Map<String, dynamic>? meta;
  if (File(files.metaJson).existsSync()) {
    meta = loadJsonFile(files.metaJson) as Map<String, dynamic>;
    final codeBlockCount = countLessonCodeBlocks(fmDoc.body);
    validateMeta(lesson.id, meta, codeBlockCount, sv, out, lesson: lesson);
  }

  if (File(files.quizJson).existsSync()) {
    final quiz = loadJsonFile(files.quizJson) as Map<String, dynamic>;
    final level = fmDoc.frontmatter['level'] as int? ?? 1;
    final maxSectionRef = level == 4 ? 11 : 9;
    final beliefs = extractMisconceptionBeliefs(fmDoc.body, level);
    validateQuiz(
      lesson.id,
      quiz,
      sv,
      out,
      QuizValidationContext(
          lesson: lesson, maxSectionRef: maxSectionRef, tree: tree, sectionHeadings6: beliefs),
    );
  }

  final claims = ((meta?['claims'] as List?) ?? []).cast<Map<String, dynamic>>();
  Map<String, dynamic>? review;
  if (File(files.reviewJson).existsSync()) {
    review = loadJsonFile(files.reviewJson) as Map<String, dynamic>;
  }
  if (review != null || _atLeastReviewed(status)) {
    validateReview(lesson.id, review, status, claims, sv, out);
  }

  if (File(files.viMd).existsSync()) {
    final viDoc = parseFrontmatter(files.viMd);
    // Parity (P) only runs explicitly via --parity per SPEC; nothing to do here.
    // ignore: unused_local_variable
    final _ = viDoc;
  }
}

bool _atLeastReviewed(String status) => status == 'reviewed' || status == 'approved' || status == 'published';

void _validateFileMode(Repo repo, ValidateArgs args, IssueCollector out) {
  final path = args.filePath!;
  final file = File(path);
  if (!file.existsSync()) {
    out.error(path, 'L01', 'file không tồn tại: $path');
    return;
  }
  final sv = SchemaValidator(repo);
  final fmDoc = parseFrontmatter(path);
  final id = (fmDoc.frontmatter['id'] as String?) ?? path;
  final codeSource = CodeSource(gitRepoPath: repo.path('examples/don-hang'), repoDir: args.repoDir);
  final input = LessonValidationInput(
    id: id,
    frontmatter: fmDoc.frontmatter,
    body: fmDoc.body,
    tree: null,
    codeSource: codeSource,
    noRepo: args.noRepo,
  );
  validateLesson(input, sv, out);
}

void _validateParityMode(Repo repo, ContentTree tree, String id, IssueCollector out) {
  final lesson = tree.lesson(id);
  if (lesson == null) {
    out.error(id, 'P01', 'lesson id không tồn tại trong content tree');
    return;
  }
  final files = lessonFiles(repo, lesson);
  if (!File(files.viMd).existsSync()) {
    return; // "nhóm P chỉ khi có .vi.md"
  }
  if (!File(files.enMd).existsSync()) {
    out.error(id, 'P01', '.en.md không tồn tại');
    return;
  }
  final enDoc = parseFrontmatter(files.enMd);
  final viDoc = parseFrontmatter(files.viMd);
  validateParity(id, enDoc.frontmatter, enDoc.body, viDoc.frontmatter, viDoc.body, lesson, tree, out);
}
