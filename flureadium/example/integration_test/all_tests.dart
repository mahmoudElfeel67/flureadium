import 'package:integration_test/integration_test.dart';

import 'launch_test.dart' as launch;
import 'audiobook_test.dart' as audiobook;
import 'epub_test.dart' as epub;
import 'epub_tts_test.dart' as epub_tts;
import 'error_handling_test.dart' as error_handling;
import 'webpub_test.dart' as webpub;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  launch.main();
  audiobook.main();
  epub.main();
  epub_tts.main();
  error_handling.main();
  webpub.main();
}
