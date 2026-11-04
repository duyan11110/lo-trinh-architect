// Routes — docs/05 §3.2. M0: the four shell tabs + settings; M1: /learn/:id;
// M3: /learn/:id/quiz and /learn/:id/result/:attemptId; M4: /path?stage=n and
// /path/tracks; M5: /review/vocab, /review/session/:attemptId, /search?q=;
// M6: /gate/:stage(/exam|result/:attemptId), /module/:track/:moduleId/quiz
// (+ /result/:attemptId, DECISIONS.md §3), /settings/content|progress.
//
// The lesson routes are nested under `/` (full-screen, on the root
// navigator) so that `go('/learn/x')` and deep links rebuild the stack
// Học tiếp → bài → quiz/kết quả and back always has somewhere to go.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/gate/gate_exam_screen.dart';
import '../features/gate/gate_intro_screen.dart';
import '../features/gate/gate_result_screen.dart';
import '../features/home/home_screen.dart';
import '../features/lesson/lesson_screen.dart';
import '../features/path/path_screen.dart';
import '../features/quiz/module_quiz_screen.dart';
import '../features/quiz/quiz_screen.dart';
import '../features/quiz/result_screen.dart';
import '../features/review/review_screen.dart';
import '../features/review/review_session_screen.dart';
import '../features/search/search_screen.dart';
import '../features/settings/settings_screen.dart';
import 'shell.dart';

abstract final class Routes {
  static const home = '/';
  static const path = '/path';
  static const review = '/review';
  static const search = '/search';
  static const settings = '/settings';
  static const learn = '/learn/:lessonId';
  static const quiz = '$learn/quiz';
  static const result = '$learn/result/:attemptId';

  /// Shell tabs in bottom-nav order (docs/05 §3.1).
  static const tabs = [home, path, review, search];
}

final routerProvider = Provider<GoRouter>((ref) {
  final rootKey = GlobalKey<NavigatorState>();
  final router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: Routes.home,
    routes: [
      GoRoute(path: '/home', redirect: (_, _) => Routes.home),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: Routes.home,
            pageBuilder: (_, state) =>
                NoTransitionPage(key: state.pageKey, child: const HomeScreen()),
            routes: [
              GoRoute(
                path: 'learn/:lessonId',
                parentNavigatorKey: rootKey,
                builder: (_, state) => LessonScreen(
                  lessonId: state.pathParameters['lessonId']!,
                  initialSection: int.tryParse(
                    RegExp(r'^s(\d+)$').firstMatch(state.uri.fragment)?[1] ?? '',
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'quiz',
                    parentNavigatorKey: rootKey,
                    builder: (_, state) =>
                        QuizScreen(lessonId: state.pathParameters['lessonId']!),
                  ),
                  GoRoute(
                    path: 'result/:attemptId',
                    parentNavigatorKey: rootKey,
                    builder: (_, state) => ResultScreen(
                      lessonId: state.pathParameters['lessonId']!,
                      attemptId:
                          int.tryParse(state.pathParameters['attemptId']!) ?? -1,
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'gate/:stage',
                parentNavigatorKey: rootKey,
                builder: (_, state) => GateIntroScreen(stage: _stage(state)),
                routes: [
                  GoRoute(
                    path: 'exam/:attemptId',
                    parentNavigatorKey: rootKey,
                    builder: (_, state) => GateExamScreen(
                      stage: _stage(state),
                      attemptId: _attemptId(state),
                    ),
                  ),
                  GoRoute(
                    path: 'result/:attemptId',
                    parentNavigatorKey: rootKey,
                    builder: (_, state) => GateResultScreen(
                      stage: _stage(state),
                      attemptId: _attemptId(state),
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'module/:track/:moduleId/quiz',
                parentNavigatorKey: rootKey,
                builder: (_, state) => ModuleQuizScreen(moduleKey: _moduleKey(state)),
              ),
              GoRoute(
                path: 'module/:track/:moduleId/result/:attemptId',
                parentNavigatorKey: rootKey,
                builder: (_, state) => ModuleResultScreen(
                  moduleKey: _moduleKey(state),
                  attemptId: _attemptId(state),
                ),
              ),
            ],
          ),
          GoRoute(
            path: Routes.path,
            pageBuilder: (_, state) => NoTransitionPage(
              key: state.pageKey,
              child: PathScreen(
                initialStage: int.tryParse(
                  state.uri.queryParameters['stage'] ?? '',
                ),
              ),
            ),
            routes: [
              GoRoute(
                path: 'tracks',
                pageBuilder: (_, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const PathScreen(byTrack: true),
                ),
              ),
            ],
          ),
          GoRoute(
            path: Routes.review,
            pageBuilder: (_, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ReviewScreen(),
            ),
            routes: [
              GoRoute(
                path: 'vocab',
                pageBuilder: (_, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const ReviewScreen(vocab: true),
                ),
              ),
              GoRoute(
                path: 'session/:attemptId',
                parentNavigatorKey: rootKey,
                builder: (_, state) => ReviewSessionScreen(
                  attemptId:
                      int.tryParse(state.pathParameters['attemptId']!) ?? -1,
                ),
              ),
            ],
          ),
          GoRoute(
            path: Routes.search,
            pageBuilder: (_, state) => NoTransitionPage(
              key: state.pageKey,
              child: SearchScreen(
                initialQuery: state.uri.queryParameters['q'] ?? '',
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: Routes.settings,
        parentNavigatorKey: rootKey,
        builder: (_, _) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'content',
            parentNavigatorKey: rootKey,
            builder: (_, _) =>
                const SettingsScreen(section: SettingsSection.content),
          ),
          GoRoute(
            path: 'progress',
            parentNavigatorKey: rootKey,
            builder: (_, _) =>
                const SettingsScreen(section: SettingsSection.progress),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

int _stage(GoRouterState s) => int.tryParse(s.pathParameters['stage']!) ?? -1;

int _attemptId(GoRouterState s) =>
    int.tryParse(s.pathParameters['attemptId']!) ?? -1;

String _moduleKey(GoRouterState s) =>
    '${s.pathParameters['track']}/${s.pathParameters['moduleId']}';
