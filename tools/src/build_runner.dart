/// `tools/build` — see tools/SPEC.md "build".
library build_runner;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import 'content_tree.dart';
import 'markdown_util.dart';
import 'repo.dart';
import 'svg_theming.dart';
import 'validate_runner.dart';
import 'yaml_json.dart';

class BuildArgs {
  bool preview = false;
  bool publish = false;
}

BuildArgs parseBuildArgs(List<String> argv) {
  final a = BuildArgs();
  for (final arg in argv) {
    if (arg == '--preview') a.preview = true;
    if (arg == '--publish') a.publish = true;
  }
  return a;
}

Future<int> runBuild(List<String> argv) async {
  final args = parseBuildArgs(argv);
  final repo = Repo.find();

  stdout.writeln('==> tools/validate (toàn bộ)');
  final validateExit = runValidate([]);
  if (validateExit != 0) {
    stderr.writeln('validate có lỗi E — dừng build.');
    return 1;
  }

  final tree = ContentTree.load(repo);
  final allowedStatuses = args.preview ? {'reviewed', 'approved', 'published'} : {'approved', 'published'};

  final lessonsOut = <String, dynamic>{};
  final quizzesOut = <String, dynamic>{};
  final publishedIds = <String>[];

  for (final lesson in tree.lessonsById.values) {
    final files = lessonFiles(repo, lesson);
    final enFile = File(files.enMd);
    if (!enFile.existsSync()) continue;
    final enDoc = parseFrontmatter(files.enMd);
    final status = enDoc.frontmatter['status'] as String? ?? 'draft';
    if (!allowedStatuses.contains(status)) continue;

    final viFile = File(files.viMd);
    final hasVi = viFile.existsSync();
    if (!args.preview && !hasVi) {
      stdout.writeln('   bỏ qua ${lesson.id}: thiếu .vi.md (chỉ preview mới cho phép)');
      continue;
    }

    final enSections = await _buildSections(enDoc.body);
    List<Map<String, dynamic>> viSections = [];
    String? skipNoteVi;
    String? skipNoteEn = _extractSkipNote(parseSections(enDoc.body).preamble, 'en');
    FrontmatterDoc? viDoc;
    if (hasVi) {
      viDoc = parseFrontmatter(files.viMd);
      viSections = (await _buildSections(viDoc.body)).sections;
      skipNoteVi = _extractSkipNote(parseSections(viDoc.body).preamble, 'vi');
    }

    String? diagramSvg = enSections.svg;

    lessonsOut[lesson.id] = {
      'id': lesson.id,
      'track': lesson.track,
      'level': lesson.level,
      'stage': lesson.stage,
      'module': lesson.moduleId,
      'main_path': lesson.mainPath,
      'duration_min': lesson.durationMin,
      'title': lesson.title ?? {'vi': '', 'en': ''},
      'skills': lesson.skills,
      'prereqs': lesson.prereqs,
      'related': lesson.related,
      'vocab': lesson.vocab,
      'example_tag': lesson.exampleTag,
      'sections': {'vi': viSections, 'en': enSections.sections},
      'diagram_svg': diagramSvg,
      'skip_note': (!lesson.mainPath && (skipNoteEn != null || skipNoteVi != null))
          ? {'vi': skipNoteVi ?? '', 'en': skipNoteEn ?? ''}
          : null,
      'content_version': enDoc.frontmatter['content_version'] ?? 1,
    };

    final quizFile = File(files.quizJson);
    if (quizFile.existsSync()) {
      quizzesOut[lesson.id] = loadJsonFile(quizFile.path);
    }

    publishedIds.add(lesson.id);
  }

  final gatesOut = <String, dynamic>{};
  final gatesDir = Directory(repo.path('content/gates'));
  if (gatesDir.existsSync()) {
    for (final f in gatesDir.listSync()) {
      if (f is File && f.path.endsWith('.json')) {
        final data = loadJsonFile(f.path) as Map<String, dynamic>;
        final gateId = data['gate'] as String? ?? p.basenameWithoutExtension(f.path);
        gatesOut[gateId] = data;
      }
    }
  }

  final glossaryOut = tree.glossary
      .map((g) => {
            'term': g.term,
            'en': g.en,
            'vi_keep': g.viKeep,
            'vi': g.vi,
            'short_vi': g.shortVi,
            'short_en': g.shortEn,
            'introduced_in': g.introducedIn,
            'aliases': g.aliases,
          })
      .toList();

  final skillsOut = tree.skills
      .map((s) => {
            'id': s.id,
            'title': s.title,
            'track': s.track,
            'prereqs': s.prereqs,
            'lessons': tree.lessonsById.values
                .where((l) => l.skills.contains(s.id) && publishedIds.contains(l.id))
                .map((l) => l.id)
                .toList(),
          })
      .toList();

  final tracksOut = tree.trackYamls.entries.map((e) => _buildTrackSummary(e.key, e.value)).toList();

  final outDir = Directory(repo.path(args.preview ? 'dist/preview' : 'dist'));
  outDir.createSync(recursive: true);

  final versionFile = File(repo.path('dist/VERSION'));
  final previousVersion = versionFile.existsSync() ? int.tryParse(versionFile.readAsStringSync().trim()) ?? 0 : 0;

  final contentJson = {
    'meta': {
      'content_version': args.preview ? previousVersion : previousVersion + 1,
      'built_at': DateTime.now().toUtc().toIso8601String(),
      'versions': _flattenVersions(repo),
      'langs': ['vi', 'en'],
    },
    'path': tree.pathYaml,
    'tracks': tracksOut,
    'lessons': lessonsOut,
    'quizzes': quizzesOut,
    'gates': gatesOut,
    'glossary': glossaryOut,
    'skills': skillsOut,
  };

  final encoder = JsonEncoder.withIndent('  ');
  var bodyJson = encoder.convert(contentJson);
  final bytesUtf8 = utf8.encode(bodyJson);
  final hash = sha256.convert(bytesUtf8).toString();

  final previousManifestFile = File(repo.path('dist/manifest.json'));
  String? previousHash;
  Map<String, dynamic>? previousLessons;
  if (previousManifestFile.existsSync()) {
    try {
      previousHash = (loadJsonFile(previousManifestFile.path) as Map<String, dynamic>)['sha256'] as String?;
    } catch (_) {}
  }
  final previousContentFile = File(repo.path('dist/content.json'));
  if (previousContentFile.existsSync()) {
    try {
      previousLessons = (loadJsonFile(previousContentFile.path) as Map<String, dynamic>)['lessons']
          as Map<String, dynamic>?;
    } catch (_) {}
  }

  int contentVersion;
  if (args.preview) {
    contentVersion = previousVersion; // preview never bumps content_version
  } else if (previousHash != null && previousHash == hash) {
    contentVersion = previousVersion == 0 ? 1 : previousVersion;
  } else {
    contentVersion = previousVersion + 1;
  }
  (contentJson['meta'] as Map<String, dynamic>)['content_version'] = contentVersion;
  bodyJson = encoder.convert(contentJson);
  final finalBytes = utf8.encode(bodyJson);
  final finalHash = sha256.convert(finalBytes).toString();

  final contentFile = File(p.join(outDir.path, 'content.json'));
  contentFile.writeAsBytesSync(finalBytes);
  final gz = gzip.encode(finalBytes);
  File(p.join(outDir.path, 'content.json.gz')).writeAsBytesSync(gz);

  final lessonsAdded = <String>[];
  final lessonsChanged = <String>[];
  for (final id in lessonsOut.keys) {
    if (previousLessons == null || !previousLessons.containsKey(id)) {
      lessonsAdded.add(id);
    } else if (encoder.convert(previousLessons[id]) != encoder.convert(lessonsOut[id])) {
      lessonsChanged.add(id);
    }
  }

  final manifest = {
    'content_version': contentVersion,
    'sha256': finalHash,
    'bytes': finalBytes.length,
    'built_at': (contentJson['meta'] as Map)['built_at'],
    'lessons_added': lessonsAdded,
    'lessons_changed': lessonsChanged,
  };
  File(p.join(outDir.path, 'manifest.json')).writeAsStringSync(encoder.convert(manifest));

  if (!args.preview) {
    File(repo.path('dist/VERSION')).writeAsStringSync('$contentVersion\n');
  }

  if (args.publish) {
    for (final lesson in tree.lessonsById.values) {
      if (!lessonsOut.containsKey(lesson.id)) continue;
      final files = lessonFiles(repo, lesson);
      final enFm = parseFrontmatter(files.enMd);
      if (enFm.frontmatter['status'] == 'approved') {
        _setStatusPublished(files.enMd);
        if (File(files.viMd).existsSync()) _setStatusPublished(files.viMd);
      }
    }
  }

  _printStats(tree, lessonsOut, quizzesOut, finalBytes.length);
  return 0;
}

