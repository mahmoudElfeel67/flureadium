// Android CI test bundle — excludes TTS, audiobook, and WebPub tests which
// require hardware audio engines or external network access unavailable on
// GitHub-hosted emulators.
import 'package:integration_test/integration_test.dart';

import 'launch_test.dart' as launch;
import 'epub_test.dart' as epub;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  launch.main();
  epub.main();
}
