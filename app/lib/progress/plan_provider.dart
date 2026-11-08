// Riverpod glue for docs/07 §5.2: content + progress → [LearningPlan].
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/content_repository.dart';
import 'learning_plan.dart';
import 'progress_repository.dart';

final learningPlanProvider = Provider<AsyncValue<LearningPlan>>((ref) {
  final content = ref.watch(contentProvider);
  final progress = ref.watch(lessonProgressProvider);
  final gates = ref.watch(passedGatesProvider);
  for (final AsyncValue<Object?> a in [content, progress, gates]) {
    if (a.hasError) return AsyncError(a.error!, a.stackTrace!);
  }
  if (!content.hasValue || !progress.hasValue || !gates.hasValue) {
    return const AsyncLoading();
  }
  return AsyncData(
    LearningPlan.compute(content.value!, progress.value!, gates.value!),
  );
});
