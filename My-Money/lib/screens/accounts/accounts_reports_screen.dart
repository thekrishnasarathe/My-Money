import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';

class AccountsReportsScreen extends StatefulWidget {
  final int initialTab;
  const AccountsReportsScreen({super.key,this.initialTab=0});
  @override State<AccountsReportsScreen> createState()=>_State();
}
class _State extends State<AccountsReportsScreen>
    with SingleTickerProviderStateMixin{
  late TabController _tab;
  @override void initState(){super.initState();
    _tab=TabController(length:3,vsync:this,initialIndex:widget.initialTab);}
  @override void dispose(){_tab.dispose();super.dispose();}

  @override
  Widget build(BuildContext context){
    final p=context.watch<AppProvider>();
    return Scaffold(
      backgroundColor:AppTheme.bgDark,
      appBar:AppBar(title:const Text('Accounts & Reports'),
        bottom:TabBar(controller:_tab,
          indicatorColor:AppTheme.primary,
          labelColor:AppTheme.primary,
          unselectedLabelColor:AppTheme.textSecondary,
          tabs:const[Tab(text:'Accounts'),
            Tab(text:'Monthly'),Tab(text:'Weekly')])),
      body:TabBarView(controller:_tab,children:[
        _AccountsTab(p:p),
        _ReportTab(p:p,weekly:false),
        _ReportTab(p:p,weekly:true),
      ]));
  }
}

// ── ACCOUNTS ──
class _AccountsTab extends StatelessWidget{
  final AppProvider p;
  const _AccountsTab({required this.p});

  static const _accountIcons=[
    ['wallet','Wallet'],['account_balance','Bank'],
    ['payments','UPI'],['credit_card','Card'],
    ['savings','Savings'],['business','Business'],
    ['home','Property'],['directions_car','Vehicle'],
  ];

  @override
  Widget build(BuildContext context)=>Scaffold(
    backgroundColor:Colors.transparent,
    body:p.accounts.isEmpty
      ?const EmptyState(icon:Icons.account_balance_wallet_outlined,
          title:'No accounts',subtitle:'Tap + to add an account')
      :ListView(padding:const EdgeInsets.all(16),children:[
        // Total balance card
        Container(padding:const EdgeInsets.all(18),
          decoration:BoxDecoration(
            gradient:LinearGradient(colors:[
              AppTheme.primary.withOpacity(0.2),
              AppTheme.cardDark]),
            borderRadius:BorderRadius.circular(16)),
          child:Row(children:[
            const Icon(Icons.account_balance_wallet,
              color:AppTheme.primary,size:28),
            const SizedBox(width:12),
            Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              const Text('Total Balance',style:TextStyle(
                color:AppTheme.textSecondary,fontSize:12)),
              Text('₹${_f(p.totalBalance)}',style:const TextStyle(
                fontSize:26,fontWeight:FontWeight.bold,
                color:AppTheme.primary)),
            ]),
          ])),
        const SizedBox(height:12),
        ...p.accounts.map((a){
          final color=AppTheme.fromHex(a.color);
          return Container(margin:const EdgeInsets.only(bottom:8),
            decoration:BoxDecoration(color:AppTheme.cardDark,
              borderRadius:BorderRadius.circular(14)),
            child:ListTile(
              leading:Container(width:44,height:44,
                decoration:BoxDecoration(color:color.withOpacity(0.15),
                  borderRadius:BorderRadius.circular(12)),
                child:Icon(categoryIconData(a.icon),color:color,size:22)),
              title:Text(a.name,style:const TextStyle(
                fontWeight:FontWeight.w600,fontSize:14)),
              subtitle:Text(a.type,style:const TextStyle(
                color:AppTheme.textSecondary,fontSize:11)),
              trailing:Text('₹${_f(a.balance)}',style:TextStyle(
                color:a.balance>=0?AppTheme.incomeGreen:AppTheme.expenseRed,
                fontWeight:FontWeight.bold,fontSize:15)),
              onLongPress:()=>_confirmDelete(context,p,a)));
        }),
      ]),
    floatingActionButton:FloatingActionButton(
      backgroundColor:AppTheme.primary,
      onPressed:()=>showModalBottomSheet(context:context,
        isScrollControlled:true,backgroundColor:Colors.transparent,
        builder:(_)=>_AccountSheet(p:p)),
      child:const Icon(Icons.add,color:Colors.black)));

  void _confirmDelete(BuildContext ctx,AppProvider p,Account a){
    showDialog(context:ctx,builder:(_)=>AlertDialog(
      backgroundColor:AppTheme.cardDark,
      title:const Text('Delete Account'),
      content:Text('Delete "${a.name}"?'),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(ctx),
          child:const Text('Cancel')),
        TextButton(onPressed:()async{
          Navigator.pop(ctx);await p.deleteAccount(a.id!);},
          child:const Text('Delete',
            style:TextStyle(color:AppTheme.expenseRed))),
      ]));
  }
}

