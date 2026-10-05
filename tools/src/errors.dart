/// Shared issue/diagnostic model used by every rule group.
///
/// Output format (tools/SPEC.md line 4): `LEVEL <id> <rule-code>: message`
/// LEVEL is `E` (error, exit code != 0) or `W` (warning, does not affect exit code).
library errors;

enum Level { error, warning }

class Issue {
  final Level level;
  final String id; // lesson id, file path, or track/module — whatever the rule is about
  final String rule; // e.g. "S01", "L05", "M02", "Q03", "R01", "P01", "T01"
  final String message;

  Issue(this.level, this.id, this.rule, this.message);

  String get levelCode => level == Level.error ? 'E' : 'W';

  @override
  String toString() => '$levelCode $id $rule: $message';
}

class IssueCollector {
  final List<Issue> issues = [];

  void error(String id, String rule, String message) {
    issues.add(Issue(Level.error, id, rule, message));
  }

  void warn(String id, String rule, String message) {
    issues.add(Issue(Level.warning, id, rule, message));
  }

  bool get hasErrors => issues.any((i) => i.level == Level.error);

  List<Issue> get errors => issues.where((i) => i.level == Level.error).toList();
  List<Issue> get warnings => issues.where((i) => i.level == Level.warning).toList();

  void addAll(IssueCollector other) => issues.addAll(other.issues);

  void printAll() {
    for (final i in issues) {
      // ignore: avoid_print
      print(i.toString());
    }
  }
}
