import 'package:test/test.dart';

import '../src/validate_runner.dart';

void main() {
  test('a .json argument is a gate bank path, not a lesson id', () {
    final a = parseValidateArgs(['content/gates/gate2.json']);
    expect(a.gatePath, 'content/gates/gate2.json');
    expect(a.lessonId, isNull);
  });

  test('a plain argument is still a lesson id', () {
    final a = parseValidateArgs(['backend.l1.middleware-pipeline']);
    expect(a.lessonId, 'backend.l1.middleware-pipeline');
    expect(a.gatePath, isNull);
  });
}
