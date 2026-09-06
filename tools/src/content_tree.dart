/// Loads content/path.yaml, content/tracks/*/track.yaml and
/// content/glossary.yaml into an in-memory index used by every validate rule
/// group and by known-vocab / merge-outline.
library content_tree;

import 'dart:io';
import 'package:path/path.dart' as p;

import 'repo.dart';
import 'yaml_json.dart';
import 'glossary.dart';

class LessonEntry {
  final Map<String, dynamic> raw;
  final String track;
  final int level;
  final String moduleId;
  int stage; // from track.yaml module; may be overridden/compared with path.yaml (T03)
  int globalOrder = -1;

  LessonEntry(this.raw, this.track, this.level, this.moduleId, this.stage);

  String get id => raw['id'] as String;
  bool get mainPath => raw['main_path'] as bool? ?? true;
  int get durationMin => raw['duration_min'] as int? ?? 0;
  List<String> get skills => ((raw['skills'] as List?) ?? []).map((e) => e.toString()).toList();
  List<String> get prereqs => ((raw['prereqs'] as List?) ?? []).map((e) => e.toString()).toList();
  List<String> get related => ((raw['related'] as List?) ?? []).map((e) => e.toString()).toList();
  List<String> get vocab => ((raw['vocab'] as List?) ?? []).map((e) => e.toString()).toList();
  String get exampleTag => raw['example_tag'] as String? ?? '';
  List<String> get exampleFiles => ((raw['example_files'] as List?) ?? []).map((e) => e.toString()).toList();
  List<String> get outline => ((raw['outline'] as List?) ?? []).map((e) => e.toString()).toList();
  List<String> get misconceptions => ((raw['misconceptions'] as List?) ?? []).map((e) => e.toString()).toList();
  Map<String, dynamic>? get title => raw['title'] as Map<String, dynamic>?;
}

class ModuleEntry {
  final String track;
  final String id;
  final int stage;
  final List<LessonEntry> lessons;
  ModuleEntry(this.track, this.id, this.stage, this.lessons);
  String get key => '$track/$id';
}

class SkillEntry {
  final String id;
  final String track;
  final Map<String, dynamic> title;
  final List<String> prereqs;
  SkillEntry(this.id, this.track, this.title, this.prereqs);
}

class ContentTree {
  final Repo repo;
  // Not `late final`: tests construct a ContentTree directly (bypassing
  // ContentTree.load()) and assign this more than once for different scenarios.
  dynamic pathYaml;
  final Map<String, Map<String, dynamic>> trackYamls = {}; // trackId -> raw
  final Map<String, ModuleEntry> modulesByKey = {}; // "track/module" -> ModuleEntry
  final Map<String, LessonEntry> lessonsById = {};
  final List<String> globalModuleOrder = []; // "track/module" in path.yaml order
  final Map<String, int> moduleStageInPath = {}; // "track/module" -> stage per path.yaml
  final List<SkillEntry> skills = [];
  final List<GlossaryEntry> glossary = [];
  final List<String> pathOnlyModules = []; // modules in path.yaml without track.yaml entry (W, S03)
  final List<String> trackOnlyModules = []; // modules in track.yaml without path.yaml entry (E, S03)

  ContentTree(this.repo);

  static ContentTree load(Repo repo) {
    final tree = ContentTree(repo);
    tree._loadPath();
    tree._loadTracks();
    tree._loadGlossary();
    tree._computeGlobalOrder();
    return tree;
  }

  void _loadPath() {
    final f = File(repo.path('content/path.yaml'));
    pathYaml = f.existsSync() ? loadYamlFile(f.path) : {'stages': []};
  }

  void _loadTracks() {
    final tracksDir = Directory(repo.path('content/tracks'));
    if (!tracksDir.existsSync()) return;
    for (final entry in tracksDir.listSync()) {
      if (entry is! Directory) continue;
      final trackFile = File(p.join(entry.path, 'track.yaml'));
      if (!trackFile.existsSync()) continue;
      final raw = loadYamlFile(trackFile.path) as Map<String, dynamic>;
      final trackId = raw['id'] as String? ?? p.basename(entry.path);
      trackYamls[trackId] = raw;
      for (final skillRaw in (raw['skills'] as List? ?? [])) {
        final sm = skillRaw as Map<String, dynamic>;
        skills.add(SkillEntry(
          sm['id'] as String,
          trackId,
          (sm['title'] as Map<String, dynamic>?) ?? {},
          ((sm['prereqs'] as List?) ?? []).map((e) => e.toString()).toList(),
        ));
      }
      for (final levelRaw in (raw['levels'] as List? ?? [])) {
        final level = levelRaw as Map<String, dynamic>;
        final levelNum = level['level'] as int;
        for (final modRaw in (level['modules'] as List? ?? [])) {
          final mod = modRaw as Map<String, dynamic>;
          final moduleId = mod['id'] as String;
          final stage = mod['stage'] as int;
          final lessons = <LessonEntry>[];
          for (final lessonRaw in (mod['lessons'] as List? ?? [])) {
            final le = LessonEntry(
              lessonRaw as Map<String, dynamic>,
              trackId,
              levelNum,
              moduleId,
              stage,
            );
            lessons.add(le);
            lessonsById[le.id] = le;
          }
          final key = '$trackId/$moduleId';
          modulesByKey[key] = ModuleEntry(trackId, moduleId, stage, lessons);
        }
      }
    }
  }

  void _loadGlossary() {
    final f = File(repo.path('content/glossary.yaml'));
    if (!f.existsSync()) return;
    final raw = loadYamlFile(f.path) as List;
    for (final e in raw) {
      glossary.add(GlossaryEntry.fromMap(e as Map<String, dynamic>));
    }
  }

  void _computeGlobalOrder() {
    int counter = 0;
    final stages = (pathYaml['stages'] as List? ?? []);
    final seenModuleKeys = <String>{};
    for (final stageRaw in stages) {
      final stage = stageRaw as Map<String, dynamic>;
      for (final modKey in (stage['modules'] as List? ?? [])) {
        final key = modKey.toString();
        seenModuleKeys.add(key);
        globalModuleOrder.add(key);
        moduleStageInPath[key] = stage['stage'] as int;
        final module = modulesByKey[key];
        if (module == null) {
          pathOnlyModules.add(key);
          continue;
        }
        for (final lesson in module.lessons) {
          lesson.globalOrder = counter++;
        }
      }
    }
    for (final key in modulesByKey.keys) {
      if (!seenModuleKeys.contains(key)) {
        trackOnlyModules.add(key);
      }
    }
  }

  LessonEntry? lesson(String id) => lessonsById[id];

  bool skillExists(String id) => skills.any((s) => s.id == id);

  GlossaryEntry? glossaryTerm(String term) {
    for (final g in glossary) {
      if (g.term == term) return g;
    }
    return null;
  }

  /// All lessons in global-order order (lessons not reachable from path.yaml,
  /// i.e. in a module missing from path.yaml, are appended at the end in
  /// track.yaml encounter order so they still get *some* stable ordering).
  List<LessonEntry> get lessonsInGlobalOrder {
    final ordered = lessonsById.values.where((l) => l.globalOrder >= 0).toList()
      ..sort((a, b) => a.globalOrder.compareTo(b.globalOrder));
    final unordered = lessonsById.values.where((l) => l.globalOrder < 0).toList();
    return [...ordered, ...unordered];
  }
}
