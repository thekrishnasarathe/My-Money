import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import '../widgets/common_widgets.dart';
import '../models/expense.dart';
import '../models/income.dart';
import 'transactions/add_transaction_sheet.dart';
import 'ai_coach/ai_coach_screen.dart';
import 'ai_budget/ai_budget_planner_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (ctx, p, _) {
      final now = DateTime.now();
      final isCurrentMonth = p.selectedMonth == now.month &&
        p.selectedYear == now.year;

      return Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: p.refresh,
            color: AppTheme.primary,
            child: CustomScrollView(slivers: [
              // ── Header ──
              SliverToBoxAdapter(child: _Header(p: p)),
              // ── Balance card ──
              SliverToBoxAdapter(child: _BalanceCard(p: p)),
              // ── Quick stats ──
              SliverToBoxAdapter(child: _QuickStats(p: p)),
              // ── AI Coach Banner ──
              SliverToBoxAdapter(child: _AiCoachBanner(p: p)),
              // ── Spending limit bar ──
              if (p.monthlySpendLimit > 0)
                SliverToBoxAdapter(child: _SpendingLimitBar(p: p)),
              // ── Recent transactions ──
              SliverToBoxAdapter(child: _RecentSection(p: p)),
              // ── Top categories ──
              SliverToBoxAdapter(child: _TopCategories(p: p)),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ]),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => showModalBottomSheet(
            context: context, isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const AddTransactionSheet(),
          ),
          backgroundColor: AppTheme.primary,
          child: const Icon(Icons.add, color: Colors.black),
        ),
      );
    });
  }
}

class _Header extends StatelessWidget {
  final AppProvider p;
  const _Header({required this.p});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppConstants.appName, style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 2),
            MonthNavigator(
              month: p.selectedMonth, year: p.selectedYear,
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
        )),
        IconButton(
          onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AiCoachScreen())),
          tooltip: 'AI Financial Coach',
          icon: const Icon(Icons.auto_awesome, color: AppTheme.primary)),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.search, color: Colors.white)),
      ]),
    );
  }
}

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
    final income = isMonth ? p.totalIncomeThisMonth : p.totalIncomeAllTime;
    final expense = isMonth ? p.totalExpensesThisMonth : p.totalExpensesAllTime;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.cardDark2, AppTheme.cardDark],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                isMonth ? 'Monthly Net Balance' : 'Total Balance (All-Time)',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _viewMode = 0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isMonth ? AppTheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            size: 13,
                            color: isMonth ? Colors.black : Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text('This Month',
                            style: TextStyle(
                              color: isMonth ? Colors.black : Colors.white70,
                              fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _viewMode = 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: !isMonth ? AppTheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.all_inclusive_rounded,
                            size: 13,
                            color: !isMonth ? Colors.black : Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text('Total Balance',
                            style: TextStyle(
                              color: !isMonth ? Colors.black : Colors.white70,
                              fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '${balance < 0 ? "-" : ""}₹${_fmt(balance.abs())}',
          style: TextStyle(
            color: balance < 0 ? AppTheme.expenseRed : Colors.white,
            fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(children: [
          _MiniStat(label: 'Income', value: income,
            color: AppTheme.incomeGreen, icon: Icons.arrow_downward),
          const SizedBox(width: 16),
          _MiniStat(label: 'Expense', value: expense,
            color: AppTheme.expenseRed, icon: Icons.arrow_upward),
        ]),
        if (p.accounts.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Divider(color: AppTheme.divider, height: 1),
          const SizedBox(height: 10),
          Text('Top spend: ${_topCat(p)}',
            style: const TextStyle(color: AppTheme.textSecondary,
              fontSize: 12)),
        ],
      ]),
    );
  }

  String _topCat(AppProvider p) {
    if (p.categoryBreakdown.isEmpty) return '—';
    final sorted = p.categoryBreakdown.entries.toList()
      ..sort((a,b) => b.value.compareTo(a.value));
    return '${sorted.first.key}  ₹${_fmt(sorted.first.value)}';
  }
}

class _MiniStat extends StatelessWidget {
  final String label; final double value;
  final Color color; final IconData icon;
  const _MiniStat({required this.label, required this.value,
    required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(
            color: AppTheme.textSecondary, fontSize: 11)),
          Text('₹${_fmt(value)}',
            style: TextStyle(color: color, fontSize: 15,
              fontWeight: FontWeight.bold)),
        ]),
      ]),
    ));
  }
}

