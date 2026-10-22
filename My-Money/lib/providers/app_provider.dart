import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/financial_repository.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/debt.dart';
import '../models/models.dart';
import '../models/ai_budget_plan.dart';
import '../utils/constants.dart';

class AppProvider extends ChangeNotifier {
  final FinancialRepository _repo = FinancialRepository();

  bool _isLoading = false;
  String? _error;
  bool _isAppLocked = true;
  String _themeMode = 'dark'; // 'dark','light','auto'
  bool _isDarkMode = true;
  String _currency = AppConstants.defaultCurrency;
  double _monthlySpendLimit = 0;
  double _weeklySpendLimit = 0;
  bool _notifBudget = true;
  bool _notifRecurring = true;

  List<Expense> _expenses = [];
  List<Income> _incomes = [];
  List<Debt> _pendingDebts = [];
  List<Debt> _paidDebts = [];
  List<Account> _accounts = [];
  List<Budget> _budgets = [];
  List<RecurringExpense> _recurring = [];
  List<SavingsGoal> _goals = [];
  List<AppCategory> _categories = [];
  AiBudgetPlan? _activeBudgetPlan;
  List<AiBudgetPlan> _savedBudgetPlans = [];

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  // ── Memoized Caches for expensive getter calculations ──
  Map<DateTime, List<dynamic>>? _cachedTransactionsByDay;
  Map<String, double>? _cachedCategoryBreakdown;
  Map<String, double>? _cachedIncomeCategoryBreakdown;
  Map<String, double>? _cachedPaymentMethodBreakdown;
  List<Map<String, dynamic>>? _cachedSixMonthOverview;

  void _invalidateCaches() {
    _cachedTransactionsByDay = null;
    _cachedCategoryBreakdown = null;
    _cachedIncomeCategoryBreakdown = null;
    _cachedPaymentMethodBreakdown = null;
    _cachedSixMonthOverview = null;
  }

  // ── Getters ──
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAppLocked => _isAppLocked;
  bool get isDarkMode => _isDarkMode;
  String get themeMode => _themeMode;
  String get currency => _currency;
  double get monthlySpendLimit => _monthlySpendLimit;
  double get weeklySpendLimit => _weeklySpendLimit;
  bool get notifBudget => _notifBudget;
  bool get notifRecurring => _notifRecurring;

  List<Expense> get expenses => _expenses;
  List<Income> get incomes => _incomes;
  List<Debt> get pendingDebts => _pendingDebts;
  List<Debt> get paidDebts => _paidDebts;
  List<Account> get accounts => _accounts;
  List<Budget> get budgets => _budgets;
  List<RecurringExpense> get recurring => _recurring;
  List<SavingsGoal> get goals => _goals;
  List<AppCategory> get categories => _categories;
  AiBudgetPlan? get activeBudgetPlan => _activeBudgetPlan;
  List<AiBudgetPlan> get savedBudgetPlans => _savedBudgetPlans;

  int get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;

  // ── Month filtered ──
  List<Expense> get monthExpenses => _expenses.where(
    (e) => e.date.month == _selectedMonth && e.date.year == _selectedYear).toList();
  List<Income> get monthIncomes => _incomes.where(
    (i) => i.date.month == _selectedMonth && i.date.year == _selectedYear).toList();

  double get totalExpensesThisMonth =>
    monthExpenses.fold(0.0, (s,e) => s + e.amount);
  double get totalIncomeThisMonth =>
    monthIncomes.fold(0.0, (s,i) => s + i.amount);
  double get netBalanceThisMonth => totalIncomeThisMonth - totalExpensesThisMonth;
  double get totalExpensesAllTime => _expenses.fold(0.0, (s, e) => s + e.amount);
  double get totalIncomeAllTime => _incomes.fold(0.0, (s, i) => s + i.amount);
  double get totalBalanceAllTime => totalIncomeAllTime - totalExpensesAllTime;
  double get savingsRate => totalIncomeThisMonth > 0
    ? ((netBalanceThisMonth / totalIncomeThisMonth) * 100) : 0;
  double get totalPendingDebt =>
    _pendingDebts.fold(0.0, (s,d) => s + d.remaining);
  double get totalBalance => _accounts.fold(0.0, (s,a) => s + a.balance);

  // ── Daily avg spend this month ──
  double get dailyAvgThisMonth {
    final day = DateTime.now().day;
    return day > 0 ? totalExpensesThisMonth / day : 0;
  }

