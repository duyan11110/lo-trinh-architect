/// R01–R04 — `.review.json` rules.
library rules_review;

import 'errors.dart';
import 'schema_validator.dart';

const List<String> _statusOrder = ['draft', 'reviewed', 'approved', 'published'];

bool _atLeast(String status, String threshold) =>
    _statusOrder.indexOf(status) >= _statusOrder.indexOf(threshold);

void validateReview(
  String id,
  Map<String, dynamic>? review,
  String status,
  List<Map<String, dynamic>> claims,
  SchemaValidator sv,
  IssueCollector out,
) {
  if (review == null) {
    if (_atLeast(status, 'reviewed')) {
      out.error(id, 'R01', '.review.json không tồn tại nhưng status="$status" (>= reviewed)');
    }
    return;
  }

  final schemaErrs = sv.validate('review.schema.json', review);
  for (final e in schemaErrs) {
    out.error(id, 'R01', '.review.json không qua schema: $e');
  }

  final technical = review['technical'] as Map<String, dynamic>?;
  final junior = review['junior'] as Map<String, dynamic>?;

  if (_atLeast(status, 'reviewed')) {
    if (technical == null) out.error(id, 'R01', '.review.json thiếu phần "technical" (status >= reviewed)');
    if (junior == null) out.error(id, 'R01', '.review.json thiếu phần "junior" (status >= reviewed)');
  }

  final claimVerdicts = <int, String>{};
  if (technical != null) {
    for (final cv in (technical['claim_verdicts'] as List? ?? [])) {
      final m = cv as Map<String, dynamic>;
      claimVerdicts[m['n'] as int] = m['verdict'] as String;
    }
    // R02: every needs_verification claim needs a verdict
    if (_atLeast(status, 'reviewed')) {
      for (final c in claims) {
        if (c['needs_verification'] == true && !claimVerdicts.containsKey(c['n'])) {
          out.error(id, 'R02', 'claim n=${c['n']} needs_verification=true nhưng chưa có verdict');
        }
      }
    }

    // R03: no open blocker (>= reviewed) / no open major (>= approved)
    final issues = (technical['issues'] as List? ?? []).cast<Map<String, dynamic>>();
    if (_atLeast(status, 'reviewed')) {
      final blockers = issues.where((i) => i['severity'] == 'blocker').length;
      if (blockers > 0) {
        out.error(id, 'R03', '$blockers issue "blocker" chưa xử lý (status >= reviewed)');
      }
    }
    if (_atLeast(status, 'approved')) {
      final majors = issues.where((i) => i['severity'] == 'major').length;
      if (majors > 0) {
        out.error(id, 'R03', '$majors issue "major" chưa xử lý (status >= approved)');
      }
    }
  }
  if (junior != null && _atLeast(status, 'reviewed')) {
    final issues = (junior['issues'] as List? ?? []).cast<Map<String, dynamic>>();
    final blockers = issues.where((i) => i['severity'] == 'blocker').length;
    if (blockers > 0) {
      out.error(id, 'R03', '$blockers issue "blocker" (junior) chưa xử lý (status >= reviewed)');
    }
    if (_atLeast(status, 'approved')) {
      final majors = issues.where((i) => i['severity'] == 'major').length;
      if (majors > 0) {
        out.error(id, 'R03', '$majors issue "major" (junior) chưa xử lý (status >= approved)');
      }
    }
  }

  // R04
  if (_atLeast(status, 'reviewed')) {
    for (final entry in claimVerdicts.entries) {
      if (entry.value == 'wrong') {
        out.error(id, 'R04', 'claim n=${entry.key} verdict="wrong" — phải sửa bài rồi review lại');
      }
    }
  }
  if (_atLeast(status, 'approved')) {
    for (final c in claims) {
      final verdict = claimVerdicts[c['n']];
      if (verdict == 'unverified') {
        final kind = c['kind'] as String?;
        if (kind == 'number' || kind == 'syntax') {
          out.error(id, 'R04', 'claim n=${c['n']} kind=$kind verdict="unverified" không được phép ở approved');
        } else {
          out.warn(id, 'R04', 'claim n=${c['n']} kind=$kind verdict="unverified" ở approved — chủ tự quyết');
        }
      }
    }
  }
}
