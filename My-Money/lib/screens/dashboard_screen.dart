import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import '../widgets/common_widgets.dart';
import '../models/expense.dart';
import '../models/income.dart';
import 'transactions/add_transaction_sheet.dart';
import 'transactions/transactions_screen.dart';
import 'ai_coach/ai_coach_screen.dart';
import 'ai_budget/ai_budget_planner_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (ctx, p, _) {
      return Scaffold(
        backgroundColor: AppTheme.jetBlack,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: p.refresh,
            color: AppTheme.champagneGold,
            backgroundColor: AppTheme.charcoalGrey,
            child: CustomScrollView(slivers: [
              // ── A. Compact MONEY Header ──
              SliverToBoxAdapter(child: _Header(p: p)),
              // ── B. Primary Financial Balance ──
              SliverToBoxAdapter(child: _BalanceCard(p: p)),
              // ── C. Income & Expense Cards ──
              SliverToBoxAdapter(child: _IncomeExpenseCards(p: p)),
              // ── D. Secondary Financial Indicators ──
              SliverToBoxAdapter(child: _SecondaryIndicators(p: p)),
              // ── E. AI Financial Coach Panel ──
              SliverToBoxAdapter(child: _AiCoachPanel(p: p)),
              // ── Spending limit bar (if set) ──
              if (p.monthlySpendLimit > 0)
                SliverToBoxAdapter(child: _SpendingLimitBar(p: p)),
              // ── F. Recent transactions ──
              SliverToBoxAdapter(child: _RecentSection(p: p)),
              // ── Top categories ──
              SliverToBoxAdapter(child: _TopCategories(p: p)),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ]),
          ),
        ),
        // ── G. Floating Action Button ──
        floatingActionButton: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.champagneGold.withOpacity(0.35),
                blurRadius: 14,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const AddTransactionSheet(),
            ),
            backgroundColor: AppTheme.champagneGold,
            elevation: 4,
            shape: const CircleBorder(),
            child: const Icon(Icons.add, color: Colors.black, size: 28),
          ),
        ),
      );
    });
  }
}

// ── A. Compact MONEY Header ──
class _Header extends StatelessWidget {
  final AppProvider p;
  const _Header({required this.p});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // MONEY branding in Champagne Gold & Month Selector
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppConstants.appName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.champagneGold,
                        letterSpacing: 3.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.charcoalGrey,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.antiqueGold, width: 0.6),
                      ),
                      child: const Text(
                        'PREMIUM',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.paleChampagne,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                MonthNavigator(
                  month: p.selectedMonth,
                  year: p.selectedYear,
                  onPrev: () {
                    int m = p.selectedMonth - 1, y = p.selectedYear;
                    if (m < 1) { m = 12; y--; }
                    p.setSelectedMonthYear(m, y);
                  },
                  onNext: () {
                    int m = p.selectedMonth + 1, y = p.selectedYear;
                    if (m > 12) { m = 1; y++; }
                    p.setSelectedMonthYear(m, y);
                  },
                ),
              ],
            ),
          ),
          // Subtle AI sparkle icon
          IconButton(
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AiCoachScreen())),
            tooltip: 'AI Financial Coach',
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.charcoalGrey,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.antiqueGold, width: 0.8),
              ),
              child: const Icon(Icons.auto_awesome, color: AppTheme.champagneGold, size: 17),
            ),
          ),
          const SizedBox(width: 8),
          // Search icon connected to existing search functionality
          IconButton(
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const TransactionsScreen())),
            tooltip: 'Search Transactions',
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.charcoalGrey,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.antiqueGold, width: 0.8),
              ),
              child: const Icon(Icons.search, color: AppTheme.paleChampagne, size: 17),
            ),
          ),
        ],
      ),
    );
  }
}

// ── B. Primary Financial Balance ──
class _BalanceCard extends StatefulWidget {
  final AppProvider p;
  const _BalanceCard({required this.p});

