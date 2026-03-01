import 'package:integration_test/integration_test.dart';

import 'launch_test.dart' as launch;
import 'audiobook_test.dart' as audiobook;
import 'epub_test.dart' as epub;
import 'webpub_test.dart' as webpub;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  launch.main();
  audiobook.main();
  epub.main();
  webpub.main();
}
