// S10 Cài đặt (`/settings`, `/settings/content`, `/settings/progress`) —
// docs/05 S10: Đọc (content language, font size, line height, theme), Ôn tập
// (questions per session), Nội dung (version in use, "Kiểm tra bản mới" with
// the diff, "Cập nhật", "Dùng bản đóng gói"), Tiến độ (export, import with
// an overwrite confirmation, two-step reset), Về (app version, licenses).
// The reminder time is hidden (DECISIONS.md E5). `/settings/content` checks
// for a new version on open (docs/07 §7).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/app_info.dart';
import '../../app/locations.dart';
import '../../app/theme/text.dart';
import '../../app/theme/tokens.dart';
import '../../content/content_repository.dart';
import '../../content/content_update.dart';
import '../../content/models/models.dart';
import '../../l10n/app_localizations.dart';
import '../../progress/export_import.dart';
import '../../progress/review_repository.dart';
import '../../progress/review_scheduler.dart';
import '../../progress/settings_repository.dart';
import 'progress_files.dart';

enum SettingsSection { content, progress }

/// S10 choices for `review_max_per_session`.
const List<int> reviewMaxChoices = [10, reviewDefaultMaxPerSession, 30, 40];

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, this.section});

  /// Only this group (the `/settings/content|progress` sub-pages).
  final SettingsSection? section;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.section == SettingsSection.content) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(contentUpdateProvider.notifier).check();
      });
    }
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<bool> _confirm(String text, String action) async {
    final l = L.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _guard(Future<void> Function() f) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await f();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export() => _guard(() async {
    final transfer = ref.read(progressTransferProvider);
    final json = await transfer.exportJson();
    try {
      await ref.read(progressFilesProvider).save(transfer.fileName(), json);
    } catch (e) {
      debugPrint('export failed: $e');
    }
  });

  Future<void> _import() => _guard(() async {
    final l = L.of(context);
    final String? json;
    try {
      json = await ref.read(progressFilesProvider).pick();
    } catch (e) {
      debugPrint('pick failed: $e');
      return;
    }
    if (json == null || !mounted) return;
    if (!await _confirm(l.progressImportConfirm, l.progressImportAction)) return;
    try {
      await ref.read(progressTransferProvider).importJson(json);
    } on ProgressImportException catch (e) {
      debugPrint('$e');
      if (mounted) _toast(l.progressImportFailed);
      return;
    }
    ref.invalidate(reviewMaxProvider);
    if (mounted) _toast(l.progressImported);
  });

  Future<void> _reset() => _guard(() async {
    final l = L.of(context);
    if (!await _confirm(l.progressResetConfirm, l.progressResetAction)) return;
    if (!mounted) return;
    if (!await _confirm(l.progressResetConfirm2, l.progressResetAction)) return;
    await ref.read(progressTransferProvider).reset();
    ref.invalidate(reviewMaxProvider);
    if (mounted) _toast(l.progressResetDone);
  });

  Future<void> _update() async {
    final ok = await ref.read(contentUpdateProvider.notifier).update();
    if (ok && mounted) context.go(homeLocation);
  }

  Future<void> _useBundled() async {
    await ref.read(contentUpdateProvider.notifier).useBundled();
    if (mounted) context.go(homeLocation);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final section = widget.section;
    final groups = <Widget>[
      if (section == null) ...[
        _ReadingGroup(),
        _ReviewGroup(),
      ],
      if (section == null || section == SettingsSection.content)
        _ContentGroup(onUpdate: _update, onUseBundled: _useBundled),
      if (section == null || section == SettingsSection.progress)
        _Group(
          title: l.settingsProgress,
          children: [
            _ActionRow(
              icon: Icons.upload_rounded,
              label: l.progressExport,
              onTap: _busy ? null : _export,
            ),
            _ActionRow(
              icon: Icons.download_rounded,
              label: l.progressImport,
              onTap: _busy ? null : _import,
            ),
            _ActionRow(
              icon: Icons.restart_alt_rounded,
              label: l.progressReset,
              onTap: _busy ? null : _reset,
            ),
          ],
        ),
      if (section == null)
        _Group(
          title: l.settingsAbout,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.settingsAppVersion),
              trailing: Text(appVersion),
            ),
            _ActionRow(
              icon: Icons.description_outlined,
              label: l.settingsLicenses,
              onTap: () => showLicensePage(
                context: context,
                applicationName: l.appTitle,
                applicationVersion: appVersion,
              ),
            ),
          ],
        ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(switch (section) {
          null => l.settingsTitle,
          SettingsSection.content => l.settingsContent,
          SettingsSection.progress => l.settingsProgress,
        }),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: LtaSpace.contentMobile,
          vertical: LtaSpace.s4,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: LtaSize.readingMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: groups,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<LtaText>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: LtaSpace.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title.toUpperCase(), style: t.eyebrow),
          const SizedBox(height: LtaSpace.s2),
          ...children,
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    minTileHeight: LtaSize.minTap,
    leading: Icon(icon, size: LtaSize.icon),
    title: Text(label),
    enabled: onTap != null,
    onTap: onTap,
  );
}

/// A label above a full-width control.
class _Labeled extends StatelessWidget {
  const _Labeled({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: LtaSpace.s3),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: LtaSpace.s2),
        child,
      ],
    ),
  );
}

