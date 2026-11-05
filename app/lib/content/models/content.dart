// Root of content.json (docs/04 §1). Immutable; built once per load in a
// background isolate (docs/07 §8).
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'catalog.dart';
import 'glossary.dart';
import 'i18n.dart';
import 'json_slice.dart';
import 'lesson.dart';
import 'quiz.dart';

@immutable
class Content {
  Content({
    required this.meta,
    required this.stages,
    required this.tracks,
    required this.lessons,
    required this.quizzes,
    required this.gates,
    required this.glossary,
    required this.skills,
  }) : _moduleByKey = {
         for (final t in tracks)
           for (final l in t.levels)
             for (final m in l.modules) m.key: m,
       },
       _glossaryByTerm = {for (final g in glossary) g.term: g},
       _trackByLesson = {
         for (final t in tracks)
           for (final l in t.levels)
             for (final m in l.modules)
               for (final r in m.lessons) r.id: t.id,
       };

  factory Content.fromJson(Object? json) {
    final m = asMap(json, 'root');
    Map<String, T> byKey<T>(String key, T Function(Object?) parse) {
      final src = asMap(m[key], key);
      return Map.unmodifiable({
        for (final e in src.entries) e.key: parse(e.value),
      });
    }

    return Content(
      meta: ContentMeta.fromJson(m['meta']),
      stages: asMap(m['path'], 'path').list('stages', PathStage.fromJson),
      tracks: m.list('tracks', Track.fromJson),
      lessons: byKey('lessons', Lesson.fromJson),
      quizzes: byKey('quizzes', Quiz.fromJson),
      gates: byKey('gates', Gate.fromJson),
      glossary: m.list('glossary', GlossaryEntry.fromJson),
      skills: m.list('skills', Skill.fromJson),
    );
  }

  final ContentMeta meta;
  final List<PathStage> stages;
  final List<Track> tracks;
  final Map<String, Lesson> lessons;
  final Map<String, Quiz> quizzes;
  final Map<String, Gate> gates;
  final List<GlossaryEntry> glossary;
  final List<Skill> skills;

  final Map<String, TrackModule> _moduleByKey;
  final Map<String, GlossaryEntry> _glossaryByTerm;
  final Map<String, String> _trackByLesson;

  /// Track of any lesson id in the track tree (or with a body).
  String? trackOfLesson(String id) => lessons[id]?.track ?? _trackByLesson[id];

  /// Track that teaches [entry] (`introduced_in`).
  String? trackOfTerm(GlossaryEntry entry) => trackOfLesson(entry.introducedIn);

  Track? track(String id) {
    for (final t in tracks) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// `track/module` → module node of the track tree.
  TrackModule? module(String key) => _moduleByKey[key];

  GlossaryEntry? glossaryEntry(String term) => _glossaryByTerm[term];

  /// Title for any lesson id the track tree knows (also lessons whose body is
  /// not in [lessons] yet).
  I18n? lessonTitle(String id) {
    final l = lessons[id];
    if (l != null) return l.title;
    for (final m in _moduleByKey.values) {
      for (final r in m.lessons) {
        if (r.id == id) return r.title;
      }
    }
    return null;
  }
}

/// Top-level so it can run in an isolate (`compute`).
Content parseContent(String source) => Content.fromJson(jsonDecode(source));

/// From UTF-8 bytes, never building the whole document as a String.
/// Lesson `sections`/`diagram_svg` stay undecoded ([decodeContentLazily]).
Content parseContentBytes(Uint8List utf8Json) =>
    Content.fromJson(decodeContentLazily(utf8Json));
