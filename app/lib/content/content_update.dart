// Remote content update state for S10 Nội dung and the S1 "Có nội dung mới"
// line — docs/07 §7, docs/05 S1/S10/§10. Checking only reads the manifest;
// applying happens only from S10 (never mid-lesson), then the content is
// reloaded and the caller routes to Học tiếp.
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../progress/clock.dart';
import '../progress/progress_repository.dart';
import '../progress/settings_repository.dart';
import 'content_loader.dart';
import 'content_repository.dart';

/// HTTP client for §7 only. Tests override it with a fake (never network).
final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

/// Background checks run at most once per this interval (docs/07 §7).
const Duration contentCheckInterval = Duration(hours: 24);

enum ContentUpdatePhase {
  idle,
  checking,
  upToDate,
  available,
  checkFailed,
  updating,
  updateFailed,
}

@immutable
class ContentUpdateState {
  const ContentUpdateState(this.phase, {this.manifest});

  final ContentUpdatePhase phase;

  /// The newer manifest (available / updating / updateFailed).
  final ContentManifest? manifest;

  /// S1 line: a newer version is known.
  bool get hasNewer => manifest != null && phase != ContentUpdatePhase.upToDate;
}

class ContentUpdateNotifier extends Notifier<ContentUpdateState> {
  @override
  ContentUpdateState build() => const ContentUpdateState(ContentUpdatePhase.idle);

  Future<RemoteContent> _remote() async {
    final url = await ref
        .read(settingsRepositoryProvider)
        .get(SettingKeys.remoteBaseUrl);
    return RemoteContent(
      ref.read(httpClientProvider),
      url == null || url.isEmpty ? defaultRemoteBaseUrl : url,
    );
  }

  /// Downloads `manifest.json` and compares it with the content in use.
  Future<void> check() async {
    if (state.phase == ContentUpdatePhase.checking ||
        state.phase == ContentUpdatePhase.updating) {
      return;
    }
    state = const ContentUpdateState(ContentUpdatePhase.checking);
    try {
      final current = await ref.read(contentProvider.future);
      final manifest = await (await _remote()).manifest();
      await ref
          .read(settingsRepositoryProvider)
          .set(
            SettingKeys.contentCheckedAt,
            isoUtc(ref.read(clockProvider).now()),
          );
      state = manifest.contentVersion > current.meta.contentVersion
          ? ContentUpdateState(ContentUpdatePhase.available, manifest: manifest)
          : const ContentUpdateState(ContentUpdatePhase.upToDate);
    } catch (e) {
      debugPrint('content check failed: $e');
      state = const ContentUpdateState(ContentUpdatePhase.checkFailed);
    }
  }

  /// docs/07 §7 "mỗi 24 giờ khi có mạng (nền, không chặn)": checks when the
  /// last check is older than [contentCheckInterval]; failures stay silent.
  Future<void> checkInBackground() async {
    try {
      final last = DateTime.tryParse(
        await ref
                .read(settingsRepositoryProvider)
                .get(SettingKeys.contentCheckedAt) ??
            '',
      );
      final now = ref.read(clockProvider).now();
      if (last != null && now.difference(last) < contentCheckInterval) return;
    } catch (e) {
      debugPrint('content check skipped: $e');
      return;
    }
    await check();
    if (state.phase == ContentUpdatePhase.checkFailed) {
      state = const ContentUpdateState(ContentUpdatePhase.idle);
    }
  }

  /// Applies the available version. Returns whether the new content is now
  /// in use; on failure the old content stays and the state says so.
  Future<bool> update() async {
    final manifest = state.manifest;
    if (manifest == null || state.phase == ContentUpdatePhase.updating) {
      return false;
    }
    state = ContentUpdateState(ContentUpdatePhase.updating, manifest: manifest);
    try {
      await ContentUpdater(
        remote: await _remote(),
        store: ref.read(contentStoreProvider),
        db: ref.read(appDatabaseProvider),
        clock: ref.read(clockProvider),
        loader: ref.read(contentLoaderProvider),
      ).apply(manifest);
    } catch (e) {
      debugPrint('content update failed: $e');
      state = ContentUpdateState(
        ContentUpdatePhase.updateFailed,
        manifest: manifest,
      );
      return false;
    }
    state = const ContentUpdateState(ContentUpdatePhase.upToDate);
    ref.invalidate(contentProvider);
    return true;
  }

  /// "Dùng bản đóng gói".
  Future<void> useBundled() async {
    await ContentUpdater(
      remote: await _remote(),
      store: ref.read(contentStoreProvider),
      db: ref.read(appDatabaseProvider),
      clock: ref.read(clockProvider),
    ).useBundled();
    state = const ContentUpdateState(ContentUpdatePhase.idle);
    ref.invalidate(contentProvider);
  }
}

final contentUpdateProvider =
    NotifierProvider<ContentUpdateNotifier, ContentUpdateState>(
      ContentUpdateNotifier.new,
    );

/// `settings.content_source` is `remote` (S10 shows "Dùng bản đóng gói").
final usingRemoteContentProvider = Provider<bool>(
  (ref) =>
      ref.watch(settingsProvider).value?[SettingKeys.contentSource] ==
      ContentSourceKind.remote.name,
);
