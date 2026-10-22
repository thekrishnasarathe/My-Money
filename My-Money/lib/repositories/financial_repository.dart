import '../database/db_helper.dart';
import '../services/session_manager.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/debt.dart';
import '../models/models.dart';

/// Centralized Financial Repository enforcing multi-user isolation
/// and abstraction over database operations.
class FinancialRepository {
  final DbHelper _db = DbHelper();
  final SessionManager _session = SessionManager();

  String get _currentUserId => _session.activeUserId;

  // ── TOTAL BALANCE ──
  Future<double> getTotalBalance() =>
    _db.getTotalBalance(userId: _currentUserId);

  // ── EXPENSES ──
  Future<int> addExpense(Expense e) =>
    _db.insertExpense(e.copyWith(userId: _currentUserId));

  Future<List<Expense>> getExpenses() =>
    _db.getAllExpenses(userId: _currentUserId);

  Future<List<Expense>> getExpensesByMonth(int month, int year) =>
    _db.getExpensesByMonth(month, year, userId: _currentUserId);

  Future<int> updateExpense(Expense e) =>
    _db.updateExpense(e.copyWith(userId: _currentUserId));

  Future<int> deleteExpense(int id) =>
    _db.deleteExpense(id, userId: _currentUserId);

  // ── INCOMES ──
  Future<int> addIncome(Income i) =>
    _db.insertIncome(i.copyWith(userId: _currentUserId));

  Future<List<Income>> getIncomes() =>
    _db.getAllIncomes(userId: _currentUserId);

  Future<List<Income>> getIncomesByMonth(int month, int year) =>
    _db.getIncomesByMonth(month, year, userId: _currentUserId);

  Future<int> updateIncome(Income i) =>
    _db.updateIncome(i.copyWith(userId: _currentUserId));

  Future<int> deleteIncome(int id) =>
    _db.deleteIncome(id, userId: _currentUserId);

  // ── DEBTS ──
  Future<int> addDebt(Debt d) =>
    _db.insertDebt(d.copyWith(userId: _currentUserId));

  Future<List<Debt>> getPendingDebts() =>
    _db.getPendingDebts(userId: _currentUserId);

  Future<List<Debt>> getPaidDebts() =>
    _db.getPaidDebts(userId: _currentUserId);

  Future<int> updateDebt(Debt d) =>
    _db.updateDebt(d.copyWith(userId: _currentUserId));

  Future<int> deleteDebt(int id) =>
    _db.deleteDebt(id, userId: _currentUserId);

  // ── ACCOUNTS ──
  Future<int> addAccount(Account a) =>
    _db.insertAccount(a.copyWith(userId: _currentUserId));

  Future<List<Account>> getAccounts() =>
    _db.getAllAccounts(userId: _currentUserId);

  Future<int> updateAccount(Account a) =>
    _db.updateAccount(a.copyWith(userId: _currentUserId));

  Future<int> deleteAccount(int id) =>
    _db.deleteAccount(id, userId: _currentUserId);

  // ── BUDGETS ──
  Future<int> addBudget(Budget b) =>
    _db.insertBudget(b.copyWith(userId: _currentUserId));

  Future<List<Budget>> getBudgetsByMonth(int month, int year) =>
    _db.getBudgetsByMonth(month, year, userId: _currentUserId);

  Future<int> updateBudget(Budget b) =>
    _db.updateBudget(b.copyWith(userId: _currentUserId));

  Future<int> deleteBudget(int id) =>
    _db.deleteBudget(id, userId: _currentUserId);

  // ── RECURRING ──
  Future<int> addRecurring(RecurringExpense r) =>
    _db.insertRecurring(r.copyWith(userId: _currentUserId));

  Future<List<RecurringExpense>> getRecurring() =>
    _db.getAllRecurring(userId: _currentUserId);

  Future<int> updateRecurring(RecurringExpense r) =>
    _db.updateRecurring(r.copyWith(userId: _currentUserId));

  Future<int> deleteRecurring(int id) =>
    _db.deleteRecurring(id, userId: _currentUserId);

  // ── CATEGORIES ──
  Future<int> addCategory(AppCategory c) =>
    _db.insertCategory(c.copyWith(userId: _currentUserId));

  Future<List<AppCategory>> getCategories() =>
    _db.getAllCategories(userId: _currentUserId);

  Future<int> updateCategory(AppCategory c) =>
    _db.updateCategory(c.copyWith(userId: _currentUserId));

  Future<int> deleteCategory(int id) =>
    _db.deleteCategory(id, userId: _currentUserId);

  // ── GOALS ──
  Future<int> addGoal(SavingsGoal g) =>
    _db.insertGoal(g.copyWith(userId: _currentUserId));

  Future<List<SavingsGoal>> getGoals() =>
    _db.getAllGoals(userId: _currentUserId);

  Future<int> updateGoal(SavingsGoal g) =>
    _db.updateGoal(g.copyWith(userId: _currentUserId));

  Future<int> deleteGoal(int id) =>
    _db.deleteGoal(id, userId: _currentUserId);

  // ── RECURRING CRON PROCESS ──
  Future<void> processDueRecurring() =>
    _db.processDueRecurring(userId: _currentUserId);
}
