// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class LEn extends L {
  LEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Lộ Trình Architect';

  @override
  String get navContinue => 'Continue';

  @override
  String get navPath => 'Path';

  @override
  String get navReview => 'Review';

  @override
  String get navSearch => 'Search';

  @override
  String get settingsTitle => 'Settings';

  @override
  String lessonTakeQuiz(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Take the quiz · $count questions',
      one: 'Take the quiz · 1 question',
    );
    return '$_temp0';
  }

  @override
  String get lessonMarkRead => 'Mark as read, quiz later';

  @override
  String get quizCheck => 'Check';

  @override
  String get quizCorrect => 'Correct';

  @override
  String quizIncorrect(String answer) {
    return 'Not quite — answer: $answer';
  }

  @override
  String quizReread(int section) {
    return 'Reread section $section';
  }

  @override
  String get quizNext => 'Next';

  @override
  String get quizLeaveConfirm =>
      'Leave the quiz? Answered questions go to review; no score is recorded.';

  @override
  String resultPassed(int score, int total) {
    return '$score/$total · Passed';
  }

  @override
  String resultNotPassed(int score, int total) {
    return '$score/$total · Not yet (need ≥ 70%)';
  }

  @override
  String prereqWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'This lesson builds on $count lessons you have not passed yet',
      one: 'This lesson builds on 1 lesson you have not passed yet',
    );
    return '$_temp0';
  }

  @override
  String get prereqLearnFirst => 'Learn those first';

  @override
  String get prereqReadAnyway => 'Read anyway';

  @override
  String get reviewEmpty =>
      'Nothing to review. Questions you miss show up here after a day.';

  @override
  String reviewTierChange(int from, int to, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Level $from → $to · back in $days days',
      one: 'Level $from → $to · back in 1 day',
    );
    return '$_temp0';
  }

  @override
  String gateReady(int stage, int count, int minutes) {
    return 'Ready for the Stage $stage gate · $count questions · ~$minutes min';
  }

  @override
  String gateFailed(int stage, int score, int threshold, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Stage $stage gate: $score% — need $threshold%. Worth rereading: $count lessons',
      one:
          'Stage $stage gate: $score% — need $threshold%. Worth rereading: 1 lesson',
    );
    return '$_temp0';
  }

  @override
  String contentNewAvailable(int version) {
    return 'New content available (v$version)';
  }

  @override
  String get contentUpdateAction => 'Update';

  @override
  String contentUpdateFailed(int version) {
    return 'Could not download the update. Version v$version keeps working.';
  }

  @override
  String get progressImportConfirm =>
      'Replace current progress with this file? This cannot be undone.';

  @override
  String get codeCopied => 'Copied';

  @override
  String searchEmpty(String query) {
    return 'Nothing for \"$query\". Try the English term — lessons keep technical terms in English.';
  }

  @override
  String get diagramMissing => 'Diagram not rendered';

  @override
  String lessonEyebrow(int stage, String module, int minutes) {
    return 'Stage $stage · $module · $minutes min';
  }

  @override
  String lessonPosition(String module, int index, int total) {
    return '$module · Lesson $index/$total';
  }

  @override
  String lessonOptional(String note) {
    return 'Optional · $note';
  }

  @override
  String get lessonUpcoming => 'coming soon';

  @override
  String get lessonNotFound => 'This lesson is not in the current content.';

  @override
  String get contentLoadFailed => 'Could not read the content.';

  @override
  String get contentRetry => 'Try again';

  @override
  String get langVi => 'VI';

  @override
  String get langEn => 'EN';

  @override
  String get outputLabel => 'output';

  @override
  String codeLines(int start, int end) {
    return 'lines $start–$end';
  }

  @override
  String get codeCopy => 'Copy';

  @override
  String codeSource(String file, String tag) {
    return '$file · $tag';
  }

  @override
  String get termLearnedIn => 'Learned in:';

  @override
  String get diagramClose => 'Close';

  @override
  String get statusNew => 'Not started';

  @override
  String get statusOpened => 'Opened';

  @override
  String get statusRead => 'Read';

  @override
  String get statusPassed => 'Passed';

  @override
  String homeStage(int stage, String title) {
    return 'Stage $stage · $title';
  }

  @override
  String homeToGate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lessons to the gate',
      one: '1 lesson to the gate',
    );
    return '$_temp0';
  }

  @override
  String homeNextEyebrow(String module, int minutes) {
    return 'Next · $module · $minutes min';
  }

  @override
  String homeStartEyebrow(int stage) {
    return 'Start · Stage $stage';
  }

  @override
  String homeLessonInModule(int index, int total) {
    return 'Lesson $index/$total in this module';
  }

  @override
  String get homeEnterGate => 'Go to the gate';

  @override
  String homeStudyAhead(int stage) {
    return 'Or study ahead in Stage $stage';
  }

  @override
  String get homeFinished => 'You have finished the whole path';

  @override
  String get homeNoNewLesson => 'No new lesson in the current content yet';

  @override
  String get homeInProgress => 'In progress';

  @override
  String get homeCurrentModule => 'Current module';

  @override
  String get lessonOptionalTag => 'optional';

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get lessonRetakeQuiz => 'Retake the quiz';

  @override
  String get lessonNextLesson => 'Next lesson';

  @override
  String lessonLastAttempt(int score, int total) {
    return 'Last time: $score/$total';
  }

  @override
  String get lessonUpdated => 'updated';

  @override
  String get readingSettings => 'Text size';

  @override
  String get readingLineHeight => 'Line spacing';

  @override
  String quizProgress(int index, int total) {
    return 'Question $index/$total';
  }

  @override
  String get quizLeaveTooltip => 'Leave the quiz';

  @override
  String get quizStay => 'Stay';

  @override
  String get quizLeave => 'Leave';

  @override
  String quizSection(int section) {
    return 'Section $section';
  }

  @override
  String get bloomRemember => 'Remember';

  @override
  String get bloomUnderstand => 'Understand';

  @override
  String get bloomApply => 'Apply';

  @override
  String get bloomAnalyze => 'Analyze';

  @override
  String get bloomEvaluate => 'Evaluate';

  @override
  String get quizSelectAll => 'Select all that apply';

  @override
  String get quizYouChose => 'Your choice';

  @override
  String quizWhyNot(String option) {
    return 'Why $option is not right';
  }

  @override
  String get quizOtherExplanations => 'See the other explanations';

  @override
  String quizWhenRight(String option) {
    return 'When option $option would be right';
  }

  @override
  String get quizTrueBecause => 'True, because…';

  @override
  String get quizFalseBecause => 'False, because…';

  @override
  String get quizOrderYours => 'Your order';

  @override
  String get quizMoveUp => 'Move up';

  @override
  String get quizMoveDown => 'Move down';

  @override
  String quizAccepted(String answers) {
    return 'Accepted answers: $answers';
  }

  @override
  String get quizContext => 'Scenario';

  @override
  String quizOptionSemantics(String letter, String text) {
    return 'Option $letter, $text';
  }

  @override
  String get quizNone => 'This lesson has no quiz yet.';

  @override
  String get resultWrongHeading => 'Missed questions';

  @override
  String resultReviewTomorrow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'These questions come back in Review tomorrow.',
      one: 'This question comes back in Review tomorrow.',
    );
    return '$_temp0';
  }

  @override
  String get resultNoWrong => 'No wrong answers.';

  @override
  String get resultAnswer => 'Answer';

  @override
  String get resultSkills => 'Skills';

  @override
  String get resultSkillNew => 'new';

  @override
  String get resultSkillUp => 'improved';

  @override
  String get resultRereadLesson => 'Reread the lesson';

  @override
  String get resultBackHome => 'Back to Continue';

  @override
  String get resultNotFound => 'This quiz attempt was not found.';

  @override
  String get pathByStage => 'Stages';

  @override
  String get pathByTrack => 'By track';

  @override
  String pathCount(int done, int total) {
    return '$done/$total';
  }

  @override
  String get pathGateNotTaken => 'Gate: not taken';

  @override
  String get pathGatePassed => 'Gate: passed';

  @override
  String pathGateFailed(int score, int threshold) {
    return 'Gate: $score% — need $threshold%';
  }

  @override
  String get pathModuleQuiz => 'Module quiz';

  @override
  String get pathModuleDone => 'Completed';

  @override
  String pathLevel(int level, String title) {
    return 'L$level · $title';
  }

  @override
  String pathStageTag(int stage) {
    return 'S$stage';
  }

  @override
  String stageLabel(int stage) {
    return 'Stage $stage';
  }

  @override
  String prereqReturn(String title) {
    return 'Back to: $title';
  }

  @override
  String get reviewTabToday => 'Today';

  @override
  String get reviewTabVocab => 'Vocabulary';

  @override
  String get reviewDueToday => 'Due today';

  @override
  String reviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questions',
      one: '1 question',
    );
    return '$_temp0';
  }

  @override
  String reviewDueMeta(int lessons, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      lessons,
      locale: localeName,
      other: '$lessons lessons',
      one: '1 lesson',
    );
    return '$_temp0 · ~$minutes min';
  }

  @override
  String get reviewStart => 'Start review';

  @override
  String reviewRemaining(int count) {
    return '$count more after this session';
  }

  @override
  String get reviewUpcoming => 'Coming up';

  @override
  String get reviewTomorrow => 'Tomorrow';

  @override
  String reviewWeekday(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      '1': 'Mon',
      '2': 'Tue',
      '3': 'Wed',
      '4': 'Thu',
      '5': 'Fri',
      '6': 'Sat',
      '7': 'Sun',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String reviewUpcomingItem(String day, int count) {
    return '$day $count';
  }

  @override
  String get reviewHistory => 'History';

  @override
  String get reviewHistoryToday => 'Today';

  @override
  String get reviewHistoryYesterday => 'Yesterday';

  @override
  String reviewHistoryScore(int score, int total) {
    return '$score/$total';
  }

  @override
  String get reviewHistorySession => 'Review session';

  @override
  String get reviewHomeTitle => 'Review today';

  @override
  String reviewHomeStart(int minutes) {
    return 'Review for $minutes min';
  }

  @override
  String get reviewTierReset => 'Back to level 0 · back tomorrow';

  @override
  String reviewTierRetired(int from, int to) {
    return 'Level $from → $to · learned, no more reviews';
  }

  @override
  String reviewEyebrow(String module, String lesson) {
    return 'Review · $module · $lesson';
  }

  @override
  String reviewSummary(int score, int total, int down) {
    return '$score/$total · $down back to level 0';
  }

  @override
  String reviewTermQuestion(String term) {
    return 'What does $term mean?';
  }

  @override
  String reviewTermOther(String term) {
    return 'That is the meaning of $term.';
  }

  @override
  String get termAddReview => 'Add to review';

  @override
  String get termAdded => 'Added to review';

  @override
  String get termInReview => 'Already in review';

  @override
  String get vocabSearchHint => 'Find a term';

  @override
  String get vocabEmpty =>
      'No terms yet. Terms from lessons you have read show up here.';

  @override
  String vocabNoMatch(String query) {
    return 'Nothing for \"$query\".';
  }

  @override
  String get searchHint => 'Search lessons';

  @override
  String get searchIndexing => 'Indexing…';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get settingsReading => 'Reading';

  @override
  String get settingsContentLang => 'Content language';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsReviewMax => 'Questions per session';

  @override
  String get settingsContent => 'Content';

  @override
  String settingsContentVersion(int version, String date) {
    return 'v$version · $date';
  }

  @override
  String get settingsContentBundled => 'Bundled version';

  @override
  String get settingsContentDownloaded => 'Downloaded version';

  @override
  String get contentCheck => 'Check for updates';

  @override
  String get contentChecking => 'Checking…';

  @override
  String get contentUpToDate => 'You have the latest version.';

  @override
  String get contentCheckFailed =>
      'Could not check for updates. A connection is needed.';

  @override
  String contentDiff(int added, int changed) {
    return '+$added lessons, $changed updated';
  }

  @override
  String get contentUpdating => 'Updating…';

  @override
  String get contentUseBundled => 'Use the bundled version';

  @override
  String get settingsProgress => 'Progress';

  @override
  String get progressExport => 'Export JSON';

  @override
  String get progressImport => 'Import JSON';

  @override
  String get progressImportAction => 'Replace';

  @override
  String get progressImported => 'Progress imported.';

  @override
  String get progressImportFailed =>
      'This file is not a valid progress export. Your current progress is unchanged.';

  @override
  String get progressReset => 'Reset progress';

  @override
  String get progressResetConfirm =>
      'Delete all progress, review and quiz history on this device?';

  @override
  String get progressResetConfirm2 => 'Reset for sure? This cannot be undone.';

  @override
  String get progressResetAction => 'Reset';

  @override
  String get progressResetDone => 'Progress reset.';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAppVersion => 'App version';

  @override
  String get settingsLicenses => 'Licenses';

  @override
  String homeResumeQuiz(String title, int answered, int total) {
    return 'Resume quiz: $title ($answered/$total)';
  }

  @override
  String get homeRetakeGate => 'Retake';

  @override
  String gateTitle(int stage) {
    return 'Stage $stage gate';
  }

  @override
  String gateIntroSize(int count, int minutes) {
    return '$count questions · ~$minutes min';
  }

  @override
  String gatePassRule(int threshold) {
    return 'Pass at ≥ $threshold% · unlimited retakes';
  }

  @override
  String get gateNoExplanations =>
      'No explanations during the exam; you can pause.';

  @override
  String gateRemaining(int count) {
    return 'You still have $count lessons not passed in this stage';
  }

  @override
  String get gateStart => 'Start';

  @override
  String gateResume(int answered, int total) {
    return 'Resume ($answered/$total)';
  }

  @override
  String get gateHistory => 'Attempts';

  @override
  String gateHistoryRow(String date, int score, int total) {
    return '$date · $score/$total';
  }

  @override
  String get gateNone => 'This stage has no gate exam yet.';

  @override
  String get gatePauseConfirm => 'Pause — you can come back within 24 hours';

  @override
  String get gatePause => 'Pause';

  @override
  String get gateFlag => 'Mark for review';

  @override
  String get gateFlagged => 'Marked';

  @override
  String get gatePrevious => 'Previous';

  @override
  String get gateSubmit => 'Submit';

  @override
  String gateSubmitConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questions are unanswered. Submit anyway?',
      one: '1 question is unanswered. Submit anyway?',
      zero: 'Submit and see your result?',
    );
    return '$_temp0';
  }

  @override
  String gateResultNotPassed(int score, int total, int threshold) {
    return '$score/$total · Not yet (need ≥ $threshold%)';
  }

  @override
  String get gateByTrack => 'By track';

  @override
  String get gateCrossTrack => 'Cross-track';

  @override
  String get gateReread => 'Worth rereading';

  @override
  String gateNextStage(int stage) {
    return 'On to Stage $stage';
  }

  @override
  String get moduleResultByLesson => 'By lesson';

  @override
  String get pathModulePassed => 'Module ✓';

  @override
  String get moduleQuizNone => 'This module has no quiz questions yet.';

  @override
  String get pathEnterGate => 'Open the gate exam';

  @override
  String get lessonToc => 'Contents';

  @override
  String get lessonMetaModule => 'Module';

  @override
  String get lessonMetaDuration => 'Duration';

  @override
  String get lessonMetaPrereqs => 'Before you start';

  @override
  String get lessonMetaRelated => 'Related';
}