  @override
  State<_BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<_BalanceCard> {
  int _viewMode = 0; // 0 = This Month, 1 = Total Balance (All Time)

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final isMonth = _viewMode == 0;
    final balance = isMonth ? p.netBalanceThisMonth : p.totalBalanceAllTime;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.charcoalGrey,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.forestGreen, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isMonth ? 'MONTHLY NET BALANCE' : 'TOTAL BALANCE (ALL-TIME)',
                  style: const TextStyle(
                    color: AppTheme.paleChampagne,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // View mode selector
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.jetBlack,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.antiqueGold, width: 0.6),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _viewMode = 0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isMonth ? AppTheme.champagneGold : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Month',
                          style: TextStyle(
                            color: isMonth ? Colors.black : AppTheme.paleChampagne.withOpacity(0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _viewMode = 1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: !isMonth ? AppTheme.champagneGold : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'All-Time',
                          style: TextStyle(
                            color: !isMonth ? Colors.black : AppTheme.paleChampagne.withOpacity(0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Dominant Balance Display in Champagne Gold Numerals
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${balance < 0 ? "-" : ""}₹',
                  style: TextStyle(
                    color: balance < 0 ? AppTheme.deepCrimson : AppTheme.champagneGold,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  _fmt(balance.abs()),
                  style: TextStyle(
                    color: balance < 0 ? AppTheme.deepCrimson : AppTheme.champagneGold,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          if (p.categoryBreakdown.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.jetBlack,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.forestGreen, width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.insights, size: 13, color: AppTheme.champagneGold),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Primary Outflow: ${_topCat(p)}',
                      style: const TextStyle(
                        color: AppTheme.paleChampagne,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _topCat(AppProvider p) {
    if (p.categoryBreakdown.isEmpty) return 'None';
    final sorted = p.categoryBreakdown.entries.toList()
      ..sort((a,b) => b.value.compareTo(a.value));
    return '${sorted.first.key} (₹${_fmt(sorted.first.value)})';
  }
}

// ── C. Income and Expense Cards ──
class _IncomeExpenseCards extends StatelessWidget {
  final AppProvider p;
  const _IncomeExpenseCards({required this.p});

  @override
  Widget build(BuildContext context) {
    final income = p.totalIncomeThisMonth;
    final expense = p.totalExpensesThisMonth;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 320;

          final incomeCard = Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.emeraldGreen,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.forestGreen, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.forestGreen.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'INCOME',
                      style: TextStyle(
                        color: AppTheme.paleChampagne,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_downward, color: AppTheme.paleChampagne, size: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '₹${_fmt(income)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          );

          final expenseCard = Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.deepCrimson,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.antiqueGold, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.crimsonShadow.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'EXPENSES',
                      style: TextStyle(
                        color: AppTheme.paleChampagne,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_upward, color: AppTheme.paleChampagne, size: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '₹${_fmt(expense)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          );

          if (isNarrow) {
            return Column(
              children: [
                incomeCard,
                const SizedBox(height: 10),
                expenseCard,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: incomeCard),
              const SizedBox(width: 12),
              Expanded(child: expenseCard),
            ],
          );
        },
      ),
    );
  }
}

// ── D. Secondary Financial Indicators ──
class _SecondaryIndicators extends StatelessWidget {
  final AppProvider p;
  const _SecondaryIndicators({required this.p});

  @override
  Widget build(BuildContext context) {
    final savings = p.savingsRate.isFinite ? p.savingsRate : 0.0;
    final txCount = p.monthExpenses.length + p.monthIncomes.length;
    final dailyAvg = p.dailyAvgThisMonth;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _IndicatorChip(
            label: 'Savings',
            value: '${savings.toStringAsFixed(1)}%',
            valueColor: AppTheme.champagneGold,
            icon: Icons.savings_outlined,
          ),
          const SizedBox(width: 10),
          _IndicatorChip(
            label: 'Transactions',
            value: '$txCount',
            valueColor: AppTheme.paleChampagne,
            icon: Icons.receipt_long_outlined,
          ),
          const SizedBox(width: 10),
          _IndicatorChip(
            label: 'Daily Average',
            value: '₹${_fmt(dailyAvg)}',
            valueColor: AppTheme.paleChampagne,
            icon: Icons.calendar_today_outlined,
          ),
        ],
      ),
    );
  }
}

class _IndicatorChip extends StatelessWidget {
  final String label, value;
  final Color valueColor;
  final IconData icon;

  const _IndicatorChip({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: AppTheme.charcoalGrey,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.forestGreen, width: 0.8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: AppTheme.paleChampagne.withOpacity(0.7)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.paleChampagne,
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── E. AI Financial Coach Panel ──
class _AiCoachPanel extends StatelessWidget {
  final AppProvider p;
  const _AiCoachPanel({required this.p});

  @override
  Widget build(BuildContext context) {
    final savings = p.savingsRate;
    final topCat = p.categoryBreakdown.isNotEmpty
        ? (p.categoryBreakdown.entries.toList()..sort((a,b)=>b.value.compareTo(a.value))).first.key
        : 'discretionary items';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.charcoalGrey,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.antiqueGold, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: AppTheme.forestGreen.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dual boundary header: Emerald accent tag + Champagne Gold Sparkle
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.jetBlack,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.champagneGold, width: 0.8),
                ),
                child: const Icon(Icons.auto_awesome, color: AppTheme.champagneGold, size: 15),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Financial Coach',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      'Gemini & Groq Intelligence',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.paleChampagne,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.emeraldGreen.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.forestGreen, width: 0.8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, size: 11, color: AppTheme.champagneGold),
                    SizedBox(width: 4),
                    Text(
                      'ONLINE',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppTheme.champagneGold,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Dynamic analytical context
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.jetBlack,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.forestGreen, width: 0.6),
            ),
            child: Text(
              savings >= 20
                  ? 'Your savings rate is ${savings.toStringAsFixed(1)}%. Ask your coach how to optimize treasury allocations and growth.'
                  : 'Highest outflow is in $topCat. Tap Ask Coach to get proactive recommendations for spending control.',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.paleChampagne,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Primary Champagne Gold CTA: Ask Coach
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AiCoachScreen())),
                  icon: const Icon(Icons.chat_bubble_outline, size: 15, color: Colors.black),
                  label: const Text(
                    'Ask Coach',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.champagneGold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AiCoachScreen(
                      initialQuery: 'Provide a luxury portfolio and spending audit for this month',
                    ))),
                  icon: const Icon(Icons.bolt, size: 15, color: AppTheme.champagneGold),
                  label: const Text(
                    'Quick Audit',
                    style: TextStyle(
                      color: AppTheme.champagneGold,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.antiqueGold, width: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // AI Monthly Budget Planner Access Button
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AiBudgetPlannerScreen())),
              icon: const Icon(Icons.calculate_outlined, size: 14, color: AppTheme.paleChampagne),
              label: const Text(
                'AI Monthly Budget Planner →',
                style: TextStyle(
                  color: AppTheme.paleChampagne,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 6),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Spending Limit Bar ──
class _SpendingLimitBar extends StatelessWidget {
  final AppProvider p;
  const _SpendingLimitBar({required this.p});

  @override
  Widget build(BuildContext context) {
    final pct = p.monthlySpendLimit > 0
      ? (p.totalExpensesThisMonth / p.monthlySpendLimit * 100) : 0.0;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.charcoalGrey,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.forestGreen, width: 0.8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('MONTHLY LIMIT',
            style: TextStyle(
              color: AppTheme.paleChampagne,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            )),
          Text('₹${_fmt(p.totalExpensesThisMonth)} / ₹${_fmt(p.monthlySpendLimit)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            )),
        ]),
        const SizedBox(height: 8),
        BudgetBar(pct: pct.toDouble()),
      ]),
    );
  }
}

// ── F. Recent Transactions & Ornate Gold Empty State ──
class _RecentSection extends StatelessWidget {
  final AppProvider p;
  const _RecentSection({required this.p});

