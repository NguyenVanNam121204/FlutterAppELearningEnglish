import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:front_elearning_flutter/app/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.testLoad(
      fileInput: '''
API_BASE_URL=http://localhost:5030
APP_ENV=test
CONNECT_TIMEOUT_MS=15000
RECEIVE_TIMEOUT_MS=15000
ENABLE_NETWORK_LOG=false
''',
    );
  });

  testWidgets('App boots to auth screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: EnglishLearningApp()));

    await tester.pumpAndSettle();

    expect(find.text('Dang nhap'), findsWidgets);
  });
}
