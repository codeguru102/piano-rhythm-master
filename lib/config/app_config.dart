/// Build-time configuration, supplied via `--dart-define` or a config file.
///
/// The text2midi endpoint is NOT set in the UI. Provide it at run/build time:
///
///   flutter run  --dart-define=MIDI_API_URL=https://your-host/generate
///   flutter build apk --dart-define=MIDI_API_URL=https://your-host/generate
///
/// or keep it in a git-ignored JSON config file and pass that instead:
///
///   flutter run --dart-define-from-file=config/app_config.json
///
/// where config/app_config.json is:
///   { "MIDI_API_URL": "https://your-host/generate" }
class AppConfig {
  const AppConfig._();

  /// text2midi generation endpoint. Empty when not configured.
  static const String midiApiUrl = String.fromEnvironment(
    'MIDI_API_URL',
    defaultValue: '',
  );

  static bool get hasMidiApi => midiApiUrl.trim().isNotEmpty;
}
