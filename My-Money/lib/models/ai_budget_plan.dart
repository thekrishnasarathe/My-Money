import 'dart:convert';

/// Input details provided by the user for AI Budget Planning.
class AiBudgetInput {
  final String name;
  final String occupation;
  final double monthlyIncome;
  final String currency;
  final double rentHousing;
  final double educationLoans;
  final double existingSavings;
  final String financialGoals;
  final double savingsTarget;
  final int dependents;
  final String cityContext;
  final double otherExpenses;

  const AiBudgetInput({
    required this.name,
    required this.occupation,
    required this.monthlyIncome,
    this.currency = 'INR',
    this.rentHousing = 0.0,
    this.educationLoans = 0.0,
    this.existingSavings = 0.0,
    this.financialGoals = '',
    this.savingsTarget = 0.0,
    this.dependents = 0,
    this.cityContext = '',
    this.otherExpenses = 0.0,
  });

  /// Validates required fields and numerical constraints.
  String? validate() {
    if (name.trim().isEmpty) {
      return 'Please enter your full name.';
    }
    if (monthlyIncome <= 0) {
      return 'Monthly income must be greater than zero.';
    }
    if (rentHousing < 0 ||
        educationLoans < 0 ||
        existingSavings < 0 ||
        savingsTarget < 0 ||
        dependents < 0 ||
        otherExpenses < 0) {
      return 'Financial values cannot be negative.';
    }
    return null;
  }

  /// Calculates total fixed mandatory obligations.
  double get totalFixedObligations =>
      rentHousing + educationLoans + otherExpenses;

  /// Checks if fixed expenses exceed monthly income (shortfall).
  bool get hasShortfall => totalFixedObligations > monthlyIncome;

  double get shortfallAmount =>
      hasShortfall ? totalFixedObligations - monthlyIncome : 0.0;

  Map<String, dynamic> toMap() => {
        'name': name.trim(),
        'occupation': occupation.trim(),
        'monthly_income': monthlyIncome,
        'currency': currency,
        'rent_housing': rentHousing,
        'education_loans': educationLoans,
        'existing_savings': existingSavings,
        'financial_goals': financialGoals.trim(),
        'savings_target': savingsTarget,
        'dependents': dependents,
        'city_context': cityContext.trim(),
        'other_expenses': otherExpenses,
      };

