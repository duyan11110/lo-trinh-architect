// Lazy decoding of content.json — docs/07 §8 ("sections chỉ parse … khi mở
// bài"). The two heavy fields of every lesson, `sections` and `diagram_svg`
// (over half of the document), stay as their UTF-8 bytes until a lesson
// opens; everything else is decoded eagerly as before. The contract
// (docs/04, schemas/content.schema.json) is unchanged: this is only how the
// app reads it.
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'i18n.dart';

final Converter<List<int>, Object?> _utf8Json = const Utf8Decoder().fuse(
  const JsonDecoder(),
);

/// One JSON value kept as a copy of its UTF-8 bytes.
@immutable
class JsonSlice {
  const JsonSlice(this.bytes);

  final Uint8List bytes;

  /// Throws [FormatException] when the bytes are not valid JSON.
  Object? decode() => _utf8Json.convert(bytes);
}

/// Lesson fields decoded on use instead of at load.
const lazyLessonKeys = {'sections', 'diagram_svg'};

/// Decodes the content.json document in [b] like `jsonDecode`, except that
/// [lazyLessonKeys] of each `lessons{}` entry become [JsonSlice]s.
JsonMap decodeContentLazily(Uint8List b) {
  final s = _Scanner(b);
  final root = <String, Object?>{};
  s.object((key) {
    if (key == 'lessons' && s.peekIs(_lbrace)) {
      final lessons = <String, Object?>{};
      s.object((id) {
        if (!s.peekIs(_lbrace)) {
          lessons[id] = s.value();
          return;
        }
        final lesson = <String, Object?>{};
        s.object((k) {
          lesson[k] = lazyLessonKeys.contains(k) ? s.slice() : s.value();
        });
        lessons[id] = lesson;
      });
      root[key] = lessons;
    } else {
      root[key] = s.value();
    }
  });
  s.end();
  return root;
}

const _quote = 0x22, _backslash = 0x5C, _comma = 0x2C, _colon = 0x3A;
const _lbrace = 0x7B, _rbrace = 0x7D, _lbracket = 0x5B, _rbracket = 0x5D;

class _Scanner {
  _Scanner(this.b);

  final Uint8List b;
  int i = 0;

  Never _fail(String what) =>
      throw FormatException('content.json: $what at byte $i');

  void _ws() {
    while (i < b.length) {
      final c = b[i];
      if (c != 0x20 && c != 0x0A && c != 0x0D && c != 0x09) return;
      i++;
    }
  }

  bool peekIs(int c) {
    _ws();
    return i < b.length && b[i] == c;
  }

  void _expect(int c) {
    if (!peekIs(c)) _fail('expected "${String.fromCharCode(c)}"');
    i++;
  }

  /// Calls [member] once per key with [i] at the value, which [member] must
  /// consume.
  void object(void Function(String key) member) {
    _expect(_lbrace);
    if (peekIs(_rbrace)) {
      i++;
      return;
    }
    while (true) {
      _ws();
      final start = i;
      final end = _skipString();
      final key = _utf8Json.convert(Uint8List.sublistView(b, start, end));
      if (key is! String) _fail('expected a key');
      _expect(_colon);
      member(key);
      if (peekIs(_comma)) {
        i++;
        continue;
      }
      _expect(_rbrace);
      return;
    }
  }

  /// The next value, decoded.
  Object? value() {
    _ws();
    final start = i;
    _skipValue();
    return _utf8Json.convert(Uint8List.sublistView(b, start, i));
  }

  /// The next value, as a copy of its bytes (checked only for balance).
  JsonSlice slice() {
    _ws();
    final start = i;
    _skipValue();
    return JsonSlice(Uint8List.fromList(Uint8List.sublistView(b, start, i)));
  }

  void end() {
    _ws();
    if (i != b.length) _fail('trailing data');
  }

  /// Leaves [i] after the string starting at [i]; returns that index.
  int _skipString() {
    if (i >= b.length || b[i] != _quote) _fail('expected a string');
    i++;
    while (i < b.length) {
      final c = b[i];
      if (c == _backslash) {
        i += 2;
      } else if (c == _quote) {
        return ++i;
      } else {
        i++;
      }
    }
    _fail('unterminated string');
  }

  void _skipValue() {
    if (i >= b.length) _fail('unexpected end');
    final c = b[i];
    if (c == _quote) {
      _skipString();
      return;
    }
    if (c == _lbrace || c == _lbracket) {
      var depth = 0;
      while (i < b.length) {
        final d = b[i];
        if (d == _quote) {
          _skipString();
          continue;
        }
        if (d == _lbrace || d == _lbracket) {
          depth++;
        } else if (d == _rbrace || d == _rbracket) {
          if (--depth == 0) {
            i++;
            return;
          }
        }
        i++;
      }
      _fail('unterminated value');
    }
    // Number, true, false, null: up to the next delimiter.
    while (i < b.length) {
      final d = b[i];
      if (d == _comma || d == _rbrace || d == _rbracket || d == 0x20 ||
          d == 0x0A || d == 0x0D || d == 0x09) {
        break;
      }
      i++;
    }
  }
}
