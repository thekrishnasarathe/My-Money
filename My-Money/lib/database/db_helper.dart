import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/debt.dart';
import '../models/models.dart';
import '../models/ai_budget_plan.dart';

class DbHelper {
  static final DbHelper _instance = DbHelper._internal();
  factory DbHelper() => _instance;
  DbHelper._internal();

  static Database? _db;
  static const int _dbVersion = 5;
  static const String _dbName = 'money.db';
  static const String _oldDbName = 'mera_paisa.db';

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbDir = await getDatabasesPath();
    final path = join(dbDir, _dbName);
    final oldPath = join(dbDir, _oldDbName);
    try {
      if (!await File(path).exists() && await File(oldPath).exists()) {
        await File(oldPath).copy(path);
      }
    } catch (_) {}
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
        try {
          await db.execute('PRAGMA journal_mode = WAL;');
        } catch (_) {}
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createAllTables(db);
    await _insertDefaultCategories(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try { await db.execute('ALTER TABLE expenses ADD COLUMN payment_method TEXT DEFAULT "UPI"'); } catch(_){}
      try { await db.execute('ALTER TABLE expenses ADD COLUMN description TEXT DEFAULT ""'); } catch(_){}
      try { await db.execute('ALTER TABLE expenses ADD COLUMN tags TEXT DEFAULT ""'); } catch(_){}
      try { await db.execute('ALTER TABLE incomes ADD COLUMN payment_method TEXT DEFAULT "Bank"'); } catch(_){}
      try { await db.execute('ALTER TABLE incomes ADD COLUMN description TEXT DEFAULT ""'); } catch(_){}
      try { await db.execute('ALTER TABLE incomes ADD COLUMN tags TEXT DEFAULT ""'); } catch(_){}
      try { await db.execute('ALTER TABLE accounts ADD COLUMN color TEXT DEFAULT "#1B8A5A"'); } catch(_){}
      try { await db.execute('ALTER TABLE accounts ADD COLUMN icon TEXT DEFAULT "wallet"'); } catch(_){}
      try { await db.execute('ALTER TABLE budgets ADD COLUMN weekly_limit REAL DEFAULT 0'); } catch(_){}
    }
    if (oldVersion < 3) {
      try {
        await db.execute('''CREATE TABLE IF NOT EXISTS categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
          type TEXT NOT NULL, color TEXT DEFAULT "#1B8A5A",
          icon TEXT DEFAULT "category", is_default INTEGER DEFAULT 0,
          created_at INTEGER NOT NULL)''');
        await db.execute('''CREATE TABLE IF NOT EXISTS savings_goals (
          id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
          target_amount REAL NOT NULL, saved_amount REAL DEFAULT 0,
          color TEXT DEFAULT "#1B8A5A", icon TEXT DEFAULT "star",
          deadline INTEGER, created_at INTEGER NOT NULL)''');
        await db.execute('''CREATE TABLE IF NOT EXISTS recurring_v2 (
          id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
          amount REAL NOT NULL, category TEXT NOT NULL,
          transaction_type TEXT DEFAULT "Expense",
          frequency TEXT DEFAULT "Monthly",
          account_id INTEGER, is_active INTEGER DEFAULT 1,
          last_processed INTEGER, created_at INTEGER NOT NULL)''');
        try {
          final old = await db.query('recurring_expenses');
          for (final r in old) {
            await db.insert('recurring_v2', {
              'name': r['name'], 'amount': r['amount'],
              'category': r['category'], 'transaction_type': r['type'] ?? 'Expense',
              'frequency': 'Monthly', 'account_id': r['account_id'],
              'is_active': r['is_active'], 'last_processed': r['last_processed'],
              'created_at': r['created_at'],
            });
          }
        } catch(_){}
      } catch(_){}
      await _insertDefaultCategories(db);
    }
    if (oldVersion < 4) {
      // Add user_id column to all tables for multi-user isolation
      final tables = [
        'expenses', 'incomes', 'debts', 'accounts',
        'budgets', 'recurring_v2', 'categories', 'savings_goals'
      ];
      for (final t in tables) {
        try {
          await db.execute('ALTER TABLE $t ADD COLUMN user_id TEXT NOT NULL DEFAULT "default_user"');
        } catch (_) {}
      }
      // Create performance composite indexes
      try { await db.execute('CREATE INDEX IF NOT EXISTS idx_exp_user_date ON expenses(user_id, date)'); } catch(_){}
      try { await db.execute('CREATE INDEX IF NOT EXISTS idx_inc_user_date ON incomes(user_id, date)'); } catch(_){}
      try { await db.execute('CREATE INDEX IF NOT EXISTS idx_exp_user_cat ON expenses(user_id, category)'); } catch(_){}
      try { await db.execute('CREATE INDEX IF NOT EXISTS idx_bud_user_mon ON budgets(user_id, month, year)'); } catch(_){}
    }
    if (oldVersion < 5) {
      try {
        await db.execute('''CREATE TABLE IF NOT EXISTS ai_budget_plans (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id TEXT NOT NULL DEFAULT "default_user",
          summary TEXT NOT NULL,
          currency TEXT NOT NULL DEFAULT "INR",
          monthly_income REAL NOT NULL,
          feasibility_status TEXT NOT NULL DEFAULT "feasible",
          deficit REAL DEFAULT 0,
          allocations_json TEXT NOT NULL,
          total_essential REAL NOT NULL,
          total_lifestyle REAL NOT NULL,
          total_savings REAL NOT NULL,
          unallocated_balance REAL DEFAULT 0,
          savings_percentage REAL DEFAULT 0,
          ai_explanation TEXT NOT NULL,
          assumptions_json TEXT DEFAULT "[]",
          financial_warnings_json TEXT DEFAULT "[]",
          savings_recommendation TEXT DEFAULT "",
          provider TEXT DEFAULT "gemini",
          model TEXT DEFAULT "gemini-1.5-flash",
          is_offline_fallback INTEGER DEFAULT 0,
          input_json TEXT DEFAULT "",
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_ai_plan_user ON ai_budget_plans(user_id, created_at)');
      } catch (_) {}
    }
  }

  Future<void> _createAllTables(Database db) async {
    await db.execute('''CREATE TABLE expenses (
      id INTEGER PRIMARY KEY AUTOINCREMENT, user_id TEXT NOT NULL DEFAULT "default_user",
      name TEXT NOT NULL, amount REAL NOT NULL, category TEXT NOT NULL,
      status TEXT DEFAULT "Variable", type TEXT DEFAULT "Variable",
      payment_method TEXT DEFAULT "UPI", description TEXT DEFAULT "",
      tags TEXT DEFAULT "", account_id INTEGER,
      date INTEGER NOT NULL, created_at INTEGER NOT NULL)''');

    await db.execute('''CREATE TABLE incomes (
      id INTEGER PRIMARY KEY AUTOINCREMENT, user_id TEXT NOT NULL DEFAULT "default_user",
      source TEXT NOT NULL, amount REAL NOT NULL, category TEXT NOT NULL,
      payment_method TEXT DEFAULT "Bank", description TEXT DEFAULT "",
      tags TEXT DEFAULT "", account_id INTEGER,
      date INTEGER NOT NULL, created_at INTEGER NOT NULL)''');

    await db.execute('''CREATE TABLE debts (
      id INTEGER PRIMARY KEY AUTOINCREMENT, user_id TEXT NOT NULL DEFAULT "default_user",
      lender_name TEXT NOT NULL, amount REAL NOT NULL, purpose TEXT,
      borrowed_date INTEGER, due_date INTEGER, status TEXT NOT NULL,
      paid_amount REAL DEFAULT 0, account_id INTEGER, created_at INTEGER NOT NULL)''');

    await db.execute('''CREATE TABLE accounts (
      id INTEGER PRIMARY KEY AUTOINCREMENT, user_id TEXT NOT NULL DEFAULT "default_user",
      name TEXT NOT NULL, type TEXT NOT NULL, balance REAL DEFAULT 0,
      color TEXT DEFAULT "#1B8A5A", icon TEXT DEFAULT "wallet",
      created_at INTEGER NOT NULL)''');

    await db.execute('''CREATE TABLE budgets (
      id INTEGER PRIMARY KEY AUTOINCREMENT, user_id TEXT NOT NULL DEFAULT "default_user",
      category TEXT NOT NULL, monthly_limit REAL NOT NULL, weekly_limit REAL DEFAULT 0,
      alert_percentage REAL DEFAULT 80, month INTEGER NOT NULL,
      year INTEGER NOT NULL, created_at INTEGER NOT NULL)''');

    await db.execute('''CREATE TABLE recurring_v2 (
      id INTEGER PRIMARY KEY AUTOINCREMENT, user_id TEXT NOT NULL DEFAULT "default_user",
      name TEXT NOT NULL, amount REAL NOT NULL, category TEXT NOT NULL,
      transaction_type TEXT DEFAULT "Expense", frequency TEXT DEFAULT "Monthly",
      account_id INTEGER, is_active INTEGER DEFAULT 1,
      last_processed INTEGER, created_at INTEGER NOT NULL)''');

    await db.execute('''CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT, user_id TEXT NOT NULL DEFAULT "default_user",
      name TEXT NOT NULL, type TEXT NOT NULL, color TEXT DEFAULT "#1B8A5A",
      icon TEXT DEFAULT "category", is_default INTEGER DEFAULT 0,
      created_at INTEGER NOT NULL)''');

    await db.execute('''CREATE TABLE savings_goals (
      id INTEGER PRIMARY KEY AUTOINCREMENT, user_id TEXT NOT NULL DEFAULT "default_user",
      name TEXT NOT NULL, target_amount REAL NOT NULL, saved_amount REAL DEFAULT 0,
      color TEXT DEFAULT "#1B8A5A", icon TEXT DEFAULT "star",
      deadline INTEGER, created_at INTEGER NOT NULL)''');

    await db.execute('''CREATE TABLE IF NOT EXISTS ai_budget_plans (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id TEXT NOT NULL DEFAULT "default_user",
      summary TEXT NOT NULL,
      currency TEXT NOT NULL DEFAULT "INR",
      monthly_income REAL NOT NULL,
      feasibility_status TEXT NOT NULL DEFAULT "feasible",
      deficit REAL DEFAULT 0,
      allocations_json TEXT NOT NULL,
      total_essential REAL NOT NULL,
      total_lifestyle REAL NOT NULL,
      total_savings REAL NOT NULL,
      unallocated_balance REAL DEFAULT 0,
      savings_percentage REAL DEFAULT 0,
      ai_explanation TEXT NOT NULL,
      assumptions_json TEXT DEFAULT "[]",
      financial_warnings_json TEXT DEFAULT "[]",
      savings_recommendation TEXT DEFAULT "",
      provider TEXT DEFAULT "gemini",
      model TEXT DEFAULT "gemini-1.5-flash",
      is_offline_fallback INTEGER DEFAULT 0,
      input_json TEXT DEFAULT "",
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_exp_user_date ON expenses(user_id, date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_inc_user_date ON incomes(user_id, date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_exp_user_cat ON expenses(user_id, category)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_bud_user_mon ON budgets(user_id, month, year)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ai_plan_user ON ai_budget_plans(user_id, created_at)');
  }

  Future<void> _insertDefaultCategories(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final expCats = [
      {'name':'Food & Dining','color':'#E53935','icon':'restaurant'},
      {'name':'Coffee & Snacks','color':'#795548','icon':'local_cafe'},
      {'name':'Transport','color':'#1E88E5','icon':'directions_car'},
      {'name':'Cab / Auto','color':'#00ACC1','icon':'local_taxi'},
      {'name':'Alcohol','color':'#E91E63','icon':'local_bar'},
      {'name':'Books & Learning','color':'#43A047','icon':'menu_book'},
      {'name':'Clothing','color':'#AB47BC','icon':'checkroom'},
      {'name':'Entertainment','color':'#FF7043','icon':'movie'},
      {'name':'Medical','color':'#26C6DA','icon':'local_hospital'},
      {'name':'Utilities','color':'#78909C','icon':'bolt'},
      {'name':'Rent','color':'#5C6BC0','icon':'home'},
      {'name':'Shopping','color':'#FF9800','icon':'shopping_bag'},
      {'name':'Fuel','color':'#F4511E','icon':'local_gas_station'},
      {'name':'Gas / Cooking','color':'#29B6F6','icon':'outdoor_grill'},
      {'name':'Child Care','color':'#EC407A','icon':'child_care'},
      {'name':'Child Education','color':'#66BB6A','icon':'school'},
      {'name':'Car Loan EMI','color':'#42A5F5','icon':'directions_car'},
      {'name':'Others','color':'#9E9E9E','icon':'category'},
    ];
    final incCats = [
      {'name':'Salary','color':'#43A047','icon':'payments'},
      {'name':'Bonus','color':'#FFB300','icon':'card_giftcard'},
      {'name':'Business Income','color':'#AB47BC','icon':'business'},
      {'name':'Cashback','color':'#00ACC1','icon':'cached'},
      {'name':'Consulting','color':'#5C6BC0','icon':'work'},
      {'name':'Family Transfer','color':'#EC407A','icon':'family_restroom'},
      {'name':'Fixed Deposit','color':'#42A5F5','icon':'account_balance'},
      {'name':'Arrears','color':'#26A69A','icon':'history'},
      {'name':'Scholarship','color':'#66BB6A','icon':'school'},
      {'name':'Stock Dividends','color':'#FF7043','icon':'trending_up'},
      {'name':'Others','color':'#9E9E9E','icon':'category'},
    ];
    for (final c in expCats) {
      try {
        await db.insert('categories', {
          'user_id': 'default_user',
          'name': c['name'], 'type': 'Expense',
          'color': c['color'], 'icon': c['icon'],
          'is_default': 1, 'created_at': now
        });
      } catch (_) {}
    }
    for (final c in incCats) {
      try {
        await db.insert('categories', {
          'user_id': 'default_user',
          'name': c['name'], 'type': 'Income',
          'color': c['color'], 'icon': c['icon'],
          'is_default': 1, 'created_at': now
        });
      } catch (_) {}
    }
  }

  // ── TOTAL BALANCE ──
  Future<double> getTotalBalance({String userId = 'default_user'}) async {
    final db = await database;
    final incRes = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0.0) as total FROM incomes WHERE user_id = ?',
      [userId]
    );
    final expRes = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0.0) as total FROM expenses WHERE user_id = ?',
      [userId]
    );
    final totalInc = (incRes.first['total'] as num? ?? 0.0).toDouble();
    final totalExp = (expRes.first['total'] as num? ?? 0.0).toDouble();
    return totalInc - totalExp;
  }

