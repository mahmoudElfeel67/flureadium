// Android CI test bundle — excludes TTS, audiobook, and WebPub tests which
// require hardware audio engines or external network access unavailable on
// GitHub-hosted emulators.
import 'package:integration_test/integration_test.dart';

import 'launch_test.dart' as launch;
import 'epub_test.dart' as epub;
import 'error_handling_test.dart' as error_handling;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  launch.main();
  epub.main();
  error_handling.main();
}
