// Glossary term matching — tools/SPEC.md Appendix A.2 (shared with validate
// L15). Runs on prose text nodes only: the Markdown layer never feeds it code
// blocks, inline code or `[[id]]` links.
import 'package:flutter/foundation.dart';

import 'models/models.dart';

@immutable
class TermMatch {
  const TermMatch(this.start, this.end, this.entry);

  final int start;
  final int end;
  final GlossaryEntry entry;

  @override
  bool operator ==(Object other) =>
      other is TermMatch &&
      other.start == start &&
      other.end == end &&
      other.entry.term == entry.term;

  @override
  int get hashCode => Object.hash(start, end, entry.term);

  @override
  String toString() => 'TermMatch($start-$end ${entry.term})';
}

class _Form {
  _Form(this.text, this.entry)
    : lower = text.toLowerCase(),
      tokens = GlossaryMatcher._tokens(text);

  final String text;
  final String lower;
  final List<String> tokens;
  final GlossaryEntry entry;
}

class GlossaryMatcher {
  /// [lang] is the language of the text being matched. For English text the
  /// `vi` form is dropped (A.2) so a short `vi` such as `Service` does not
  /// match ordinary English words.
  GlossaryMatcher(Iterable<GlossaryEntry> entries, {required this.lang}) {
    final seen = <String>{};
    for (final e in entries) {
      final english = [e.en, ...e.aliases];
      final forms = <String>{
        for (final f in english) ...[f, ..._plurals(f)],
        if (lang == ContentLang.vi) e.vi,
      };
      for (final f in forms) {
        final trimmed = f.trim();
        if (trimmed.isEmpty) continue;
        // First entry wins when two entries share a surface form.
        if (!seen.add(trimmed.toLowerCase())) continue;
        final form = _Form(trimmed, e);
        if (form.tokens.isEmpty || !_wordAt(trimmed, 0)) {
          _leading.add(form);
        } else {
          _byFirstToken
              .putIfAbsent(form.tokens.first.toLowerCase(), () => [])
              .add(form);
        }
      }
    }
    for (final list in _byFirstToken.values) {
      list.sort((a, b) => b.lower.length.compareTo(a.lower.length));
    }
    _leading.sort((a, b) => b.lower.length.compareTo(a.lower.length));
  }

  final ContentLang lang;
  final Map<String, List<_Form>> _byFirstToken = {};
  final List<_Form> _leading = [];

  static final _wordChar = RegExp(r'[\p{L}\p{N}\p{M}]', unicode: true);
  static final _tokenRe = RegExp(r'[\p{L}\p{N}\p{M}]+', unicode: true);
  static final _hasLetter = RegExp(r'\p{L}', unicode: true);

  static bool _wordAt(String s, int i) {
    if (i < 0 || i >= s.length) return false;
    final c = s.codeUnitAt(i);
    // Surrogate pairs: look at the full code point.
    if (c >= 0xD800 && c <= 0xDBFF && i + 1 < s.length) {
      return _wordChar.hasMatch(s.substring(i, i + 2));
    }
    if (c >= 0xDC00 && c <= 0xDFFF && i > 0) {
      return _wordChar.hasMatch(s.substring(i - 1, i + 1));
    }
    return _wordChar.hasMatch(String.fromCharCode(c));
  }

  static List<String> _tokens(String s) =>
      [for (final m in _tokenRe.allMatches(s)) m[0]!];

  /// Simple English plurals: +s, +es, y→ies (A.2).
  static List<String> _plurals(String f) {
    if (f.isEmpty || !_wordAt(f, f.length - 1)) return const [];
    final out = ['${f}s', '${f}es'];
    if (f.endsWith('y') && f.length > 1) {
      out.add('${f.substring(0, f.length - 1)}ies');
    }
    return out;
  }

  /// All-caps token of ≥ 3 letters (`COMMIT`, `GET`).
  static bool _isShouting(String token) =>
      token.length >= 3 &&
      _hasLetter.hasMatch(token) &&
      token == token.toUpperCase() &&
      token != token.toLowerCase();

  static bool _isCaps(String token) =>
      _hasLetter.hasMatch(token) &&
      token == token.toUpperCase() &&
      token != token.toLowerCase();

  /// Matches every glossary occurrence in [text], longest form first at each
  /// position, Unicode word boundaries on both sides, case-insensitive except
  /// that an all-caps token only matches an all-caps token of the form, and an
  /// acronym token of the form only matches itself, same case.
  List<TermMatch> match(String text) {
    final out = <TermMatch>[];
    var i = 0;
    while (i < text.length) {
      final startsWord = _wordAt(text, i) && !_wordAt(text, i - 1);
      _Form? hit;
      if (startsWord) {
        final tok = _tokenRe.matchAsPrefix(text, i)?[0];
        if (tok != null) {
          hit = _firstFit(_byFirstToken[tok.toLowerCase()], text, i);
        }
      }
      hit ??= _leading.isEmpty || _wordAt(text, i - 1) && _wordAt(text, i)
          ? null
          : _firstFit(_leading, text, i);
      if (hit != null) {
        out.add(TermMatch(i, i + hit.text.length, hit.entry));
        i += hit.text.length;
      } else if (startsWord) {
        i = _tokenRe.matchAsPrefix(text, i)!.end;
      } else {
        i++;
      }
    }
    return out;
  }

  /// The entry whose form equals the whole of [text] (bold terms, docs/07
  /// §3): parenthesised parts are removed first.
  GlossaryEntry? exact(String text) {
    final cleaned = text
        .replaceAll(RegExp(r'\([^)]*\)'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return null;
    final m = match(cleaned);
    if (m.length == 1 && m.first.start == 0 && m.first.end == cleaned.length) {
      return m.first.entry;
    }
    return null;
  }

  _Form? _firstFit(List<_Form>? forms, String text, int i) {
    if (forms == null) return null;
    for (final f in forms) {
      final end = i + f.text.length;
      if (end > text.length) continue;
      final span = text.substring(i, end);
      if (span.toLowerCase() != f.lower) continue;
      if (_wordAt(text, end) && _wordAt(text, end - 1)) continue;
      if (!_capsOk(span, f)) continue;
      return f;
    }
    return null;
  }

  bool _capsOk(String span, _Form f) {
    final src = _tokens(span);
    for (var k = 0; k < src.length; k++) {
      if (!_isShouting(src[k])) continue;
      if (k >= f.tokens.length || !_isCaps(f.tokens[k])) return false;
    }
    // An acronym token of the form matches only the same token, same case
    // ("cap" is not `CAP`, "join" is not `JOIN`).
    for (var k = 0; k < f.tokens.length; k++) {
      if (!_isAcronym(f.tokens[k])) continue;
      if (k >= src.length || src[k] != f.tokens[k]) return false;
    }
    return true;
  }

  /// At least two letters, all upper case apart from a plural `s`/`es`
  /// (`CAP`, `CA`, `APIs`).
  static bool _isAcronym(String token) {
    final core = token.replaceFirst(_pluralTail, '');
    final letters = core.replaceAll(_nonLetter, '');
    return letters.length >= 2 && _isCaps(core);
  }

  static final _pluralTail = RegExp(r'e?s$');
  static final _nonLetter = RegExp(r'[^\p{L}]', unicode: true);
}
