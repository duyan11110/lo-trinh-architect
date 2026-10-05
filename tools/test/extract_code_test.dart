import 'package:test/test.dart';

import '../src/extract_code_runner.dart';

void main() {
  test('sliceLines extracts an inclusive 1-indexed a-b range', () {
    final result = sliceLines('l1\nl2\nl3\nl4\nl5', '2-4');
    expect(result.error, isNull);
    expect(result.content, 'l2\nl3\nl4');
  });

  test('sliceLines rejects a malformed spec', () {
    final result = sliceLines('l1\nl2', 'nope');
    expect(result.error, isNotNull);
  });

  test('sliceLines rejects a range past the end of the file', () {
    final result = sliceLines('l1\nl2', '1-5');
    expect(result.error, isNotNull);
  });
}