  @override
  Widget build(BuildContext context) {
    final byDay = p.transactionsByDay;
    final days = byDay.keys.take(3).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text(
            'Recent Transactions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const TransactionsScreen())),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'See all',
                  style: TextStyle(
                    color: AppTheme.champagneGold,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 2),
                Icon(Icons.chevron_right, size: 14, color: AppTheme.champagneGold),
              ],
            ),
          ),
        ]),
        if (days.isEmpty)
          // Intentional Ornate Restrained Gold Empty State
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: AppTheme.charcoalGrey,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.forestGreen, width: 1.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ornate restrained gold receipt icon with subtle decorative spark elements
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppTheme.jetBlack,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.antiqueGold, width: 1.2),
                      ),
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        size: 32,
                        color: AppTheme.champagneGold,
                      ),
                    ),
                    const Positioned(
                      top: 4,
                      right: 6,
                      child: Icon(Icons.auto_awesome, size: 14, color: AppTheme.paleChampagne),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Transactions Recorded',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.paleChampagne,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your financial ledger is clear for this period. Add an income or expense to begin tracking with luxury intelligence.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const AddTransactionSheet(),
                  ),
                  icon: const Icon(Icons.add, size: 16, color: Colors.black),
                  label: const Text(
                    'Add Transaction',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.champagneGold,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppTheme.charcoalGrey,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.forestGreen, width: 0.8),
            ),
            child: Column(children: [
              for (final day in days) ...[
                _DayGroup(day: day, items: byDay[day]!.take(3).toList()),
              ],
            ]),
          ),
      ]),
    );
  }
}

