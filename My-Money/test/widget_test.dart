import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_money/providers/app_provider.dart';
import 'package:my_money/screens/ai_coach/ai_coach_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AiCoachScreen renders correctly with tabs and prompt chips', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => AppProvider())],
        child: const MaterialApp(
          home: AiCoachScreen(),
        ),
      ),
    );

    expect(find.byType(AiCoachScreen), findsOneWidget);
    expect(find.text('AI Financial Coach'), findsWidgets);
    expect(find.text('Coach Q&A'), findsOneWidget);
    expect(find.text('Insights'), findsOneWidget);
    expect(find.text('Savings Goals'), findsOneWidget);
  });
}
