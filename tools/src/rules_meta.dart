/// M01–M06 — sidecar `.meta.json` rules.
library rules_meta;

import 'content_tree.dart';
import 'errors.dart';
import 'markdown_util.dart';
import 'schema_validator.dart';

void validateMeta(
  String id,
  Map<String, dynamic> meta,
  int codeBlockCount,
  SchemaValidator sv,
  IssueCollector out, {
  LessonEntry? lesson,
}) {
  // validate schema, but ignore open_questions/repo_changes_needed content per spec
  final schemaErrs = sv.validate('meta.schema.json', meta);
  for (final e in schemaErrs) {
    out.error(id, 'M01', '.meta.json không qua schema: $e');
  }
  if (meta['id'] != id) {
    out.error(id, 'M01', '.meta.json id "${meta['id']}" lệch với bài "$id"');
  }

  final coverage = meta['coverage'] as Map<String, dynamic>?;
  if (coverage != null) {
    final missing = (coverage['outline_items_missing'] as List?) ?? [];
    if (missing.isNotEmpty) {
      out.error(id, 'M02', 'coverage.outline_items_missing khác rỗng: $missing');
    }
    if (lesson != null) {
      final n = lesson.outline.length;
      final covered = ((coverage['outline_items_covered'] as List?) ?? []).map((e) => e as int).toSet();
      final expected = Set<int>.from(List.generate(n, (i) => i + 1));
      if (covered.length != expected.length || !covered.containsAll(expected)) {
        out.error(id, 'M02',
            'coverage.outline_items_covered ($covered) phải bằng đúng tập 1..$n');
      }
    }
  }

  final claims = (meta['claims'] as List?) ?? [];
  for (final c in claims) {
    final claim = c as Map<String, dynamic>;
    final kind = claim['kind'] as String?;
    if (['behavior', 'number', 'syntax', 'history'].contains(kind) && claim['needs_verification'] != true) {
      out.error(id, 'M03', 'claim n=${claim['n']} kind=$kind phải needs_verification: true');
    }
  }

  final selfCheck = meta['self_check'] as Map<String, dynamic>?;
  if (selfCheck != null) {
    if (selfCheck['code_from_repo'] == false) {
      out.error(id, 'M04', 'self_check.code_from_repo = false');
    }
    if (selfCheck['no_external_urls'] == false) {
      out.error(id, 'M04', 'self_check.no_external_urls = false');
    }
  }

  if (codeBlockCount >= 1 && claims.length < 3) {
    out.warn(id, 'M05', 'bài có code block nhưng chỉ ${claims.length} claim (< 3), nghi ngờ bỏ sót');
  }

  final openQuestions = (meta['open_questions'] as List?) ?? [];
  if (openQuestions.isNotEmpty) {
    out.warn(id, 'M06', 'open_questions: ${openQuestions.join("; ")}');
  }
  final repoChanges = (meta['repo_changes_needed'] as List?) ?? [];
  if (repoChanges.isNotEmpty) {
    out.warn(id, 'M06', 'repo_changes_needed: ${repoChanges.length} mục');
  }
}

int countLessonCodeBlocks(String body) => parseCodeBlocks(body).length;
