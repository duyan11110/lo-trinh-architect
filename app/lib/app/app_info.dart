// App version shown in S10 "Về". Mirrors `version:` in pubspec.yaml; CI may
// pass `--dart-define=APP_VERSION=…` (no package_info dependency, docs/07 §2).
const String appVersion = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: '1.0.0+1',
);