class _AccountSheet extends StatefulWidget{
  final AppProvider p;
  const _AccountSheet({required this.p});
  @override State<_AccountSheet> createState()=>_ASState();
}
class _ASState extends State<_AccountSheet>{
  final _nameCtrl=TextEditingController();
  final _balCtrl=TextEditingController();
  String _type='Cash',_color='#00C6A2',_icon='wallet';

  static const _quickTypes=[
    ['Cash','wallet','#43A047'],
    ['Bank','account_balance','#1E88E5'],
    ['UPI Wallet','payments','#AB47BC'],
    ['Credit Card','credit_card','#E53935'],
  ];
  static const _icons=['wallet','account_balance','payments','credit_card',
    'savings','business','home','directions_car','flight','shopping_bag'];

  @override void dispose(){_nameCtrl.dispose();_balCtrl.dispose();super.dispose();}

  @override
  Widget build(BuildContext context)=>Container(
    decoration:const BoxDecoration(color:AppTheme.cardDark,
      borderRadius:BorderRadius.vertical(top:Radius.circular(24))),
    padding:EdgeInsets.only(bottom:MediaQuery.of(context).viewInsets.bottom),
    child:SingleChildScrollView(padding:const EdgeInsets.all(20),
      child:Column(mainAxisSize:MainAxisSize.min,
        crossAxisAlignment:CrossAxisAlignment.start,children:[
      Center(child:Container(width:40,height:4,
        decoration:BoxDecoration(color:AppTheme.divider,
          borderRadius:BorderRadius.circular(2)))),
      const SizedBox(height:12),
      Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
        const Text('New Account',style:TextStyle(fontSize:18,
          fontWeight:FontWeight.bold)),
        IconButton(onPressed:()=>Navigator.pop(context),
          icon:const Icon(Icons.close)),
      ]),
      const SizedBox(height:12),
      const Text('QUICK ADD',style:TextStyle(color:AppTheme.textSecondary,
        fontSize:11,fontWeight:FontWeight.w600)),
      const SizedBox(height:8),
      Wrap(spacing:8,runSpacing:8,children:_quickTypes.map((qt){
        final sel=_type==qt[0];
        final c=AppTheme.fromHex(qt[2]);
        return GestureDetector(
          onTap:()=>setState((){_type=qt[0];_icon=qt[1];_color=qt[2];
            _nameCtrl.text=qt[0];}),
          child:Container(padding:const EdgeInsets.symmetric(
            horizontal:14,vertical:8),
            decoration:BoxDecoration(
              color:sel?c.withOpacity(0.2):AppTheme.cardDark2,
              borderRadius:BorderRadius.circular(20),
              border:sel?Border.all(color:c):null),
            child:Row(mainAxisSize:MainAxisSize.min,children:[
              Icon(categoryIconData(qt[1]),color:sel?c:AppTheme.textSecondary,
                size:16),
              const SizedBox(width:6),
              Text(qt[0],style:TextStyle(
                color:sel?c:AppTheme.textSecondary,fontSize:13)),
            ])));
      }).toList()),
      const SizedBox(height:14),
      Center(child:Container(width:64,height:64,
        decoration:BoxDecoration(
          color:AppTheme.fromHex(_color).withOpacity(0.15),
          borderRadius:BorderRadius.circular(18)),
        child:Icon(categoryIconData(_icon),
          color:AppTheme.fromHex(_color),size:32))),
      const SizedBox(height:14),
      TextField(controller:_nameCtrl,
        decoration:const InputDecoration(hintText:'Account Name',
          prefixIcon:Icon(Icons.label_outline,
            color:AppTheme.textSecondary))),
      const SizedBox(height:10),
      TextField(controller:_balCtrl,keyboardType:TextInputType.number,
        decoration:const InputDecoration(hintText:'Opening Balance',
          prefixIcon:Icon(Icons.account_balance_wallet_outlined,
            color:AppTheme.textSecondary))),
      const SizedBox(height:14),
      const Text('COLOR',style:TextStyle(color:AppTheme.textSecondary,
        fontSize:11,fontWeight:FontWeight.w600)),
      const SizedBox(height:8),
      ColorPickerRow(selected:_color,onSelect:(c)=>setState(()=>_color=c)),
      const SizedBox(height:12),
      const Text('ICON',style:TextStyle(color:AppTheme.textSecondary,
        fontSize:11,fontWeight:FontWeight.w600)),
      const SizedBox(height:8),
      Wrap(spacing:8,runSpacing:8,children:_icons.map((ico){
        final sel=ico==_icon;
        final color=AppTheme.fromHex(_color);
        return GestureDetector(
          onTap:()=>setState(()=>_icon=ico),
          child:Container(width:44,height:44,
            decoration:BoxDecoration(
              color:sel?color.withOpacity(0.2):AppTheme.cardDark2,
              borderRadius:BorderRadius.circular(10),
              border:sel?Border.all(color:color):null),
            child:Icon(categoryIconData(ico),
              color:sel?color:AppTheme.textSecondary,size:22)));
      }).toList()),
      const SizedBox(height:20),
      PrimaryButton(label:'Add Account',onTap:()async{
        if(_nameCtrl.text.trim().isEmpty)return;
        final bal=double.tryParse(_balCtrl.text)??0;
        await widget.p.addAccount(Account(name:_nameCtrl.text.trim(),
          type:_type,balance:bal,color:_color,icon:_icon,
          createdAt:DateTime.now()));
        if(mounted)Navigator.pop(context);
      }),
      const SizedBox(height:8),
    ])));
}