  // ── Category breakdown (Memoized) ──
  Map<String,double> get categoryBreakdown {
    if (_cachedCategoryBreakdown != null) return _cachedCategoryBreakdown!;
    final map = <String,double>{};
    for (final e in monthExpenses) {
      map[e.category] = (map[e.category]??0) + e.amount;
    }
    _cachedCategoryBreakdown = map;
    return map;
  }

  Map<String,double> get incomeCategoryBreakdown {
    if (_cachedIncomeCategoryBreakdown != null) return _cachedIncomeCategoryBreakdown!;
    final map = <String,double>{};
    for (final i in monthIncomes) {
      map[i.category] = (map[i.category]??0) + i.amount;
    }
    _cachedIncomeCategoryBreakdown = map;
    return map;
  }

  // ── Payment method breakdown (Memoized) ──
  Map<String,double> get paymentMethodBreakdown {
    if (_cachedPaymentMethodBreakdown != null) return _cachedPaymentMethodBreakdown!;
    final map = <String,double>{};
    for (final e in monthExpenses) {
      map[e.paymentMethod] = (map[e.paymentMethod]??0) + e.amount;
    }
    _cachedPaymentMethodBreakdown = map;
    return map;
  }

  // ── Top spends (sorted) ──
  List<Expense> get topSpends {
    final list = [...monthExpenses];
    list.sort((a,b) => b.amount.compareTo(a.amount));
    return list.take(10).toList();
  }

  // ── Daily spending for current month (day → total) ──
  Map<int,double> get dailySpendingMap {
    final map = <int,double>{};
    for (final e in monthExpenses) {
      map[e.date.day] = (map[e.date.day]??0) + e.amount;
    }
    return map;
  }

  // ── Weekday spending (0=Mon..6=Sun) ──
  Map<int,double> get weekdaySpendingMap {
    final map = <int,double>{};
    for (final e in monthExpenses) {
      final wd = e.date.weekday - 1; // 0=Mon
      map[wd] = (map[wd]??0) + e.amount;
    }
    return map;
  }

  // ── 6-month overview (Memoized) ──
  List<Map<String,dynamic>> get sixMonthOverview {
    if (_cachedSixMonthOverview != null) return _cachedSixMonthOverview!;
    final result = <Map<String,dynamic>>[];
    for (int i = 5; i >= 0; i--) {
      DateTime d = DateTime(_selectedYear, _selectedMonth - i, 1);
      if (d.month < 1) d = DateTime(d.year - 1, d.month + 12, 1);
      final exp = _expenses.where((e) =>
        e.date.month == d.month && e.date.year == d.year)
        .fold(0.0, (s,e) => s + e.amount);
      final inc = _incomes.where((i) =>
        i.date.month == d.month && i.date.year == d.year)
        .fold(0.0, (s,i) => s + i.amount);
      result.add({'month': d, 'expense': exp, 'income': inc});
    }
    _cachedSixMonthOverview = result;
    return result;
  }

  // ── Grouped by day for transactions view (Memoized) ──
  Map<DateTime,List<dynamic>> get transactionsByDay {
    if (_cachedTransactionsByDay != null) return _cachedTransactionsByDay!;
    final map = <DateTime,List<dynamic>>{};
    for (final e in _expenses) {
      final k = DateTime(e.date.year,e.date.month,e.date.day);
      map.putIfAbsent(k,()=>[]).add(e);
    }
    for (final i in _incomes) {
      final k = DateTime(i.date.year,i.date.month,i.date.day);
      map.putIfAbsent(k,()=>[]).add(i);
    }
    for (final k in map.keys) {
      map[k]!.sort((a,b) {
        final da = a is Expense ? a.date : (a as Income).date;
        final db2 = b is Expense ? b.date : (b as Income).date;
        return db2.compareTo(da);
      });
    }
    final sortedMap = Map.fromEntries(
      map.entries.toList()..sort((a,b) => b.key.compareTo(a.key)));
    _cachedTransactionsByDay = sortedMap;
    return sortedMap;
  }

