// Account
class Account {
  final int? id;
  final String userId;
  final String name;
  final String type; // Cash, Bank, UPI, Credit Card
  final double balance;
  final String color;
  final String icon;
  final DateTime createdAt;

  const Account({
    this.id,
    this.userId = 'default_user',
    required this.name,
    required this.type,
    required this.balance,
    this.color = '#1B8A5A',
    this.icon = 'wallet',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'name': name,
    'type': type,
    'balance': balance,
    'color': color,
    'icon': icon,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory Account.fromMap(Map<String, dynamic> m) => Account(
    id: m['id'],
    userId: m['user_id'] ?? 'default_user',
    name: m['name'],
    type: m['type'],
    balance: (m['balance'] as num).toDouble(),
    color: m['color'] ?? '#1B8A5A',
    icon: m['icon'] ?? 'wallet',
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at']),
  );

  Account copyWith({
    int? id,
    String? userId,
    String? name,
    String? type,
    double? balance,
    String? color,
    String? icon,
    DateTime? createdAt,
  }) => Account(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    type: type ?? this.type,
    balance: balance ?? this.balance,
    color: color ?? this.color,
    icon: icon ?? this.icon,
    createdAt: createdAt ?? this.createdAt,
  );
}

// Budget
class Budget {
  final int? id;
  final String userId;
  final String category;
  final double monthlyLimit;
  final double weeklyLimit;
  final double alertPercentage;
  final int month;
  final int year;
  final DateTime createdAt;

  const Budget({
    this.id,
    this.userId = 'default_user',
    required this.category,
    required this.monthlyLimit,
    this.weeklyLimit = 0,
    this.alertPercentage = 80.0,
    required this.month,
    required this.year,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'category': category,
    'monthly_limit': monthlyLimit,
    'weekly_limit': weeklyLimit,
    'alert_percentage': alertPercentage,
    'month': month,
    'year': year,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory Budget.fromMap(Map<String, dynamic> m) => Budget(
    id: m['id'],
    userId: m['user_id'] ?? 'default_user',
    category: m['category'],
    monthlyLimit: (m['monthly_limit'] as num).toDouble(),
    weeklyLimit: (m['weekly_limit'] as num? ?? 0).toDouble(),
    alertPercentage: (m['alert_percentage'] as num? ?? 80).toDouble(),
    month: m['month'],
    year: m['year'],
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at']),
  );

  Budget copyWith({
    int? id,
    String? userId,
    String? category,
    double? monthlyLimit,
    double? weeklyLimit,
    double? alertPercentage,
    int? month,
    int? year,
    DateTime? createdAt,
  }) => Budget(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    category: category ?? this.category,
    monthlyLimit: monthlyLimit ?? this.monthlyLimit,
    weeklyLimit: weeklyLimit ?? this.weeklyLimit,
    alertPercentage: alertPercentage ?? this.alertPercentage,
    month: month ?? this.month,
    year: year ?? this.year,
    createdAt: createdAt ?? this.createdAt,
  );
}

// RecurringExpense
class RecurringExpense {
  final int? id;
  final String userId;
  final String name;
  final double amount;
  final String category;
  final String transactionType; // 'Expense' or 'Income'
  final String frequency; // 'Daily','Weekly','Monthly','Yearly'
  final int? accountId;
  final bool isActive;
  final DateTime? lastProcessed;
  final DateTime createdAt;

  const RecurringExpense({
    this.id,
    this.userId = 'default_user',
    required this.name,
    required this.amount,
    required this.category,
    this.transactionType = 'Expense',
    this.frequency = 'Monthly',
    this.accountId,
    this.isActive = true,
    this.lastProcessed,
    required this.createdAt,
  });

  String get type => transactionType;

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'name': name,
    'amount': amount,
    'category': category,
    'transaction_type': transactionType,
    'frequency': frequency,
    'account_id': accountId,
    'is_active': isActive ? 1 : 0,
    'last_processed': lastProcessed?.millisecondsSinceEpoch,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory RecurringExpense.fromMap(Map<String, dynamic> m) => RecurringExpense(
    id: m['id'],
    userId: m['user_id'] ?? 'default_user',
    name: m['name'],
    amount: (m['amount'] as num).toDouble(),
    category: m['category'],
    transactionType: m['transaction_type'] ?? m['type'] ?? 'Expense',
    frequency: m['frequency'] ?? 'Monthly',
    accountId: m['account_id'],
    isActive: (m['is_active'] as int? ?? 1) == 1,
    lastProcessed: m['last_processed'] != null
      ? DateTime.fromMillisecondsSinceEpoch(m['last_processed']) : null,
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at']),
  );

  RecurringExpense copyWith({
    int? id,
    String? userId,
    String? name,
    double? amount,
    String? category,
    String? transactionType,
    String? frequency,
    int? accountId,
    bool? isActive,
    DateTime? lastProcessed,
    DateTime? createdAt,
  }) => RecurringExpense(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    amount: amount ?? this.amount,
    category: category ?? this.category,
    transactionType: transactionType ?? this.transactionType,
    frequency: frequency ?? this.frequency,
    accountId: accountId ?? this.accountId,
    isActive: isActive ?? this.isActive,
    lastProcessed: lastProcessed ?? this.lastProcessed,
    createdAt: createdAt ?? this.createdAt,
  );
}

// SavingsGoal
class SavingsGoal {
  final int? id;
  final String userId;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final String color;
  final String icon;
  final DateTime? deadline;
  final DateTime createdAt;

  const SavingsGoal({
    this.id,
    this.userId = 'default_user',
    required this.name,
    required this.targetAmount,
    this.savedAmount = 0,
    this.color = '#1B8A5A',
    this.icon = 'star',
    this.deadline,
    required this.createdAt,
  });

  double get progress => targetAmount > 0 ? (savedAmount / targetAmount).clamp(0, 1) : 0;
  double get remaining => (targetAmount - savedAmount).clamp(0, double.infinity);

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'name': name,
    'target_amount': targetAmount,
    'saved_amount': savedAmount,
    'color': color,
    'icon': icon,
    'deadline': deadline?.millisecondsSinceEpoch,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory SavingsGoal.fromMap(Map<String, dynamic> m) => SavingsGoal(
    id: m['id'],
    userId: m['user_id'] ?? 'default_user',
    name: m['name'],
    targetAmount: (m['target_amount'] as num).toDouble(),
    savedAmount: (m['saved_amount'] as num? ?? 0).toDouble(),
    color: m['color'] ?? '#1B8A5A',
    icon: m['icon'] ?? 'star',
    deadline: m['deadline'] != null
      ? DateTime.fromMillisecondsSinceEpoch(m['deadline']) : null,
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at']),
  );

  SavingsGoal copyWith({
    int? id,
    String? userId,
    String? name,
    double? targetAmount,
    double? savedAmount,
    String? color,
    String? icon,
    DateTime? deadline,
    DateTime? createdAt,
  }) => SavingsGoal(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    targetAmount: targetAmount ?? this.targetAmount,
    savedAmount: savedAmount ?? this.savedAmount,
    color: color ?? this.color,
    icon: icon ?? this.icon,
    deadline: deadline ?? this.deadline,
    createdAt: createdAt ?? this.createdAt,
  );
}

// AppCategory
class AppCategory {
  final int? id;
  final String userId;
  final String name;
  final String type; // 'Expense' or 'Income'
  final String color;
  final String icon;
  final bool isDefault;
  final DateTime createdAt;

  const AppCategory({
    this.id,
    this.userId = 'default_user',
    required this.name,
    required this.type,
    this.color = '#1B8A5A',
    this.icon = 'category',
    this.isDefault = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'name': name,
    'type': type,
    'color': color,
    'icon': icon,
    'is_default': isDefault ? 1 : 0,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory AppCategory.fromMap(Map<String, dynamic> m) => AppCategory(
    id: m['id'],
    userId: m['user_id'] ?? 'default_user',
    name: m['name'],
    type: m['type'],
    color: m['color'] ?? '#1B8A5A',
    icon: m['icon'] ?? 'category',
    isDefault: (m['is_default'] as int? ?? 0) == 1,
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at']),
  );

  AppCategory copyWith({
    int? id,
    String? userId,
    String? name,
    String? type,
    String? color,
    String? icon,
    bool? isDefault,
    DateTime? createdAt,
  }) => AppCategory(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    type: type ?? this.type,
    color: color ?? this.color,
    icon: icon ?? this.icon,
    isDefault: isDefault ?? this.isDefault,
    createdAt: createdAt ?? this.createdAt,
  );
}

// SpendingLimit
class SpendingLimit {
  final double monthlyLimit;
  final double weeklyLimit;
  SpendingLimit({this.monthlyLimit = 0, this.weeklyLimit = 0});
}
