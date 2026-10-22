import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF00C6A2);      // teal-green (Paisa accent)
  static const Color primaryGreen = Color(0xFF00C6A2);
  static const Color bgDark = Color(0xFF0F1117);
  static const Color cardDark = Color(0xFF1A1D26);
  static const Color cardDark2 = Color(0xFF222635);
  static const Color bgLight = Color(0xFFF2F4F8);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color incomeGreen = Color(0xFF00C6A2);
  static const Color expenseRed = Color(0xFFFF5B5B);
  static const Color errorRed = Color(0xFFFF5B5B);
  static const Color successGreen = Color(0xFF00C6A2);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9096A8);
  static const Color divider = Color(0xFF2A2D3A);

  static const List<Color> chartColors = [
    Color(0xFF00C6A2), Color(0xFFFF5B5B), Color(0xFF7C6FFF),
    Color(0xFFFFB547), Color(0xFF4FC3F7), Color(0xFFEC407A),
    Color(0xFF66BB6A), Color(0xFFFF7043), Color(0xFF42A5F5),
    Color(0xFFAB47BC),
  ];

  static Color chartColor(int i) => chartColors[i % chartColors.length];

  static Color getCategoryColor(String cat) {
    const map = {
      'Food & Dining': Color(0xFFFF5B5B),
      'Coffee & Snacks': Color(0xFF795548),
      'Transport': Color(0xFF42A5F5),
      'Cab / Auto': Color(0xFF00ACC1),
      'Alcohol': Color(0xFFEC407A),
      'Books & Learning': Color(0xFF66BB6A),
      'Clothing': Color(0xFFAB47BC),
      'Entertainment': Color(0xFFFF7043),
      'Medical': Color(0xFF26C6DA),
      'Utilities': Color(0xFF78909C),
      'Rent': Color(0xFF5C6BC0),
      'Shopping': Color(0xFFFFB547),
      'Fuel': Color(0xFFF4511E),
      'Gas / Cooking': Color(0xFF29B6F6),
      'Child Care': Color(0xFFEC407A),
      'Child Education': Color(0xFF66BB6A),
      'Car Loan EMI': Color(0xFF42A5F5),
      'Salary': Color(0xFF00C6A2),
      'Bonus': Color(0xFFFFB300),
      'Business Income': Color(0xFFAB47BC),
      'Cashback': Color(0xFF00ACC1),
      'Consulting': Color(0xFF5C6BC0),
      'Family Transfer': Color(0xFFEC407A),
      'Fixed Deposit': Color(0xFF42A5F5),
      'Arrears': Color(0xFF26A69A),
      'Scholarship': Color(0xFF66BB6A),
      'Stock Dividends': Color(0xFFFF7043),
      'Others': Color(0xFF9E9E9E),
    };
    return map[cat] ?? primary;
  }

  // hex string → Color
  static Color fromHex(String hex) {
    final h = hex.replaceAll('#','');
    return Color(int.parse('FF$h', radix: 16));
  }

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgDark,
    colorScheme: const ColorScheme.dark(
      primary: primary, surface: cardDark,
      onPrimary: Colors.white, onSurface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bgDark, foregroundColor: Colors.white,
      elevation: 0, centerTitle: false,
      titleTextStyle: TextStyle(color: Colors.white,
        fontSize: 20, fontWeight: FontWeight.bold),
    ),
    cardTheme: CardTheme(color: cardDark, elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: cardDark, selectedItemColor: primary,
      unselectedItemColor: Color(0xFF6B7280),
      showUnselectedLabels: true, type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary, foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: cardDark2,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 1.5)),
      hintStyle: const TextStyle(color: Color(0xFF6B7280)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    dividerTheme: const DividerThemeData(color: divider, thickness: 1),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white),
      bodySmall: TextStyle(color: Color(0xFF9096A8)),
    ),
  );

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: bgLight,
    colorScheme: ColorScheme.fromSeed(seedColor: primary),
    appBarTheme: const AppBarTheme(
      backgroundColor: bgLight, foregroundColor: Color(0xFF1A1D26),
      elevation: 0, centerTitle: false,
      titleTextStyle: TextStyle(color: Color(0xFF1A1D26),
        fontSize: 20, fontWeight: FontWeight.bold),
    ),
    cardTheme: CardTheme(color: cardLight, elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: cardLight, selectedItemColor: primary,
      unselectedItemColor: Color(0xFF9E9E9E),
      showUnselectedLabels: true, type: BottomNavigationBarType.fixed,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary, foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: Colors.grey[100],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}

// Extension for missing color aliases
