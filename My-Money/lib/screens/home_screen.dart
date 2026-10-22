import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import 'dashboard_screen.dart';
import 'transactions/transactions_screen.dart';
import 'analytics/analytics_screen.dart';
import 'categories/categories_screen.dart';
import 'expenses/expenses_screen.dart';
import 'budgets/budgets_goals_screen.dart';
import 'accounts/accounts_reports_screen.dart';
import 'more/spending_control_screen.dart';
import 'more/data_screen.dart';
import 'more/preferences_screen.dart';
import 'more/security_screen.dart';
import 'about_screen.dart';
import 'debts/debts_screen.dart';
import 'ai_coach/ai_coach_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _idx = 0;

  static const _navItems = [
    _NavItem(Icons.home_outlined, Icons.home, 'Home'),
    _NavItem(Icons.auto_awesome_outlined, Icons.auto_awesome, 'AI Coach'),
    _NavItem(Icons.receipt_long_outlined, Icons.receipt_long, 'Transactions'),
    _NavItem(Icons.pie_chart_outline, Icons.pie_chart, 'Analytics'),
    _NavItem(Icons.grid_view_outlined, Icons.grid_view, 'Categories'),
    _NavItem(Icons.bar_chart_outlined, Icons.bar_chart, 'Expenses'),
    _NavItem(Icons.handshake_outlined, Icons.handshake, 'Debts'),
    _NavItem(Icons.savings_outlined, Icons.savings, 'Budgets'),
    _NavItem(Icons.account_balance_wallet_outlined,
      Icons.account_balance_wallet, 'Accounts'),
    _NavItem(Icons.shield_outlined, Icons.shield, 'Limits'),
    _NavItem(Icons.import_export_outlined, Icons.import_export, 'Data'),
    _NavItem(Icons.settings_outlined, Icons.settings, 'Settings'),
  ];

  static const _pages = [
    DashboardScreen(),
    AiCoachScreen(),
    TransactionsScreen(),
    AnalyticsScreen(),
    CategoriesScreen(),
    ExpensesTrackerScreen(),
    DebtsScreen(),
    BudgetsGoalsScreen(),
    AccountsReportsScreen(),
    SpendingControlScreen(),
    DataScreen(),
    _SettingsHub(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
      context.read<AppProvider>().refresh());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: _pages),
      bottomNavigationBar: _ScrollableNav(
        items: _navItems,
        selectedIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
      ),
    );
  }
}

class _NavItem {
  final IconData icon, activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

class _ScrollableNav extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const _ScrollableNav({required this.items,
    required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const itemWidth = 72.0;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        border: const Border(top: BorderSide(color: AppTheme.divider, width: 0.5)),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 12, offset: const Offset(0,-2))],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: items.asMap().entries.map((e) {
            final i = e.key; final item = e.value;
            final active = i == selectedIndex;
            final color = active ? AppTheme.primary : AppTheme.textSecondary;
            return GestureDetector(
              onTap: () => onTap(i),
              child: Container(
                width: itemWidth,
                padding: EdgeInsets.only(top: 10, bottom: 10 + bottomPad),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(active ? item.activeIcon : item.icon,
                      key: ValueKey(active),
                      color: color, size: 22)),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(color: color, fontSize: 10,
                      fontWeight: active ? FontWeight.w600 : FontWeight.normal),
                    child: Text(item.label,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center)),
                  const SizedBox(height: 3),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: active ? 20 : 0, height: 3,
                    decoration: BoxDecoration(
                      color: active ? AppTheme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(2))),
                ]),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// Settings hub screen (Preferences + Security + About)
class _SettingsHub extends StatelessWidget {
  const _SettingsHub();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Settings', style: TextStyle(fontSize: 24,
            fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _S('PREFERENCES', [
            _I(context, Icons.palette_outlined, 'Theme & Notifications',
              'Appearance and alert settings',
              const PreferencesScreen()),
          ]),
          const SizedBox(height: 14),
          _S('SECURITY', [
            _I(context, Icons.lock_outline, 'Security & PIN',
              'Protect app with 4-digit PIN',
              const SecurityScreen()),
          ]),
          const SizedBox(height: 14),
          _S('INFO', [
            _I(context, Icons.info_outline, 'About ${AppConstants.appName}',
              'v2.0.0 — Personal finance tracker',
              const AboutScreen()),
          ]),
        ]),
      )),
    );
  }
}

Widget _S(String title, List<Widget> items) => Column(
  crossAxisAlignment: CrossAxisAlignment.start, children: [
  Text(title, style: const TextStyle(color: AppTheme.textSecondary,
    fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
  const SizedBox(height: 8),
  Container(decoration: BoxDecoration(color: AppTheme.cardDark,
    borderRadius: BorderRadius.circular(14)),
  child: Column(children: items)),
]);

Widget _I(BuildContext ctx, IconData icon, String title, String sub, Widget dest) =>
  ListTile(
    leading: Container(width: 38, height: 38,
      decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: AppTheme.primary, size: 20)),
    title: Text(title, style: const TextStyle(fontSize: 14,
      fontWeight: FontWeight.w500)),
    subtitle: Text(sub, style: const TextStyle(
      color: AppTheme.textSecondary, fontSize: 11)),
    trailing: const Icon(Icons.chevron_right,
      color: AppTheme.textSecondary, size: 18),
    onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => dest)));
