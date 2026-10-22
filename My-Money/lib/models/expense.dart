class Expense {
  final int? id;
  final String userId;
  final String name;
  final double amount;
  final String category;
  final String status;
  final String type; // kept for DB compat, use 'Variable' as default
  final String paymentMethod; // Cash, UPI, Debit Card, Credit Card, Net Banking, Other
  final String description;
  final String tags;
  final int? accountId;
  final DateTime date;
  final DateTime createdAt;

  const Expense({
    this.id,
    this.userId = 'default_user',
    required this.name,
    required this.amount,
    required this.category,
    this.status = 'Variable',
    this.type = 'Variable',
    this.paymentMethod = 'UPI',
    this.description = '',
    this.tags = '',
    this.accountId,
    required this.date,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'name': name,
    'amount': amount,
    'category': category,
    'status': status,
    'type': type,
    'payment_method': paymentMethod,
    'description': description,
    'tags': tags,
    'account_id': accountId,
    'date': date.millisecondsSinceEpoch,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory Expense.fromMap(Map<String, dynamic> m) => Expense(
    id: m['id'],
    userId: m['user_id'] ?? 'default_user',
    name: m['name'],
    amount: (m['amount'] as num).toDouble(),
    category: m['category'],
    status: m['status'] ?? 'Variable',
    type: m['type'] ?? 'Variable',
    paymentMethod: m['payment_method'] ?? 'UPI',
    description: m['description'] ?? '',
    tags: m['tags'] ?? '',
    accountId: m['account_id'],
    date: DateTime.fromMillisecondsSinceEpoch(m['date']),
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at']),
  );

  Expense copyWith({
    int? id,
    String? userId,
    String? name,
    double? amount,
    String? category,
    String? status,
    String? type,
    String? paymentMethod,
    String? description,
    String? tags,
    int? accountId,
    DateTime? date,
    DateTime? createdAt,
  }) => Expense(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    amount: amount ?? this.amount,
    category: category ?? this.category,
    status: status ?? this.status,
    type: type ?? this.type,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    description: description ?? this.description,
    tags: tags ?? this.tags,
    accountId: accountId ?? this.accountId,
    date: date ?? this.date,
    createdAt: createdAt ?? this.createdAt,
  );
}
