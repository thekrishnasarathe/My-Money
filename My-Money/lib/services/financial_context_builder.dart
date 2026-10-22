import '../providers/app_provider.dart';

class FinancialContextBuilder {
  /// Extracts verified mathematical totals and metrics from AppProvider
  /// to provide exact, non-hallucinated ground truth for the LLM.
  static Map<String, dynamic> buildContext(AppProvider p) {
    final totalExpenses = p.totalExpensesThisMonth;
    final totalIncome = p.totalIncomeThisMonth;
    final netBalance = p.netBalanceThisMonth;
    final savingsRate = p.savingsRate;
    final dailyAvg = p.dailyAvgThisMonth;
    final monthlySpendLimit = p.monthlySpendLimit;

    // Top categories with spending and percentage of total
    final categoryBreakdown = <String, dynamic>{};
    p.categoryBreakdown.forEach((cat, amt) {
      final pct = totalExpenses > 0 ? (amt / totalExpenses) * 100 : 0.0;
      categoryBreakdown[cat] = {
        'amount': amt,
        'percentage_of_total': double.parse(pct.toStringAsFixed(1)),
      };
    });

    // Payment methods breakdown
    final paymentBreakdown = <String, double>{};
    p.paymentMethodBreakdown.forEach((pm, amt) {
      paymentBreakdown[pm] = amt;
    });

    // Top 5 largest expenses this month
    final topSpends = p.topSpends.take(5).map((e) => {
      'name': e.name,
      'amount': e.amount,
      'category': e.category,
      'date': '//',
      'payment_method': e.paymentMethod,
    }).toList();

    // Savings goals
    final goals = p.goals.map((g) => {
      'name': g.name,
      'target_amount': g.targetAmount,
      'saved_amount': g.savedAmount,
      'progress_percent': double.parse((g.progress * 100).toStringAsFixed(1)),
      'remaining_amount': g.remaining,
      'deadline': g.deadline != null
          ? '//'
          : null,
    }).toList();

    // Debts summary
    final pendingDebt = p.totalPendingDebt;
    final activeDebtsCount = p.pendingDebts.length;

    return {
      'period': {
        'month': p.selectedMonth,
        'year': p.selectedYear,
        'is_current_month': p.selectedMonth == DateTime.now().month &&
            p.selectedYear == DateTime.now().year,
      },
      'verified_financial_totals': {
        'total_income_this_month': totalIncome,
        'total_expenses_this_month': totalExpenses,
        'net_balance_this_month': netBalance,
        'savings_rate_percent': double.parse(savingsRate.toStringAsFixed(1)),
        'daily_average_spend': double.parse(dailyAvg.toStringAsFixed(1)),
        'all_time_balance': p.totalBalanceAllTime,
        'all_time_expenses': p.totalExpensesAllTime,
        'all_time_income': p.totalIncomeAllTime,
        'monthly_spend_limit': monthlySpendLimit,
        'is_spend_limit_exceeded':
            monthlySpendLimit > 0 && totalExpenses > monthlySpendLimit,
      },
      'category_breakdown': categoryBreakdown,
      'payment_method_breakdown': paymentBreakdown,
      'top_recent_spends': topSpends,
      'savings_goals': goals,
      'debt_obligations': {
        'total_pending_debt': pendingDebt,
        'active_lenders_count': activeDebtsCount,
      },
      'available_categories': p.categories.map((c) => c.name).toList(),
      'currency': p.currency,
    };
  }
}
