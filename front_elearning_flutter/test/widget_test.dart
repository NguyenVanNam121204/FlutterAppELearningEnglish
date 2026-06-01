import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:front_elearning_flutter/app/app.dart';
import 'package:front_elearning_flutter/app/theme/theme_provider.dart';

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

  testWidgets('App boots successfully', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const EnglishLearningApp(),
    ));

    await tester.pumpAndSettle();

    expect(find.byType(EnglishLearningApp), findsOneWidget);
  });
}
