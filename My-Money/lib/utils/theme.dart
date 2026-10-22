import 'package:flutter/material.dart';

class AppTheme {
  // ── Official Luxury Color Palette ──
  static const Color jetBlack = Color(0xFF000000);       // Main application background
  static const Color charcoalGrey = Color(0xFF1C1C24);   // Elevated cards and panels
  static const Color forestGreen = Color(0xFF0B2E20);    // Card borders and depth
  static const Color emeraldGreen = Color(0xFF0F6B4F);   // Active accent surfaces & Income box
  static const Color champagneGold = Color(0xFFD4AF37);  // Primary branding, highlights, hero text, icons, action buttons
  static const Color paleChampagne = Color(0xFFF5E2A1);  // Secondary gold text & readable secondary info
  static const Color deepCrimson = Color(0xFF8B0000);    // Expense cards and negative indicators
  static const Color crimsonShadow = Color(0xFF5A0000);  // Dark red supporting surfaces
  static const Color antiqueGold = Color(0xFF3E3A1D);    // Secondary borders

  // ── Core Semantic Tokens ──
  static const Color primary = champagneGold;            // Champagne Gold (#D4AF37)
  static const Color primaryGreen = emeraldGreen;        // Emerald Green (#0F6B4F)
  static const Color bgDark = jetBlack;                  // Solid Jet Black (#000000)
  static const Color cardDark = charcoalGrey;            // Charcoal Grey (#1C1C24)
  static const Color cardDark2 = Color(0xFF14141B);      // Elevated surface 2
  static const Color bgLight = Color(0xFFF2F4F8);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color incomeGreen = emeraldGreen;         // Emerald Green (#0F6B4F)
  static const Color expenseRed = deepCrimson;           // Deep Crimson (#8B0000)
  static const Color errorRed = deepCrimson;             // Deep Crimson (#8B0000)
  static const Color successGreen = emeraldGreen;        // Emerald Green (#0F6B4F)
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFA5A5B5);   // Muted neutral
  static const Color textGold = paleChampagne;           // Pale Champagne (#F5E2A1)
  static const Color divider = forestGreen;              // Forest Green (#0B2E20)
  static const Color borderForest = forestGreen;         // Forest Green (#0B2E20)
  static const Color borderGold = antiqueGold;           // Antique Gold (#3E3A1D)

  static const List<Color> chartColors = [
    champagneGold, emeraldGreen, deepCrimson, paleChampagne,
    Color(0xFF7C6FFF), Color(0xFFFFB547), Color(0xFF4FC3F7),
    Color(0xFF26C6DA), Color(0xFFAB47BC), Color(0xFF66BB6A),
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
      'Salary': emeraldGreen,
      'Bonus': champagneGold,
      'Business Income': Color(0xFFAB47BC),
      'Cashback': Color(0xFF00ACC1),
      'Consulting': Color(0xFF5C6BC0),
      'Family Transfer': Color(0xFFEC407A),
      'Fixed Deposit': Color(0xFF42A5F5),
      'Arrears': Color(0xFF26A69A),
      'Scholarship': Color(0xFF66BB6A),
      'Stock Dividends': champagneGold,
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
    scaffoldBackgroundColor: jetBlack,
    colorScheme: const ColorScheme.dark(
      primary: champagneGold,
      surface: charcoalGrey,
      onPrimary: Colors.black,
      onSurface: Colors.white,
      secondary: emeraldGreen,
      error: deepCrimson,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: jetBlack,
      foregroundColor: champagneGold,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: champagneGold,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
      iconTheme: IconThemeData(color: champagneGold),
    ),
    cardTheme: CardTheme(
      color: charcoalGrey,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: borderForest, width: 0.75),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: jetBlack,
      selectedItemColor: champagneGold,
      unselectedItemColor: Color(0xFF6E6E7A),
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: champagneGold,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.3),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: champagneGold,
        side: const BorderSide(color: antiqueGold, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: charcoalGrey,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderForest, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderForest, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: champagneGold, width: 1.5),
      ),
      hintStyle: const TextStyle(color: Color(0xFF6E6E78)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    dividerTheme: const DividerThemeData(color: borderForest, thickness: 1),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white),
      bodySmall: TextStyle(color: Color(0xFFA5A5B5)),
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
