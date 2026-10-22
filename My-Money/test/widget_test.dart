import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_money/providers/app_provider.dart';
import 'package:my_money/models/ai_budget_plan.dart';
import 'package:my_money/screens/ai_coach/ai_coach_screen.dart';
import 'package:my_money/screens/ai_budget/ai_budget_planner_screen.dart';
import 'package:my_money/screens/dashboard_screen.dart';
import 'package:my_money/screens/home_screen.dart';
import 'package:my_money/utils/theme.dart';

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

  testWidgets('DashboardScreen renders all luxury fintech elements correctly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => AppProvider())],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const DashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Header: Branding, Luxury tag, Search, AI Sparkle
    expect(find.text('MONEY'), findsOneWidget);
    expect(find.text('PREMIUM'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome), findsWidgets);

    // 2. Primary Financial Balance Card
    expect(find.text('MONTHLY NET BALANCE'), findsOneWidget);
    expect(find.text('Month'), findsOneWidget);
    expect(find.text('All-Time'), findsOneWidget);

    // 3. Income & Expense Cards
    expect(find.text('INCOME'), findsOneWidget);
    expect(find.text('EXPENSES'), findsOneWidget);

    // 4. Secondary Indicators
    expect(find.text('Savings'), findsOneWidget);
    expect(find.text('Daily Average'), findsOneWidget);

    // 5. AI Financial Coach Panel
    expect(find.text('Ask Coach'), findsOneWidget);
    expect(find.text('Quick Audit'), findsOneWidget);
    expect(find.text('AI Monthly Budget Planner →'), findsOneWidget);

    // 6. Recent Transactions & Ornate Empty State
    expect(find.text('Recent Transactions'), findsOneWidget);
    expect(find.text('See all'), findsOneWidget);
    expect(find.text('No Transactions Recorded'), findsOneWidget);
    expect(find.text('Add Transaction'), findsOneWidget);

    // 7. Floating Action Button
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byIcon(Icons.add), findsWidgets);
  });

  testWidgets('HomeScreen renders all 13 navigation destinations', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => AppProvider())],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(HomeScreen), findsOneWidget);
    // Verify all 13 destinations exist
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('AI Coach'), findsOneWidget);
    expect(find.text('AI Planner'), findsOneWidget);
    expect(find.text('Transactions'), findsWidgets);
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text('Debts'), findsOneWidget);
    expect(find.text('Budgets'), findsOneWidget);
    expect(find.text('Accounts'), findsOneWidget);
    expect(find.text('Limits'), findsOneWidget);
    expect(find.text('Data'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}

