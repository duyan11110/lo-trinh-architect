import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L
/// returned by `L.of(context)`.
///
/// Applications need to include `L.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L.localizationsDelegates,
///   supportedLocales: L.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L.supportedLocales
/// property.
abstract class L {
  L(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L of(BuildContext context) {
    return Localizations.of<L>(context, L)!;
  }

  static const LocalizationsDelegate<L> delegate = _LDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// Tên app (DECISIONS.md D7).
  ///
  /// In vi, this message translates to:
  /// **'Lộ Trình Architect'**
  String get appTitle;

  /// Bottom nav / nút chính trang chủ (docs/05 §3.1, §7).
  ///
  /// In vi, this message translates to:
  /// **'Học tiếp'**
  String get navContinue;

  /// Bottom nav (docs/05 §3.1).
  ///
  /// In vi, this message translates to:
  /// **'Lộ trình'**
  String get navPath;

  /// Bottom nav (docs/05 §3.1).
  ///
  /// In vi, this message translates to:
  /// **'Ôn tập'**
  String get navReview;

  /// Bottom nav (docs/05 §3.1).
  ///
  /// In vi, this message translates to:
  /// **'Tìm'**
  String get navSearch;

  /// Nút ⚙ ở app bar Học tiếp và màn S10 (docs/05 §3.1).
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get settingsTitle;

  /// Cuối bài.
  ///
  /// In vi, this message translates to:
  /// **'Làm quiz · {count} câu'**
  String lessonTakeQuiz(int count);

  /// Cuối bài, nút phụ.
  ///
  /// In vi, this message translates to:
  /// **'Đánh dấu đã đọc, quiz sau'**
  String get lessonMarkRead;

  /// No description provided for @quizCheck.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra'**
  String get quizCheck;

  /// No description provided for @quizCorrect.
  ///
  /// In vi, this message translates to:
  /// **'Đúng'**
  String get quizCorrect;

  /// No description provided for @quizIncorrect.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đúng — đáp án: {answer}'**
  String quizIncorrect(String answer);

  /// No description provided for @quizReread.
  ///
  /// In vi, this message translates to:
  /// **'Đọc lại mục {section}'**
  String quizReread(int section);

  /// No description provided for @quizNext.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp'**
  String get quizNext;

  /// No description provided for @quizLeaveConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Thoát quiz? Câu đã trả lời được lưu vào ôn tập; điểm không được tính.'**
  String get quizLeaveConfirm;

  /// No description provided for @resultPassed.
  ///
  /// In vi, this message translates to:
  /// **'{score}/{total} · Đã qua'**
  String resultPassed(int score, int total);

  /// No description provided for @resultNotPassed.
  ///
  /// In vi, this message translates to:
  /// **'{score}/{total} · Chưa qua (cần ≥ 70%)'**
  String resultNotPassed(int score, int total);

  /// No description provided for @prereqWarning.
  ///
  /// In vi, this message translates to:
  /// **'Bài này dựa trên {count} bài bạn chưa qua quiz'**
  String prereqWarning(int count);

  /// No description provided for @prereqLearnFirst.
  ///
  /// In vi, this message translates to:
  /// **'Học bài trước'**
  String get prereqLearnFirst;

  /// No description provided for @prereqReadAnyway.
  ///
  /// In vi, this message translates to:
  /// **'Cứ đọc'**
  String get prereqReadAnyway;

  /// No description provided for @reviewEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có gì để ôn. Câu bạn trả lời sai sẽ xuất hiện ở đây sau 1 ngày.'**
  String get reviewEmpty;

  /// No description provided for @reviewTierChange.
  ///
  /// In vi, this message translates to:
  /// **'Bậc {from} → {to} · gặp lại sau {days} ngày'**
  String reviewTierChange(int from, int to, int days);

  /// No description provided for @gateReady.
  ///
  /// In vi, this message translates to:
  /// **'Sẵn sàng thi cổng Giai đoạn {stage} · {count} câu · ~{minutes} phút'**
  String gateReady(int stage, int count, int minutes);

  /// No description provided for @gateFailed.
  ///
  /// In vi, this message translates to:
  /// **'Cổng GĐ{stage}: {score}% — cần {threshold}%. Nên đọc lại: {count} bài'**
  String gateFailed(int stage, int score, int threshold, int count);

  /// No description provided for @contentNewAvailable.
  ///
  /// In vi, this message translates to:
  /// **'Có nội dung mới (v{version})'**
  String contentNewAvailable(int version);

  /// No description provided for @contentUpdateAction.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật'**
  String get contentUpdateAction;

  /// No description provided for @contentUpdateFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được bản mới. Bạn vẫn dùng bản v{version} bình thường.'**
  String contentUpdateFailed(int version);

  /// No description provided for @progressImportConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Ghi đè tiến độ hiện tại bằng file này? Không hoàn tác được.'**
  String get progressImportConfirm;

  /// No description provided for @codeCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép'**
  String get codeCopied;

  /// No description provided for @searchEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Không thấy \"{query}\". Thử từ tiếng Anh — thuật ngữ trong bài giữ tiếng Anh.'**
  String searchEmpty(String query);

  /// DiagramView khi diagram_svg null (docs/05 §7).
  ///
  /// In vi, this message translates to:
  /// **'Sơ đồ chưa render'**
  String get diagramMissing;

  /// Eyebrow S3 (docs/05 S3: GIAI ĐOẠN 0 · HTTP · 12 PHÚT); in hoa khi hiển thị.
  ///
  /// In vi, this message translates to:
  /// **'Giai đoạn {stage} · {module} · {minutes} phút'**
  String lessonEyebrow(int stage, String module, int minutes);

  /// Tiêu đề LessonAppBar (docs/05 S3: HTTP · Bài 3/8).
  ///
  /// In vi, this message translates to:
  /// **'{module} · Bài {index}/{total}'**
  String lessonPosition(String module, int index, int total);

  /// Banner bài nhánh phụ (docs/05 S3 Trạng thái).
  ///
  /// In vi, this message translates to:
  /// **'Tùy chọn · {note}'**
  String lessonOptional(String note);

  /// LessonLinkChip tới bài chưa có trong content.json (docs/04 §2, docs/05 S3).
  ///
  /// In vi, this message translates to:
  /// **'sắp có'**
  String get lessonUpcoming;

  /// /learn/:id với id không có trong content.json (M1, DECISIONS.md §3).
  ///
  /// In vi, this message translates to:
  /// **'Không có bài này trong nội dung hiện tại.'**
  String get lessonNotFound;

  /// Lỗi nạp content.json (docs/05 §10).
  ///
  /// In vi, this message translates to:
  /// **'Không đọc được nội dung.'**
  String get contentLoadFailed;

  /// Nút thử lại (docs/05 §10).
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get contentRetry;

  /// LangToggle.
  ///
  /// In vi, this message translates to:
  /// **'VI'**
  String get langVi;

  /// LangToggle.
  ///
  /// In vi, this message translates to:
  /// **'EN'**
  String get langEn;

  /// Nhãn OutputBlock (docs/05 S3: nhãn "output").
  ///
  /// In vi, this message translates to:
  /// **'output'**
  String get outputLabel;

  /// Header CodeBlock (docs/05 S3: "dòng 1–7").
  ///
  /// In vi, this message translates to:
  /// **'dòng {start}–{end}'**
  String codeLines(int start, int end);

  /// Tooltip nút copy của CodeBlock.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép'**
  String get codeCopy;

  /// Chạm file chip: đường dẫn đầy đủ + tag (docs/05 S3).
  ///
  /// In vi, this message translates to:
  /// **'{file} · {tag}'**
  String codeSource(String file, String tag);

  /// TermTooltip (docs/05 S3: "Học ở: <bài>").
  ///
  /// In vi, this message translates to:
  /// **'Học ở:'**
  String get termLearnedIn;

  /// Nút đóng DiagramFullScreen.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get diagramClose;

  /// Nhãn Semantics của StatusDot (docs/05 §8).
  ///
  /// In vi, this message translates to:
  /// **'Chưa học'**
  String get statusNew;

  /// No description provided for @statusOpened.
  ///
  /// In vi, this message translates to:
  /// **'Đã mở'**
  String get statusOpened;

  /// No description provided for @statusRead.
  ///
  /// In vi, this message translates to:
  /// **'Đã đọc'**
  String get statusRead;

  /// No description provided for @statusPassed.
  ///
  /// In vi, this message translates to:
  /// **'Đã qua'**
  String get statusPassed;

  /// Eyebrow S1 (docs/05 S1: GIAI ĐOẠN 0 · NỀN TẢNG); in hoa khi hiển thị. M2, DECISIONS.md §3.
  ///
  /// In vi, this message translates to:
  /// **'Giai đoạn {stage} · {title}'**
  String homeStage(int stage, String title);

  /// S1 (docs/05 S1 wireframe).
  ///
  /// In vi, this message translates to:
  /// **'Còn {count} bài tới cổng'**
  String homeToGate(int count);

  /// Eyebrow NextLessonCard (docs/05 S1: TIẾP THEO · HTTP · 12 ph); in hoa khi hiển thị.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp theo · {module} · {minutes} ph'**
  String homeNextEyebrow(String module, int minutes);

  /// Eyebrow NextLessonCard khi mới cài (docs/05 S1 Trạng thái).
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu · Giai đoạn {stage}'**
  String homeStartEyebrow(int stage);

  /// NextLessonCard (docs/05 S1). Đếm mọi bài trong module, kể cả nhánh phụ (DECISIONS.md E7).
  ///
  /// In vi, this message translates to:
  /// **'Bài {index}/{total} trong module'**
  String homeLessonInModule(int index, int total);

  /// GateReadyCard (docs/05 S1 Trạng thái).
  ///
  /// In vi, this message translates to:
  /// **'Vào bài cổng'**
  String get homeEnterGate;

  /// Link nhỏ dưới GateReadyCard (docs/05 S1 Trạng thái).
  ///
  /// In vi, this message translates to:
  /// **'Hoặc học trước GĐ{stage}'**
  String homeStudyAhead(int stage);

  /// NextLessonCard khi học xong toàn bộ (docs/05 S1 Trạng thái).
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã đi hết lộ trình'**
  String get homeFinished;

  /// NextLessonCard khi không còn bài new/opened có trong content.json mà giai đoạn chưa xong (M2, DECISIONS.md §3).
  ///
  /// In vi, this message translates to:
  /// **'Chưa có bài mới trong nội dung hiện tại'**
  String get homeNoNewLesson;

  /// S1 (docs/05 S1 wireframe).
  ///
  /// In vi, this message translates to:
  /// **'Đang dở'**
  String get homeInProgress;

  /// S1 (docs/05 S1 wireframe).
  ///
  /// In vi, this message translates to:
  /// **'Module hiện tại'**
  String get homeCurrentModule;

  /// Nhãn mờ cho bài nhánh phụ trong danh sách (docs/05 S1, S2).
  ///
  /// In vi, this message translates to:
  /// **'tùy chọn'**
  String get lessonOptionalTag;

  /// Thời lượng ở LessonRow (docs/05 S2: 10 ph).
  ///
  /// In vi, this message translates to:
  /// **'{minutes} ph'**
  String durationMinutes(int minutes);

  /// BottomActionBar bài đã qua (docs/05 S3 Trạng thái).
  ///
  /// In vi, this message translates to:
  /// **'Làm lại quiz'**
  String get lessonRetakeQuiz;

  /// BottomActionBar bài đã qua (docs/05 S3 Trạng thái).
  ///
  /// In vi, this message translates to:
  /// **'Bài tiếp theo'**
  String get lessonNextLesson;

  /// BottomActionBar bài đã đọc, chưa qua (docs/05 S3 Trạng thái).
  ///
  /// In vi, this message translates to:
  /// **'Lần trước: {score}/{total}'**
  String lessonLastAttempt(int score, int total);

  /// Nhãn bài passed có content_version mới hơn (docs/07 §5.1).
  ///
  /// In vi, this message translates to:
  /// **'đã cập nhật'**
  String get lessonUpdated;

  /// Nút Aa và tiêu đề bottom sheet cỡ chữ (docs/05 S3).
  ///
  /// In vi, this message translates to:
  /// **'Cỡ chữ'**
  String get readingSettings;

  /// Bottom sheet Aa: 2 nấc khoảng dòng (docs/05 S3).
  ///
  /// In vi, this message translates to:
  /// **'Khoảng dòng'**
  String get readingLineHeight;

  /// App bar S4 (docs/05 S4: Câu 3/6).
  ///
  /// In vi, this message translates to:
  /// **'Câu {index}/{total}'**
  String quizProgress(int index, int total);

  /// Tooltip nút ✕ của S4 (M3, DECISIONS.md §3).
  ///
  /// In vi, this message translates to:
  /// **'Thoát quiz'**
  String get quizLeaveTooltip;

  /// Hộp thoại thoát quiz (docs/05 S4: [Ở lại] [Thoát]).
  ///
  /// In vi, this message translates to:
  /// **'Ở lại'**
  String get quizStay;

  /// Hộp thoại thoát quiz (docs/05 S4: [Ở lại] [Thoát]).
  ///
  /// In vi, this message translates to:
  /// **'Thoát'**
  String get quizLeave;

  /// Eyebrow S4 (docs/05 S4: HIỂU · MỤC 4); in hoa khi hiển thị.
  ///
  /// In vi, this message translates to:
  /// **'Mục {section}'**
  String quizSection(int section);

  /// Eyebrow S4 — bloom (docs/05 S4: NHỚ/HIỂU/ÁP DỤNG/PHÂN TÍCH).
  ///
  /// In vi, this message translates to:
  /// **'Nhớ'**
  String get bloomRemember;

  /// Eyebrow S4 — bloom.
  ///
  /// In vi, this message translates to:
  /// **'Hiểu'**
  String get bloomUnderstand;

  /// Eyebrow S4 — bloom.
  ///
  /// In vi, this message translates to:
  /// **'Áp dụng'**
  String get bloomApply;

  /// Eyebrow S4 — bloom.
  ///
  /// In vi, this message translates to:
  /// **'Phân tích'**
  String get bloomAnalyze;

  /// Eyebrow S4 — bloom `evaluate` (docs/05 không liệt kê; M3, DECISIONS.md §3).
  ///
  /// In vi, this message translates to:
  /// **'Đánh giá'**
  String get bloomEvaluate;

  /// Nhãn câu multi (docs/05 S4).
  ///
  /// In vi, this message translates to:
  /// **'Chọn tất cả ý đúng'**
  String get quizSelectAll;

  /// Nhãn trên phương án đã chọn sai và trong QuestionRecap (docs/05 S4, S6).
  ///
  /// In vi, this message translates to:
  /// **'Bạn chọn'**
  String get quizYouChose;

  /// ExplanationPanel (docs/05 S4).
  ///
  /// In vi, this message translates to:
  /// **'Vì sao {option} không đúng'**
  String quizWhyNot(String option);

  /// ExplanationPanel (docs/05 S4: Xem giải thích khác ▾).
  ///
  /// In vi, this message translates to:
  /// **'Xem giải thích khác'**
  String get quizOtherExplanations;

  /// ExplanationPanel câu scenario (docs/05 S4).
  ///
  /// In vi, this message translates to:
  /// **'Khi nào phương án {option} lại đúng'**
  String quizWhenRight(String option);

  /// Nhãn hàng câu truefalse theo polarity (docs/05 S4).
  ///
  /// In vi, this message translates to:
  /// **'Đúng, vì…'**
  String get quizTrueBecause;

  /// Nhãn hàng câu truefalse theo polarity (docs/05 S4).
  ///
  /// In vi, this message translates to:
  /// **'Sai, vì…'**
  String get quizFalseBecause;

  /// Cột thứ tự của người học khi câu order sai (docs/05 S4: cột "Đúng" cạnh cột "Bạn xếp").
  ///
  /// In vi, this message translates to:
  /// **'Bạn xếp'**
  String get quizOrderYours;

  /// Nút ▲ câu order (M3, DECISIONS.md §3).
  ///
  /// In vi, this message translates to:
  /// **'Lên'**
  String get quizMoveUp;

  /// Nút ▼ câu order (M3, DECISIONS.md §3).
  ///
  /// In vi, this message translates to:
  /// **'Xuống'**
  String get quizMoveDown;

  /// Câu fill khi sai (docs/05 S4: hiện các đáp án chấp nhận; M3, DECISIONS.md §3).
  ///
  /// In vi, this message translates to:
  /// **'Đáp án chấp nhận: {answers}'**
  String quizAccepted(String answers);

  /// Tiêu đề ContextCard câu scenario (M3, DECISIONS.md §3).
  ///
  /// In vi, this message translates to:
  /// **'Tình huống'**
  String get quizContext;

  /// Semantics label QuizOption (docs/05 §8).
  ///
  /// In vi, this message translates to:
  /// **'Phương án {letter}, {text}'**
  String quizOptionSemantics(String letter, String text);

  /// /learn/:id/quiz khi bài không có quiz (M3, DECISIONS.md §3).
  ///
  /// In vi, this message translates to:
  /// **'Bài này chưa có quiz.'**
  String get quizNone;

  /// S6 (docs/05 S6).
  ///
  /// In vi, this message translates to:
  /// **'Câu sai'**
  String get resultWrongHeading;

  /// S6 (docs/05 S6); dạng số nhiều thêm ở M3.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, =1{Câu này sẽ xuất hiện trong Ôn tập vào ngày mai.} other{Những câu này sẽ xuất hiện trong Ôn tập vào ngày mai.}}'**
  String resultReviewTomorrow(int count);

  /// S6 khi 100% (docs/05 S6).
  ///
  /// In vi, this message translates to:
  /// **'Không có câu sai.'**
  String get resultNoWrong;

  /// QuestionRecap (docs/05 S6: câu, bạn chọn, đáp án).
  ///
  /// In vi, this message translates to:
  /// **'Đáp án'**
  String get resultAnswer;

  /// S6 (docs/05 S6).
  ///
  /// In vi, this message translates to:
  /// **'Kỹ năng'**
  String get resultSkills;

  /// SkillDelta (docs/05 S6: mũi tên/“mới”).
  ///
  /// In vi, this message translates to:
  /// **'mới'**
  String get resultSkillNew;

  /// Semantics của mũi tên ▲ ở SkillDelta (M3, DECISIONS.md §3).
  ///
  /// In vi, this message translates to:
  /// **'tiến bộ'**
  String get resultSkillUp;

  /// S6 nút chính khi chưa qua (docs/05 S6).
  ///
  /// In vi, this message translates to:
  /// **'Đọc lại bài'**
  String get resultRereadLesson;

  /// S6 (docs/05 S6).
  ///
  /// In vi, this message translates to:
  /// **'Về Học tiếp'**
  String get resultBackHome;

  /// /learn/:id/result/:attemptId với attempt không có (M3, DECISIONS.md §3).
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy lần làm quiz này.'**
  String get resultNotFound;

  /// S2 SegmentedButton (docs/05 S2: [Giai đoạn|Theo track]).
  ///
  /// In vi, this message translates to:
  /// **'Giai đoạn'**
  String get pathByStage;

  /// S2 SegmentedButton, route /path/tracks (docs/05 §3.2, S2).
  ///
  /// In vi, this message translates to:
  /// **'Theo track'**
  String get pathByTrack;

  /// Tiến độ StageHeader/ModuleTile (docs/05 S2: 34/57). M4, DECISIONS.md §3.
  ///
  /// In vi, this message translates to:
  /// **'{done}/{total}'**
  String pathCount(int done, int total);

  /// StageHeader (docs/05 S2 wireframe).
  ///
  /// In vi, this message translates to:
  /// **'Cổng: chưa thi'**
  String get pathGateNotTaken;

  /// StageHeader, gate_passed_at có giá trị (M4, DECISIONS.md §3).
  ///
  /// In vi, this message translates to:
  /// **'Cổng: đã qua'**
  String get pathGatePassed;

  /// StageHeader, đã thi chưa đạt; theo copy cổng chưa đạt của docs/05 §7 (M4, DECISIONS.md §3).
  ///
  /// In vi, this message translates to:
  /// **'Cổng: {score}% — cần {threshold}%'**
  String pathGateFailed(int score, int threshold);

  /// ModuleTile khi mọi bài đã read (docs/05 S2).
  ///
  /// In vi, this message translates to:
  /// **'Quiz module'**
  String get pathModuleQuiz;

  /// Semantics của dấu ✓ ở ModuleTile (M4, DECISIONS.md §3).
  ///
  /// In vi, this message translates to:
  /// **'Hoàn thành'**
  String get pathModuleDone;

  /// Cấp 2 của Theo track (docs/05 S2: L1–L4).
  ///
  /// In vi, this message translates to:
  /// **'L{level} · {title}'**
  String pathLevel(int level, String title);

  /// Nhãn GĐ nhỏ trên mỗi bài ở Theo track (docs/05 S2).
  ///
  /// In vi, this message translates to:
  /// **'GĐ{stage}'**
  String pathStageTag(int stage);

  /// Semantics/tooltip mỗi điểm của StageBar (M4, DECISIONS.md §3).
  ///
  /// In vi, this message translates to:
  /// **'Giai đoạn {stage}'**
  String stageLabel(int stage);

  /// S6 sau khi qua quiz prereq mở từ S5 (docs/05 S5: "Quay lại: <bài đang định đọc>").
  ///
  /// In vi, this message translates to:
  /// **'Quay lại: {title}'**
  String prereqReturn(String title);

  /// S7 tab (docs/05 S7 [Hôm nay|Từ vựng]).
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get reviewTabToday;

  /// S7 tab.
  ///
  /// In vi, this message translates to:
  /// **'Từ vựng'**
  String get reviewTabVocab;

  /// S7.
  ///
  /// In vi, this message translates to:
  /// **'Đến hạn hôm nay'**
  String get reviewDueToday;

  /// S7 / S1 số câu đến hạn.
  ///
  /// In vi, this message translates to:
  /// **'{count} câu'**
  String reviewCount(int count);

  /// S7 dưới số câu (5 bài · ~4 phút).
  ///
  /// In vi, this message translates to:
  /// **'{lessons} bài · ~{minutes} phút'**
  String reviewDueMeta(int lessons, int minutes);

  /// S7 nút chính.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu ôn'**
  String get reviewStart;

  /// S7 khi đến hạn > số câu tối đa mỗi phiên.
  ///
  /// In vi, this message translates to:
  /// **'Còn {count} câu, ôn tiếp sau'**
  String reviewRemaining(int count);

  /// S7.
  ///
  /// In vi, this message translates to:
  /// **'Sắp tới'**
  String get reviewUpcoming;

  /// S7 Sắp tới.
  ///
  /// In vi, this message translates to:
  /// **'Ngày mai'**
  String get reviewTomorrow;

  /// S7 Sắp tới: thứ (DateTime.weekday).
  ///
  /// In vi, this message translates to:
  /// **'{day, select, 1{T2} 2{T3} 3{T4} 4{T5} 5{T6} 6{T7} 7{CN} other{}}'**
  String reviewWeekday(String day);

  /// S7 Sắp tới: "T4 9".
  ///
  /// In vi, this message translates to:
  /// **'{day} {count}'**
  String reviewUpcomingItem(String day, int count);

  /// S7.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử'**
  String get reviewHistory;

  /// S7 Lịch sử.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get reviewHistoryToday;

  /// S7 Lịch sử.
  ///
  /// In vi, this message translates to:
  /// **'Hôm qua'**
  String get reviewHistoryYesterday;

  /// S7 Lịch sử.
  ///
  /// In vi, this message translates to:
  /// **'{score}/{total}'**
  String reviewHistoryScore(int score, int total);

  /// S7 Lịch sử: dòng của một phiên ôn.
  ///
  /// In vi, this message translates to:
  /// **'Phiên ôn'**
  String get reviewHistorySession;

  /// S1 ReviewDueRow.
  ///
  /// In vi, this message translates to:
  /// **'Ôn hôm nay'**
  String get reviewHomeTitle;

  /// S1 ReviewDueRow nút phụ.
  ///
  /// In vi, this message translates to:
  /// **'Ôn {minutes} phút'**
  String reviewHomeStart(int minutes);

  /// S4 chế độ review, trả lời sai.
  ///
  /// In vi, this message translates to:
  /// **'Về bậc 0 · gặp lại ngày mai'**
  String get reviewTierReset;

  /// S4 review, lên bậc 4 (retired).
  ///
  /// In vi, this message translates to:
  /// **'Bậc {from} → {to} · đã nhớ, không gặp lại'**
  String reviewTierRetired(int from, int to);

  /// S4 review eyebrow (ÔN · HTTP · Cấu trúc một request…); in hoa khi hiển thị.
  ///
  /// In vi, this message translates to:
  /// **'Ôn · {module} · {lesson}'**
  String reviewEyebrow(String module, String lesson);

  /// Tổng kết phiên ôn (docs/05 §3.3).
  ///
  /// In vi, this message translates to:
  /// **'{score}/{total} · {down} câu về bậc 0'**
  String reviewSummary(int score, int total, int down);

  /// Flashcard thuật ngữ trong phiên ôn (docs/07 §5.3).
  ///
  /// In vi, this message translates to:
  /// **'{term} nghĩa là gì?'**
  String reviewTermQuestion(String term);

  /// Giải thích phương án sai của flashcard thuật ngữ.
  ///
  /// In vi, this message translates to:
  /// **'Đây là nghĩa của {term}.'**
  String reviewTermOther(String term);

  /// TermTooltip (docs/05 S3).
  ///
  /// In vi, this message translates to:
  /// **'Thêm vào ôn'**
  String get termAddReview;

  /// TermTooltip sau khi thêm.
  ///
  /// In vi, this message translates to:
  /// **'Đã thêm vào ôn'**
  String get termAdded;

  /// TermTooltip khi term đang trong ôn.
  ///
  /// In vi, this message translates to:
  /// **'Đã có trong ôn tập'**
  String get termInReview;

  /// Từ vựng: ô tìm nhanh.
  ///
  /// In vi, this message translates to:
  /// **'Tìm từ'**
  String get vocabSearchHint;

  /// Từ vựng rỗng.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có từ nào. Thuật ngữ của bài bạn đã đọc sẽ hiện ở đây.'**
  String get vocabEmpty;

  /// Từ vựng: lọc không ra.
  ///
  /// In vi, this message translates to:
  /// **'Không thấy \"{query}\".'**
  String vocabNoMatch(String query);

  /// S9 ô tìm.
  ///
  /// In vi, this message translates to:
  /// **'Tìm trong bài'**
  String get searchHint;

  /// S9 khi FTS chưa xây xong (docs/07 §8).
  ///
  /// In vi, this message translates to:
  /// **'Đang lập chỉ mục…'**
  String get searchIndexing;

  /// Nút hủy hộp thoại (M6).
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get actionCancel;

  /// S10 nhóm Đọc (docs/05 S10).
  ///
  /// In vi, this message translates to:
  /// **'Đọc'**
  String get settingsReading;

  /// S10 nhóm Đọc.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ nội dung'**
  String get settingsContentLang;

  /// S10 nhóm Đọc: theme (M6, DECISIONS.md §3).
  ///
  /// In vi, this message translates to:
  /// **'Giao diện'**
  String get settingsTheme;

  /// S10 theme (docs/05 S10).
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống'**
  String get settingsThemeSystem;

  /// S10 theme (docs/05 S10).
  ///
  /// In vi, this message translates to:
  /// **'Sáng'**
  String get settingsThemeLight;

  /// S10 theme (docs/05 S10).
  ///
  /// In vi, this message translates to:
  /// **'Tối'**
  String get settingsThemeDark;

  /// S10 nhóm Ôn tập (docs/05 S10).
  ///
  /// In vi, this message translates to:
  /// **'Số câu tối đa mỗi phiên'**
  String get settingsReviewMax;

  /// S10 nhóm Nội dung (docs/05 S10).
  ///
  /// In vi, this message translates to:
  /// **'Nội dung'**
  String get settingsContent;

  /// S10 phiên bản nội dung đang dùng (docs/05 S10: v37 · 06/09/2026).
  ///
  /// In vi, this message translates to:
  /// **'v{version} · {date}'**
  String settingsContentVersion(int version, String date);

  /// S10: nguồn nội dung là asset (M6, DECISIONS.md §3).
  ///
  /// In vi, this message translates to:
  /// **'Bản đóng gói'**
  String get settingsContentBundled;

  /// S10: nguồn nội dung là bản tải về (M6, DECISIONS.md §3).
  ///
  /// In vi, this message translates to:
  /// **'Bản đã tải'**
  String get settingsContentDownloaded;

  /// S10 (docs/05 S10).
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra bản mới'**
  String get contentCheck;

  /// S10 khi đang tải manifest (M6, DECISIONS.md §3).
  ///
  /// In vi, this message translates to:
  /// **'Đang kiểm tra…'**
  String get contentChecking;

  /// S10 sau khi kiểm tra (M6, DECISIONS.md §3).
  ///
  /// In vi, this message translates to:
  /// **'Bạn đang dùng bản mới nhất.'**
  String get contentUpToDate;

  /// S10 khi tải manifest lỗi (M6, DECISIONS.md §3).
  ///
  /// In vi, this message translates to:
  /// **'Không kiểm tra được bản mới. Cần kết nối mạng.'**
  String get contentCheckFailed;

  /// S10 diff (docs/05 S10: +12 bài, 3 bài cập nhật).
  ///
  /// In vi, this message translates to:
  /// **'+{added} bài, {changed} bài cập nhật'**
  String contentDiff(int added, int changed);

  /// S10 khi đang tải/áp dụng bản mới (M6, DECISIONS.md §3).
  ///
  /// In vi, this message translates to:
  /// **'Đang cập nhật…'**
  String get contentUpdating;

  /// S10 (docs/05 S10, §10).
  ///
  /// In vi, this message translates to:
  /// **'Dùng bản đóng gói'**
  String get contentUseBundled;

  /// S10 nhóm Tiến độ (docs/05 S10).
  ///
  /// In vi, this message translates to:
  /// **'Tiến độ'**
  String get settingsProgress;

  /// S10 (docs/05 S10).
  ///
  /// In vi, this message translates to:
  /// **'Xuất JSON'**
  String get progressExport;

  /// S10 (docs/05 S10).
  ///
  /// In vi, this message translates to:
  /// **'Nhập JSON'**
  String get progressImport;

  /// Nút xác nhận nhập tiến độ (M6, DECISIONS.md §3).
  ///
  /// In vi, this message translates to:
  /// **'Ghi đè'**
  String get progressImportAction;

  /// S10 sau khi nhập (M6, DECISIONS.md §3).
  ///
  /// In vi, this message translates to:
  /// **'Đã nhập tiến độ.'**
  String get progressImported;

  /// S10 nhập lỗi (M6, DECISIONS.md §3).
  ///
  /// In vi, this message translates to:
  /// **'File này không phải bản xuất tiến độ hợp lệ. Tiến độ hiện tại giữ nguyên.'**
  String get progressImportFailed;

  /// S10 (docs/05 S10: đặt lại, hai bước).
  ///
  /// In vi, this message translates to:
  /// **'Đặt lại tiến độ'**
  String get progressReset;

  /// Đặt lại bước 1 (M6, DECISIONS.md §3).
  ///
  /// In vi, this message translates to:
  /// **'Xóa mọi tiến độ, ôn tập và lịch sử quiz trên máy này?'**
  String get progressResetConfirm;

  /// Đặt lại bước 2 (M6, DECISIONS.md §3).
  ///
  /// In vi, this message translates to:
  /// **'Chắc chắn đặt lại? Không hoàn tác được.'**
  String get progressResetConfirm2;

  /// Nút xác nhận đặt lại.
  ///
  /// In vi, this message translates to:
  /// **'Đặt lại'**
  String get progressResetAction;

  /// Sau khi đặt lại (M6, DECISIONS.md §3).
  ///
  /// In vi, this message translates to:
  /// **'Đã đặt lại tiến độ.'**
  String get progressResetDone;

  /// S10 nhóm Về (docs/05 S10).
  ///
  /// In vi, this message translates to:
  /// **'Về'**
  String get settingsAbout;

  /// S10 nhóm Về.
  ///
  /// In vi, this message translates to:
  /// **'Phiên bản app'**
  String get settingsAppVersion;

  /// S10 nhóm Về.
  ///
  /// In vi, this message translates to:
  /// **'Giấy phép'**
  String get settingsLicenses;

  /// S1 khi có quiz dở (docs/05 §10).
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục quiz: {title} ({answered}/{total})'**
  String homeResumeQuiz(String title, int answered, int total);

  /// GateReadyCard đã thi chưa đạt (docs/05 S1).
  ///
  /// In vi, this message translates to:
  /// **'Thi lại'**
  String get homeRetakeGate;

  /// S8 tiêu đề (M6, DECISIONS.md §3).
  ///
  /// In vi, this message translates to:
  /// **'Bài cổng Giai đoạn {stage}'**
  String gateTitle(int stage);

  /// S8 số câu và thời gian (docs/05 S8).
  ///
  /// In vi, this message translates to:
  /// **'{count} câu · ~{minutes} phút'**
  String gateIntroSize(int count, int minutes);

  /// S8 điều kiện đạt (docs/05 §3.3).
  ///
  /// In vi, this message translates to:
  /// **'Đạt khi đúng ≥ {threshold}% · làm lại không giới hạn'**
  String gatePassRule(int threshold);

  /// S8 (docs/05 S8).
  ///
  /// In vi, this message translates to:
  /// **'Không có giải thích trong lúc thi, có thể tạm dừng.'**
  String get gateNoExplanations;

  /// S8 cảnh báo mềm (docs/05 S8).
  ///
  /// In vi, this message translates to:
  /// **'Bạn còn {count} bài chưa qua trong giai đoạn này'**
  String gateRemaining(int count);

  /// S8 (docs/05 S8).
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu'**
  String get gateStart;

  /// S8 khi có lần thi tạm dừng < 24 giờ (M6, DECISIONS.md §3).
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục ({answered}/{total})'**
  String gateResume(int answered, int total);

  /// S8 lịch sử (docs/05 S8).
  ///
  /// In vi, this message translates to:
  /// **'Các lần thi'**
  String get gateHistory;

  /// S8 một lần thi.
  ///
  /// In vi, this message translates to:
  /// **'{date} · {score}/{total}'**
  String gateHistoryRow(String date, int score, int total);

  /// /gate/:stage khi content.json không có gate (M6, DECISIONS.md §3).
  ///
  /// In vi, this message translates to:
  /// **'Giai đoạn này chưa có bài cổng.'**
  String get gateNone;

  /// S4 chế độ gate khi thoát (docs/05 S4).
  ///
  /// In vi, this message translates to:
  /// **'Tạm dừng — bạn có thể quay lại trong 24 giờ'**
  String get gatePauseConfirm;

  /// Nút hộp thoại tạm dừng (M6, DECISIONS.md §3).
  ///
  /// In vi, this message translates to:
  /// **'Tạm dừng'**
  String get gatePause;

  /// S4 gate (docs/05 S4).
  ///
  /// In vi, this message translates to:
  /// **'Đánh dấu xem lại'**
  String get gateFlag;

  /// S4 gate, câu đã đánh dấu (M6, DECISIONS.md §3).
  ///
  /// In vi, this message translates to:
  /// **'Đã đánh dấu'**
  String get gateFlagged;

  /// S4 gate ◀ (M6, DECISIONS.md §3).
  ///
  /// In vi, this message translates to:
  /// **'Câu trước'**
  String get gatePrevious;

  /// S4 gate câu cuối (M6, DECISIONS.md §3).
  ///
  /// In vi, this message translates to:
  /// **'Nộp bài'**
  String get gateSubmit;

  /// Hộp thoại nộp bài cổng (M6, DECISIONS.md §3).
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, =0{Nộp bài và xem kết quả?} other{Còn {count} câu chưa trả lời. Vẫn nộp bài?}}'**
  String gateSubmitConfirm(int count);