class _ReadingGroup extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final lang = effectiveLang(ref, context);
    final prefs = ref.watch(readingPrefsProvider);
    final prefsN = ref.read(readingPrefsProvider.notifier);
    final theme = ref.watch(themeModeProvider);
    return _Group(
      title: l.settingsReading,
      children: [
        _Labeled(
          label: l.settingsContentLang,
          child: SegmentedButton<ContentLang>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: ContentLang.vi, label: Text(l.langVi)),
              ButtonSegment(value: ContentLang.en, label: Text(l.langEn)),
            ],
            selected: {lang},
            onSelectionChanged: (s) =>
                ref.read(contentLangProvider.notifier).set(s.single),
          ),
        ),
        _Labeled(
          label: l.readingSettings,
          child: Slider(
            value: prefs.fontStep.toDouble(),
            max: (ReadingPrefs.steps.length - 1).toDouble(),
            divisions: ReadingPrefs.steps.length - 1,
            semanticFormatterCallback: (v) =>
                '${ReadingPrefs.steps[v.round()].round()}',
            onChanged: (v) => prefsN.setFontStep(v.round()),
          ),
        ),
        _Labeled(
          label: l.readingLineHeight,
          child: Slider(
            value: prefs.lineStep.toDouble(),
            max: (LtaText.readingLineHeights.length - 1).toDouble(),
            divisions: LtaText.readingLineHeights.length - 1,
            onChanged: (v) => prefsN.setLineStep(v.round()),
          ),
        ),
        _Labeled(
          label: l.settingsTheme,
          child: SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: ThemeMode.system, label: Text(l.settingsThemeSystem)),
              ButtonSegment(value: ThemeMode.light, label: Text(l.settingsThemeLight)),
              ButtonSegment(value: ThemeMode.dark, label: Text(l.settingsThemeDark)),
            ],
            selected: {theme},
            onSelectionChanged: (s) =>
                ref.read(themeModeProvider.notifier).set(s.single),
          ),
        ),
      ],
    );
  }
}

class _ReviewGroup extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final current = ref.watch(reviewMaxProvider).value ?? reviewDefaultMaxPerSession;
    return _Group(
      title: l.navReview,
      children: [
        _Labeled(
          label: l.settingsReviewMax,
          child: SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [
              for (final n in {...reviewMaxChoices, current}.toList()..sort())
                ButtonSegment(value: n, label: Text('$n')),
            ],
            selected: {current},
            onSelectionChanged: (s) async {
              await ref
                  .read(settingsRepositoryProvider)
                  .set(SettingKeys.reviewMax, '${s.single}');
              ref.invalidate(reviewMaxProvider);
            },
          ),
        ),
      ],
    );
  }
}

class _ContentGroup extends ConsumerWidget {
  const _ContentGroup({required this.onUpdate, required this.onUseBundled});

  final VoidCallback onUpdate;
  final VoidCallback onUseBundled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final theme = Theme.of(context);
    final c = theme.extension<LtaColors>()!;
    final content = ref.watch(contentProvider).value;
    final update = ref.watch(contentUpdateProvider);
    final remote = ref.watch(usingRemoteContentProvider);
    final meta = content?.meta;
    final built = meta == null ? null : DateTime.tryParse(meta.builtAt);
    final date = built == null
        ? (meta?.builtAt ?? '')
        : DateFormat(
            'dd/MM/yyyy',
            Localizations.localeOf(context).toLanguageTag(),
          ).format(built.toLocal());
    final muted = theme.textTheme.bodyMedium!.copyWith(color: c.ink2);
    final m = update.manifest;
    final busy = update.phase == ContentUpdatePhase.checking ||
        update.phase == ContentUpdatePhase.updating;

    final status = switch (update.phase) {
      ContentUpdatePhase.idle => null,
      ContentUpdatePhase.checking => l.contentChecking,
      ContentUpdatePhase.upToDate => l.contentUpToDate,
      ContentUpdatePhase.checkFailed => l.contentCheckFailed,
      ContentUpdatePhase.updating => l.contentUpdating,
      ContentUpdatePhase.available => null,
      ContentUpdatePhase.updateFailed => l.contentUpdateFailed(
        meta?.contentVersion ?? 0,
      ),
    };

    return _Group(
      title: l.settingsContent,
      children: [
        if (meta != null)
          Padding(
            padding: const EdgeInsets.only(bottom: LtaSpace.s2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.settingsContentVersion(meta.contentVersion, date),
                  style: theme.textTheme.bodyLarge,
                ),
                Text(
                  remote ? l.settingsContentDownloaded : l.settingsContentBundled,
                  style: muted,
                ),
              ],
            ),
          ),
        if (m != null &&
            (update.phase == ContentUpdatePhase.available ||
                update.phase == ContentUpdatePhase.updateFailed)) ...[
          Text(
            l.contentNewAvailable(m.contentVersion),
            style: theme.textTheme.bodyLarge,
          ),
          Text(
            l.contentDiff(m.lessonsAdded.length, m.lessonsChanged.length),
            style: muted,
          ),
          const SizedBox(height: LtaSpace.s2),
          SizedBox(
            height: LtaSize.minTouch,
            child: FilledButton(
              onPressed: busy ? null : onUpdate,
              child: Text(l.contentUpdateAction),
            ),
          ),
          const SizedBox(height: LtaSpace.s2),
        ],
        if (status != null)
          Padding(
            padding: const EdgeInsets.only(bottom: LtaSpace.s2),
            child: Text(status, style: muted),
          ),
        _ActionRow(
          icon: Icons.sync_rounded,
          label: l.contentCheck,
          onTap: busy
              ? null
              : () => ref.read(contentUpdateProvider.notifier).check(),
        ),
        if (remote)
          _ActionRow(
            icon: Icons.inventory_2_outlined,
            label: l.contentUseBundled,
            onTap: busy ? null : onUseBundled,
          ),
      ],
    );
  }
}
