class Debt {
  final int? id;
  final String userId;
  final String lenderName;
  final double amount;
  final String? purpose;
  final DateTime? borrowedDate;
  final DateTime? dueDate;
  final String status; // Pending, Partially Paid, Paid
  final double paidAmount;
  final int? accountId;
  final DateTime createdAt;

  const Debt({
    this.id,
    this.userId = 'default_user',
    required this.lenderName,
    required this.amount,
    this.purpose,
    this.borrowedDate,
    this.dueDate,
    required this.status,
    this.paidAmount = 0.0,
    this.accountId,
    required this.createdAt,
  });

  double get remaining => amount - paidAmount;

  bool get isOverdue {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!) && status != 'Paid';
  }

  int get daysLeft {
    if (dueDate == null) return 0;
    return dueDate!.difference(DateTime.now()).inDays;
  }

  int get daysOverdue {
    if (!isOverdue) return 0;
    return DateTime.now().difference(dueDate!).inDays;
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'lender_name': lenderName,
      'amount': amount,
      'purpose': purpose,
      'borrowed_date': borrowedDate?.millisecondsSinceEpoch,
      'due_date': dueDate?.millisecondsSinceEpoch,
      'status': status,
      'paid_amount': paidAmount,
      'account_id': accountId,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'] as int?,
      userId: map['user_id'] as String? ?? 'default_user',
      lenderName: map['lender_name'] as String,
      amount: (map['amount'] as num).toDouble(),
      purpose: map['purpose'] as String?,
      borrowedDate: map['borrowed_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['borrowed_date'] as int)
          : null,
      dueDate: map['due_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['due_date'] as int)
          : null,
      status: map['status'] as String,
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0.0,
      accountId: map['account_id'] as int?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  Debt copyWith({
    int? id,
    String? userId,
    String? lenderName,
    double? amount,
    String? purpose,
    DateTime? borrowedDate,
    DateTime? dueDate,
    String? status,
    double? paidAmount,
    int? accountId,
    DateTime? createdAt,
  }) {
    return Debt(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      lenderName: lenderName ?? this.lenderName,
      amount: amount ?? this.amount,
      purpose: purpose ?? this.purpose,
      borrowedDate: borrowedDate ?? this.borrowedDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      paidAmount: paidAmount ?? this.paidAmount,
      accountId: accountId ?? this.accountId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
