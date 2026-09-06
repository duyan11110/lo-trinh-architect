import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../src/yaml_json.dart';
import '../src/yaml_writer.dart';
import 'support.dart';

void main() {
  test('round-trips a nested map/list structure through the real YAML parser', () {
    final data = {
      'id': 'foundation',
      'title': {'vi': 'Nền tảng', 'en': 'Foundations'},
      'skills': [
        {
          'id': 'foundation.os.process',
          'title': {'vi': 'x', 'en': 'y'},
        }
      ],
      'levels': [
        {
          'level': 1,
          'modules': [
            {
              'id': 'computer',
              'lessons': [
                {
                  'id': 'foundation.l1.a',
                  'vocab': ['process', 'thread'],
                  'prereqs': <String>[],
                  'outline': [
                    'A sentence with a colon: and a comma, and "quotes".',
                    'Another line.',
                  ],
                }
              ]
            }
          ]
        }
      ],
    };

    final yamlText = toYaml(data);
    final reparsed = yamlToPlain(loadYaml(yamlText));
    expect(reparsed, equals(data));
  });

  test('scalar quoting: reserved words and numeric-looking strings are quoted', () {
    final data = {'a': 'true', 'b': '123', 'c': 'plain-word', 'd': 'has: a colon'};
    final reparsed = yamlToPlain(loadYaml(toYaml(data))) as Map;
    expect(reparsed['a'], 'true');
    expect(reparsed['b'], '123');
    expect(reparsed['c'], 'plain-word');
    expect(reparsed['d'], 'has: a colon');
  });

  test('round-trips the real content/tracks/management/track.yaml unchanged', () {
    final path = realRepo().path('content/tracks/management/track.yaml');
    final original = loadYamlFile(path);
    final reparsed = yamlToPlain(loadYaml(toYaml(original)));
    expect(reparsed, equals(original));
  });
}
