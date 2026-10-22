import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_money/models/ai_budget_plan.dart';
import 'package:my_money/services/ai_budget_planner_fallback.dart';

void main() {
  group('AI Budget Planner Input & Validation Tests', () {
    test('1. Required field validation: empty name fails validation', () {
      const input = AiBudgetInput(
        name: '',
        occupation: 'student',
        monthlyIncome: 15000,
      );
      expect(input.validate(), isNotNull);
      expect(input.validate(), contains('name'));
    });

    test('2. Invalid or negative income fails validation', () {
      const zeroIncome = AiBudgetInput(
        name: 'Rahul',
        occupation: 'student',
        monthlyIncome: 0,
      );
      expect(zeroIncome.validate(), isNotNull);
      expect(zeroIncome.validate(), contains('greater than zero'));

      const negativeIncome = AiBudgetInput(
        name: 'Rahul',
        occupation: 'student',
        monthlyIncome: -5000,
      );
      expect(negativeIncome.validate(), isNotNull);
    });

    test('3. Negative constraints fail validation', () {
      const negativeRent = AiBudgetInput(
        name: 'Rahul',
        occupation: 'student',
        monthlyIncome: 15000,
        rentHousing: -1000,
      );
      expect(negativeRent.validate(), contains('negative'));
    });

    test('4. Valid minimal input passes validation', () {
      const valid = AiBudgetInput(
        name: 'Rahul',
        occupation: 'student',
        monthlyIncome: 15000,
      );
      expect(valid.validate(), isNull);
    });
  });

  group('Shortfall & Deficit Feasibility Tests', () {
    test('5. Fixed expenses exceeding available income creates shortfall budget without fabrication', () {
      const input = AiBudgetInput(
        name: 'Rahul',
        occupation: 'student',
        monthlyIncome: 10000,
        rentHousing: 8000,
        educationLoans: 4000, // Total fixed = 12000 > 10000
      );

      expect(input.hasShortfall, isTrue);
      expect(input.shortfallAmount, equals(2000.0));

      final plan = AiBudgetPlannerFallbackEngine.generate(input);

      expect(plan.feasibilityStatus, equals('shortfall'));
      expect(plan.deficit, equals(2000.0));
      expect(plan.totalLifestyle, equals(0.0));
      expect(plan.totalSavings, equals(0.0));
      expect(plan.allocations.any((a) => a.isFixed), isTrue);
      expect(plan.allocations.length, equals(2)); // Only Housing & Education
    });

    test('6. Savings goal exceeding remaining budget is clamped responsibly', () {
      const input = AiBudgetInput(
        name: 'Rahul',
        occupation: 'student',
        monthlyIncome: 15000,
        rentHousing: 5000,
        educationLoans: 3000, // Remaining = 7000
        savingsTarget: 10000, // Exceeds remaining 7000!
      );

      final plan = AiBudgetPlannerFallbackEngine.generate(input);

      expect(plan.feasibilityStatus, isNot('shortfall'));
      expect(plan.totalSavings, lessThanOrEqualTo(7000.0));
      expect(plan.isBalanced, isTrue);
      expect(plan.totalAllocated, equals(15000.0));
    });
  });

  group('Allocation Math & Normalization Tests', () {
    test('7. Feasible budget reconciles exactly: Sum(allocations) == monthlyIncome', () {
      const input = AiBudgetInput(
        name: 'Rahul',
        occupation: 'student',
        monthlyIncome: 15000,
        rentHousing: 3000,
        educationLoans: 2000,
        savingsTarget: 2000,
        financialGoals: 'Laptop',
      );

      final plan = AiBudgetPlannerFallbackEngine.generate(input);

      expect(plan.monthlyIncome, equals(15000.0));
      expect(plan.totalAllocated, equals(15000.0));
      expect(plan.unallocatedBalance, equals(0.0));
      expect(plan.isBalanced, isTrue);

      // Verify user constraints are preserved
      final housing = plan.allocations.firstWhere((a) => a.category == 'Housing');
      expect(housing.amount, equals(3000.0));
      expect(housing.isFixed, isTrue);

      final education = plan.allocations.firstWhere((a) => a.category == 'Education Fees');
      expect(education.amount, equals(2000.0));
      expect(education.isFixed, isTrue);
    });

    test('8. Category percentage calculations sum to 100%', () {
      const input = AiBudgetInput(
        name: 'Priya',
        occupation: 'salaried employee',
        monthlyIncome: 60000,
        rentHousing: 15000,
        savingsTarget: 12000,
      );

      final plan = AiBudgetPlannerFallbackEngine.generate(input);

      final sumPercentages = plan.allocations.fold(0.0, (s, a) => s + a.percentage);
      expect(sumPercentages, closeTo(100.0, 0.5));

      for (final a in plan.allocations) {
        final expectedPct = (a.amount / 60000) * 100;
        expect(a.percentage, closeTo(expectedPct, 0.05));
      }
    });

    test('9. No negative allocations permitted in recalculation', () {
      final now = DateTime.now();
      final plan = AiBudgetPlan(
        summary: 'Test',
        monthlyIncome: 10000,
        allocations: const [
          AiBudgetAllocation(category: 'Food', amount: -500, percentage: 0, type: 'essential'),
          AiBudgetAllocation(category: 'Rent', amount: 5000, percentage: 50, type: 'essential'),
        ],
        totalEssential: 5000,
        totalLifestyle: 0,
        totalSavings: 0,
        savingsPercentage: 0,
        aiExplanation: 'Test',
        createdAt: now,
        updatedAt: now,
      );

      final recalculated = plan.recalculate();
      expect(recalculated.allocations.first.amount, equals(0.0));
      expect(recalculated.allocations.first.percentage, equals(0.0));
    });
  });

  group('Interactive Editing, De-duplication & Rebalancing Tests', () {
    test('10. Editing a category amount immediately recalculates totals and balance', () {
      const input = AiBudgetInput(
        name: 'Rahul',
        occupation: 'student',
        monthlyIncome: 15000,
        rentHousing: 3000,
      );

      final plan = AiBudgetPlannerFallbackEngine.generate(input);
      expect(plan.isBalanced, isTrue);

      // User increases Food and Groceries by 1000
      final edited = plan.updateCategoryAmount('Food and Groceries', 5000);

      expect(edited.isOverallocated, isTrue);
      expect(edited.unallocatedBalance, lessThan(0.0));
      expect(edited.totalAllocated, greaterThan(15000.0));
    });

    test('11. Adding a new category and duplicate handling', () {
      const input = AiBudgetInput(
        name: 'Rahul',
        occupation: 'student',
        monthlyIncome: 15000,
      );

      final plan = AiBudgetPlannerFallbackEngine.generate(input);

      // Add custom unique category
      final withCustom = plan.addCategory(const AiBudgetAllocation(
        category: 'Gym Membership',
        amount: 800,
        percentage: 0,
        type: 'discretionary',
        isCustom: true,
      ));

      expect(withCustom.allocations.any((a) => a.category == 'Gym Membership'), isTrue);

      // Add duplicate category merges amounts instead of duplicating
      final countBefore = withCustom.allocations.length;
      final withDuplicate = withCustom.addCategory(const AiBudgetAllocation(
        category: 'Gym Membership',
        amount: 200,
        percentage: 0,
        type: 'discretionary',
      ));

      expect(withDuplicate.allocations.length, equals(countBefore));
      final gym = withDuplicate.allocations.firstWhere((a) => a.category == 'Gym Membership');
      expect(gym.amount, equals(1000.0));
    });

    test('12. Removing a category recalculates totals', () {
      const input = AiBudgetInput(
        name: 'Rahul',
        occupation: 'student',
        monthlyIncome: 15000,
      );

      final plan = AiBudgetPlannerFallbackEngine.generate(input);
      expect(plan.allocations.any((a) => a.category == 'Entertainment'), isTrue);

      final removed = plan.removeCategory('Entertainment');
      expect(removed.allocations.any((a) => a.category == 'Entertainment'), isFalse);
      expect(removed.unallocatedBalance, greaterThan(0.0));
      expect(removed.isUnderallocated, isTrue);
    });

    test('13. Rebalancing budget restores 100% balance without touching fixed expenses', () {
      const input = AiBudgetInput(
        name: 'Rahul',
        occupation: 'student',
        monthlyIncome: 15000,
        rentHousing: 3000, // Fixed
      );

      final plan = AiBudgetPlannerFallbackEngine.generate(input);

      // Overallocate manually
      final overallocated = plan.updateCategoryAmount('Food and Groceries', 8000);
      expect(overallocated.isOverallocated, isTrue);

      // Rebalance
      final rebalanced = overallocated.rebalanceDiscretionary();
      expect(rebalanced.isBalanced, isTrue);
      expect(rebalanced.totalAllocated, equals(15000.0));

      // Fixed constraint remains strictly untouched
      final housing = rebalanced.allocations.firstWhere((a) => a.category == 'Housing');
      expect(housing.amount, equals(3000.0));
    });
  });

  group('Serialization, Persistence & User Isolation Tests', () {
    test('14. Full JSON serialization and deserialization preserves all budget data', () {
      const input = AiBudgetInput(
        name: 'Rahul',
        occupation: 'student',
        monthlyIncome: 15000,
        rentHousing: 3000,
        educationLoans: 2000,
        savingsTarget: 2000,
      );

      final plan = AiBudgetPlannerFallbackEngine.generate(input);
      final map = plan.toMap();

      final restored = AiBudgetPlan.fromMap(map);

      expect(restored.monthlyIncome, equals(plan.monthlyIncome));
      expect(restored.totalEssential, equals(plan.totalEssential));
      expect(restored.totalLifestyle, equals(plan.totalLifestyle));
      expect(restored.totalSavings, equals(plan.totalSavings));
      expect(restored.allocations.length, equals(plan.allocations.length));
      expect(restored.input?.name, equals('Rahul'));
      expect(restored.input?.occupation, equals('student'));
    });

    test('15. Multi-user isolation assigns active user ID correctly', () {
      final now = DateTime.now();
      final planUserA = AiBudgetPlan(
        userId: 'user_alice_123',
        summary: 'Alice Budget',
        monthlyIncome: 50000,
        allocations: const [],
        totalEssential: 25000,
        totalLifestyle: 15000,
        totalSavings: 10000,
        savingsPercentage: 20,
        aiExplanation: 'Alice explanation',
        createdAt: now,
        updatedAt: now,
      );

      final map = planUserA.toMap();
      expect(map['user_id'], equals('user_alice_123'));

      final restored = AiBudgetPlan.fromMap(map);
      expect(restored.userId, equals('user_alice_123'));
    });
  });
}
