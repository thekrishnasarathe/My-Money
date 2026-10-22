class Income {
  final int? id;
  final String userId;
  final String source;
  final double amount;
  final String category;
  final String paymentMethod;
  final String description;
  final String tags;
  final int? accountId;
  final DateTime date;
  final DateTime createdAt;

  const Income({
    this.id,
    this.userId = 'default_user',
    required this.source,
    required this.amount,
    required this.category,
    this.paymentMethod = 'Bank',
    this.description = '',
    this.tags = '',
    this.accountId,
    required this.date,
    required this.createdAt,
  });

  String get notes => description;

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'source': source,
    'amount': amount,
    'category': category,
    'payment_method': paymentMethod,
    'description': description,
    'tags': tags,
    'account_id': accountId,
    'date': date.millisecondsSinceEpoch,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory Income.fromMap(Map<String, dynamic> m) => Income(
    id: m['id'],
    userId: m['user_id'] ?? 'default_user',
    source: m['source'] ?? m['notes'] ?? '',
    amount: (m['amount'] as num).toDouble(),
    category: m['category'],
    paymentMethod: m['payment_method'] ?? 'Bank',
    description: m['description'] ?? m['notes'] ?? '',
    tags: m['tags'] ?? '',
    accountId: m['account_id'],
    date: DateTime.fromMillisecondsSinceEpoch(m['date']),
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at']),
  );

  Income copyWith({
    int? id,
    String? userId,
    String? source,
    double? amount,
    String? category,
    String? paymentMethod,
    String? description,
    String? tags,
    int? accountId,
    DateTime? date,
    DateTime? createdAt,
  }) => Income(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    source: source ?? this.source,
    amount: amount ?? this.amount,
    category: category ?? this.category,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    description: description ?? this.description,
    tags: tags ?? this.tags,
    accountId: accountId ?? this.accountId,
    date: date ?? this.date,
    createdAt: createdAt ?? this.createdAt,
  );
}