  // ── EXPENSES ──
  Future<int> insertExpense(Expense e) async =>
    (await database).insert('expenses', e.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<List<Expense>> getAllExpenses({String userId = 'default_user'}) async =>
    (await (await database).query('expenses',
      where: 'user_id = ?', whereArgs: [userId],
      orderBy: 'date DESC')).map(Expense.fromMap).toList();

  Future<List<Expense>> getExpensesByDateRange(DateTime from, DateTime to, {String userId = 'default_user'}) async =>
    (await (await database).query('expenses',
      where: 'user_id = ? AND date >= ? AND date <= ?',
      whereArgs: [userId, from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
      orderBy: 'date DESC')).map(Expense.fromMap).toList();

  Future<List<Expense>> getExpensesByMonth(int month, int year, {String userId = 'default_user'}) =>
    getExpensesByDateRange(DateTime(year, month, 1),
      DateTime(year, month + 1, 0, 23, 59, 59, 999), userId: userId);

  Future<int> updateExpense(Expense e) async =>
    (await database).update('expenses', e.toMap(),
      where: 'id = ? AND user_id = ?', whereArgs: [e.id, e.userId]);

  Future<int> deleteExpense(int id, {String userId = 'default_user'}) async =>
    (await database).delete('expenses',
      where: 'id = ? AND user_id = ?', whereArgs: [id, userId]);

  // ── INCOMES ──
  Future<int> insertIncome(Income i) async =>
    (await database).insert('incomes', i.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<List<Income>> getAllIncomes({String userId = 'default_user'}) async =>
    (await (await database).query('incomes',
      where: 'user_id = ?', whereArgs: [userId],
      orderBy: 'date DESC')).map(Income.fromMap).toList();

  Future<List<Income>> getIncomesByMonth(int month, int year, {String userId = 'default_user'}) async {
    final from = DateTime(year, month, 1);
    final to = DateTime(year, month + 1, 0, 23, 59, 59, 999);
    return (await (await database).query('incomes',
      where: 'user_id = ? AND date >= ? AND date <= ?',
      whereArgs: [userId, from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
      orderBy: 'date DESC')).map(Income.fromMap).toList();
  }

  Future<int> updateIncome(Income i) async =>
    (await database).update('incomes', i.toMap(),
      where: 'id = ? AND user_id = ?', whereArgs: [i.id, i.userId]);

  Future<int> deleteIncome(int id, {String userId = 'default_user'}) async =>
    (await database).delete('incomes',
      where: 'id = ? AND user_id = ?', whereArgs: [id, userId]);

  // ── DEBTS ──
  Future<int> insertDebt(Debt d) async =>
    (await database).insert('debts', d.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<List<Debt>> getAllDebts({String userId = 'default_user'}) async =>
    (await (await database).query('debts',
      where: 'user_id = ?', whereArgs: [userId],
      orderBy: 'created_at DESC')).map(Debt.fromMap).toList();

  Future<List<Debt>> getPendingDebts({String userId = 'default_user'}) async =>
    (await (await database).query('debts',
      where: "user_id = ? AND status != 'Paid'", whereArgs: [userId],
      orderBy: 'due_date ASC')).map(Debt.fromMap).toList();

  Future<List<Debt>> getPaidDebts({String userId = 'default_user'}) async =>
    (await (await database).query('debts',
      where: "user_id = ? AND status = 'Paid'", whereArgs: [userId],
      orderBy: 'created_at DESC')).map(Debt.fromMap).toList();

  Future<int> updateDebt(Debt d) async =>
    (await database).update('debts', d.toMap(),
      where: 'id = ? AND user_id = ?', whereArgs: [d.id, d.userId]);

  Future<int> deleteDebt(int id, {String userId = 'default_user'}) async =>
    (await database).delete('debts',
      where: 'id = ? AND user_id = ?', whereArgs: [id, userId]);

  // ── ACCOUNTS ──
  Future<int> insertAccount(Account a) async =>
    (await database).insert('accounts', a.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<List<Account>> getAllAccounts({String userId = 'default_user'}) async =>
    (await (await database).query('accounts',
      where: 'user_id = ?', whereArgs: [userId],
      orderBy: 'name ASC')).map(Account.fromMap).toList();

  Future<int> updateAccount(Account a) async =>
    (await database).update('accounts', a.toMap(),
      where: 'id = ? AND user_id = ?', whereArgs: [a.id, a.userId]);

  Future<int> deleteAccount(int id, {String userId = 'default_user'}) async =>
    (await database).delete('accounts',
      where: 'id = ? AND user_id = ?', whereArgs: [id, userId]);

  // ── BUDGETS ──
  Future<int> insertBudget(Budget b) async =>
    (await database).insert('budgets', b.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<List<Budget>> getBudgetsByMonth(int month, int year, {String userId = 'default_user'}) async =>
    (await (await database).query('budgets',
      where: 'user_id = ? AND month = ? AND year = ?',
      whereArgs: [userId, month, year])).map(Budget.fromMap).toList();

  Future<List<Budget>> getAllBudgets({String userId = 'default_user'}) async =>
    (await (await database).query('budgets',
      where: 'user_id = ?', whereArgs: [userId])).map(Budget.fromMap).toList();

  Future<int> updateBudget(Budget b) async =>
    (await database).update('budgets', b.toMap(),
      where: 'id = ? AND user_id = ?', whereArgs: [b.id, b.userId]);

  Future<int> deleteBudget(int id, {String userId = 'default_user'}) async =>
    (await database).delete('budgets',
      where: 'id = ? AND user_id = ?', whereArgs: [id, userId]);

  // ── RECURRING ──
  Future<int> insertRecurring(RecurringExpense r) async =>
    (await database).insert('recurring_v2', r.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<List<RecurringExpense>> getAllRecurring({String userId = 'default_user'}) async =>
    (await (await database).query('recurring_v2',
      where: 'user_id = ?', whereArgs: [userId],
      orderBy: 'name ASC')).map(RecurringExpense.fromMap).toList();

  Future<int> updateRecurring(RecurringExpense r) async =>
    (await database).update('recurring_v2', r.toMap(),
      where: 'id = ? AND user_id = ?', whereArgs: [r.id, r.userId]);

  Future<int> deleteRecurring(int id, {String userId = 'default_user'}) async =>
    (await database).delete('recurring_v2',
      where: 'id = ? AND user_id = ?', whereArgs: [id, userId]);

  // ── CATEGORIES ──
  Future<int> insertCategory(AppCategory c) async =>
    (await database).insert('categories', c.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);

  Future<List<AppCategory>> getCategoriesByType(String type, {String userId = 'default_user'}) async {
    final db = await database;
    var list = (await db.query('categories',
      where: '(user_id = ? OR is_default = 1) AND type = ?', whereArgs: [userId, type],
      orderBy: 'name ASC')).map(AppCategory.fromMap).toList();
    if (list.isEmpty) {
      await _insertDefaultCategories(db);
      list = (await db.query('categories',
        where: '(user_id = ? OR is_default = 1) AND type = ?', whereArgs: [userId, type],
        orderBy: 'name ASC')).map(AppCategory.fromMap).toList();
    }
    return list;
  }

  Future<List<AppCategory>> getAllCategories({String userId = 'default_user'}) async {
    final db = await database;
    var list = (await db.query('categories',
      where: 'user_id = ? OR is_default = 1', whereArgs: [userId],
      orderBy: 'type ASC, name ASC')).map(AppCategory.fromMap).toList();
    if (list.isEmpty) {
      await _insertDefaultCategories(db);
      list = (await db.query('categories',
        where: 'user_id = ? OR is_default = 1', whereArgs: [userId],
        orderBy: 'type ASC, name ASC')).map(AppCategory.fromMap).toList();
    }
    return list;
  }

  Future<int> updateCategory(AppCategory c) async =>
    (await database).update('categories', c.toMap(),
      where: 'id = ? AND user_id = ?', whereArgs: [c.id, c.userId]);

  Future<int> deleteCategory(int id, {String userId = 'default_user'}) async =>
    (await database).delete('categories',
      where: 'id = ? AND user_id = ?', whereArgs: [id, userId]);

  // ── SAVINGS GOALS ──
  Future<int> insertGoal(SavingsGoal g) async =>
    (await database).insert('savings_goals', g.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<List<SavingsGoal>> getAllGoals({String userId = 'default_user'}) async =>
    (await (await database).query('savings_goals',
      where: 'user_id = ?', whereArgs: [userId],
      orderBy: 'created_at DESC')).map(SavingsGoal.fromMap).toList();

  Future<int> updateGoal(SavingsGoal g) async =>
    (await database).update('savings_goals', g.toMap(),
      where: 'id = ? AND user_id = ?', whereArgs: [g.id, g.userId]);

  Future<int> deleteGoal(int id, {String userId = 'default_user'}) async =>
    (await database).delete('savings_goals',
      where: 'id = ? AND user_id = ?', whereArgs: [id, userId]);

  // ── AI BUDGET PLANS ──
  Future<int> insertAiBudgetPlan(AiBudgetPlan plan, {String userId = 'default_user'}) async {
    final db = await database;
    final map = plan.copyWith(userId: userId).toMap();
    return db.insert('ai_budget_plans', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<AiBudgetPlan>> getAiBudgetPlans({String userId = 'default_user'}) async {
    final db = await database;
    final list = await db.query(
      'ai_budget_plans',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return list.map(AiBudgetPlan.fromMap).toList();
  }

  Future<AiBudgetPlan?> getLatestAiBudgetPlan({String userId = 'default_user'}) async {
    final db = await database;
    final list = await db.query(
      'ai_budget_plans',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (list.isEmpty) return null;
    return AiBudgetPlan.fromMap(list.first);
  }

  Future<int> deleteAiBudgetPlan(int id, {String userId = 'default_user'}) async =>
    (await database).delete(
      'ai_budget_plans',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );

  /// Automatically applies the AI Budget Plan's category limits to the monthly budgets table.
  /// Seamlessly bridges AI-generated budgets to the application's actual budget & expense tracker!
  Future<void> applyPlanToMonthlyBudgets(
    AiBudgetPlan plan,
    int month,
    int year, {
    String userId = 'default_user',
  }) async {
    final db = await database;
    final now = DateTime.now();

    for (final alloc in plan.allocations) {
      if (alloc.amount <= 0) continue;

      final existing = await db.query(
        'budgets',
        where: 'user_id = ? AND category = ? AND month = ? AND year = ?',
        whereArgs: [userId, alloc.category, month, year],
      );

      final weekly = double.parse((alloc.amount / 4.0).toStringAsFixed(2));

      if (existing.isNotEmpty) {
        final existingId = existing.first['id'] as int;
        await db.update(
          'budgets',
          {
            'monthly_limit': alloc.amount,
            'weekly_limit': weekly,
          },
          where: 'id = ? AND user_id = ?',
          whereArgs: [existingId, userId],
        );
      } else {
        await db.insert('budgets', {
          'user_id': userId,
          'category': alloc.category,
          'monthly_limit': alloc.amount,
          'weekly_limit': weekly,
          'alert_percentage': 80.0,
          'month': month,
          'year': year,
          'created_at': now.millisecondsSinceEpoch,
        });
      }
    }
  }

  Future<void> processDueRecurring({String userId = 'default_user'}) async {
    final now = DateTime.now();
    final list = await getAllRecurring(userId: userId);
    for (final r in list) {
      if (!r.isActive) continue;
      bool isDue = false;
      if (r.frequency == 'Daily') isDue = true;
      else if (r.frequency == 'Weekly' && now.weekday == 1) isDue = true;
      else if (r.frequency == 'Monthly' && now.day == 1) isDue = true;
      else if (r.frequency == 'Yearly' && now.day == 1 && now.month == 1) isDue = true;
      if (!isDue) continue;
      if (r.lastProcessed != null &&
          r.lastProcessed!.year == now.year &&
          r.lastProcessed!.month == now.month &&
          r.lastProcessed!.day == now.day) continue;
      if (r.transactionType == 'Income') {
        await insertIncome(Income(userId: userId, source: r.name, amount: r.amount,
          category: r.category, accountId: r.accountId,
          date: now, createdAt: now));
      } else {
        await insertExpense(Expense(userId: userId, name: r.name, amount: r.amount,
          category: r.category, accountId: r.accountId,
          date: now, createdAt: now));
      }
      await updateRecurring(r.copyWith(lastProcessed: now));
    }
  }

  Future<void> close() async { await _db?.close(); _db = null; }
}
