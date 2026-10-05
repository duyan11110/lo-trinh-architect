/// Repo-root discovery so every tool works regardless of the caller's cwd,
/// as long as it is invoked from somewhere inside the repo (the bash wrappers
/// always `cd` to the repo root before calling `dart run`, but we defend
/// against being invoked otherwise too).
library repo;

import 'dart:io';
import 'package:path/path.dart' as p;

class Repo {
  final String root;
  Repo(this.root);

  String path(String relative) => p.join(root, relative);

  static Repo find() {
    // 1. cwd
    var dir = Directory.current;
    if (File(p.join(dir.path, 'tools', 'SPEC.md')).existsSync()) {
      return Repo(dir.path);
    }
    // 2. walk up from cwd
    var cur = dir;
    for (int i = 0; i < 6; i++) {
      final parent = cur.parent;
      if (parent.path == cur.path) break;
      if (File(p.join(parent.path, 'tools', 'SPEC.md')).existsSync()) {
        return Repo(parent.path);
      }
      cur = parent;
    }
    // 3. derive from the running script's location (tools/bin/xxx.dart)
    final scriptPath = Platform.script.toFilePath();
    var d = p.dirname(scriptPath); // bin
    d = p.dirname(d); // tools
    d = p.dirname(d); // repo root
    if (File(p.join(d, 'tools', 'SPEC.md')).existsSync()) {
      return Repo(d);
    }
    // give up, use cwd
    return Repo(Directory.current.path);
  }
}
