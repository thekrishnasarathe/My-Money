import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(title: const Text('About')),
      body: SingleChildScrollView(
        child: Column(children: [
          // Hero banner
          Container(width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D3B2E), AppTheme.bgDark],
                begin: Alignment.topCenter, end: Alignment.bottomCenter)),
            child: Column(children: [
              Container(width: 76, height: 76,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.asset('assets/images/app_logo.png', fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(AppConstants.appName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                  color: Colors.white)),
              const SizedBox(height: 4),
              const Text(AppConstants.appTagline,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Container(padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.4))),
                child: Text('v${AppConstants.appVersion}',
                  style: const TextStyle(color: AppTheme.primary,
                    fontSize: 12, fontWeight: FontWeight.w600))),
            ])),
          Padding(padding: const EdgeInsets.all(16), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Created By
            _SectionTitle('👤  Created By'),
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                Container(width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.2),
                    shape: BoxShape.circle),
                  child: const Center(child: Text('KS',
                    style: TextStyle(color: AppTheme.primary,
                      fontWeight: FontWeight.bold, fontSize: 16)))),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(AppConstants.ownerName,
                    style: const TextStyle(fontWeight: FontWeight.bold,
                      fontSize: 16, color: Colors.white)),
                  const Text('Owner & Developer',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  Text(AppConstants.ownerEmail,
                    style: const TextStyle(color: AppTheme.primary, fontSize: 12)),
                ]),
              ])),
            const SizedBox(height: 20),
            // Ownership
            _SectionTitle('🔒  Ownership & Rights'),
            const SizedBox(height: 8),
            Container(width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2A20),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(AppConstants.copyright,
                  style: const TextStyle(color: AppTheme.primary,
                    fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  'This application is the exclusive intellectual property of '
                  '${AppConstants.ownerName}. Unauthorized copying, modification, '
                  'distribution, or use of this app or its source code without '
                  'explicit written permission from the owner is strictly prohibited.',
                  style: const TextStyle(color: Colors.white, fontSize: 13,
                    height: 1.5)),
              ])),
            const SizedBox(height: 20),
            // App Features
            _SectionTitle('📱  App Features'),
            const SizedBox(height: 8),
            Container(decoration: BoxDecoration(color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(14)),
              child: Column(children: [
                _FeatRow(Icons.receipt_long, 'Expenses Tracker',
                  'Daily, Weekly, Monthly views', AppTheme.expenseRed),
                _FeatRow(Icons.trending_up, 'Income Tracker',
                  'Track all earnings', AppTheme.incomeGreen),
                _FeatRow(Icons.handshake_outlined, 'Lender / Debt Tracker',
                  'Pending & paid with due dates', Colors.orange),
                _FeatRow(Icons.pie_chart_outline, 'Budget & Goals',
                  'Category-wise spending limits', const Color(0xFF7C6FFF)),
                _FeatRow(Icons.analytics_outlined, 'Analytics',
                  'Breakdown, Trends, Insights', AppTheme.primary),
                _FeatRow(Icons.account_balance_wallet_outlined, 'Accounts',
                  'Cash, Bank, UPI, Cards', const Color(0xFFFFB547)),
                _FeatRow(Icons.lock_outline, 'Security',
                  'PIN protection', const Color(0xFF42A5F5), isLast: true),
              ])),
            const SizedBox(height: 80),
          ])),
        ]),
      ),
    );
  }
}

Widget _SectionTitle(String t) => Text(t, style: const TextStyle(
  fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white));

Widget _FeatRow(IconData icon, String title, String sub, Color color,
    {bool isLast = false}) =>
  Column(children: [
    ListTile(
      leading: Container(width: 38, height: 38,
        decoration: BoxDecoration(color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20)),
      title: Text(title, style: const TextStyle(fontSize: 13,
        fontWeight: FontWeight.w500, color: Colors.white)),
      subtitle: Text(sub, style: const TextStyle(
        color: AppTheme.textSecondary, fontSize: 11))),
    if (!isLast) const Divider(indent: 60, endIndent: 16,
      height: 1, color: AppTheme.divider),
  ]);
