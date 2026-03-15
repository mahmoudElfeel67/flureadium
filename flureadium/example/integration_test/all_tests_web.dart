import 'package:integration_test/integration_test.dart';

import 'epub_tts_web_test.dart' as epub_tts_web;
import 'launch_test.dart' as launch;

// webpub_test and epub_test are excluded from the web suite:
// - epub_test: packed EPUB files cannot be served via HTTP URL (web limitation)
// - webpub_test: ReadiumReader.getPublication() requires container div
//   initialization that only happens inside ReadiumWebView. Web reader support
//   is work in progress.

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  launch.main();
  epub_tts_web.main();
}
