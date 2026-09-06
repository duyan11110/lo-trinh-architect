/// Q01–Q15 — lesson quiz (.quiz.json) and gate bank rules.
library rules_quiz;

import 'bloom.dart';
import 'content_tree.dart';
import 'errors.dart';
import 'schema_validator.dart';

int _wordCount(String s) => s.trim().isEmpty ? 0 : s.trim().split(RegExp(r'\s+')).length;

Set<String> _tokens(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ').split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toSet();

double _jaccard(Set<String> a, Set<String> b) {
  if (a.isEmpty && b.isEmpty) return 1;
  final inter = a.intersection(b).length;
  final union = a.union(b).length;
  if (union == 0) return 0;
  return inter / union;
}

final List<String> _bannedOptionPhrases = [
  'all of the above',
  'none of the above',
  'tất cả',
  'không ý nào',
];

class QuizValidationContext {
  final LessonEntry? lesson; // null for a gate bank
  final bool isGate;
  final int? gateStage;
  final int maxSectionRef; // 9 or 11
  final List<String> sectionHeadings6; // misconception bullets for Q06 (optional)
  final ContentTree? tree;

  QuizValidationContext({
    this.lesson,
    this.isGate = false,
    this.gateStage,
    this.maxSectionRef = 9,
    this.sectionHeadings6 = const [],
    this.tree,
  });
}

void validateQuiz(
  String id,
  Map<String, dynamic> quiz,
  SchemaValidator sv,
  IssueCollector out,
  QuizValidationContext ctx,
) {
  final schemaErrs = sv.validate('quiz.schema.json', quiz);
  for (final e in schemaErrs) {
    out.error(id, 'Q01', 'quiz không qua schema: $e');
  }
  if (!ctx.isGate) {
    if (quiz['lesson'] != id) {
      out.error(id, 'Q01', 'quiz.lesson "${quiz['lesson']}" lệch với bài "$id"');
    }
    if (ctx.lesson != null && quiz['stage'] != ctx.lesson!.stage) {
      out.error(id, 'Q01', 'quiz.stage lệch với bài (mong đợi ${ctx.lesson!.stage})');
    }
  }

  final questions = ((quiz['questions'] as List?) ?? []).cast<Map<String, dynamic>>();
  final n = questions.length;

  // Q02
  if (ctx.isGate) {
    if (n < 90) out.error(id, 'Q02', 'gate có $n câu, tối thiểu 90');
  } else {
    if (n < 5 || n > 7) out.error(id, 'Q02', 'bài có $n câu, phải trong [5,7]');
  }

  // Q03 bloom distribution
  final stage = ctx.isGate ? ctx.gateStage : ctx.lesson?.stage;
  if (stage != null && kBloomDistribution.containsKey(stage) && n > 0) {
    final dist = kBloomDistribution[stage]!;
    final counts = <String, int>{'remember': 0, 'understand': 0, 'apply': 0, 'analyze_evaluate': 0};
    for (final q in questions) {
      final bucket = bloomBucket(q['bloom'] as String? ?? '');
      counts[bucket] = (counts[bucket] ?? 0) + 1;
    }
    for (final bucketEntry in dist.entries) {
      final bucket = bucketEntry.key;
      final pct = bucketEntry.value;
      final actual = counts[bucket] ?? 0;
      if (ctx.isGate) {
        final actualPct = 100.0 * actual / n;
        if ((actualPct - pct).abs() > 5) {
          out.error(id, 'Q03',
              'phân bố Bloom "$bucket": $actual/$n (${actualPct.toStringAsFixed(1)}%) lệch quá 5 điểm % so với $pct%');
        }
      } else {
        final range = acceptedCountRange(n, pct);
        if (!range.contains(actual)) {
          out.error(id, 'Q03',
              'phân bố Bloom "$bucket": $actual câu, phải trong [${range.min},${range.max}] (kỳ vọng ${pct}% của $n)');
        }
      }
    }
  }

  for (final q in questions) {
    _validateQuestion(id, q, ctx, out);
  }

  // Q12 duplicate questions (Jaccard token > 0.7) within this quiz
  for (int i = 0; i < questions.length; i++) {
    for (int j = i + 1; j < questions.length; j++) {
      final qi = (questions[i]['question'] as Map<String, dynamic>?)?['en'] as String? ?? '';
      final qj = (questions[j]['question'] as Map<String, dynamic>?)?['en'] as String? ?? '';
      if (qi.isEmpty || qj.isEmpty) continue;
      final sim = _jaccard(_tokens(qi), _tokens(qj));
      if (sim > 0.7) {
        out.error(id, 'Q12',
            'câu ${questions[i]['id']} và ${questions[j]['id']} trùng ý (Jaccard ${sim.toStringAsFixed(2)})');
      }
    }
  }

  if (ctx.isGate) {
    _validateQ14GateMix(id, questions, out);
  }
}

void _validateQuestion(String id, Map<String, dynamic> q, QuizValidationContext ctx, IssueCollector out) {
  final qid = q['id'] as String? ?? '?';
  final type = q['type'] as String?;
  final options = ((q['options'] as List?) ?? []).cast<Map<String, dynamic>>();
  final answer = ((q['answer'] as List?) ?? []).map((e) => e.toString()).toList();
  final explanation = q['explanation'] as Map<String, dynamic>?;

  // Q04 section_ref
  if (!ctx.isGate) {
    final sectionRef = q['section_ref'];
    if (sectionRef == null) {
      out.error(id, 'Q04', 'câu $qid thiếu section_ref');
    } else if (sectionRef is int && (sectionRef < 1 || sectionRef > ctx.maxSectionRef)) {
      out.error(id, 'Q04', 'câu $qid section_ref=$sectionRef trỏ mục không có (tối đa ${ctx.maxSectionRef})');
    }
  }

  // Q05 explanation coverage for wrong options
  if (options.isNotEmpty && explanation != null) {
    for (final lang in ['vi', 'en']) {
      final expl = explanation[lang] as Map<String, dynamic>?;
      if (expl == null) continue;
      for (final opt in options) {
        final optId = opt['id'] as String;
        if (answer.contains(optId)) continue;
        if (!expl.containsKey(optId)) {
          out.error(id, 'Q05', 'câu $qid: phương án sai "$optId" thiếu explanation.$lang.$optId');
        }
      }
    }
  }

  // Q06 misconception must roughly match outline.misconceptions or a mục 6/8 bullet
  final lessonMisconceptions = [...(ctx.lesson?.misconceptions ?? []), ...ctx.sectionHeadings6];
  if (!ctx.isGate && lessonMisconceptions.isNotEmpty) {
    for (final opt in options) {
      final m = opt['misconception'] as String?;
      if (m == null) continue;
      final matched = lessonMisconceptions.any((mc) => _jaccard(_tokens(mc), _tokens(m)) >= 0.6);
      if (!matched) {
        out.error(id, 'Q06',
            'câu $qid: misconception "$m" không khớp (≥60% từ chung) mục nào trong misconceptions của outline hoặc mục ngộ nhận');
      }
    }
  }

  // Q07 banned option phrases
  for (final opt in options) {
    for (final lang in ['vi', 'en']) {
      final text = (opt[lang] as String? ?? '').toLowerCase();
      for (final banned in _bannedOptionPhrases) {
        if (text.contains(banned)) {
          out.error(id, 'Q07', 'câu $qid: phương án "${opt['id']}" chứa cụm cấm "$banned"');
        }
      }
    }
  }

  // Q08 answer length reveal (single/scenario)
  if ((type == 'single' || type == 'scenario') && options.isNotEmpty && answer.length == 1) {
    final lens = options.map((o) => (o['en'] as String? ?? '').length).toList();
    final avg = lens.reduce((a, b) => a + b) / lens.length;
    final correctOpt = options.firstWhere((o) => o['id'] == answer.first, orElse: () => {});
    if (correctOpt.isNotEmpty) {
      final correctLen = (correctOpt['en'] as String? ?? '').length;
      if (avg > 0 && (correctLen - avg).abs() / avg > 0.6) {
        out.error(id, 'Q08', 'câu $qid: độ dài phương án đúng lệch > 60% so với trung bình (lộ đáp án)');
      }
    }
  }

  // Q09 truefalse
  if (type == 'truefalse') {
    if (options.length != 4) {
      out.error(id, 'Q09', 'câu $qid: truefalse phải có 4 phương án');
    } else {
      final expectedPolarity = {'a': 'true', 'b': 'true', 'c': 'false', 'd': 'false'};
      for (final opt in options) {
        final optId = opt['id'] as String;
        if (opt['polarity'] != expectedPolarity[optId]) {
          out.error(id, 'Q09', 'câu $qid: phương án $optId phải polarity=${expectedPolarity[optId]}');
        }
        final en = opt['en'] as String? ?? '';
        final vi = opt['vi'] as String? ?? '';
        if (expectedPolarity[optId] == 'true') {
          if (!en.startsWith('True, because')) out.error(id, 'Q09', 'câu $qid: $optId (en) phải bắt đầu "True, because"');
          if (!vi.startsWith('Đúng, vì')) out.error(id, 'Q09', 'câu $qid: $optId (vi) phải bắt đầu "Đúng, vì"');
        } else {
          if (!en.startsWith('False, because')) out.error(id, 'Q09', 'câu $qid: $optId (en) phải bắt đầu "False, because"');
          if (!vi.startsWith('Sai, vì')) out.error(id, 'Q09', 'câu $qid: $optId (vi) phải bắt đầu "Sai, vì"');
        }
      }
    }
    if (answer.length != 1) {
      out.error(id, 'Q09', 'câu $qid: truefalse phải có đúng 1 đáp án');
    }
  }

  // Q10 scenario
  if (type == 'scenario') {
    final context = q['context'] as Map<String, dynamic>?;
    final ctxEn = context?['en'] as String? ?? '';
    final wc = _wordCount(ctxEn);
    final range = ctx.isGate ? const [80, 150] : const [40, 150];
    if (wc < range[0] || wc > range[1]) {
      out.error(id, 'Q10', 'câu $qid: context có $wc từ, phải trong [${range[0]},${range[1]}]');
    }
    if (explanation != null) {
      for (final lang in ['vi', 'en']) {
        final expl = explanation[lang] as Map<String, dynamic>?;
        if (expl == null) continue;
        final needle = lang == 'vi' ? 'khi' : 'when';
        for (final opt in options) {
          final optId = opt['id'] as String;
          if (answer.contains(optId)) continue;
          final text = (expl[optId] as String? ?? '').toLowerCase();
          if (text.isNotEmpty && !text.contains(needle)) {
            out.error(id, 'Q10', 'câu $qid: explanation.$lang.$optId thiếu điều kiện "$needle"');
          }
        }
      }
    }
  }

  // Q11 fill
  if (type == 'fill') {
    final question = q['question'] as Map<String, dynamic>?;
    for (final lang in ['vi', 'en']) {
      final text = question?[lang] as String? ?? '';
      if (!text.contains('___')) {
        out.error(id, 'Q11', 'câu $qid: fill.question.$lang phải chứa "___"');
      }
    }
    if (answer.isEmpty || answer.any((a) => a.trim().isEmpty)) {
      out.error(id, 'Q11', 'câu $qid: fill.answer rỗng');
    }
  }

  // Q13 skills subset (bài) / gate skill checks
  final qSkills = ((q['skills'] as List?) ?? []).map((e) => e.toString()).toList();
  if (ctx.isGate) {
    if (qSkills.length < 2) {
      out.error(id, 'Q13', 'câu $qid (gate): cần ≥ 2 skill');
    }
    if (ctx.tree != null) {
      for (final s in qSkills) {
        if (!ctx.tree!.skillExists(s)) {
          out.error(id, 'Q13', 'câu $qid (gate): skill "$s" không tồn tại');
        }
      }
    }
  } else if (ctx.lesson != null) {
    for (final s in qSkills) {
      if (!ctx.lesson!.skills.contains(s)) {
        out.error(id, 'Q13', 'câu $qid: skill "$s" ⊄ skills của bài');
      }
    }
  }

  // Q15 order not shuffled
  if (type == 'order' && options.isNotEmpty) {
    final optionIds = options.map((o) => o['id'] as String).toList();
    if (_listEquals(optionIds, answer)) {
      out.error(id, 'Q15', 'câu $qid: order options chưa được xáo (trùng thứ tự answer)');
    }
  }
}

bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

void _validateQ14GateMix(String id, List<Map<String, dynamic>> questions, IssueCollector out) {
  final scenarioCount = questions.where((q) => q['type'] == 'scenario').length;
  if (scenarioCount < 3 || scenarioCount > 5) {
    out.error(id, 'Q14', 'gate cần 3–5 câu scenario xuyên track, thấy $scenarioCount');
  }
}