class _SectionsResult {
  final List<Map<String, dynamic>> sections;
  final String? svg;
  _SectionsResult(this.sections, this.svg);
}

Future<_SectionsResult> _buildSections(String body) async {
  final parsed = parseSections(body);
  final out = <Map<String, dynamic>>[];
  String? svg;
  for (final section in parsed.sections) {
    var md = section.content;
    final mermaidBlocks = section.codeBlocks.where((b) => b.lang == 'mermaid').toList();
    if (mermaidBlocks.isNotEmpty) {
      final block = mermaidBlocks.first;
      final fence = '```${block.infoLine}\n${block.content}\n```';
      md = md.replaceFirst(fence, '{{diagram}}');
      svg ??= await _renderMermaid(block.content);
    }
    out.add({'n': section.index, 'heading': section.heading, 'md': md.trim()});
  }
  return _SectionsResult(out, svg);
}

String? _extractSkipNote(String preamble, String lang) {
  final marker = lang == 'vi' ? 'Bỏ qua được nếu' : 'Skip this if';
  final lines = preamble.split('\n').where((l) => l.trim().startsWith('>')).map((l) {
    return l.replaceFirst(RegExp(r'^\s*>\s?'), '');
  }).toList();
  if (lines.isEmpty) return null;
  final text = lines.join(' ').trim();
  if (!text.contains(marker)) return null;
  final idx = text.indexOf(':');
  return idx >= 0 ? text.substring(idx + 1).trim() : text;
}