class _DayGroup extends StatelessWidget {
  final DateTime day; final List<dynamic> items;
  const _DayGroup({required this.day, required this.items});

  @override
  Widget build(BuildContext context) {
    final isToday = day == DateTime(DateTime.now().year,
      DateTime.now().month, DateTime.now().day);
    final dayTotal = items.fold<double>(0, (s, t) =>
      s + (t is Expense ? -t.amount : (t as Income).amount));

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(isToday ? 'Today' : formatDateShort(day),
              style: const TextStyle(
                color: AppTheme.paleChampagne,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              )),
            Text(
              '${dayTotal < 0 ? "-" : "+"}₹${_fmt(dayTotal.abs())}',
              style: TextStyle(
                color: dayTotal < 0 ? AppTheme.deepCrimson : AppTheme.emeraldGreen,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      ...items.map((t) => _TxRow(t: t)),
      const Divider(color: AppTheme.forestGreen, height: 1, thickness: 0.5),
    ]);
  }
}

class _TxRow extends StatelessWidget {
  final dynamic t;
  const _TxRow({required this.t});

  @override
  Widget build(BuildContext context) {
    final isExp = t is Expense;
    final cat = isExp ? (t as Expense).category : (t as Income).category;
    final name = isExp ? (t as Expense).name : (t as Income).source;
    final amt = isExp ? (t as Expense).amount : (t as Income).amount;
    final method = isExp ? (t as Expense).paymentMethod : (t as Income).paymentMethod;
    final color = AppTheme.getCategoryColor(cat);
    final p = context.read<AppProvider>();
    final iconData = categoryIconData(p.getCategoryIcon(cat));

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppTheme.jetBlack,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.5), width: 0.8),
        ),
        child: Icon(iconData, color: color, size: 18),
      ),
      title: Text(
        name,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      subtitle: Text(
        '$cat · $method',
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
      ),
      trailing: AmountText(amt, isExpense: isExp, fontSize: 13),
    );
  }
}

// ── Top Categories ──
class _TopCategories extends StatelessWidget {
  final AppProvider p;
  const _TopCategories({required this.p});

  @override
  Widget build(BuildContext context) {
    final cats = p.categoryBreakdown.entries.toList()
      ..sort((a,b) => b.value.compareTo(a.value));
    final top = cats.take(5).toList();
    if (top.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text(
          'Top Spending Categories',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.charcoalGrey,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.forestGreen, width: 0.8),
          ),
          child: Column(children: top.asMap().entries.map((e) {
            final idx = e.key; final cat = e.value;
            final pct = p.totalExpensesThisMonth > 0
              ? cat.value / p.totalExpensesThisMonth * 100 : 0;
            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 4),
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: AppTheme.jetBlack,
                child: Text(
                  '${idx+1}',
                  style: const TextStyle(
                    color: AppTheme.champagneGold,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                cat.key,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                '${pct.toStringAsFixed(1)}% of expenses',
                style: const TextStyle(
                  color: AppTheme.paleChampagne,
                  fontSize: 11,
                ),
              ),
              trailing: Text(
                '₹${_fmt(cat.value)}',
                style: const TextStyle(
                  color: AppTheme.champagneGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            );
          }).toList()),
        ),
      ]),
    );
  }
}

String _fmt(double v) => formatCompactNumber(v);
