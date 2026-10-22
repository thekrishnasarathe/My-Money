class AppConstants {
  static const String appName = 'MONEY';
  static const String ownerName = 'Krishna Sarathe';
  static const String ownerEmail = 'thekrishnasarathe000@gmail.com';
  static const String appVersion = '2.0.0';
  static const String appTagline = 'Your Personal Finance Manager';
  static const String copyright = '© 2026 Krishna Sarathe. All rights reserved.';

  static const String fcDevices = 'money_devices';
  static const String fcSettings = 'money_app';
  static const String fcDocSettings = 'global_settings';

  static const String kPinEnabled = 'pin_enabled';
  static const String kPinCode = 'pin_code';
  static const String kPinHash = 'pin_hash';
  static const String kPinSalt = 'pin_salt';
  static const String kBioEnabled = 'bio_enabled';
  static const String kPinMigrationNeeded = 'pin_security_migration_needed';
  static const String kOwnerKey = 'owner_key';
  static const String kDeviceId = 'device_id';
  static const String kThemeMode = 'theme_mode'; // 'dark','light','auto'
  static const String kThemeDark = 'theme_dark';
  static const String kCurrency = 'currency';
  static const String kFirstRun = 'first_run';
  static const String kRemoteEnabled = 'remote_enabled';
  static const String kMonthlySpendLimit = 'monthly_spend_limit';
  static const String kWeeklySpendLimit = 'weekly_spend_limit';
  static const String kNotifBudget = 'notif_budget';
  static const String kNotifRecurring = 'notif_recurring';

  static const String masterOwnerKey = 'KRISHNA@MY-MONEY#2026';
  static const String defaultCurrency = '₹';

  static const List<String> paymentMethods = [
    'Cash','UPI','Debit Card','Credit Card','Net Banking','Other'
  ];

  static const List<String> accountTypes = [
    'Cash','Bank','UPI Wallet','Credit Card'
  ];

  static const List<String> recurringFrequencies = [
    'Daily','Weekly','Monthly','Yearly'
  ];

  static const List<String> debtStatus = [
    'Pending', 'Partially Paid', 'Paid'
  ];

  // Kept for fallback — real categories come from DB
  static const List<String> defaultExpenseCategories = [
    'Food & Dining','Coffee & Snacks','Transport','Cab / Auto','Alcohol',
    'Books & Learning','Clothing','Entertainment','Medical','Utilities',
    'Rent','Shopping','Fuel','Gas / Cooking','Child Care',
    'Child Education','Car Loan EMI','Others',
  ];
  static const List<String> defaultIncomeCategories = [
    'Salary','Bonus','Business Income','Cashback','Consulting',
    'Family Transfer','Fixed Deposit','Arrears','Scholarship',
    'Stock Dividends','Others',
  ];

  static const List<String> expenseCategories = defaultExpenseCategories;
  static const List<String> incomeCategories = defaultIncomeCategories;
  static List<String> get budgetCategories => defaultExpenseCategories;

  static const Map<String, String> categoryIcons = {
    'Food & Dining':'restaurant','Coffee & Snacks':'local_cafe',
    'Transport':'directions_car','Cab / Auto':'local_taxi',
    'Alcohol':'local_bar','Books & Learning':'menu_book',
    'Clothing':'checkroom','Entertainment':'movie',
    'Medical':'local_hospital','Utilities':'bolt','Rent':'home',
    'Shopping':'shopping_bag','Fuel':'local_gas_station',
    'Gas / Cooking':'outdoor_grill','Child Care':'child_care',
    'Child Education':'school','Car Loan EMI':'directions_car',
    'Salary':'payments','Bonus':'card_giftcard',
    'Business Income':'business','Cashback':'cached',
    'Consulting':'work','Family Transfer':'family_restroom',
    'Fixed Deposit':'account_balance','Arrears':'history',
    'Scholarship':'school','Stock Dividends':'trending_up',
    'Others':'category',
  };
}