  factory AiBudgetInput.fromMap(Map<String, dynamic> map) {
    return AiBudgetInput(
      name: map['name'] ?? '',
      occupation: map['occupation'] ?? 'salaried',
      monthlyIncome: (map['monthly_income'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'INR',
      rentHousing: (map['rent_housing'] as num?)?.toDouble() ?? 0.0,
      educationLoans: (map['education_loans'] as num?)?.toDouble() ?? 0.0,
      existingSavings: (map['existing_savings'] as num?)?.toDouble() ?? 0.0,
      financialGoals: map['financial_goals'] ?? '',
      savingsTarget: (map['savings_target'] as num?)?.toDouble() ?? 0.0,
      dependents: (map['dependents'] as num?)?.toInt() ?? 0,
      cityContext: map['city_context'] ?? '',
      otherExpenses: (map['other_expenses'] as num?)?.toDouble() ?? 0.0,
    );
  }

  AiBudgetInput copyWith({
    String? name,
    String? occupation,
    double? monthlyIncome,
    String? currency,
    double? rentHousing,
    double? educationLoans,
    double? existingSavings,
    String? financialGoals,
    double? savingsTarget,
    int? dependents,
    String? cityContext,
    double? otherExpenses,
  }) {
    return AiBudgetInput(
      name: name ?? this.name,
      occupation: occupation ?? this.occupation,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      currency: currency ?? this.currency,
      rentHousing: rentHousing ?? this.rentHousing,
      educationLoans: educationLoans ?? this.educationLoans,
      existingSavings: existingSavings ?? this.existingSavings,
      financialGoals: financialGoals ?? this.financialGoals,
      savingsTarget: savingsTarget ?? this.savingsTarget,
      dependents: dependents ?? this.dependents,
      cityContext: cityContext ?? this.cityContext,
      otherExpenses: otherExpenses ?? this.otherExpenses,
    );
  }
}

/// An individual category allocation within the AI Budget Plan.
class AiBudgetAllocation {
  final String category;
  final double amount;
  final double percentage;
  final String type; // 'essential', 'discretionary', 'debt', 'savings'
  final String explanation;
  final bool isFixed; // e.g. user-specified rent or loan
  final bool isCustom; // added by user in the editor

  const AiBudgetAllocation({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.type,
    this.explanation = '',
    this.isFixed = false,
    this.isCustom = false,
  });

  Map<String, dynamic> toMap() => {
        'category': category,
        'amount': amount,
        'percentage': percentage,
        'type': type,
        'explanation': explanation,
        'is_fixed': isFixed,
        'is_custom': isCustom,
      };

  factory AiBudgetAllocation.fromMap(Map<String, dynamic> map) {
    return AiBudgetAllocation(
      category: map['category'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
      type: map['type'] ?? 'discretionary',
      explanation: map['explanation'] ?? '',
      isFixed: map['is_fixed'] == true || map['is_fixed'] == 1,
      isCustom: map['is_custom'] == true || map['is_custom'] == 1,
    );
  }

  AiBudgetAllocation copyWith({
    String? category,
    double? amount,
    double? percentage,
    String? type,
    String? explanation,
    bool? isFixed,
    bool? isCustom,
  }) {
    return AiBudgetAllocation(
      category: category ?? this.category,
      amount: amount ?? this.amount,
      percentage: percentage ?? this.percentage,
      type: type ?? this.type,
      explanation: explanation ?? this.explanation,
      isFixed: isFixed ?? this.isFixed,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}

/// Complete AI-generated or user-edited monthly budget plan.
class AiBudgetPlan {
  final int? id;
  final String userId;
  final String summary;
  final String currency;
  final double monthlyIncome;
  final String feasibilityStatus; // 'feasible', 'tight', 'shortfall'
  final double deficit;
  final List<AiBudgetAllocation> allocations;
  final double totalEssential;
  final double totalLifestyle;
  final double totalSavings;
  final double unallocatedBalance;
  final double savingsPercentage;
  final String aiExplanation;
  final List<String> assumptions;
  final List<String> financialWarnings;
  final String savingsRecommendation;
  final String provider;
  final String model;
  final bool isOfflineFallback;
  final AiBudgetInput? input;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AiBudgetPlan({
    this.id,
    this.userId = 'default_user',
    required this.summary,
    this.currency = 'INR',
    required this.monthlyIncome,
    this.feasibilityStatus = 'feasible',
    this.deficit = 0.0,
    required this.allocations,
    required this.totalEssential,
    required this.totalLifestyle,
    required this.totalSavings,
    this.unallocatedBalance = 0.0,
    required this.savingsPercentage,
    required this.aiExplanation,
    this.assumptions = const [],
    this.financialWarnings = const [],
    this.savingsRecommendation = '',
    this.provider = 'gemini',
    this.model = 'gemini-1.5-flash',
    this.isOfflineFallback = false,
    this.input,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Currency symbol helper.
  String get currencySymbol => currency == 'INR' ? '₹' : '$currency ';

  /// Total allocated across all categories.
  double get totalAllocated =>
      allocations.fold(0.0, (sum, a) => sum + a.amount);

  /// True if total allocations match monthly income exactly within 1 cent/paise.
  bool get isBalanced => (monthlyIncome - totalAllocated).abs() <= 0.05;

  bool get isOverallocated => (totalAllocated - monthlyIncome) > 0.05;

  bool get isUnderallocated => (monthlyIncome - totalAllocated) > 0.05;

  /// Recalculates all category percentages, summary totals, and unallocated balance.
  AiBudgetPlan recalculate() {
    if (monthlyIncome <= 0) return this;

    final updatedAllocs = allocations.map((a) {
      final safeAmt = a.amount < 0 ? 0.0 : a.amount;
      final pct = (safeAmt / monthlyIncome) * 100;
      return a.copyWith(
        amount: double.parse(safeAmt.toStringAsFixed(2)),
        percentage: double.parse(pct.toStringAsFixed(2)),
      );
    }).toList();

    double essential = 0.0;
    double lifestyle = 0.0;
    double savings = 0.0;

    for (final a in updatedAllocs) {
      if (a.type == 'essential' || a.type == 'debt') {
        essential += a.amount;
      } else if (a.type == 'savings') {
        savings += a.amount;
      } else {
        lifestyle += a.amount;
      }
    }

    final totalAlloc = essential + lifestyle + savings;
    final unallocated = double.parse((monthlyIncome - totalAlloc).toStringAsFixed(2));
    final savingsPct = double.parse(((savings / monthlyIncome) * 100).toStringAsFixed(2));

    String status = feasibilityStatus;
    if (input != null && input!.hasShortfall) {
      status = 'shortfall';
    } else if (essential / monthlyIncome > 0.70) {
      status = 'tight';
    } else {
      status = 'feasible';
    }

    return copyWith(
      allocations: updatedAllocs,
      totalEssential: double.parse(essential.toStringAsFixed(2)),
      totalLifestyle: double.parse(lifestyle.toStringAsFixed(2)),
      totalSavings: double.parse(savings.toStringAsFixed(2)),
      unallocatedBalance: unallocated,
      savingsPercentage: savingsPct,
      feasibilityStatus: status,
      updatedAt: DateTime.now(),
    );
  }

  /// Rebalances discretionary categories to absorb unallocated balance or eliminate overallocation.
  AiBudgetPlan rebalanceDiscretionary() {
    final diff = double.parse((monthlyIncome - totalAllocated).toStringAsFixed(2));
    if (diff.abs() <= 0.05) return this;

    final list = List<AiBudgetAllocation>.from(allocations);

    if (diff > 0) {
      // Underallocated: Add to Miscellaneous or Emergency Fund or create buffer
      final miscIdx = list.indexWhere((a) =>
          a.category.toLowerCase().contains('misc') ||
          a.category.toLowerCase().contains('buffer'));
      if (miscIdx != -1) {
        list[miscIdx] = list[miscIdx].copyWith(
          amount: double.parse((list[miscIdx].amount + diff).toStringAsFixed(2)),
        );
      } else {
        final discIdx = list.indexWhere((a) =>
            a.type == 'discretionary' && !a.isFixed);
        if (discIdx != -1) {
          list[discIdx] = list[discIdx].copyWith(
            amount: double.parse((list[discIdx].amount + diff).toStringAsFixed(2)),
          );
        } else {
          list.add(AiBudgetAllocation(
            category: 'Miscellaneous Expenses',
            amount: diff,
            percentage: (diff / monthlyIncome) * 100,
            type: 'discretionary',
            explanation: 'Rebalanced allocation buffer',
            isCustom: true,
          ));
        }
      }
    } else {
      // Overallocated: Trim discretionary categories first without touching fixed or essential
      double toTrim = diff.abs();
      for (int i = list.length - 1; i >= 0; i--) {
        if (list[i].type == 'discretionary' && !list[i].isFixed && list[i].amount > 0) {
          final reduction = list[i].amount >= toTrim ? toTrim : list[i].amount;
          list[i] = list[i].copyWith(
            amount: double.parse((list[i].amount - reduction).toStringAsFixed(2)),
          );
          toTrim = double.parse((toTrim - reduction).toStringAsFixed(2));
          if (toTrim <= 0.01) break;
        }
      }

      // If still overallocated, trim non-fixed savings
      if (toTrim > 0.01) {
        for (int i = list.length - 1; i >= 0; i--) {
          if (list[i].type == 'savings' && !list[i].isFixed && list[i].amount > 0) {
            final reduction = list[i].amount >= toTrim ? toTrim : list[i].amount;
            list[i] = list[i].copyWith(
              amount: double.parse((list[i].amount - reduction).toStringAsFixed(2)),
            );
            toTrim = double.parse((toTrim - reduction).toStringAsFixed(2));
            if (toTrim <= 0.01) break;
          }
        }
      }
    }

    return copyWith(allocations: list).recalculate();
  }

  /// Updates an individual category amount and immediately recalculates totals.
  AiBudgetPlan updateCategoryAmount(String categoryName, double newAmount) {
    final safeAmt = newAmount < 0 ? 0.0 : newAmount;
    final updatedList = allocations.map((a) {
      if (a.category.toLowerCase() == categoryName.toLowerCase()) {
        return a.copyWith(amount: safeAmt);
      }
      return a;
    }).toList();

    return copyWith(allocations: updatedList).recalculate();
  }

  /// Adds a custom category to the budget plan.
  AiBudgetPlan addCategory(AiBudgetAllocation newAlloc) {
    // Check if category already exists
    final idx = allocations.indexWhere((a) =>
        a.category.trim().toLowerCase() == newAlloc.category.trim().toLowerCase());
    if (idx != -1) {
      // Merge amount into existing
      final merged = allocations[idx].copyWith(
        amount: allocations[idx].amount + newAlloc.amount,
      );
      final list = List<AiBudgetAllocation>.from(allocations)..[idx] = merged;
      return copyWith(allocations: list).recalculate();
    }

    final list = List<AiBudgetAllocation>.from(allocations)..add(newAlloc);
    return copyWith(allocations: list).recalculate();
  }

  /// Removes an optional category (unless fixed).
  AiBudgetPlan removeCategory(String categoryName) {
    final list = allocations
        .where((a) =>
            a.category.toLowerCase() != categoryName.toLowerCase() || a.isFixed)
        .toList();
    return copyWith(allocations: list).recalculate();
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'summary': summary,
        'currency': currency,
        'monthly_income': monthlyIncome,
        'feasibility_status': feasibilityStatus,
        'deficit': deficit,
        'allocations_json': json.encode(allocations.map((a) => a.toMap()).toList()),
        'total_essential': totalEssential,
        'total_lifestyle': totalLifestyle,
        'total_savings': totalSavings,
        'unallocated_balance': unallocatedBalance,
        'savings_percentage': savingsPercentage,
        'ai_explanation': aiExplanation,
        'assumptions_json': json.encode(assumptions),
        'financial_warnings_json': json.encode(financialWarnings),
        'savings_recommendation': savingsRecommendation,
        'provider': provider,
        'model': model,
        'is_offline_fallback': isOfflineFallback ? 1 : 0,
        'input_json': input != null ? json.encode(input!.toMap()) : '',
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory AiBudgetPlan.fromMap(Map<String, dynamic> map) {
    List<AiBudgetAllocation> parsedAllocs = [];
    if (map['allocations_json'] != null && map['allocations_json'] is String) {
      try {
        final List list = json.decode(map['allocations_json']);
        parsedAllocs = list.map((x) => AiBudgetAllocation.fromMap(x)).toList();
      } catch (_) {}
    } else if (map['allocations'] is List) {
      parsedAllocs = (map['allocations'] as List)
          .map((x) => AiBudgetAllocation.fromMap(x))
          .toList();
    }

    List<String> parsedAssumptions = [];
    if (map['assumptions_json'] != null) {
      try {
        parsedAssumptions = List<String>.from(json.decode(map['assumptions_json']));
      } catch (_) {}
    } else if (map['assumptions'] is List) {
      parsedAssumptions = List<String>.from(map['assumptions']);
    }

    List<String> parsedWarnings = [];
    if (map['financial_warnings_json'] != null) {
      try {
        parsedWarnings = List<String>.from(json.decode(map['financial_warnings_json']));
      } catch (_) {}
    } else if (map['financial_warnings'] is List) {
      parsedWarnings = List<String>.from(map['financial_warnings']);
    }

    AiBudgetInput? parsedInput;
    if (map['input_json'] != null && (map['input_json'] as String).isNotEmpty) {
      try {
        parsedInput = AiBudgetInput.fromMap(json.decode(map['input_json']));
      } catch (_) {}
    } else if (map['input'] is Map<String, dynamic>) {
      parsedInput = AiBudgetInput.fromMap(map['input']);
    }

    return AiBudgetPlan(
      id: map['id'],
      userId: map['user_id'] ?? 'default_user',
      summary: map['summary'] ?? '',
      currency: map['currency'] ?? 'INR',
      monthlyIncome: (map['monthly_income'] as num?)?.toDouble() ?? 0.0,
      feasibilityStatus: map['feasibility_status'] ?? 'feasible',
      deficit: (map['deficit'] as num?)?.toDouble() ?? 0.0,
      allocations: parsedAllocs,
      totalEssential: (map['total_essential'] as num?)?.toDouble() ?? 0.0,
      totalLifestyle: (map['total_lifestyle'] as num?)?.toDouble() ?? 0.0,
      totalSavings: (map['total_savings'] as num?)?.toDouble() ?? 0.0,
      unallocatedBalance: (map['unallocated_balance'] as num?)?.toDouble() ?? 0.0,
      savingsPercentage: (map['savings_percentage'] as num?)?.toDouble() ?? 0.0,
      aiExplanation: map['ai_explanation'] ?? '',
      assumptions: parsedAssumptions,
      financialWarnings: parsedWarnings,
      savingsRecommendation: map['savings_recommendation'] ?? '',
      provider: map['provider'] ?? 'gemini',
      model: map['model'] ?? 'gemini-1.5-flash',
      isOfflineFallback: map['is_offline_fallback'] == 1 || map['is_offline_fallback'] == true,
      input: parsedInput,
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'])
          : DateTime.now(),
    );
  }

  AiBudgetPlan copyWith({
    int? id,
    String? userId,
    String? summary,
    String? currency,
    double? monthlyIncome,
    String? feasibilityStatus,
    double? deficit,
    List<AiBudgetAllocation>? allocations,
    double? totalEssential,
    double? totalLifestyle,
    double? totalSavings,
    double? unallocatedBalance,
    double? savingsPercentage,
    String? aiExplanation,
    List<String>? assumptions,
    List<String>? financialWarnings,
    String? savingsRecommendation,
    String? provider,
    String? model,
    bool? isOfflineFallback,
    AiBudgetInput? input,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AiBudgetPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      summary: summary ?? this.summary,
      currency: currency ?? this.currency,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      feasibilityStatus: feasibilityStatus ?? this.feasibilityStatus,
      deficit: deficit ?? this.deficit,
      allocations: allocations ?? this.allocations,
      totalEssential: totalEssential ?? this.totalEssential,
      totalLifestyle: totalLifestyle ?? this.totalLifestyle,
      totalSavings: totalSavings ?? this.totalSavings,
      unallocatedBalance: unallocatedBalance ?? this.unallocatedBalance,
      savingsPercentage: savingsPercentage ?? this.savingsPercentage,
      aiExplanation: aiExplanation ?? this.aiExplanation,
      assumptions: assumptions ?? this.assumptions,
      financialWarnings: financialWarnings ?? this.financialWarnings,
      savingsRecommendation: savingsRecommendation ?? this.savingsRecommendation,
      provider: provider ?? this.provider,
      model: model ?? this.model,
      isOfflineFallback: isOfflineFallback ?? this.isOfflineFallback,
      input: input ?? this.input,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
