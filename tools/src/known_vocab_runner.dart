/// `tools/known-vocab` — see tools/SPEC.md.
library known_vocab_runner;

import 'dart:convert';

import 'content_tree.dart';
import 'repo.dart';

class GlossaryOut {
  final String term, en, vi, shortEn, shortVi;
  final bool viKeep;
  final List<String> aliases;
  GlossaryOut(this.term, this.en, this.vi, this.viKeep, this.shortEn, this.shortVi, this.aliases);

  Map<String, dynamic> toJson() => {
        'term': term,
        'en': en,
        'vi': vi,
        'vi_keep': viKeep,
        'short_en': shortEn,
        'short_vi': shortVi,
        'aliases': aliases,
      };
}

int runKnownVocab(List<String> argv) {
  String? beforeLesson;
  String? beforeModule;
  int i = 0;
  while (i < argv.length) {
    switch (argv[i]) {
      case '--before':
        beforeLesson = argv[++i];
        break;
      case '--before-module':
        beforeModule = argv[++i];
        break;
    }
    i++;
  }
  if (beforeLesson == null && beforeModule == null) {
    // ignore: avoid_print
    print('Usage: known-vocab --before <lesson-id> | --before-module <track>/<module>');
    return 1;
  }

  final repo = Repo.find();
  final tree = ContentTree.load(repo);

  int cutoffOrder;
  if (beforeLesson != null) {
    final lesson = tree.lesson(beforeLesson);
    if (lesson == null || lesson.globalOrder < 0) {
      // ignore: avoid_print
      print('[]');
      return 0;
    }
    cutoffOrder = lesson.globalOrder;
  } else {
    final module = tree.modulesByKey[beforeModule];
    if (module == null || module.lessons.isEmpty) {
      // ignore: avoid_print
      print('[]');
      return 0;
    }
    final orders = module.lessons.map((l) => l.globalOrder).where((o) => o >= 0);
    cutoffOrder = orders.isEmpty ? -1 : orders.reduce((a, b) => a < b ? a : b);
  }

  final knownTerms = <String>{};
  for (final l in tree.lessonsInGlobalOrder) {
    if (l.globalOrder >= 0 && l.globalOrder < cutoffOrder) {
      knownTerms.addAll(l.vocab);
    }
  }

  final result = <Map<String, dynamic>>[];
  for (final term in knownTerms) {
    final g = tree.glossaryTerm(term);
    if (g == null) continue;
    result.add(GlossaryOut(g.term, g.en, g.vi, g.viKeep, g.shortEn, g.shortVi, g.aliases).toJson());
  }
  // ignore: avoid_print
  print(const JsonEncoder.withIndent('  ').convert(result));
  return 0;
}
