import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../budgets/budgets_goals_screen.dart';
import '../accounts/accounts_reports_screen.dart';
import '../expenses/expenses_screen.dart';
import 'data_screen.dart';
import 'spending_control_screen.dart';
import 'preferences_screen.dart';
import 'security_screen.dart';
import '../about_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('More', style: TextStyle(fontSize:24, fontWeight:FontWeight.bold)),
          const SizedBox(height: 20),
          _S('EXPENSES',[
            _I(Icons.receipt_long_outlined,'Expenses Tracker',
              'Daily, weekly & monthly view',
              ()=>_go(context,const ExpensesTrackerScreen())),
          ]),
          const SizedBox(height:14),
          _S('BUDGETS & GOALS',[
            _I(Icons.pie_chart_outline,'Monthly Budgets','Set spending limits',
              ()=>_go(context,const BudgetsGoalsScreen())),
            _I(Icons.calendar_view_week,'Weekly Budgets','Set weekly limits',
              ()=>_go(context,const BudgetsGoalsScreen(initialTab:1))),
            _I(Icons.savings_outlined,'Savings Goals','Track your savings targets',
              ()=>_go(context,const BudgetsGoalsScreen(initialTab:2))),
          ]),
          const SizedBox(height:14),
          _S('ACCOUNTS & REPORTS',[
            _I(Icons.account_balance_wallet_outlined,'Accounts',
              'Cash, bank and wallet balances',
              ()=>_go(context,const AccountsReportsScreen())),
            _I(Icons.calendar_month,'Monthly Report','Full monthly summary',
              ()=>_go(context,const AccountsReportsScreen(initialTab:1))),
            _I(Icons.calendar_view_week,'Weekly Report','This week summary',
              ()=>_go(context,const AccountsReportsScreen(initialTab:2))),
          ]),
          const SizedBox(height:14),
          _S('SPENDING CONTROL',[
            _I(Icons.shield_outlined,'Spending Limits',
              'Monthly & weekly budget limits',
              ()=>_go(context,const SpendingControlScreen())),
          ]),
          const SizedBox(height:14),
          _S('DATA',[
            _I(Icons.import_export_outlined,'Import / Export',
              'CSV, JSON, PDF backup & restore',
              ()=>_go(context,const DataScreen())),
          ]),
          const SizedBox(height:14),
          _S('SETTINGS',[
            _I(Icons.palette_outlined,'Preferences',
              'Theme & notification settings',
              ()=>_go(context,const PreferencesScreen())),
            _I(Icons.lock_outline,'Security','PIN protection',
              ()=>_go(context,const SecurityScreen())),
          ]),
          const SizedBox(height:14),
          _S('INFO',[
            _I(Icons.info_outline,'About ${AppConstants.appName}',
              'Version 2.0.0 — Personal finance tracker',
              ()=>_go(context,const AboutScreen())),
          ]),
          const SizedBox(height:40),
        ]),
      )),
    );
  }

  void _go(BuildContext ctx, Widget s) =>
    Navigator.push(ctx, MaterialPageRoute(builder:(_)=>s));
}

Widget _S(String title, List<Widget> items) => Column(
  crossAxisAlignment:CrossAxisAlignment.start, children:[
  Text(title, style:const TextStyle(color:AppTheme.textSecondary,
    fontSize:11,fontWeight:FontWeight.w600,letterSpacing:0.5)),
  const SizedBox(height:8),
  Container(decoration:BoxDecoration(color:AppTheme.cardDark,
    borderRadius:BorderRadius.circular(16)),
  child:Column(children:items.asMap().entries.map((e)=>Column(children:[
    e.value,
    if(e.key<items.length-1)
      const Divider(indent:60,endIndent:16,height:1,color:AppTheme.divider),
  ])).toList())),
]);

Widget _I(IconData icon,String title,String sub,VoidCallback onTap)=>
  ListTile(
    leading:Container(width:38,height:38,
      decoration:BoxDecoration(color:AppTheme.primary.withOpacity(0.1),
        borderRadius:BorderRadius.circular(10)),
      child:Icon(icon,color:AppTheme.primary,size:20)),
    title:Text(title,style:const TextStyle(fontSize:14,fontWeight:FontWeight.w500)),
    subtitle:Text(sub,style:const TextStyle(color:AppTheme.textSecondary,fontSize:11)),
    trailing:const Icon(Icons.chevron_right,color:AppTheme.textSecondary,size:18),
    onTap:onTap);
