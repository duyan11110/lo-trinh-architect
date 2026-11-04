// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class LVi extends L {
  LVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Lộ Trình Architect';

  @override
  String get navContinue => 'Học tiếp';

  @override
  String get navPath => 'Lộ trình';

  @override
  String get navReview => 'Ôn tập';

  @override
  String get navSearch => 'Tìm';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String lessonTakeQuiz(int count) {
    return 'Làm quiz · $count câu';
  }

  @override
  String get lessonMarkRead => 'Đánh dấu đã đọc, quiz sau';

  @override
  String get quizCheck => 'Kiểm tra';

  @override
  String get quizCorrect => 'Đúng';

  @override
  String quizIncorrect(String answer) {
    return 'Chưa đúng — đáp án: $answer';
  }

  @override
  String quizReread(int section) {
    return 'Đọc lại mục $section';
  }

  @override
  String get quizNext => 'Tiếp';

  @override
  String get quizLeaveConfirm =>
      'Thoát quiz? Câu đã trả lời được lưu vào ôn tập; điểm không được tính.';

  @override
  String resultPassed(int score, int total) {
    return '$score/$total · Đã qua';
  }

  @override
  String resultNotPassed(int score, int total) {
    return '$score/$total · Chưa qua (cần ≥ 70%)';
  }

  @override
  String prereqWarning(int count) {
    return 'Bài này dựa trên $count bài bạn chưa qua quiz';
  }

  @override
  String get prereqLearnFirst => 'Học bài trước';

  @override
  String get prereqReadAnyway => 'Cứ đọc';

  @override
  String get reviewEmpty =>
      'Chưa có gì để ôn. Câu bạn trả lời sai sẽ xuất hiện ở đây sau 1 ngày.';

  @override
  String reviewTierChange(int from, int to, int days) {
    return 'Bậc $from → $to · gặp lại sau $days ngày';
  }

  @override
  String gateReady(int stage, int count, int minutes) {
    return 'Sẵn sàng thi cổng Giai đoạn $stage · $count câu · ~$minutes phút';
  }

  @override
  String gateFailed(int stage, int score, int threshold, int count) {
    return 'Cổng GĐ$stage: $score% — cần $threshold%. Nên đọc lại: $count bài';
  }

  @override
  String contentNewAvailable(int version) {
    return 'Có nội dung mới (v$version)';
  }

  @override
  String get contentUpdateAction => 'Cập nhật';

  @override
  String contentUpdateFailed(int version) {
    return 'Không tải được bản mới. Bạn vẫn dùng bản v$version bình thường.';
  }

  @override
  String get progressImportConfirm =>
      'Ghi đè tiến độ hiện tại bằng file này? Không hoàn tác được.';

  @override
  String get codeCopied => 'Đã sao chép';

  @override
  String searchEmpty(String query) {
    return 'Không thấy \"$query\". Thử từ tiếng Anh — thuật ngữ trong bài giữ tiếng Anh.';
  }

  @override
  String get diagramMissing => 'Sơ đồ chưa render';

  @override
  String lessonEyebrow(int stage, String module, int minutes) {
    return 'Giai đoạn $stage · $module · $minutes phút';
  }

  @override
  String lessonPosition(String module, int index, int total) {
    return '$module · Bài $index/$total';
  }

  @override
  String lessonOptional(String note) {
    return 'Tùy chọn · $note';
  }

  @override
  String get lessonUpcoming => 'sắp có';

  @override
  String get lessonNotFound => 'Không có bài này trong nội dung hiện tại.';

  @override
  String get contentLoadFailed => 'Không đọc được nội dung.';

  @override
  String get contentRetry => 'Thử lại';

  @override
  String get langVi => 'VI';

  @override
  String get langEn => 'EN';

  @override
  String get outputLabel => 'output';

  @override
  String codeLines(int start, int end) {
    return 'dòng $start–$end';
  }

  @override
  String get codeCopy => 'Sao chép';

  @override
  String codeSource(String file, String tag) {
    return '$file · $tag';
  }

  @override
  String get termLearnedIn => 'Học ở:';

  @override
  String get diagramClose => 'Đóng';

  @override
  String get statusNew => 'Chưa học';

  @override
  String get statusOpened => 'Đã mở';

  @override
  String get statusRead => 'Đã đọc';

  @override
  String get statusPassed => 'Đã qua';

  @override
  String homeStage(int stage, String title) {
    return 'Giai đoạn $stage · $title';
  }

  @override
  String homeToGate(int count) {
    return 'Còn $count bài tới cổng';
  }

  @override
  String homeNextEyebrow(String module, int minutes) {
    return 'Tiếp theo · $module · $minutes ph';
  }

  @override
  String homeStartEyebrow(int stage) {
    return 'Bắt đầu · Giai đoạn $stage';
  }

  @override
  String homeLessonInModule(int index, int total) {
    return 'Bài $index/$total trong module';
  }

  @override
  String get homeEnterGate => 'Vào bài cổng';

  @override
  String homeStudyAhead(int stage) {
    return 'Hoặc học trước GĐ$stage';
  }

  @override
  String get homeFinished => 'Bạn đã đi hết lộ trình';

  @override
  String get homeNoNewLesson => 'Chưa có bài mới trong nội dung hiện tại';

  @override
  String get homeInProgress => 'Đang dở';

  @override
  String get homeCurrentModule => 'Module hiện tại';

  @override
  String get lessonOptionalTag => 'tùy chọn';

  @override
  String durationMinutes(int minutes) {
    return '$minutes ph';
  }

  @override
  String get lessonRetakeQuiz => 'Làm lại quiz';

  @override
  String get lessonNextLesson => 'Bài tiếp theo';

  @override
  String lessonLastAttempt(int score, int total) {
    return 'Lần trước: $score/$total';
  }

  @override
  String get lessonUpdated => 'đã cập nhật';

  @override
  String get readingSettings => 'Cỡ chữ';

  @override
  String get readingLineHeight => 'Khoảng dòng';

  @override
  String quizProgress(int index, int total) {
    return 'Câu $index/$total';
  }

  @override
  String get quizLeaveTooltip => 'Thoát quiz';

  @override
  String get quizStay => 'Ở lại';

  @override
  String get quizLeave => 'Thoát';

  @override
  String quizSection(int section) {
    return 'Mục $section';
  }

  @override
  String get bloomRemember => 'Nhớ';

  @override
  String get bloomUnderstand => 'Hiểu';

  @override
  String get bloomApply => 'Áp dụng';

  @override
  String get bloomAnalyze => 'Phân tích';

  @override
  String get bloomEvaluate => 'Đánh giá';

  @override
  String get quizSelectAll => 'Chọn tất cả ý đúng';

  @override
  String get quizYouChose => 'Bạn chọn';

  @override
  String quizWhyNot(String option) {
    return 'Vì sao $option không đúng';
  }

  @override
  String get quizOtherExplanations => 'Xem giải thích khác';

  @override
  String quizWhenRight(String option) {
    return 'Khi nào phương án $option lại đúng';
  }

  @override
  String get quizTrueBecause => 'Đúng, vì…';

  @override
  String get quizFalseBecause => 'Sai, vì…';

  @override
  String get quizOrderYours => 'Bạn xếp';

  @override
  String get quizMoveUp => 'Lên';

  @override
  String get quizMoveDown => 'Xuống';

  @override
  String quizAccepted(String answers) {
    return 'Đáp án chấp nhận: $answers';
  }

  @override
  String get quizContext => 'Tình huống';

  @override
  String quizOptionSemantics(String letter, String text) {
    return 'Phương án $letter, $text';
  }

  @override
  String get quizNone => 'Bài này chưa có quiz.';

  @override
  String get resultWrongHeading => 'Câu sai';

  @override
  String resultReviewTomorrow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Những câu này sẽ xuất hiện trong Ôn tập vào ngày mai.',
      one: 'Câu này sẽ xuất hiện trong Ôn tập vào ngày mai.',
    );
    return '$_temp0';
  }

  @override
  String get resultNoWrong => 'Không có câu sai.';

  @override
  String get resultAnswer => 'Đáp án';

  @override
  String get resultSkills => 'Kỹ năng';

  @override
  String get resultSkillNew => 'mới';

  @override
  String get resultSkillUp => 'tiến bộ';

  @override
  String get resultRereadLesson => 'Đọc lại bài';

  @override
  String get resultBackHome => 'Về Học tiếp';

  @override
  String get resultNotFound => 'Không tìm thấy lần làm quiz này.';

  @override
  String get pathByStage => 'Giai đoạn';

  @override
  String get pathByTrack => 'Theo track';

  @override
  String pathCount(int done, int total) {
    return '$done/$total';
  }

  @override
  String get pathGateNotTaken => 'Cổng: chưa thi';

  @override
  String get pathGatePassed => 'Cổng: đã qua';

  @override
  String pathGateFailed(int score, int threshold) {
    return 'Cổng: $score% — cần $threshold%';
  }

  @override
  String get pathModuleQuiz => 'Quiz module';

  @override
  String get pathModuleDone => 'Hoàn thành';

  @override
  String pathLevel(int level, String title) {
    return 'L$level · $title';
  }

  @override
  String pathStageTag(int stage) {
    return 'GĐ$stage';
  }

  @override
  String stageLabel(int stage) {
    return 'Giai đoạn $stage';
  }

  @override
  String prereqReturn(String title) {
    return 'Quay lại: $title';
  }

  @override
  String get reviewTabToday => 'Hôm nay';

  @override
  String get reviewTabVocab => 'Từ vựng';

  @override
  String get reviewDueToday => 'Đến hạn hôm nay';

  @override
  String reviewCount(int count) {
    return '$count câu';
  }

  @override
  String reviewDueMeta(int lessons, int minutes) {
    return '$lessons bài · ~$minutes phút';
  }

  @override
  String get reviewStart => 'Bắt đầu ôn';

  @override
  String reviewRemaining(int count) {
    return 'Còn $count câu, ôn tiếp sau';
  }

  @override
  String get reviewUpcoming => 'Sắp tới';

  @override
  String get reviewTomorrow => 'Ngày mai';

  @override
  String reviewWeekday(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      '1': 'T2',
      '2': 'T3',
      '3': 'T4',
      '4': 'T5',
      '5': 'T6',
      '6': 'T7',
      '7': 'CN',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String reviewUpcomingItem(String day, int count) {
    return '$day $count';
  }

  @override
  String get reviewHistory => 'Lịch sử';

  @override
  String get reviewHistoryToday => 'Hôm nay';

  @override
  String get reviewHistoryYesterday => 'Hôm qua';

  @override
  String reviewHistoryScore(int score, int total) {
    return '$score/$total';
  }

  @override
  String get reviewHistorySession => 'Phiên ôn';

  @override
  String get reviewHomeTitle => 'Ôn hôm nay';

  @override
  String reviewHomeStart(int minutes) {
    return 'Ôn $minutes phút';
  }

  @override
  String get reviewTierReset => 'Về bậc 0 · gặp lại ngày mai';

  @override
  String reviewTierRetired(int from, int to) {
    return 'Bậc $from → $to · đã nhớ, không gặp lại';
  }

  @override
  String reviewEyebrow(String module, String lesson) {
    return 'Ôn · $module · $lesson';
  }

  @override
  String reviewSummary(int score, int total, int down) {
    return '$score/$total · $down câu về bậc 0';
  }

  @override
  String reviewTermQuestion(String term) {
    return '$term nghĩa là gì?';
  }

  @override
  String reviewTermOther(String term) {
    return 'Đây là nghĩa của $term.';
  }

  @override
  String get termAddReview => 'Thêm vào ôn';

  @override
  String get termAdded => 'Đã thêm vào ôn';

  @override
  String get termInReview => 'Đã có trong ôn tập';

  @override
  String get vocabSearchHint => 'Tìm từ';

  @override
  String get vocabEmpty =>
      'Chưa có từ nào. Thuật ngữ của bài bạn đã đọc sẽ hiện ở đây.';

  @override
  String vocabNoMatch(String query) {
    return 'Không thấy \"$query\".';
  }

  @override
  String get searchHint => 'Tìm trong bài';

  @override
  String get searchIndexing => 'Đang lập chỉ mục…';

  @override
  String get actionCancel => 'Hủy';

  @override
  String get settingsReading => 'Đọc';

  @override
  String get settingsContentLang => 'Ngôn ngữ nội dung';

  @override
  String get settingsTheme => 'Giao diện';

  @override
  String get settingsThemeSystem => 'Hệ thống';

  @override
  String get settingsThemeLight => 'Sáng';

  @override
  String get settingsThemeDark => 'Tối';

  @override
  String get settingsReviewMax => 'Số câu tối đa mỗi phiên';

  @override
  String get settingsContent => 'Nội dung';

  @override
  String settingsContentVersion(int version, String date) {
    return 'v$version · $date';
  }

  @override
  String get settingsContentBundled => 'Bản đóng gói';

  @override
  String get settingsContentDownloaded => 'Bản đã tải';

  @override
  String get contentCheck => 'Kiểm tra bản mới';

  @override
  String get contentChecking => 'Đang kiểm tra…';

  @override
  String get contentUpToDate => 'Bạn đang dùng bản mới nhất.';

  @override
  String get contentCheckFailed =>
      'Không kiểm tra được bản mới. Cần kết nối mạng.';

  @override
  String contentDiff(int added, int changed) {
    return '+$added bài, $changed bài cập nhật';
  }

  @override
  String get contentUpdating => 'Đang cập nhật…';

  @override
  String get contentUseBundled => 'Dùng bản đóng gói';

  @override
  String get settingsProgress => 'Tiến độ';

  @override
  String get progressExport => 'Xuất JSON';

  @override
  String get progressImport => 'Nhập JSON';

  @override
  String get progressImportAction => 'Ghi đè';

  @override
  String get progressImported => 'Đã nhập tiến độ.';

  @override
  String get progressImportFailed =>
      'File này không phải bản xuất tiến độ hợp lệ. Tiến độ hiện tại giữ nguyên.';

  @override
  String get progressReset => 'Đặt lại tiến độ';

  @override
  String get progressResetConfirm =>
      'Xóa mọi tiến độ, ôn tập và lịch sử quiz trên máy này?';

  @override
  String get progressResetConfirm2 => 'Chắc chắn đặt lại? Không hoàn tác được.';

  @override
  String get progressResetAction => 'Đặt lại';

  @override
  String get progressResetDone => 'Đã đặt lại tiến độ.';

  @override
  String get settingsAbout => 'Về';

  @override
  String get settingsAppVersion => 'Phiên bản app';

  @override
  String get settingsLicenses => 'Giấy phép';

  @override
  String homeResumeQuiz(String title, int answered, int total) {
    return 'Tiếp tục quiz: $title ($answered/$total)';
  }

  @override
  String get homeRetakeGate => 'Thi lại';

  @override
  String gateTitle(int stage) {
    return 'Bài cổng Giai đoạn $stage';
  }

  @override
  String gateIntroSize(int count, int minutes) {
    return '$count câu · ~$minutes phút';
  }

  @override
  String gatePassRule(int threshold) {
    return 'Đạt khi đúng ≥ $threshold% · làm lại không giới hạn';
  }

  @override
  String get gateNoExplanations =>
      'Không có giải thích trong lúc thi, có thể tạm dừng.';

  @override
  String gateRemaining(int count) {
    return 'Bạn còn $count bài chưa qua trong giai đoạn này';
  }

  @override
  String get gateStart => 'Bắt đầu';

  @override
  String gateResume(int answered, int total) {
    return 'Tiếp tục ($answered/$total)';
  }

  @override
  String get gateHistory => 'Các lần thi';

  @override
  String gateHistoryRow(String date, int score, int total) {
    return '$date · $score/$total';
  }

  @override
  String get gateNone => 'Giai đoạn này chưa có bài cổng.';

  @override
  String get gatePauseConfirm => 'Tạm dừng — bạn có thể quay lại trong 24 giờ';

  @override
  String get gatePause => 'Tạm dừng';

  @override
  String get gateFlag => 'Đánh dấu xem lại';

  @override
  String get gateFlagged => 'Đã đánh dấu';

  @override
  String get gatePrevious => 'Câu trước';

  @override
  String get gateSubmit => 'Nộp bài';

  @override
  String gateSubmitConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Còn $count câu chưa trả lời. Vẫn nộp bài?',
      zero: 'Nộp bài và xem kết quả?',
    );
    return '$_temp0';
  }

  @override
  String gateResultNotPassed(int score, int total, int threshold) {
    return '$score/$total · Chưa qua (cần ≥ $threshold%)';
  }

  @override
  String get gateByTrack => 'Theo track';

  @override
  String get gateCrossTrack => 'Xuyên track';

  @override
  String get gateReread => 'Nên đọc lại';

  @override
  String gateNextStage(int stage) {
    return 'Sang Giai đoạn $stage';
  }

  @override
  String get moduleResultByLesson => 'Theo bài';

  @override
  String get pathModulePassed => 'Module ✓';

  @override
  String get moduleQuizNone => 'Module này chưa có câu hỏi quiz.';

  @override
  String get pathEnterGate => 'Vào bài cổng';
}
