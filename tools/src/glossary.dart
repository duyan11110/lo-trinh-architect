/// Glossary loading and the A.2 term-matching algorithm.
library glossary;

import 'markdown_util.dart';

class GlossaryEntry {
  final String term;
  final String en;
  final bool viKeep;
  final String vi;
  final String shortVi;
  final String shortEn;
  final String introducedIn;
  final List<String> aliases;

  GlossaryEntry({
    required this.term,
    required this.en,
    required this.viKeep,
    required this.vi,
    required this.shortVi,
    required this.shortEn,
    required this.introducedIn,
    required this.aliases,
  });

  factory GlossaryEntry.fromMap(Map<String, dynamic> m) => GlossaryEntry(
        term: m['term'] as String,
        en: m['en'] as String,
        viKeep: m['vi_keep'] as bool? ?? false,
        vi: m['vi'] as String? ?? '',
        shortVi: m['short_vi'] as String? ?? '',
        shortEn: m['short_en'] as String? ?? '',
        introducedIn: m['introduced_in'] as String? ?? '',
        aliases: (m['aliases'] as List?)?.map((e) => e.toString()).toList() ?? [],
      );

  List<String> get forms {
    final set = <String>{};
    if (en.isNotEmpty) set.add(en);
    if (vi.isNotEmpty) set.add(vi);
    set.addAll(aliases);
    final plural = simplePlural(en);
    if (plural != en) set.add(plural);
    return set.where((f) => f.trim().isNotEmpty).toList();
  }
}

String simplePlural(String word) {
  if (word.isEmpty) return word;
  // Only pluralize simple single/compound English words made of letters.
  if (!RegExp(r'^[A-Za-z][A-Za-z \-]*$').hasMatch(word)) return word;
  final parts = word.split(' ');
  final last = parts.removeLast();
  final lower = last.toLowerCase();
  String pluralLast;
  if (lower.length > 1 &&
      lower.endsWith('y') &&
      !'aeiou'.contains(lower[lower.length - 2])) {
    pluralLast = '${last.substring(0, last.length - 1)}ies';
  } else if (lower.endsWith('s') ||
      lower.endsWith('x') ||
      lower.endsWith('z') ||
      lower.endsWith('ch') ||
      lower.endsWith('sh')) {
    pluralLast = '${last}es';
  } else {
    pluralLast = '${last}s';
  }
  parts.add(pluralLast);
  return parts.join(' ');
}

bool _isAllCapsWord(String s) {
  if (s.length < 3) return false;
  final hasLetter = RegExp(r'[A-Za-z]').hasMatch(s);
  if (!hasLetter) return false;
  return s == s.toUpperCase() && s != s.toLowerCase();
}

class TermMatch {
  final String term;
  final int start;
  final int end;
  final String matchedText;
  TermMatch(this.term, this.start, this.end, this.matchedText);
}

String _escapeRegex(String s) => s.replaceAllMapped(
    RegExp(r'[.*+?^${}()|[\]\\]'), (m) => '\\${m.group(0)}');

/// A.2 — find every occurrence of a glossary term in [prose] (already run
/// through [stripForTermMatch] by the caller, or raw — this function strips
/// code/inline-code/[[id]] itself for safety).
List<TermMatch> findTermOccurrences(String rawText, List<GlossaryEntry> glossary) {
  final text = stripForTermMatch(rawText);
  final candidates = <MapEntry<String, String>>[]; // form -> term
  for (final entry in glossary) {
    for (final form in entry.forms) {
      candidates.add(MapEntry(form, entry.term));
    }
  }
  candidates.sort((a, b) => b.key.length.compareTo(a.key.length));

  final consumed = List<bool>.filled(text.length, false);
  final results = <TermMatch>[];
  for (final c in candidates) {
    final form = c.key;
    if (form.trim().isEmpty) continue;
    final pattern = RegExp(
      r'(?<![\p{L}\p{N}])' + _escapeRegex(form) + r'(?![\p{L}\p{N}])',
      unicode: true,
      caseSensitive: false,
    );
    for (final m in pattern.allMatches(text)) {
      bool overlap = false;
      for (int i = m.start; i < m.end; i++) {
        if (consumed[i]) {
          overlap = true;
          break;
        }
      }
      if (overlap) continue;
      final matchedText = text.substring(m.start, m.end);
      final entryEn = glossary.firstWhere((e) => e.term == c.value).en;
      if (_isAllCapsWord(matchedText) && !_isAllCapsWord(entryEn)) {
        continue;
      }
      for (int i = m.start; i < m.end; i++) {
        consumed[i] = true;
      }
      results.add(TermMatch(c.value, m.start, m.end, matchedText));
    }
  }
  results.sort((a, b) => a.start.compareTo(b.start));
  return results;
}
