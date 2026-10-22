import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/expense.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';
import '../transactions/add_transaction_sheet.dart';

class ExpensesTrackerScreen extends StatefulWidget {
  const ExpensesTrackerScreen({super.key});
  @override State<ExpensesTrackerScreen> createState() => _State();
}
class _State extends State<ExpensesTrackerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  @override void initState() { super.initState(); _tab=TabController(length:3,vsync:this); }
  @override void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(20,16,20,0),
          child: Row(children: [
            const Icon(Icons.receipt_long, color: AppTheme.primary, size: 22),
            const SizedBox(width: 8),
            const Text('Expenses Tracker',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ])),
        const SizedBox(height: 12),
        TabBar(controller: _tab,
          indicatorColor: AppTheme.primary, labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [Tab(text:'Daily'), Tab(text:'Weekly'), Tab(text:'Monthly')]),
        Expanded(child: TabBarView(controller: _tab, children: [
          _DailyView(p: p), _WeeklyView(p: p), _MonthlyView(p: p),
        ])),
      ])),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: () => showModalBottomSheet(context: context,
          isScrollControlled: true, backgroundColor: Colors.transparent,
          builder: (_) => const AddTransactionSheet()),
        child: const Icon(Icons.add, color: Colors.black)),
    );
  }
}

class _DailyView extends StatelessWidget {
  final AppProvider p;
  const _DailyView({required this.p});
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(4, (i) =>
      DateTime(now.year, now.month, now.day - i));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16,12,16,80),
      itemCount: days.length,
      itemBuilder: (_, i) {
        final day = days[i];
        final items = p.expenses.where((e) =>
          e.date.year==day.year&&e.date.month==day.month&&
          e.date.day==day.day).toList()
          ..sort((a,b)=>b.date.compareTo(a.date));
        final total = items.fold(0.0,(s,e)=>s+e.amount);
        return _DayBlock(
          label: i==0 ? 'Today' : DateFormat('d MMM yyyy').format(day),
          isActive: i==0, total: total, items: items, showDate: false);
      });
  }
}

class _WeeklyView extends StatelessWidget {
  final AppProvider p;
  const _WeeklyView({required this.p});
  DateTime _ws(DateTime d) =>
    DateTime(d.year, d.month, d.day-(d.weekday-1));
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weeks = List.generate(4,(i)=>_ws(now.subtract(Duration(days:i*7))));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16,12,16,80),
      itemCount: weeks.length,
      itemBuilder: (_, i) {
        final ws = weeks[i];
        final we = ws.add(const Duration(days:6));
        final items = p.expenses.where((e){
          final d=DateTime(e.date.year,e.date.month,e.date.day);
          return !d.isBefore(ws)&&!d.isAfter(we);
        }).toList()..sort((a,b)=>b.date.compareTo(a.date));
        final total = items.fold(0.0,(s,e)=>s+e.amount);
        final wn = ((ws.difference(DateTime(ws.year,1,1)).inDays)/7).ceil()+1;
        return _DayBlock(
          label: 'Week $wn · ${DateFormat("d MMM").format(ws)} – ${DateFormat("d MMM").format(we)}',
          isActive: i==0, total: total, items: items, showDate: true);
      });
  }
}

class _MonthlyView extends StatelessWidget {
  final AppProvider p;
  const _MonthlyView({required this.p});
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(4,(i)=>DateTime(now.year,now.month-i,1));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16,12,16,80),
      itemCount: months.length,
      itemBuilder: (_, i) {
        final m = months[i];
        final items = p.expenses.where((e)=>
          e.date.month==m.month&&e.date.year==m.year).toList()
          ..sort((a,b)=>b.date.compareTo(a.date));
        final total = items.fold(0.0,(s,e)=>s+e.amount);
        final catMap = <String,double>{};
        for(final e in items) catMap[e.category]=(catMap[e.category]??0)+e.amount;
        final topCats = catMap.entries.toList()..sort((a,b)=>b.value.compareTo(a.value));

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.symmetric(vertical:10),
            child: Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal:10,vertical:4),
                decoration: BoxDecoration(
                  color: i==0?AppTheme.primary.withOpacity(0.2):AppTheme.cardDark2,
                  borderRadius: BorderRadius.circular(8)),
                child: Text(DateFormat('MMMM yyyy').format(m),
                  style: TextStyle(fontSize:13,fontWeight:FontWeight.w600,
                    color:i==0?AppTheme.primary:AppTheme.textSecondary))),
              const Spacer(),
              Text('₹${_f(total)}', style: const TextStyle(
                color:AppTheme.expenseRed,fontWeight:FontWeight.bold,fontSize:14)),
            ])),
          // Category summary — fixed height with overflow scroll
          if(topCats.isNotEmpty)
            SizedBox(height: 76,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: topCats.length,
                separatorBuilder: (_,__)=>const SizedBox(width:8),
                itemBuilder: (_,j) {
                  final cat = topCats[j];
                  final color = AppTheme.getCategoryColor(cat.key);
                  final pct = total>0?cat.value/total*100:0;
                  return Container(
                    width: 100,
                    padding: const EdgeInsets.symmetric(horizontal:10,vertical:8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color:color.withOpacity(0.3))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cat.key,
                          style: TextStyle(color:color,fontSize:10,
                            fontWeight:FontWeight.w600),
                          maxLines:1, overflow:TextOverflow.ellipsis),
                        const SizedBox(height:3),
                        Text('₹${_f(cat.value)}',
                          style: const TextStyle(fontSize:13,
                            fontWeight:FontWeight.bold)),
                        Text('${pct.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color:AppTheme.textSecondary,fontSize:10)),
                      ]));
                })),
          const SizedBox(height:8),
          if(items.isNotEmpty) Container(
            decoration: BoxDecoration(color:AppTheme.cardDark,
              borderRadius:BorderRadius.circular(14)),
            child: Column(children: items.take(5).toList().asMap().entries
              .map((e)=>_ExpRow(exp:e.value,
                isLast:e.key==_min(4,items.length-1),showDate:true))
              .toList())),
          if(items.length>5)
            Padding(padding:const EdgeInsets.symmetric(vertical:6),
              child:Center(child:Text('+${items.length-5} more',
                style:const TextStyle(color:AppTheme.textSecondary,fontSize:12)))),
          const SizedBox(height:12),
        ]);
      });
  }
}

