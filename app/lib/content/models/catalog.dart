// `meta`, `path`, `tracks`, `skills` of content.json (docs/04 §1).
import 'package:flutter/foundation.dart';

import 'i18n.dart';

@immutable
class ContentMeta {
  const ContentMeta({
    required this.contentVersion,
    required this.builtAt,
    required this.versions,
    required this.langs,
  });

  factory ContentMeta.fromJson(Object? json) {
    final m = asMap(json, 'meta');
    return ContentMeta(
      contentVersion: m.integer('content_version'),
      builtAt: m.str('built_at'),
      versions: Map.unmodifiable(
        asMap(m['versions'], 'meta.versions').cast<String, String>(),
      ),
      langs: m.strings('langs'),
    );
  }

  final int contentVersion;
  final String builtAt;
  final Map<String, String> versions;
  final List<String> langs;
}

/// One entry of `path.stages`.
@immutable
class PathStage {
  const PathStage({
    required this.stage,
    required this.title,
    required this.gate,
    required this.outcome,
    required this.modules,
  });

  factory PathStage.fromJson(Object? json) {
    final m = asMap(json, 'path.stages[]');
    return PathStage(
      stage: m.integer('stage'),
      title: m.i18n('title'),
      gate: m.str('gate'),
      outcome: m.i18nOrNull('outcome'),
      modules: m.strings('modules'),
    );
  }

  final int stage;
  final I18n title;
  final String gate;
  final I18n? outcome;

  /// `track/module` keys.
  final List<String> modules;
}

@immutable
class Track {
  const Track({
    required this.id,
    required this.title,
    required this.description,
    required this.levels,
  });

  factory Track.fromJson(Object? json) {
    final m = asMap(json, 'tracks[]');
    final id = m.str('id');
    return Track(
      id: id,
      title: m.i18n('title'),
      description: m.i18nOrNull('description'),
      levels: m.list('levels', (j) => TrackLevel.fromJson(j, id)),
    );
  }

  final String id;
  final I18n title;
  final I18n? description;
  final List<TrackLevel> levels;
}

@immutable
class TrackLevel {
  const TrackLevel({
    required this.level,
    required this.title,
    required this.modules,
  });

  factory TrackLevel.fromJson(Object? json, String trackId) {
    final m = asMap(json, 'levels[]');
    return TrackLevel(
      level: m.integer('level'),
      title: m.i18n('title'),
      modules: m.list('modules', (j) => TrackModule.fromJson(j, trackId)),
    );
  }

  final int level;
  final I18n title;
  final List<TrackModule> modules;
}

@immutable
class TrackModule {
  const TrackModule({
    required this.track,
    required this.id,
    required this.title,
    required this.stage,
    required this.summary,
    required this.lessons,
  });

  factory TrackModule.fromJson(Object? json, String trackId) {
    final m = asMap(json, 'modules[]');
    return TrackModule(
      track: trackId,
      id: m.str('id'),
      title: m.i18n('title'),
      stage: m.integer('stage'),
      summary: m.i18nOrNull('summary'),
      lessons: m.list('lessons', LessonRef.fromJson),
    );
  }

  final String track;
  final String id;
  final I18n title;
  final int stage;
  final I18n? summary;
  final List<LessonRef> lessons;

  /// `track/module`, the key used by `path.stages[].modules`.
  String get key => '$track/$id';
}

/// Lesson stub in the track tree (id + title + main_path + duration).
@immutable
class LessonRef {
  const LessonRef({
    required this.id,
    required this.title,
    required this.mainPath,
    required this.durationMin,
  });

  factory LessonRef.fromJson(Object? json) {
    final m = asMap(json, 'lessons[]');
    return LessonRef(
      id: m.str('id'),
      title: m.i18n('title'),
      mainPath: m.boolean('main_path'),
      durationMin: m.integer('duration_min'),
    );
  }

  final String id;
  final I18n title;
  final bool mainPath;
  final int durationMin;
}

@immutable
class Skill {
  const Skill({
    required this.id,
    required this.title,
    required this.track,
    required this.prereqs,
    required this.lessons,
  });

  factory Skill.fromJson(Object? json) {
    final m = asMap(json, 'skills[]');
    return Skill(
      id: m.str('id'),
      title: m.i18n('title'),
      track: m.str('track'),
      prereqs: m.strings('prereqs'),
      lessons: m.strings('lessons'),
    );
  }

  final String id;
  final I18n title;
  final String track;
  final List<String> prereqs;
  final List<String> lessons;
}