  /// Kết quả cổng chưa đạt (theo docs/05 §7).
  ///
  /// In vi, this message translates to:
  /// **'{score}/{total} · Chưa qua (cần ≥ {threshold}%)'**
  String gateResultNotPassed(int score, int total, int threshold);

  /// Kết quả cổng: bảng theo track (docs/05 S6).
  ///
  /// In vi, this message translates to:
  /// **'Theo track'**
  String get gateByTrack;

  /// Dòng câu scenario xuyên track (M6, DECISIONS.md §3).
  ///
  /// In vi, this message translates to:
  /// **'Xuyên track'**
  String get gateCrossTrack;

  /// Kết quả cổng (docs/05 S6).
  ///
  /// In vi, this message translates to:
  /// **'Nên đọc lại'**
  String get gateReread;

  /// Kết quả cổng đạt (docs/05 S6).
  ///
  /// In vi, this message translates to:
  /// **'Sang Giai đoạn {stage}'**
  String gateNextStage(int stage);

  /// Kết quả module: bảng theo bài (docs/05 S6).
  ///
  /// In vi, this message translates to:
  /// **'Theo bài'**
  String get moduleResultByLesson;

  /// ModuleTile khi quiz module ≥ 70% (docs/07 §5.5).
  ///
  /// In vi, this message translates to:
  /// **'Module ✓'**
  String get pathModulePassed;

  /// /module/.../quiz khi không bài nào có quiz (M6, DECISIONS.md §3).
  ///
  /// In vi, this message translates to:
  /// **'Module này chưa có câu hỏi quiz.'**
  String get moduleQuizNone;

  /// S2 StageHeader, lối vào S8 (M6, DECISIONS.md §3).
  ///
  /// In vi, this message translates to:
  /// **'Vào bài cổng'**
  String get pathEnterGate;
}

class _LDelegate extends LocalizationsDelegate<L> {
  const _LDelegate();

  @override
  Future<L> load(Locale locale) {
    return SynchronousFuture<L>(lookupL(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_LDelegate old) => false;
}

L lookupL(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return LEn();
    case 'vi':
      return LVi();
  }

  throw FlutterError(
    'L.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