class _DayBlock extends StatelessWidget {
  final String label; final bool isActive;
  final double total; final List<Expense> items; final bool showDate;
  const _DayBlock({required this.label,required this.isActive,
    required this.total,required this.items,required this.showDate});
  @override
  Widget build(BuildContext context)=>Column(
    crossAxisAlignment:CrossAxisAlignment.start,children:[
    Padding(padding:const EdgeInsets.symmetric(vertical:10),
      child:Row(children:[
        Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:4),
          decoration:BoxDecoration(
            color:isActive?AppTheme.primary.withOpacity(0.2):AppTheme.cardDark2,
            borderRadius:BorderRadius.circular(8)),
          child:Text(label,style:TextStyle(fontSize:12,fontWeight:FontWeight.w600,
            color:isActive?AppTheme.primary:AppTheme.textSecondary))),
        const Spacer(),
        if(total>0)Text('₹${_f(total)}',style:const TextStyle(
          color:AppTheme.expenseRed,fontWeight:FontWeight.bold,fontSize:14)),
      ])),
    if(items.isEmpty)
      Padding(padding:const EdgeInsets.only(bottom:8),
        child:Container(padding:const EdgeInsets.all(14),
          decoration:BoxDecoration(color:AppTheme.cardDark,
            borderRadius:BorderRadius.circular(12)),
          child:const Center(child:Text('No expenses',
            style:TextStyle(color:AppTheme.textSecondary,fontSize:13)))))
    else Container(
      decoration:BoxDecoration(color:AppTheme.cardDark,
        borderRadius:BorderRadius.circular(14)),
      child:Column(children:items.asMap().entries.map((e)=>
        _ExpRow(exp:e.value,isLast:e.key==items.length-1,
          showDate:showDate)).toList())),
    const SizedBox(height:8),
  ]);
}

class _ExpRow extends StatelessWidget {
  final Expense exp; final bool isLast, showDate;
  const _ExpRow({required this.exp,required this.isLast,this.showDate=false});
  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getCategoryColor(exp.category);
    final p = context.read<AppProvider>();
    final catObj = p.categories.where((c)=>c.name==exp.category).toList();
    final iconName = catObj.isNotEmpty?catObj.first.icon:'category';
    return Column(children:[
      Material(color:Colors.transparent,child:ListTile(
        contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:2),
        leading:Container(width:40,height:40,
          decoration:BoxDecoration(color:color.withOpacity(0.15),
            borderRadius:BorderRadius.circular(10)),
          child:Icon(categoryIconData(iconName),color:color,size:20)),
        title:Text(exp.name,style:const TextStyle(fontSize:13,
          fontWeight:FontWeight.w500)),
        subtitle:Row(children:[
          Container(padding:const EdgeInsets.symmetric(horizontal:7,vertical:2),
            decoration:BoxDecoration(color:color.withOpacity(0.15),
              borderRadius:BorderRadius.circular(6)),
            child:Text(exp.category,style:TextStyle(color:color,fontSize:10))),
          if(showDate)...[
            const SizedBox(width:6),
            Text(DateFormat('d MMM').format(exp.date),
              style:const TextStyle(color:AppTheme.textSecondary,fontSize:10)),
          ],
        ]),
        trailing:Text('-₹${_f(exp.amount)}',style:const TextStyle(
          color:AppTheme.expenseRed,fontWeight:FontWeight.bold,fontSize:13)))),
      if(!isLast)const Divider(indent:16,endIndent:16,height:1,color:AppTheme.divider),
    ]);
  }
}

int _min(int a,int b)=>a<b?a:b;
String _f(double v){
  if(v>=100000)return '${(v/100000).toStringAsFixed(1)}L';
  if(v>=1000)return '${(v/1000).toStringAsFixed(1)}k';
  return v%1==0?v.toInt().toString():v.toStringAsFixed(1);
}