  // ── Budget progress ──
  Map<String,Map<String,double>> getBudgetProgress() {
    final result = <String,Map<String,double>>{};
    final cat = categoryBreakdown;
    for (final b in _budgets) {
      if (b.month==_selectedMonth && b.year==_selectedYear) {
        final spent = cat[b.category]??0;
        result[b.category] = {
          'monthly_limit': b.monthlyLimit,
          'weekly_limit': b.weeklyLimit,
          'spent': spent,
          'pct': b.monthlyLimit>0 ? (spent/b.monthlyLimit)*100 : 0,
          'alert': b.alertPercentage,
        };
      }
    }
    return result;
  }

  // ── Categories by type ──
  String getCategoryIcon(String categoryName) {
    final cat = _categories.where((c) => c.name == categoryName).toList();
    if (cat.isNotEmpty && cat.first.icon.isNotEmpty) {
      return cat.first.icon;
    }
    return AppConstants.categoryIcons[categoryName] ?? 'category';
  }

  List<AppCategory> expenseCategories() {
    final list = _categories.where((c) => c.type == 'Expense').toList();
    if (list.isNotEmpty) return list;
    return AppConstants.defaultExpenseCategories.map((name) => AppCategory(
      name: name,
      type: 'Expense',
      color: '#E53935',
      icon: AppConstants.categoryIcons[name] ?? 'category',
      isDefault: true,
      createdAt: DateTime.now(),
    )).toList();
  }

  List<AppCategory> incomeCategories() {
    final list = _categories.where((c) => c.type == 'Income').toList();
    if (list.isNotEmpty) return list;
    return AppConstants.defaultIncomeCategories.map((name) => AppCategory(
      name: name,
      type: 'Income',
      color: '#43A047',
      icon: AppConstants.categoryIcons[name] ?? 'payments',
      isDefault: true,
      createdAt: DateTime.now(),
    )).toList();
  }

