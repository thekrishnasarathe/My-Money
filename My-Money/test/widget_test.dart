import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_money/providers/app_provider.dart';
import 'package:my_money/models/ai_budget_plan.dart';
import 'package:my_money/screens/ai_coach/ai_coach_screen.dart';
import 'package:my_money/screens/ai_budget/ai_budget_planner_screen.dart';

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

  testWidgets('AiBudgetPlannerScreen renders form and empty/loaded state properly', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => AppProvider())],
        child: const MaterialApp(
          home: AiBudgetPlannerScreen(),
        ),
      ),
    );

    expect(find.byType(AiBudgetPlannerScreen), findsOneWidget);
    expect(find.text('AI Monthly Budget Planner'), findsOneWidget);
    expect(find.text('Financial Form'), findsOneWidget);
  });

  testWidgets('AiBudgetPlannerScreen renders dashboard when initialPlan provided', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime.now();
    final samplePlan = AiBudgetPlan(
      summary: 'Test Student Budget',
      monthlyIncome: 15000,
      allocations: const [
        AiBudgetAllocation(category: 'Housing', amount: 3000, percentage: 20, type: 'essential', isFixed: true),
        AiBudgetAllocation(category: 'Education Fees', amount: 2000, percentage: 13.33, type: 'debt', isFixed: true),
        AiBudgetAllocation(category: 'Food and Groceries', amount: 4000, percentage: 26.67, type: 'essential'),
        AiBudgetAllocation(category: 'Emergency Savings', amount: 2000, percentage: 13.33, type: 'savings'),
        AiBudgetAllocation(category: 'Entertainment', amount: 1000, percentage: 6.67, type: 'discretionary'),
        AiBudgetAllocation(category: 'Miscellaneous', amount: 3000, percentage: 20, type: 'discretionary'),
      ],
      totalEssential: 9000,
      totalLifestyle: 4000,
      totalSavings: 2000,
      savingsPercentage: 13.33,
      aiExplanation: 'Personalized student allocation strategy.',
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => AppProvider())],
        child: MaterialApp(
          home: AiBudgetPlannerScreen(initialPlan: samplePlan),
        ),
      ),
    );

    expect(find.text('Available Budget'), findsOneWidget);
    expect(find.text('Essential Spend'), findsOneWidget);
    expect(find.text('Planned Savings'), findsOneWidget);
    expect(find.text('Category Allocations'), findsOneWidget);
    expect(find.text('Accept & Apply to Budget Tracker'), findsOneWidget);
  });
}