Future<String?> _renderMermaid(String mermaidSource) async {
  Directory? tmpDir;
  try {
    tmpDir = Directory.systemTemp.createTempSync('lta_mmd_');
    final inputFile = File(p.join(tmpDir.path, 'in.mmd'))..writeAsStringSync(mermaidSource);
    final configFile = File(p.join(tmpDir.path, 'config.json'))..writeAsStringSync(mermaidConfigJson());
    final outputFile = File(p.join(tmpDir.path, 'out.svg'));
    final result = await Process.run(
      'npx',
      [
        '-y',
        '@mermaid-js/mermaid-cli',
        '-i',
        inputFile.path,
        '-o',
        outputFile.path,
        '-c',
        configFile.path,
        '-b',
        'transparent',
      ],
      runInShell: true,
    ).timeout(const Duration(seconds: 60), onTimeout: () => ProcessResult(0, 124, '', 'timeout'));
    if (result.exitCode != 0 || !outputFile.existsSync()) {
      stderr.writeln('   [mermaid] không render được (mmdc lỗi hoặc không có mạng): ${result.stderr}');
      return null;
    }
    return postprocessMermaidSvg(outputFile.readAsStringSync());
  } catch (e) {
    stderr.writeln('   [mermaid] không render được: $e');
    return null;
  } finally {
    try {
      tmpDir?.deleteSync(recursive: true);
    } catch (_) {}
  }
}

Map<String, dynamic> _buildTrackSummary(String trackId, Map<String, dynamic> raw) {
  return {
    'id': trackId,
    'title': raw['title'],
    'description': raw['description'],
    'levels': ((raw['levels'] as List?) ?? []).map((levelRaw) {
      final level = levelRaw as Map<String, dynamic>;
      return {
        'level': level['level'],
        'title': level['title'],
        'modules': ((level['modules'] as List?) ?? []).map((modRaw) {
          final mod = modRaw as Map<String, dynamic>;
          return {
            'id': mod['id'],
            'title': mod['title'],
            'stage': mod['stage'],
            if (mod['summary'] != null) 'summary': mod['summary'],
            'lessons': ((mod['lessons'] as List?) ?? []).map((lRaw) {
              final l = lRaw as Map<String, dynamic>;
              return {
                'id': l['id'],
                'title': l['title'],
                'main_path': l['main_path'],
                'duration_min': l['duration_min'],
              };
            }).toList(),
          };
        }).toList(),
      };
    }).toList(),
  };
}

Map<String, String> _flattenVersions(Repo repo) {
  final versionsPath = repo.path('content/versions.yaml');
  final out = <String, String>{};
  if (!File(versionsPath).existsSync()) return out;
  final data = loadYamlFile(versionsPath) as Map<String, dynamic>;
  void walk(dynamic node) {
    if (node is Map) {
      if (node.containsKey('version')) {
        // handled by caller with key context; see below
      }
      node.forEach((k, v) {
        if (v is Map && v.containsKey('version')) {
          out[k.toString()] = v['version'].toString();
        } else if (v is Map) {
          walk(v);
        }
      });
    }
  }
  for (final section in ['runtimes', 'data', 'infra']) {
    if (data[section] is Map) walk({section: data[section]});
  }
  if (data['standards'] is Map) {
    (data['standards'] as Map).forEach((k, v) {
      out[k.toString()] = 'docs';
    });
  }
  return out;
}

void _setStatusPublished(String path) {
  final raw = File(path).readAsStringSync();
  final lines = raw.replaceAll('\r\n', '\n').split('\n');
  if (lines.isEmpty || lines[0] != '---') return;
  int endIdx = -1;
  for (int i = 1; i < lines.length; i++) {
    if (lines[i] == '---') {
      endIdx = i;
      break;
    }
  }
  if (endIdx == -1) return;
  for (int i = 1; i < endIdx; i++) {
    if (RegExp(r'^status:\s*approved\s*$').hasMatch(lines[i])) {
      lines[i] = 'status: published';
    }
  }
  File(path).writeAsStringSync(lines.join('\n'));
}

void _printStats(ContentTree tree, Map<String, dynamic> lessonsOut, Map<String, dynamic> quizzesOut, int bytes) {
  stdout.writeln('\n==> Thống kê build');
  final byTrackStage = <String, int>{};
  for (final l in lessonsOut.values) {
    final key = '${l['track']}/stage${l['stage']}';
    byTrackStage[key] = (byTrackStage[key] ?? 0) + 1;
  }
  byTrackStage.forEach((k, v) => stdout.writeln('   $k: $v bài'));
  final totalQuestions = quizzesOut.values.fold<int>(
      0, (a, q) => a + (((q as Map<String, dynamic>)['questions'] as List?)?.length ?? 0));
  stdout.writeln('   tổng bài đưa vào build: ${lessonsOut.length}');
  stdout.writeln('   tổng câu quiz: $totalQuestions');
  stdout.writeln('   kích thước content.json: $bytes bytes');
}