  // ── INIT ──
  Future<void> init() async {
    _setLoading(true);
    try {
      final p = await SharedPreferences.getInstance();
      _themeMode = p.getString(AppConstants.kThemeMode) ?? 'dark';
      _isDarkMode = _themeMode == 'dark' ||
        (_themeMode == 'auto');
      _currency = p.getString(AppConstants.kCurrency) ?? AppConstants.defaultCurrency;
      _monthlySpendLimit = p.getDouble(AppConstants.kMonthlySpendLimit) ?? 0;
      _weeklySpendLimit = p.getDouble(AppConstants.kWeeklySpendLimit) ?? 0;
      _notifBudget = p.getBool(AppConstants.kNotifBudget) ?? true;
      _notifRecurring = p.getBool(AppConstants.kNotifRecurring) ?? true;
      await _repo.processDueRecurring();
      await _loadAllData();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadAllData() async {
    _expenses = await _repo.getExpenses();
    _incomes = await _repo.getIncomes();
    _pendingDebts = await _repo.getPendingDebts();
    _paidDebts = await _repo.getPaidDebts();
    _accounts = await _repo.getAccounts();
    _budgets = await _repo.getBudgetsByMonth(_selectedMonth, _selectedYear);
    _recurring = await _repo.getRecurring();
    _goals = await _repo.getGoals();
    _categories = await _repo.getCategories();
    _activeBudgetPlan = await _repo.getLatestAiBudgetPlan();
    _savedBudgetPlans = await _repo.getAiBudgetPlans();
    _invalidateCaches();
    notifyListeners();
  }

  void unlockApp() { _isAppLocked = false; notifyListeners(); }
  void lockApp() { _isAppLocked = true; notifyListeners(); }

  void setSelectedMonthYear(int month, int year) {
    _selectedMonth = month; _selectedYear = year; _loadAllData();
  }

  Future<void> setThemeMode(String mode) async {
    _themeMode = mode;
    _isDarkMode = mode == 'dark' || mode == 'auto';
    final p = await SharedPreferences.getInstance();
    await p.setString(AppConstants.kThemeMode, mode);
    notifyListeners();
  }

  void toggleTheme() => setThemeMode(_isDarkMode ? 'light' : 'dark');

  Future<void> setSpendLimits(double monthly, double weekly) async {
    _monthlySpendLimit = monthly; _weeklySpendLimit = weekly;
    final p = await SharedPreferences.getInstance();
    await p.setDouble(AppConstants.kMonthlySpendLimit, monthly);
    await p.setDouble(AppConstants.kWeeklySpendLimit, weekly);
    notifyListeners();
  }

  Future<void> setNotifications(bool budget, bool recurring) async {
    _notifBudget = budget; _notifRecurring = recurring;
    final p = await SharedPreferences.getInstance();
    await p.setBool(AppConstants.kNotifBudget, budget);
    await p.setBool(AppConstants.kNotifRecurring, recurring);
    notifyListeners();
  }

  // ── EXPENSE CRUD (Incremental State Updates) ──
  Future<void> addExpense(Expense e) async {
    final id = await _repo.addExpense(e);
    _expenses.insert(0, e.copyWith(id: id));
    _invalidateCaches();
    notifyListeners();
  }

  Future<void> updateExpense(Expense e) async {
    await _repo.updateExpense(e);
    final idx = _expenses.indexWhere((x) => x.id == e.id);
    if (idx != -1) _expenses[idx] = e;
    _invalidateCaches();
    notifyListeners();
  }

  Future<void> deleteExpense(int id) async {
    await _repo.deleteExpense(id);
    _expenses.removeWhere((x) => x.id == id);
    _invalidateCaches();
    notifyListeners();
  }

  // ── INCOME CRUD (Incremental State Updates) ──
  Future<void> addIncome(Income i) async {
    final id = await _repo.addIncome(i);
    _incomes.insert(0, i.copyWith(id: id));
    _invalidateCaches();
    notifyListeners();
  }

  Future<void> updateIncome(Income i) async {
    await _repo.updateIncome(i);
    final idx = _incomes.indexWhere((x) => x.id == i.id);
    if (idx != -1) _incomes[idx] = i;
    _invalidateCaches();
    notifyListeners();
  }

  Future<void> deleteIncome(int id) async {
    await _repo.deleteIncome(id);
    _incomes.removeWhere((x) => x.id == id);
    _invalidateCaches();
    notifyListeners();
  }

  // ── DEBT CRUD (Incremental State Updates) ──
  Future<void> addDebt(Debt d) async {
    final id = await _repo.addDebt(d);
    final newDebt = d.copyWith(id: id);
    if (newDebt.status == 'Paid') {
      _paidDebts.insert(0, newDebt);
    } else {
      _pendingDebts.insert(0, newDebt);
    }
    notifyListeners();
  }

  Future<void> updateDebt(Debt d) async {
    await _repo.updateDebt(d);
    _pendingDebts.removeWhere((x) => x.id == d.id);
    _paidDebts.removeWhere((x) => x.id == d.id);
    if (d.status == 'Paid') {
      _paidDebts.insert(0, d);
    } else {
      _pendingDebts.insert(0, d);
    }
    notifyListeners();
  }

  Future<void> makeDebtPayment(int debtId, double amt) async {
    final all = [..._pendingDebts, ..._paidDebts];
    final d = all.firstWhere((x) => x.id == debtId);
    final paid = d.paidAmount + amt;
    final updated = d.copyWith(
      paidAmount: paid, status: paid >= d.amount ? 'Paid' : 'Partially Paid');
    await updateDebt(updated);
  }

  Future<void> deleteDebt(int id) async {
    await _repo.deleteDebt(id);
    _pendingDebts.removeWhere((x) => x.id == id);
    _paidDebts.removeWhere((x) => x.id == id);
    notifyListeners();
  }

  // ── ACCOUNT CRUD (Incremental State Updates) ──
  Future<void> addAccount(Account a) async {
    final id = await _repo.addAccount(a);
    _accounts.add(a.copyWith(id: id));
    notifyListeners();
  }

  Future<void> updateAccount(Account a) async {
    await _repo.updateAccount(a);
    final idx = _accounts.indexWhere((x) => x.id == a.id);
    if (idx != -1) _accounts[idx] = a;
    notifyListeners();
  }

  Future<void> deleteAccount(int id) async {
    await _repo.deleteAccount(id);
    _accounts.removeWhere((x) => x.id == id);
    notifyListeners();
  }

  // ── BUDGET CRUD (Incremental State Updates) ──
  Future<void> addBudget(Budget b) async {
    final id = await _repo.addBudget(b);
    _budgets.add(b.copyWith(id: id));
    notifyListeners();
  }

  Future<void> updateBudget(Budget b) async {
    await _repo.updateBudget(b);
    final idx = _budgets.indexWhere((x) => x.id == b.id);
    if (idx != -1) _budgets[idx] = b;
    notifyListeners();
  }

  Future<void> deleteBudget(int id) async {
    await _repo.deleteBudget(id);
    _budgets.removeWhere((x) => x.id == id);
    notifyListeners();
  }

  // ── RECURRING CRUD (Incremental State Updates) ──
  Future<void> addRecurring(RecurringExpense r) async {
    final id = await _repo.addRecurring(r);
    _recurring.add(r.copyWith(id: id));
    notifyListeners();
  }

  Future<void> updateRecurring(RecurringExpense r) async {
    await _repo.updateRecurring(r);
    final idx = _recurring.indexWhere((x) => x.id == r.id);
    if (idx != -1) _recurring[idx] = r;
    notifyListeners();
  }

  Future<void> deleteRecurring(int id) async {
    await _repo.deleteRecurring(id);
    _recurring.removeWhere((x) => x.id == id);
    notifyListeners();
  }

  // ── GOALS CRUD (Incremental State Updates) ──
  Future<void> addGoal(SavingsGoal g) async {
    final id = await _repo.addGoal(g);
    _goals.insert(0, g.copyWith(id: id));
    notifyListeners();
  }

  Future<void> updateGoal(SavingsGoal g) async {
    await _repo.updateGoal(g);
    final idx = _goals.indexWhere((x) => x.id == g.id);
    if (idx != -1) _goals[idx] = g;
    notifyListeners();
  }

  Future<void> deleteGoal(int id) async {
    await _repo.deleteGoal(id);
    _goals.removeWhere((x) => x.id == id);
    notifyListeners();
  }

  // ── CATEGORY CRUD (Incremental State Updates) ──
  Future<void> addCategory(AppCategory c) async {
    final id = await _repo.addCategory(c);
    _categories.add(c.copyWith(id: id));
    notifyListeners();
  }

  Future<void> updateCategory(AppCategory c) async {
    await _repo.updateCategory(c);
    final idx = _categories.indexWhere((x) => x.id == c.id);
    if (idx != -1) _categories[idx] = c;
    notifyListeners();
  }

  Future<void> deleteCategory(int id) async {
    await _repo.deleteCategory(id);
    _categories.removeWhere((x) => x.id == id);
    notifyListeners();
  }

  Future<void> addMissingDefaultCategories() async {
    final existing = _categories.map((c) => '${c.type}:${c.name}').toSet();
    final now = DateTime.now();
    for (final name in AppConstants.defaultExpenseCategories) {
      if (!existing.contains('Expense:$name')) {
        final cat = AppCategory(name: name, type: 'Expense', createdAt: now);
        final id = await _repo.addCategory(cat);
        _categories.add(cat.copyWith(id: id));
      }
    }
    for (final name in AppConstants.defaultIncomeCategories) {
      if (!existing.contains('Income:$name')) {
        final cat = AppCategory(name: name, type: 'Income', createdAt: now);
        final id = await _repo.addCategory(cat);
        _categories.add(cat.copyWith(id: id));
      }
    }
    notifyListeners();
  }

  // ── AI BUDGET PLANNER CRUD ──
  void setActiveBudgetPlan(AiBudgetPlan? plan) {
    _activeBudgetPlan = plan;
    notifyListeners();
  }

  Future<void> saveAiBudgetPlan(AiBudgetPlan plan) async {
    final id = await _repo.saveAiBudgetPlan(plan);
    final saved = plan.copyWith(id: id);
    _activeBudgetPlan = saved;
    _savedBudgetPlans = await _repo.getAiBudgetPlans();
    notifyListeners();
  }

  Future<void> deleteAiBudgetPlan(int id) async {
    await _repo.deleteAiBudgetPlan(id);
    _savedBudgetPlans.removeWhere((p) => p.id == id);
    if (_activeBudgetPlan?.id == id) {
      _activeBudgetPlan = _savedBudgetPlans.isNotEmpty ? _savedBudgetPlans.first : null;
    }
    notifyListeners();
  }

  Future<void> applyAiBudgetPlanToBudgets(AiBudgetPlan plan, {int? month, int? year}) async {
    final m = month ?? _selectedMonth;
    final y = year ?? _selectedYear;
    await _repo.applyPlanToMonthlyBudgets(plan, m, y);
    await saveAiBudgetPlan(plan);
    _budgets = await _repo.getBudgetsByMonth(_selectedMonth, _selectedYear);
    _invalidateCaches();
    notifyListeners();
  }

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
  void clearError() { _error = null; notifyListeners(); }
  Future<void> refresh() => _loadAllData();
}
