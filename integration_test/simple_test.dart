import 'package:flutter_test/flutter_test.dart';
import 'package:quarkdrop/src/app/quarkdrop_app.dart';
import 'package:quarkdrop/src/platform/platform_paths.dart';
import 'package:quarkdrop/src/rust/api/simple.dart' as rust_simple;
import 'package:quarkdrop/src/rust/frb_generated.dart';
import 'package:quarkdrop/src/state/app_store.dart';
import 'package:integration_test/integration_test.dart';
import 'dart:io';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await RustLib.init();
    final configDir = await Directory.systemTemp.createTemp('quarkdrop-itest-');
    rust_simple.configureApp(configDir: configDir.path);
  });
  testWidgets('Shows login shell before Quark auth is wired', (
    WidgetTester tester,
  ) async {
    final store = AppStore(
      platformPaths: const PlatformPaths(
        configDir: '/tmp/quarkdrop-itest',
        downloadDir: '/tmp',
        displayName: 'QuarkDrop Test',
        requiresDownloadPicker: false,
      ),
    );
    await store.bootstrap();
    await tester.pumpWidget(QuarkDropApp(store: store));

    expect(find.text('Sign In'), findsOneWidget);
    expect(find.textContaining('Manifest + commit.ok.enc'), findsOneWidget);
  });
}
