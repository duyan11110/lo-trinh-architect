/// `tools/merge-outline <track> <draft.yaml>` — see tools/SPEC.md.
library merge_outline_runner;

import 'dart:io';

import 'repo.dart';
import 'schema_validator.dart';
import 'validate_runner.dart';
import 'yaml_json.dart';
import 'yaml_writer.dart';

List<String> _headerComments(String path) {
  final lines = File(path).readAsStringSync().replaceAll('\r\n', '\n').split('\n');
  final header = <String>[];
  for (final line in lines) {
    if (line.trim().isEmpty || line.trim().startsWith('#')) {
      header.add(line);
    } else {
      break;
    }
  }
  return header;
}

int? _levelOfModule(Map<String, dynamic> module) {
  final lessons = (module['lessons'] as List?) ?? [];
  for (final l in lessons) {
    final id = (l as Map)['id'] as String?;
    if (id == null) continue;
    final m = RegExp(r'\.l([1-4])\.').firstMatch(id);
    if (m != null) return int.parse(m.group(1)!);
  }
  return null;
}

int runMergeOutline(List<String> argv) {
  if (argv.length < 2) {
    stderr.writeln('Usage: merge-outline <track> <path-to-draft.yaml>');
    return 1;
  }
  final track = argv[0];
  final draftPath = argv[1];
  final repo = Repo.find();
  final sv = SchemaValidator(repo);

  if (!File(draftPath).existsSync()) {
    stderr.writeln('draft không tồn tại: $draftPath');
    return 1;
  }
  final draft = loadYamlFile(draftPath) as Map<String, dynamic>;
  final schemaErrs = sv.validate('outline-draft.schema.json', draft);
  if (schemaErrs.isNotEmpty) {
    for (final e in schemaErrs) {
      stderr.writeln('E draft $e');
    }
    return 1;
  }

  final trackPath = repo.path('content/tracks/$track/track.yaml');
  if (!File(trackPath).existsSync()) {
    stderr.writeln(
        'content/tracks/$track/track.yaml chưa tồn tại — tạo file track mới (title/description) trước khi merge-outline.');
    return 1;
  }
  final trackData = loadYamlFile(trackPath) as Map<String, dynamic>;

  // --- merge module ---
  final module = draft['module'] as Map<String, dynamic>?;
  if (module != null) {
    final moduleId = module['id'] as String;
    final level = _levelOfModule(module) ?? 1;
    final levels = (trackData['levels'] as List).cast<Map<String, dynamic>>();
    Map<String, dynamic>? levelEntry;
    for (final l in levels) {
      if (l['level'] == level) {
        levelEntry = l;
        break;
      }
    }
    if (levelEntry == null) {
      levelEntry = {
        'level': level,
        'title': {'vi': 'Level $level', 'en': 'Level $level'},
        'modules': <Map<String, dynamic>>[],
      };
      levels.add(levelEntry);
      levels.sort((a, b) => (a['level'] as int).compareTo(b['level'] as int));
    }
    final modules = (levelEntry['modules'] as List).cast<Map<String, dynamic>>();
    final existingIdx = modules.indexWhere((m) => m['id'] == moduleId);
    if (existingIdx >= 0) {
      modules[existingIdx] = module;
      print('Đã thay module "$moduleId" (level $level) trong $trackPath');
    } else {
      modules.add(module);
      print('Đã thêm module "$moduleId" (level $level) vào $trackPath');
    }
  }

  // --- merge skills ---
  final draftSkills = ((draft['skills'] as List?) ?? []).cast<Map<String, dynamic>>();
  if (draftSkills.isNotEmpty) {
    final skills = (trackData['skills'] as List?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];
    final existingIds = skills.map((s) => s['id']).toSet();
    for (final s in draftSkills) {
      if (!existingIds.contains(s['id'])) {
        skills.add(s);
        print('Đã thêm skill "${s['id']}"');
      }
    }
    trackData['skills'] = skills;
  }

  final header = _headerComments(trackPath);
  final newTrackYaml = '${header.join('\n')}${header.isEmpty ? '' : '\n'}${toYaml(trackData)}';
  File(trackPath).writeAsStringSync(newTrackYaml);

  // --- merge glossary_additions ---
  final additions = ((draft['glossary_additions'] as List?) ?? []).cast<Map<String, dynamic>>();
  if (additions.isNotEmpty) {
    final glossaryPath = repo.path('content/glossary.yaml');
    final glossary = (loadYamlFile(glossaryPath) as List).cast<Map<String, dynamic>>();
    final byTerm = {for (final g in glossary) g['term'] as String: g};
    var changed = false;
    for (final add in additions) {
      final term = add['term'] as String;
      final existing = byTerm[term];
      if (existing == null) {
        glossary.add(add);
        byTerm[term] = add;
        changed = true;
        print('Đã thêm glossary term "$term"');
      } else if (existing['introduced_in'] != add['introduced_in']) {
        stderr.writeln(
            'E glossary term "$term" đã tồn tại với introduced_in="${existing['introduced_in']}" khác với draft ("${add['introduced_in']}") — từ chối');
      } else {
        print('Glossary term "$term" đã có sẵn, bỏ qua');
      }
    }
    if (changed) {
      final glossaryHeader = _headerComments(glossaryPath);
      final newGlossaryYaml =
          '${glossaryHeader.join('\n')}${glossaryHeader.isEmpty ? '' : '\n'}${toYaml(glossary)}';
      File(glossaryPath).writeAsStringSync(newGlossaryYaml);
    }
  }

  final openQuestions = (draft['open_questions'] as List?) ?? [];
  if (openQuestions.isNotEmpty) {
    print('\nopen_questions:');
    for (final q in openQuestions) {
      print('  - $q');
    }
  }
  final repoChanges = (draft['repo_changes_needed'] as List?) ?? [];
  if (repoChanges.isNotEmpty) {
    print('\nrepo_changes_needed:');
    for (final r in repoChanges) {
      print('  - ${(r as Map)['need']}');
    }
  }

  print('\nChạy validate --structure-only --no-repo...');
  return runValidate(['--structure-only', '--no-repo']);
}
