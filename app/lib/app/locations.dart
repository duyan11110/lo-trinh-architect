// Locations of the lesson routes (docs/05 §3.2). Ids come from content.json.
const String homeLocation = '/';

/// S2; `?stage=n` opens that stage (docs/05 §3.2).
String pathLocation({int? stage}) =>
    stage == null ? '/path' : '/path?stage=$stage';

/// S2 "Theo track".
const String pathTracksLocation = '/path/tracks';

String lessonLocation(String id, {int? section}) =>
    section == null ? '/learn/$id' : '/learn/$id#s$section';

String quizLocation(String lessonId) => '/learn/$lessonId/quiz';

String resultLocation(String lessonId, int attemptId) =>
    '/learn/$lessonId/result/$attemptId';

/// S7 "Hôm nay" / "Từ vựng" (docs/05 §3.2).
const String reviewLocation = '/review';
const String reviewVocabLocation = '/review/vocab';

/// Review session over `quiz_attempt` [attemptId] (S4 in mode `review`).
String reviewSessionLocation(int attemptId) => '/review/session/$attemptId';

/// S9; `?q=` pre-fills the query.
String searchLocation([String? query]) =>
    query == null || query.isEmpty ? '/search' : '/search?q=${Uri.encodeQueryComponent(query)}';

/// S8 (docs/05 §3.2).
String gateLocation(int stage) => '/gate/$stage';

String gateExamLocation(int stage, int attemptId) =>
    '/gate/$stage/exam/$attemptId';

String gateResultLocation(int stage, int attemptId) =>
    '/gate/$stage/result/$attemptId';

/// Module quiz (S4 mode `module`) for a `track/module` key.
String moduleQuizLocation(String moduleKey) => '/module/$moduleKey/quiz';

/// Module quiz result (M6, DECISIONS.md §3: not in the docs/05 §3.2 table).
String moduleResultLocation(String moduleKey, int attemptId) =>
    '/module/$moduleKey/result/$attemptId';

/// S10 and its two sub-pages (docs/05 §3.2).
const String settingsLocation = '/settings';
const String settingsContentLocation = '/settings/content';
const String settingsProgressLocation = '/settings/progress';