class _QuickStats extends StatelessWidget {
  final AppProvider p;
  const _QuickStats({required this.p});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: [
        _StatChip(label: 'Savings', value:
          '${p.savingsRate.toStringAsFixed(1)}%',
          color: AppTheme.primary),
        const SizedBox(width: 10),
        _StatChip(label: 'Transactions',
          value: '${p.monthExpenses.length + p.monthIncomes.length}',
          color: const Color(0xFF7C6FFF)),
        const SizedBox(width: 10),
        _StatChip(label: 'Daily Avg',
          value: '₹${_fmt(p.dailyAvgThisMonth)}',
          color: const Color(0xFFFFB547)),
      ]),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value; final Color color;
  const _StatChip({required this.label, required this.value,
    required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardDark, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider, width: 0.5)),
      child: Column(children: [
        Text(value, style: TextStyle(color: color,
          fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(
          color: AppTheme.textSecondary, fontSize: 10)),
      ]),
    ));
  }
}

class _AiCoachBanner extends StatelessWidget {
  final AppProvider p;
  const _AiCoachBanner({required this.p});

  @override
  Widget build(BuildContext context) {
    final savings = p.savingsRate;
    final topCat = p.categoryBreakdown.isNotEmpty
        ? (p.categoryBreakdown.entries.toList()..sort((a,b)=>b.value.compareTo(a.value))).first.key
        : 'spending';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0.16),
            AppTheme.cardDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.35), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'AI Financial Coach',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Gemini / Groq',
                  style: TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            savings >= 20
                ? 'Great job! Your savings rate is ${savings.toStringAsFixed(1)}%. Ask your coach how to optimize allocations.'
                : 'Highest outflow is in $topCat. Tap below to ask your coach how to reduce discretionary spend.',
            style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AiCoachScreen())),
                  icon: const Icon(Icons.chat_bubble_outline, size: 14, color: AppTheme.primary),
                  label: const Text('Ask Coach', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.primary.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AiCoachScreen(initialQuery: 'Summarize this month\'s spending'))),
                  icon: const Icon(Icons.bolt, size: 14, color: Colors.black),
                  label: const Text('Quick Audit', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AiBudgetPlannerScreen())),
              icon: const Icon(Icons.calculate_outlined, size: 14, color: Colors.white),
              label: const Text('AI Monthly Budget Planner',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withOpacity(0.25)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
        color: AppTheme.cardDark, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider, width: 0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Monthly Limit',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          Text('₹${_fmt(p.totalExpensesThisMonth)} / ₹${_fmt(p.monthlySpendLimit)}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 8),
        BudgetBar(pct: pct.toDouble()),
      ]),
    );
  }
}

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
          const Text('Recent', style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold)),
          TextButton(onPressed: () {}, child: const Text('See all',
            style: TextStyle(color: AppTheme.primary, fontSize: 12))),
        ]),
        if (days.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 16),
            child: EmptyState(icon: Icons.receipt_long_outlined,
              title: 'No transactions yet'))
        else
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16)),
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(isToday ? 'Today' : formatDateShort(day),
              style: const TextStyle(color: AppTheme.textSecondary,
                fontSize: 12, fontWeight: FontWeight.w600)),
            Text('₹${_fmt(dayTotal.abs())}',
              style: TextStyle(
                color: dayTotal < 0 ? AppTheme.expenseRed : AppTheme.incomeGreen,
                fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      ...items.map((t) => _TxRow(t: t)),
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
    final method = isExp ? (t as Expense).paymentMethod
      : (t as Income).paymentMethod;
    final color = AppTheme.getCategoryColor(cat);
    final p = context.read<AppProvider>();
    final iconData = categoryIconData(p.getCategoryIcon(cat));

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(iconData, color: color, size: 18),
      ),
      title: Text(name, style: const TextStyle(fontSize: 13,
        fontWeight: FontWeight.w500)),
      subtitle: Text('$cat · $method',
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      trailing: AmountText(amt, isExpense: isExp, fontSize: 13),
    );
  }
}

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
        const Text('Top Categories', style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(16)),
          child: Column(children: top.asMap().entries.map((e) {
            final idx = e.key; final cat = e.value;
            final color = AppTheme.getCategoryColor(cat.key);
            final pct = p.totalExpensesThisMonth > 0
              ? cat.value / p.totalExpensesThisMonth * 100 : 0;
            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 4),
              leading: CircleAvatar(radius: 14,
                backgroundColor: color.withOpacity(0.15),
                child: Text('${idx+1}',
                  style: TextStyle(color: color, fontSize: 12,
                    fontWeight: FontWeight.bold))),
              title: Text(cat.key, style: const TextStyle(fontSize: 13)),
              subtitle: Text('${pct.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11)),
              trailing: Text('₹${_fmt(cat.value)}',
                style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            );
          }).toList()),
        ),
      ]),
    );
  }
}

String _fmt(double v) => formatCompactNumber(v);
