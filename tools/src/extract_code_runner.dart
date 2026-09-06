/// `tools/extract-code` — see tools/SPEC.md.
library extract_code_runner;

import 'dart:io';

import 'repo.dart';

/// Extracts the `a-b` (1-indexed, inclusive) line range from [content].
/// Returns an error message instead of throwing, so the CLI can print it and
/// exit non-zero without a stack trace; returns null on the happy path via
/// the [onOk] callback receiving the sliced text.
class LineSliceResult {
  final String? content;
  final String? error;
  LineSliceResult.ok(this.content) : error = null;
  LineSliceResult.error(this.error) : content = null;
}

LineSliceResult sliceLines(String content, String linesSpec) {
  final m = RegExp(r'^(\d+)-(\d+)$').firstMatch(linesSpec);
  if (m == null) {
    return LineSliceResult.error('lines= không hợp lệ: $linesSpec');
  }
  final a = int.parse(m.group(1)!);
  final b = int.parse(m.group(2)!);
  final allLines = content.split('\n');
  if (a < 1 || b > allLines.length || a > b) {
    return LineSliceResult.error('lines=$linesSpec vượt quá số dòng của file (${allLines.length})');
  }
  return LineSliceResult.ok(allLines.sublist(a - 1, b).join('\n'));
}

int runExtractCode(List<String> argv) {
  String? path;
  String? tag;
  String? lines;
  final positional = <String>[];
  int i = 0;
  while (i < argv.length) {
    switch (argv[i]) {
      case '--tag':
        tag = argv[++i];
        break;
      case '--lines':
        lines = argv[++i];
        break;
      default:
        positional.add(argv[i]);
    }
    i++;
  }
  if (positional.isEmpty || tag == null) {
    stderr.writeln('Usage: extract-code <path> --tag <tag> [--lines a-b]');
    return 1;
  }
  path = positional.first;

  final repo = Repo.find();
  final gitRepoPath = repo.path('examples/don-hang');
  final result = Process.runSync('git', ['-C', gitRepoPath, 'show', '$tag:$path']);
  if (result.exitCode != 0) {
    stderr.writeln('git show $tag:$path thất bại: ${result.stderr}');
    return 1;
  }
  var content = result.stdout as String;
  if (lines != null) {
    final sliced = sliceLines(content, lines);
    if (sliced.error != null) {
      stderr.writeln(sliced.error);
      return 1;
    }
    content = sliced.content!;
  }
  stdout.write(content);
  if (!content.endsWith('\n')) stdout.writeln();
  return 0;
}