// ── REPORT TAB (monthly + weekly) ──
class _ReportTab extends StatelessWidget{
  final AppProvider p; final bool weekly;
  const _ReportTab({required this.p,required this.weekly});

  @override
  Widget build(BuildContext context){
    DateTime start,end;
    String title;
    if(weekly){
      final now=DateTime.now();
      final wd=now.weekday-1;
      start=DateTime(now.year,now.month,now.day-wd);
      end=start.add(const Duration(days:6));
      title='Week of ${DateFormat('d MMM').format(start)}';
    }else{
      start=DateTime(p.selectedYear,p.selectedMonth,1);
      end=DateTime(p.selectedYear,p.selectedMonth+1,0);
      title=DateFormat('MMMM yyyy').format(start);
    }

    final expenses=p.expenses.where((e){
      final d=e.date;
      return !d.isBefore(start)&&!d.isAfter(end);
    }).toList();
    final incomes=p.incomes.where((i){
      final d=i.date;
      return !d.isBefore(start)&&!d.isAfter(end);
    }).toList();

    final totalExp=expenses.fold(0.0,(s,e)=>s+e.amount);
    final totalInc=incomes.fold(0.0,(s,i)=>s+i.amount);
    final balance=totalInc-totalExp;
    final savings=totalInc>0?(balance/totalInc*100):0.0;
    final txCount=expenses.length+incomes.length;
    final days=weekly?7:end.day;
    final dailyAvg=days>0?totalExp/days:0.0;

    final catMap=<String,double>{};
    for(final e in expenses) catMap[e.category]=(catMap[e.category]??0)+e.amount;
    final cats=catMap.entries.toList()..sort((a,b)=>b.value.compareTo(a.value));
    final top3=expenses.toList()..sort((a,b)=>b.amount.compareTo(a.amount));

    return SingleChildScrollView(
      padding:const EdgeInsets.all(16),
      child:Column(children:[
        // Header
        Container(padding:const EdgeInsets.all(18),
          decoration:BoxDecoration(
            gradient:LinearGradient(colors:[
              AppTheme.primary.withOpacity(0.15),AppTheme.cardDark],
              begin:Alignment.topLeft,end:Alignment.bottomRight),
            borderRadius:BorderRadius.circular(16),
            border:Border.all(color:AppTheme.divider,width:0.5)),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(children:[
              Icon(weekly?Icons.calendar_view_week:Icons.calendar_month,
                color:AppTheme.primary,size:16),
              const SizedBox(width:6),
              Text(title,style:const TextStyle(
                color:AppTheme.textSecondary,fontSize:12)),
            ]),
            const SizedBox(height:4),
            Text(weekly?'Weekly Report':'Monthly Report',
              style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
            const SizedBox(height:16),
            Row(children:[
              _RI('Income','₹${_f(totalInc)}',AppTheme.incomeGreen),
              _RI('Expense','₹${_f(totalExp)}',AppTheme.expenseRed),
              _RI('Balance','₹${_f(balance.abs())}',
                balance<0?AppTheme.expenseRed:AppTheme.incomeGreen),
            ]),
            const SizedBox(height:10),
            Row(children:[
              _RI('Savings','${savings.toStringAsFixed(1)}%',AppTheme.primary),
              _RI('Transactions','$txCount',const Color(0xFF7C6FFF)),
              _RI('Daily Avg','₹${_f(dailyAvg)}',const Color(0xFFFFB547)),
            ]),
          ])),
        const SizedBox(height:12),
        // Category breakdown
        if(cats.isNotEmpty)Container(
          padding:const EdgeInsets.all(16),
          decoration:BoxDecoration(color:AppTheme.cardDark,
            borderRadius:BorderRadius.circular(14)),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('Expenses by Category',
              style:TextStyle(fontWeight:FontWeight.bold,fontSize:14)),
            const SizedBox(height:12),
            ...cats.map((e){
              final pct=totalExp>0?e.value/totalExp:0.0;
              final color=AppTheme.getCategoryColor(e.key);
              // get icon
              final catObj=p.categories.where((c)=>c.name==e.key).toList();
              final ico=catObj.isNotEmpty?catObj.first.icon:'category';
              return Padding(padding:const EdgeInsets.only(bottom:10),
                child:Column(children:[
                  Row(children:[
                    Container(width:32,height:32,
                      decoration:BoxDecoration(color:color.withOpacity(0.15),
                        borderRadius:BorderRadius.circular(8)),
                      child:Icon(categoryIconData(ico),color:color,size:16)),
                    const SizedBox(width:10),
                    Expanded(child:Text(e.key,
                      style:const TextStyle(fontSize:13))),
                    Text('₹${_f(e.value)}',style:TextStyle(
                      color:color,fontWeight:FontWeight.w600)),
                  ]),
                  const SizedBox(height:4),
                  LinearProgressIndicator(value:pct,
                    backgroundColor:AppTheme.divider,
                    valueColor:AlwaysStoppedAnimation(color),minHeight:4),
                ]));
            }),
          ])),
        const SizedBox(height:12),
        // Largest expenses
        if(top3.isNotEmpty)Container(
          padding:const EdgeInsets.all(16),
          decoration:BoxDecoration(color:AppTheme.cardDark,
            borderRadius:BorderRadius.circular(14)),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('Largest Expenses',
              style:TextStyle(fontWeight:FontWeight.bold,fontSize:14)),
            const SizedBox(height:10),
            ...top3.take(3).toList().asMap().entries.map((e){
              const medals=['🥇','🥈','🥉'];
              final exp=e.value;
              final color=AppTheme.getCategoryColor(exp.category);
              return ListTile(contentPadding:EdgeInsets.zero,
                leading:Text(medals[e.key],
                  style:const TextStyle(fontSize:22)),
                title:Text(exp.name,style:const TextStyle(fontSize:13)),
                subtitle:Text('${exp.category} · ${formatDateShort(exp.date)}',
                  style:const TextStyle(color:AppTheme.textSecondary,
                    fontSize:11)),
                trailing:Text('₹${_f(exp.amount)}',style:TextStyle(
                  color:color,fontWeight:FontWeight.bold)));
            }),
          ])),
        const SizedBox(height:80),
      ]));
  }
}

Widget _RI(String l,String v,Color c)=>Expanded(child:Column(children:[
  Text(l,style:const TextStyle(color:AppTheme.textSecondary,fontSize:10)),
  const SizedBox(height:2),
  Text(v,style:TextStyle(color:c,fontWeight:FontWeight.bold,fontSize:13)),
]));

String _f(double v){
  if(v>=100000)return '${(v/100000).toStringAsFixed(1)}L';
  if(v>=1000)return '${(v/1000).toStringAsFixed(1)}k';
  return v%1==0?v.toInt().toString():v.toStringAsFixed(1);
}
