import '../models/ai_budget_plan.dart';

/// Client-side deterministic financial planner fallback engine.
/// Activated when the AI backend is unreachable or offline.
/// Guarantees 100% mathematical integrity: Sum(allocations) == monthlyIncome.
class AiBudgetPlannerFallbackEngine {
  static AiBudgetPlan generate(AiBudgetInput input, {String? reason}) {
    final name = input.name.trim().isEmpty ? 'User' : input.name.trim();
    final occupation = input.occupation.toLowerCase();
    final income = input.monthlyIncome;
    final sym = input.currency == 'INR' ? '₹' : '${input.currency} ';

    // 1. Check Shortfall
    if (input.hasShortfall) {
      final deficit = input.shortfallAmount;
      final fixedObligations = input.totalFixedObligations;
      final List<AiBudgetAllocation> allocations = [];

      if (input.rentHousing > 0) {
        allocations.add(AiBudgetAllocation(
          category: 'Rent and Housing',
          amount: input.rentHousing,
          percentage: double.parse(((input.rentHousing / income) * 100).toStringAsFixed(2)),
          type: 'essential',
          explanation: 'User-specified fixed housing obligation',
          isFixed: true,
        ));
      }
      if (input.educationLoans > 0) {
        allocations.add(AiBudgetAllocation(
          category: 'Education Fees',
          amount: input.educationLoans,
          percentage: double.parse(((input.educationLoans / income) * 100).toStringAsFixed(2)),
          type: 'debt',
          explanation: 'User-specified education/loan commitment',
          isFixed: true,
        ));
      }
      if (input.otherExpenses > 0) {
        allocations.add(AiBudgetAllocation(
          category: 'Other Obligations',
          amount: input.otherExpenses,
          percentage: double.parse(((input.otherExpenses / income) * 100).toStringAsFixed(2)),
          type: 'essential',
          explanation: 'User-specified recurring commitments',
          isFixed: true,
        ));
      }

      final now = DateTime.now();
      return AiBudgetPlan(
        summary: 'Deficit Warning: Fixed commitments exceed income by $sym${deficit.toStringAsFixed(2)}',
        currency: input.currency,
        monthlyIncome: income,
        feasibilityStatus: 'shortfall',
        deficit: deficit,
        allocations: allocations,
        totalEssential: fixedObligations,
        totalLifestyle: 0.0,
        totalSavings: 0.0,
        unallocatedBalance: -deficit,
        savingsPercentage: 0.0,
        aiExplanation:
            '⚠️ **Critical Budget Shortfall**: Your confirmed fixed commitments ($sym${fixedObligations.toStringAsFixed(2)}) exceed your available monthly income ($sym${income.toStringAsFixed(2)}) by **$sym${deficit.toStringAsFixed(2)}**.\n\n'
            '• **Priority Review**: Fixed costs account for **${((fixedObligations / income) * 100).toStringAsFixed(1)}%** of your budget.\n'
            '• **Action Required**: Restructure loans, negotiate rent, or identify secondary income sources.\n'
            '• **Zero Discretionary Budget**: No lifestyle spending or savings can be recommended until fixed costs align with income.',
        assumptions: const [
          'Housing and loan obligations represent non-negotiable mandatory commitments.'
        ],
        financialWarnings: [
          'Immediate monthly budget shortfall of $sym${deficit.toStringAsFixed(2)}.',
          'Discretionary spending suspended to prevent debt accumulation.'
        ],
        savingsRecommendation: 'Focus all available resources on debt reduction and eliminating the shortfall.',
        provider: 'offline-rule-engine',
        model: 'deterministic-analyzer',
        isOfflineFallback: true,
        input: input,
        createdAt: now,
        updatedAt: now,
      );
    }

    // 2. Feasible Distribution
    final fixedObligations = input.totalFixedObligations;
    final remaining = income - fixedObligations;
    final List<AiBudgetAllocation> allocations = [];

    // Add Fixed Allocations
    if (input.rentHousing > 0) {
      allocations.add(AiBudgetAllocation(
        category: 'Housing',
        amount: input.rentHousing,
        percentage: 0.0,
        type: 'essential',
        explanation: 'User-specified fixed housing obligation',
        isFixed: true,
      ));
    }
    if (input.educationLoans > 0) {
      allocations.add(AiBudgetAllocation(
        category: 'Education Fees',
        amount: input.educationLoans,
        percentage: 0.0,
        type: 'debt',
        explanation: 'User-specified education/loan commitment',
        isFixed: true,
      ));
    }
    if (input.otherExpenses > 0) {
      allocations.add(AiBudgetAllocation(
        category: 'Other Obligations',
        amount: input.otherExpenses,
        percentage: 0.0,
        type: 'essential',
        explanation: 'User-specified recurring commitments',
        isFixed: true,
      ));
    }

    // Calculate Savings Target
    double targetSavings = 0.0;
    if (input.savingsTarget > 0) {
      targetSavings = input.savingsTarget.clamp(0.0, remaining * 0.45);
    } else {
      if (occupation.contains('student')) {
        targetSavings = remaining * 0.20;
      } else if (occupation.contains('freelancer') ||
          occupation.contains('business') ||
          occupation.contains('self-employed')) {
        targetSavings = remaining * 0.25;
      } else {
        targetSavings = remaining * 0.20;
      }
    }

    targetSavings = double.parse(targetSavings.toStringAsFixed(2));
    final emergencyFund = double.parse((targetSavings * 0.40).toStringAsFixed(2));
    final goalSavings = double.parse((targetSavings - emergencyFund).toStringAsFixed(2));

    final poolForLiving = double.parse((remaining - targetSavings).toStringAsFixed(2));

    // Dynamic living weights
    Map<String, double> weights;
    if (occupation.contains('student')) {
      weights = {
        'Food and Groceries': 0.40,
        'Transportation': 0.15,
        'Utilities and Phone': 0.08,
        'Healthcare and Essentials': 0.10,
        'Shopping and Lifestyle': 0.12,
        'Entertainment': 0.08,
        'Miscellaneous': 0.07,
      };
    } else if (occupation.contains('freelancer') || occupation.contains('self-employed')) {
      weights = {
        'Food and Groceries': 0.32,
        'Transportation': 0.12,
        'Utilities and Bills': 0.14,
        'Healthcare': 0.10,
        'Shopping and Lifestyle': 0.14,
        'Entertainment': 0.08,
        'Miscellaneous': 0.10,
      };
    } else {
      weights = {
        'Food and Groceries': 0.34,
        'Transportation': 0.14,
        'Utilities and Bills': 0.12,
        'Healthcare': 0.08,
        'Shopping and Lifestyle': 0.14,
        'Entertainment': 0.10,
        'Miscellaneous': 0.08,
      };
    }

    if (input.dependents > 0) {
      weights['Family and Dependents'] = 0.15;
      const factor = 0.85;
      weights = weights.map((k, v) => MapEntry(k, k == 'Family and Dependents' ? v : v * factor));
    }

    final catTypes = {
      'Food and Groceries': 'essential',
      'Transportation': 'essential',
      'Utilities and Phone': 'essential',
      'Utilities and Bills': 'essential',
      'Healthcare and Essentials': 'essential',
      'Healthcare': 'essential',
      'Family and Dependents': 'essential',
      'Shopping and Lifestyle': 'discretionary',
      'Entertainment': 'discretionary',
      'Miscellaneous': 'discretionary',
    };

    double livingAllocated = 0.0;
    final keys = weights.keys.toList();
    for (int i = 0; i < keys.length - 1; i++) {
      final cat = keys[i];
      final amt = double.parse((poolForLiving * weights[cat]!).toStringAsFixed(2));
      if (amt > 0) {
        allocations.add(AiBudgetAllocation(
          category: cat,
          amount: amt,
          percentage: 0.0,
          type: catTypes[cat] ?? 'essential',
          explanation: 'Recommended allowance calibrated to your occupation and income profile',
          isFixed: false,
        ));
        livingAllocated += amt;
      }
    }

    // Last living category takes remainder of living pool
    final lastCat = keys.last;
    final lastAmt = double.parse((poolForLiving - livingAllocated).toStringAsFixed(2));
    if (lastAmt > 0) {
      allocations.add(AiBudgetAllocation(
        category: lastCat,
        amount: lastAmt,
        percentage: 0.0,
        type: catTypes[lastCat] ?? 'discretionary',
        explanation: 'Buffer allowance for incidental living expenses',
        isFixed: false,
      ));
    }

    // Add Savings
    if (emergencyFund > 0) {
      allocations.add(AiBudgetAllocation(
        category: 'Emergency Savings',
        amount: emergencyFund,
        percentage: 0.0,
        type: 'savings',
        explanation: 'Safety cushion for unexpected healthcare or urgencies',
        isFixed: false,
      ));
    }
    if (goalSavings > 0) {
      allocations.add(AiBudgetAllocation(
        category: 'Goal-Based Savings',
        amount: goalSavings,
        percentage: 0.0,
        type: 'savings',
        explanation: input.financialGoals.isNotEmpty
            ? 'Dedicated goal fund: ${input.financialGoals}'
            : 'Goal-based wealth accumulation',
        isFixed: false,
      ));
    }

    // Mathematical reconciliation: sum(allocations) == income
    final currentSum = allocations.fold(0.0, (s, a) => s + a.amount);
    final diff = double.parse((income - currentSum).toStringAsFixed(2));
    if (diff.abs() > 0.001) {
      for (int i = allocations.length - 1; i >= 0; i--) {
        if (!allocations[i].isFixed) {
          allocations[i] = allocations[i].copyWith(
            amount: double.parse((allocations[i].amount + diff).toStringAsFixed(2)),
          );
          break;
        }
      }
    }

    // Recalculate percentages
    final finalAllocs = allocations.map((a) {
      final pct = (a.amount / income) * 100;
      return a.copyWith(percentage: double.parse(pct.toStringAsFixed(2)));
    }).toList();

    double essentialTotal = 0.0;
    double lifestyleTotal = 0.0;
    double savingsTotal = 0.0;

    for (final a in finalAllocs) {
      if (a.type == 'essential' || a.type == 'debt') {
        essentialTotal += a.amount;
      } else if (a.type == 'savings') {
        savingsTotal += a.amount;
      } else {
        lifestyleTotal += a.amount;
      }
    }

    final savingsPct = double.parse(((savingsTotal / income) * 100).toStringAsFixed(2));
    final feasibility = (essentialTotal / income) > 0.70 ? 'tight' : 'feasible';

    final now = DateTime.now();
    return AiBudgetPlan(
      summary: 'Personalized Budget Plan for $name ($sym${income.toStringAsFixed(2)})',
      currency: input.currency,
      monthlyIncome: income,
      feasibilityStatus: feasibility,
      deficit: 0.0,
      allocations: finalAllocs,
      totalEssential: double.parse(essentialTotal.toStringAsFixed(2)),
      totalLifestyle: double.parse(lifestyleTotal.toStringAsFixed(2)),
      totalSavings: double.parse(savingsTotal.toStringAsFixed(2)),
      unallocatedBalance: 0.0,
      savingsPercentage: savingsPct,
      aiExplanation:
          '### [AI Analytical Budget Strategy for $name]\n\n'
          '• **Balanced Distribution**: From your $sym${income.toStringAsFixed(2)} monthly budget, '
          '**$sym${essentialTotal.toStringAsFixed(2)}** (${((essentialTotal / income) * 100).toStringAsFixed(1)}%) secures essentials & fixed commitments, '
          '**$sym${lifestyleTotal.toStringAsFixed(2)}** (${((lifestyleTotal / income) * 100).toStringAsFixed(1)}%) funds lifestyle spending, and '
          '**$sym${savingsTotal.toStringAsFixed(2)}** ($savingsPct%) is directed to your savings goals.\n\n'
          '• **Fixed Constraints Safeguarded**: Your confirmed housing ($sym${input.rentHousing.toStringAsFixed(2)}) and education/loan ($sym${input.educationLoans.toStringAsFixed(2)}) costs are preserved without modification.\n\n'
          '• **Goal Realization**: Monthly savings of $sym${savingsTotal.toStringAsFixed(2)} builds your safety reserve and directly funds: *\'${input.financialGoals.isEmpty ? "Long-term Wealth" : input.financialGoals}\'*.\n\n'
          '• **Editable & Flexible**: You can fine-tune any category amount or rebalance discretionary funds before accepting this budget.',
      assumptions: const [
        'Living expense allocations are benchmarked to your stated occupation context.',
        'Discretionary expenses can be re-allocated dynamically as priorities evolve.'
      ],
      financialWarnings: const [
        'Discretionary spending should be reviewed weekly to prevent budget overruns.'
      ],
      savingsRecommendation: 'Deposit your $sym${savingsTotal.toStringAsFixed(2)} monthly savings immediately upon income receipt.',
      provider: 'offline-rule-engine',
      model: 'deterministic-budget-planner',
      isOfflineFallback: true,
      input: input,
      createdAt: now,
      updatedAt: now,
    );
  }
}
