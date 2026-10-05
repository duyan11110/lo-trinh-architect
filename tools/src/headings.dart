/// docs/01-mo-hinh-noi-dung.md §4 — canonical H2 heading tables (L02, L03, L09).
library headings;

import 'markdown_util.dart';

const List<String> kSectionNamesL13En = [
  'Before you start',
  'The situation',
  'Core concepts',
  'How it works',
  'In the Đơn Hàng system',
  '__MISCONCEPTIONS__',
  'Try it (3 minutes)',
  'Connections',
  'Five-line summary',
];

const List<String> kSectionNamesL13Vi = [
  'Bạn cần biết trước',
  'Tình huống',
  'Khái niệm cốt lõi',
  'Cơ chế hoạt động',
  'Trong hệ thống Đơn Hàng',
  '__MISCONCEPTIONS__',
  'Thử ngay (3 phút)',
  'Liên hệ',
  'Tóm tắt 5 dòng',
];

const List<String> kSectionNamesL4En = [
  'Before you start',
  'The situation',
  'Core concepts',
  'How it works',
  'In the Đơn Hàng system',
  'Trade-offs',
  'What would you choose if…',
  '__MISCONCEPTIONS__',
  'Try it (3 minutes)',
  'Connections',
  'Five-line summary',
];

const List<String> kSectionNamesL4Vi = [
  'Bạn cần biết trước',
  'Tình huống',
  'Khái niệm cốt lõi',
  'Cơ chế hoạt động',
  'Trong hệ thống Đơn Hàng',
  'Đánh đổi',
  'Bạn sẽ chọn gì nếu…',
  '__MISCONCEPTIONS__',
  'Thử ngay (3 phút)',
  'Liên hệ',
  'Tóm tắt 5 dòng',
];

String misconceptionHeading(String lang, int stage) {
  final beginners = stage <= 2;
  if (lang == 'vi') {
    return beginners ? 'Người mới hay nghĩ rằng…' : 'Senior hay nhầm rằng…';
  } else {
    return beginners ? 'Beginners often think…' : 'Seniors often assume…';
  }
}

/// Returns the canonical, ordered list of H2 headings expected for a lesson
/// with the given [lang] ('vi'|'en'), [level] (1-4) and [stage] (0-4).
List<String> expectedHeadings(String lang, int level, int stage) {
  final template = level == 4
      ? (lang == 'vi' ? kSectionNamesL4Vi : kSectionNamesL4En)
      : (lang == 'vi' ? kSectionNamesL13Vi : kSectionNamesL13En);
  final misc = misconceptionHeading(lang, stage);
  return template.map((h) => h == '__MISCONCEPTIONS__' ? misc : h).toList();
}

/// Index (1-based) of the misconceptions section for a given level.
int misconceptionsSectionIndex(int level) => level == 4 ? 8 : 6;

/// Index (1-based) of the "Connections"/"Liên hệ" section.
int connectionsSectionIndex(int level) => level == 4 ? 10 : 8;

/// Index of "Try it" section.
int tryItSectionIndex(int level) => level == 4 ? 9 : 7;

/// Index of "Five-line summary" section.
int summarySectionIndex(int level) => level == 4 ? 11 : 9;

/// Index of "Core concepts" section (vocab bolding).
int coreConceptsSectionIndex(int level) => 3;

/// Index of "How it works" section.
int howItWorksSectionIndex(int level) => 4;

/// Index of "In the Đơn Hàng system" section (code blocks).
int inSystemSectionIndex(int level) => 5;

/// Index of "The situation" section.
int situationSectionIndex(int level) => 2;

/// Index of "Before you start" section.
int beforeYouStartSectionIndex(int level) => 1;

bool headingsMatch(String actual, String expected) =>
    normalizeHeading(actual) == normalizeHeading(expected);
