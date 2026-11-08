// A fake GitHub Pages `content/` directory (docs/07 §7) behind
// `package:http/testing.dart` MockClient — tests never touch the network.
// Web-safe (no dart:io): also used by integration_test/.
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// [json] (a content.json) with `meta.content_version` set to [version].
String withContentVersion(String json, int version) {
  final m = jsonDecode(json) as Map<String, Object?>;
  (m['meta']! as Map<String, Object?>)['content_version'] = version;
  return jsonEncode(m);
}

class FakeRemote {
  FakeRemote({
    required this.version,
    String? base,
    String? json,
    List<int>? archive,
    this.badChecksum = false,
    this.manifestStatus = 200,
    this.archiveStatus = 200,
    this.added = const ['a.l1.new'],
    this.changed = const [],
  }) : archive = archive ??
           const GZipEncoder().encodeBytes(
             utf8.encode(json ?? withContentVersion(base!, version)),
           );

  final int version;
  final List<int> archive;
  final bool badChecksum;
  final int manifestStatus;
  final int archiveStatus;
  final List<String> added;
  final List<String> changed;
  final requests = <Uri>[];

  String get manifest => jsonEncode({
    'content_version': version,
    'built_at': '2026-11-06T00:00:00Z',
    'sha256': badChecksum
        ? sha256.convert(utf8.encode('something else')).toString()
        : sha256.convert(archive).toString(),
    'bytes': archive.length,
    'lessons_added': added,
    'lessons_changed': changed,
  });

  http.Client client() => MockClient((req) async {
    requests.add(req.url);
    if (req.url.path.endsWith('/manifest.json')) {
      return http.Response(manifest, manifestStatus);
    }
    if (req.url.path.endsWith('/content.json.gz')) {
      return http.Response.bytes(archive, archiveStatus);
    }
    return http.Response('', 404);
  });
}

/// A client that fails every request like a lost connection.
http.Client offlineClient() =>
    MockClient((_) async => throw http.ClientException('offline'));
