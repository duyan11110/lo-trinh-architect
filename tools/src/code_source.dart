/// Reading files from the Đơn Hàng example repo, either at a git tag or from
/// a plain directory (--repo-dir, used for the not-yet-tagged stage-0 seed).
/// Also the normalization + matching algorithms from Phụ lục A.6/A.7.
library code_source;

import 'dart:io';
import 'package:path/path.dart' as p;

/// Normalizes text the same way tools/extract-code does when comparing:
/// strip trailing whitespace per line, CRLF -> LF, tabs -> 4 spaces.
String normalizeForCompare(String text) {
  var t = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  t = t.replaceAll('\t', '    ');
  final lines = t.split('\n').map((l) => l.replaceAll(RegExp(r'[ \t]+$'), ''));
  return lines.join('\n').replaceFirst(RegExp(r'\n+$'), '');
}

class TagStatus {
  final bool exists;
  TagStatus(this.exists);
}

/// Abstraction over "the example repo", either examples/don-hang at a git tag,
/// or a plain directory (--repo-dir) standing in for a tag that doesn't exist yet.
class CodeSource {
  final String? repoDir; // if set, plain directory mode
  final String gitRepoPath; // examples/don-hang absolute path

  CodeSource({required this.gitRepoPath, this.repoDir});

  bool get isRepoDirMode => repoDir != null;

  bool tagExists(String tag) {
    if (isRepoDirMode) return true; // N/A; caller treats repo-dir specially
    if (!Directory(p.join(gitRepoPath, '.git')).existsSync()) return false;
    final result = Process.runSync(
      'git',
      ['-C', gitRepoPath, 'tag', '-l', tag],
    );
    if (result.exitCode != 0) return false;
    return (result.stdout as String).trim() == tag;
  }

  /// Returns file content, or null if it does not exist at [tag] / in repoDir.
  String? readFile(String tag, String relativePath) {
    if (isRepoDirMode) {
      final f = File(p.join(repoDir!, relativePath));
      if (!f.existsSync()) return null;
      return f.readAsStringSync();
    }
    if (!tagExists(tag)) return null;
    final result = Process.runSync(
      'git',
      ['-C', gitRepoPath, 'show', '$tag:$relativePath'],
      stdoutEncoding: null,
    );
    if (result.exitCode != 0) return null;
    final bytes = result.stdout;
    if (bytes is List<int>) {
      return String.fromCharCodes(bytes);
    }
    return bytes.toString();
  }

  bool fileExists(String tag, String relativePath) {
    if (isRepoDirMode) {
      return File(p.join(repoDir!, relativePath)).existsSync();
    }
    if (!tagExists(tag)) return false;
    final result = Process.runSync(
      'git',
      ['-C', gitRepoPath, 'cat-file', '-e', '$tag:$relativePath'],
    );
    return result.exitCode == 0;
  }
}

/// A.7 — code block matching against the repo file content.
/// Returns null if it matches, or an error message describing the mismatch.
String? matchCodeBlock({
  required String blockContent,
  required String fileContent,
  String? linesSpec,
}) {
  final normBlock = normalizeForCompare(blockContent);
  final normFile = normalizeForCompare(fileContent);
  final fileLines = normFile.split('\n');
  final blockLines = normBlock.split('\n');

  if (linesSpec != null) {
    final m = RegExp(r'^(\d+)-(\d+)$').firstMatch(linesSpec);
    if (m == null) return 'lines= không hợp lệ: $linesSpec';
    final a = int.parse(m.group(1)!);
    final b = int.parse(m.group(2)!);
    if (blockLines.length != (b - a + 1)) {
      return 'số dòng của block (${blockLines.length}) khác lines=$linesSpec (${b - a + 1} dòng)';
    }
    if (a < 1 || b > fileLines.length) {
      return 'lines=$linesSpec vượt quá số dòng của file (${fileLines.length})';
    }
    final expected = fileLines.sublist(a - 1, b).join('\n');
    if (expected != normBlock) {
      return 'nội dung block không khớp dòng $linesSpec của file trong repo ví dụ';
    }
    return null;
  }

  // No lines=: block must be a contiguous run of lines in the file.
  if (blockLines.isEmpty) return 'block rỗng';
  for (int start = 0; start + blockLines.length <= fileLines.length; start++) {
    bool ok = true;
    for (int k = 0; k < blockLines.length; k++) {
      if (fileLines[start + k] != blockLines[k]) {
        ok = false;
        break;
      }
    }
    if (ok) return null;
  }
  return 'nội dung block không phải một đoạn liên tục của file trong repo ví dụ';
}

/// A.6 — output block matching: `...` in the block matches `[\s\S]*?` in the
/// captured output file, non-greedy, whole-content match.
bool matchOutputBlock({required String blockContent, required String fileContent}) {
  final normBlock = normalizeForCompare(blockContent);
  final normFile = normalizeForCompare(fileContent);
  final segments = normBlock.split('...');
  final buffer = StringBuffer('^');
  for (int i = 0; i < segments.length; i++) {
    buffer.write(RegExp.escape(segments[i]));
    if (i != segments.length - 1) {
      buffer.write(r'[\s\S]*?');
    }
  }
  buffer.write(r'$');
  final re = RegExp(buffer.toString());
  return re.hasMatch(normFile);
}
