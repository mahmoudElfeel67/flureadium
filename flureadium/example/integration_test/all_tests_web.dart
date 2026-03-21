import 'package:integration_test/integration_test.dart';

import 'launch_test.dart' as launch;

// Web reader support is work in progress — many widget and platform methods
// are stubs. Only the launch smoke test runs on web for now.
//
// Excluded:
// - epub_test: packed EPUB files cannot be served via HTTP URL
// - webpub_test: requires container div init inside ReadiumWebView
// - epub_tts_web_test: TTS depends on navigator init which relies on
//   unfinished web reader plumbing (onErrorEvent, applyDecorations, etc.)

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  launch.main();
}
