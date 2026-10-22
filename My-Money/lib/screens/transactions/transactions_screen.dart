import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/expense.dart';
import '../../models/income.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';
import 'add_transaction_sheet.dart';
import 'recurring_sheet.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});
  @override
  State<TransactionsScreen> createState() => _State();
}

class _State extends State<TransactionsScreen> {
  String _search = '';
  bool _searching = false;
  bool _showAllTimeBalance = false;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final byDay = p.transactionsByDay;
    final allDays = byDay.keys.where((d)=>
      d.month==p.selectedMonth&&d.year==p.selectedYear).toList();
    final days = _search.isEmpty ? allDays : allDays.where((d){
      return byDay[d]!.any((t){
        final n=t is Expense?t.name:(t as Income).source;
        return n.toLowerCase().contains(_search.toLowerCase());
      });
    }).toList();

    return Scaffold(
      backgroundColor:AppTheme.bgDark,
      body:SafeArea(child:Column(children:[
        Padding(
          padding:const EdgeInsets.fromLTRB(20,16,8,0),
          child:Row(children:[
            Expanded(child:_searching
              ?TextField(autofocus:true,
                  decoration:const InputDecoration(hintText:'Search...'),
                  onChanged:(v)=>setState(()=>_search=v))
              :MonthNavigator(
                  month:p.selectedMonth,year:p.selectedYear,
                  onPrev:(){int m=p.selectedMonth-1,y=p.selectedYear;
                    if(m<1){m=12;y--;}p.setSelectedMonthYear(m,y);},
                  onNext:(){int m=p.selectedMonth+1,y=p.selectedYear;
                    if(m>12){m=1;y++;}p.setSelectedMonthYear(m,y);})),
            IconButton(icon:Icon(_searching?Icons.close:Icons.search,
              color:Colors.white),
              onPressed:()=>setState((){_searching=!_searching;_search='';})),
            IconButton(icon:const Icon(Icons.repeat,color:Colors.white),
              onPressed:()=>showModalBottomSheet(context:context,
                isScrollControlled:true,backgroundColor:Colors.transparent,
                builder:(_)=>const RecurringSheet())),
          ])),
        Padding(
          padding:const EdgeInsets.fromLTRB(16,12,16,8),
          child:Container(
            padding:const EdgeInsets.symmetric(vertical:10,horizontal:14),
            decoration:BoxDecoration(color:AppTheme.cardDark,
              borderRadius:BorderRadius.circular(14),
              border:Border.all(color:AppTheme.divider,width:0.5)),
            child:Column(children:[
              Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[
                Expanded(
                  child: Text(_showAllTimeBalance ? 'All-Time Totals' : 'Monthly Totals',
                    style:const TextStyle(color:AppTheme.textSecondary, fontSize:11, fontWeight:FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _showAllTimeBalance = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: !_showAllTimeBalance ? AppTheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_month_outlined, size: 12,
                                color: !_showAllTimeBalance ? Colors.black : Colors.white70),
                              const SizedBox(width: 3),
                              Text('Monthly', style: TextStyle(
                                color: !_showAllTimeBalance ? Colors.black : Colors.white70,
                                fontSize: 10, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _showAllTimeBalance = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _showAllTimeBalance ? AppTheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.all_inclusive_rounded, size: 12,
                                color: _showAllTimeBalance ? Colors.black : Colors.white70),
                              const SizedBox(width: 3),
                              Text('All-Time', style: TextStyle(
                                color: _showAllTimeBalance ? Colors.black : Colors.white70,
                                fontSize: 10, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height:8),
              Row(mainAxisAlignment:MainAxisAlignment.spaceAround,
                children:[
                _SI('Income', _showAllTimeBalance ? p.totalIncomeAllTime : p.totalIncomeThisMonth,
                  AppTheme.incomeGreen,Icons.arrow_downward),
                Container(width:1,height:28,color:AppTheme.divider),
                _SI('Expense', _showAllTimeBalance ? p.totalExpensesAllTime : p.totalExpensesThisMonth,
                  AppTheme.expenseRed,Icons.arrow_upward),
                Container(width:1,height:28,color:AppTheme.divider),
                _SI('Balance', (_showAllTimeBalance ? p.totalBalanceAllTime : p.netBalanceThisMonth).abs(),
                  (_showAllTimeBalance ? p.totalBalanceAllTime : p.netBalanceThisMonth)<0 ? AppTheme.expenseRed : AppTheme.incomeGreen,
                  _showAllTimeBalance ? Icons.all_inclusive_rounded : Icons.account_balance_wallet_outlined),
              ]),
            ]))),
        Expanded(child:days.isEmpty
          ?const EmptyState(icon:Icons.receipt_long_outlined,
              title:'No transactions',
              subtitle:'Tap + to add your first transaction')
          :ListView.builder(
              padding:const EdgeInsets.symmetric(horizontal:16),
              itemCount:days.length,
              itemBuilder:(_,i){
                final day=days[i];
                final items=_search.isEmpty?byDay[day]!:byDay[day]!.where((t){
                  final n=t is Expense?t.name:(t as Income).source;
                  return n.toLowerCase().contains(_search.toLowerCase());
                }).toList();
                return _DaySection(day:day,items:items);
              })),
      ])),
      floatingActionButton:FloatingActionButton(
        backgroundColor:AppTheme.primary,
        onPressed:()=>showModalBottomSheet(context:context,
          isScrollControlled:true,backgroundColor:Colors.transparent,
          builder:(_)=>const AddTransactionSheet()),
        child:const Icon(Icons.add,color:Colors.black)),
    );
  }
}

class _SI extends StatelessWidget {
  final String label; final double value;
  final Color color; final IconData icon;
  const _SI(this.label,this.value,this.color,this.icon);
  @override
  Widget build(BuildContext context)=>Column(children:[
    Row(mainAxisSize:MainAxisSize.min,children:[
      Icon(icon,color:color,size:12),const SizedBox(width:4),
      Text(label,style:const TextStyle(color:AppTheme.textSecondary,fontSize:11))]),
    const SizedBox(height:2),
    Text('₹${_f(value)}',style:TextStyle(color:color,
      fontWeight:FontWeight.bold,fontSize:13)),
  ]);
}

class _DaySection extends StatelessWidget {
  final DateTime day; final List<dynamic> items;
  const _DaySection({required this.day,required this.items});
  @override
  Widget build(BuildContext context){
    final now=DateTime.now();
    final isToday=day==DateTime(now.year,now.month,now.day);
    final total=items.fold<double>(0,(s,t)=>
      s+(t is Expense?-t.amount:(t as Income).amount));
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Padding(padding:const EdgeInsets.symmetric(vertical:10),
        child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
          Text(isToday?'Today':formatDate(day),
            style:const TextStyle(color:AppTheme.textSecondary,
              fontSize:12,fontWeight:FontWeight.w600)),
          Text('₹${_f(total.abs())}',style:TextStyle(
            color:total<0?AppTheme.expenseRed:AppTheme.incomeGreen,
            fontSize:12,fontWeight:FontWeight.w600)),
        ])),
      Container(
        decoration:BoxDecoration(color:AppTheme.cardDark,
          borderRadius:BorderRadius.circular(14)),
        child:Column(children:items.asMap().entries.map((e)=>
          _TxTile(t:e.value,isLast:e.key==items.length-1)).toList())),
      const SizedBox(height:8),
    ]);
  }
}

class _TxTile extends StatelessWidget {
  final dynamic t; final bool isLast;
  const _TxTile({required this.t,required this.isLast});
  @override
  Widget build(BuildContext context){
    final isExp=t is Expense;
    final cat=isExp?(t as Expense).category:(t as Income).category;
    final name=isExp?(t as Expense).name:(t as Income).source;
    final amt=isExp?(t as Expense).amount:(t as Income).amount;
    final method=isExp?(t as Expense).paymentMethod:(t as Income).paymentMethod;
    final date=isExp?(t as Expense).date:(t as Income).date;
    final color=AppTheme.getCategoryColor(cat);
    final p=context.read<AppProvider>();
    return Column(children:[
      ListTile(
        contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:4),
        leading:Container(width:42,height:42,
          decoration:BoxDecoration(color:color.withOpacity(0.15),
            borderRadius:BorderRadius.circular(12)),
          child:Icon(categoryIconData(p.getCategoryIcon(cat)),color:color,size:20)),
        title:Text(name,style:const TextStyle(fontSize:14,
          fontWeight:FontWeight.w500)),
        subtitle:Text('$cat · ${DateFormat('h:mm a').format(date)}',
          style:const TextStyle(color:AppTheme.textSecondary,fontSize:11)),
        trailing:Column(mainAxisAlignment:MainAxisAlignment.center,
          crossAxisAlignment:CrossAxisAlignment.end,children:[
          AmountText(amt,isExpense:isExp,fontSize:14),
          Text(method,style:const TextStyle(
            color:AppTheme.textSecondary,fontSize:10)),
        ]),
        onTap:()=>_detail(context,p)),
      if(!isLast)const Divider(indent:16,endIndent:16,
        height:1,color:AppTheme.divider),
    ]);
  }

  void _detail(BuildContext context,AppProvider p){
    final isExp=t is Expense;
    showModalBottomSheet(context:context,
      backgroundColor:AppTheme.cardDark,
      shape:const RoundedRectangleBorder(
        borderRadius:BorderRadius.vertical(top:Radius.circular(20))),
      builder:(_)=>Padding(padding:const EdgeInsets.all(20),
        child:Column(mainAxisSize:MainAxisSize.min,children:[
          Container(width:40,height:4,decoration:BoxDecoration(
            color:AppTheme.divider,borderRadius:BorderRadius.circular(2))),
          const SizedBox(height:16),
          Text(isExp?(t as Expense).name:(t as Income).source,
            style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
          const SizedBox(height:8),
          AmountText(isExp?(t as Expense).amount:(t as Income).amount,
            isExpense:isExp,fontSize:28,fontWeight:FontWeight.bold),
          const SizedBox(height:16),
          _DR('Category',isExp?(t as Expense).category:(t as Income).category),
          _DR('Date',formatDate(isExp?(t as Expense).date:(t as Income).date)),
          _DR('Payment',isExp?(t as Expense).paymentMethod:(t as Income).paymentMethod),
          _DR('Type',isExp?'Expense':'Income'),
          const SizedBox(height:16),
          Row(children:[
            Expanded(child:OutlinedButton.icon(
              icon:const Icon(Icons.edit_outlined),label:const Text('Edit'),
              style:OutlinedButton.styleFrom(foregroundColor:AppTheme.primary,
                side:const BorderSide(color:AppTheme.primary)),
              onPressed:(){
                Navigator.pop(context);
                showModalBottomSheet(context:context,isScrollControlled:true,
                  backgroundColor:Colors.transparent,
                  builder:(_)=>AddTransactionSheet(
                    editExpense:isExp?t:null,editIncome:!isExp?t:null));
              })),
            const SizedBox(width:12),
            Expanded(child:OutlinedButton.icon(
              icon:const Icon(Icons.delete_outline),label:const Text('Delete'),
              style:OutlinedButton.styleFrom(foregroundColor:AppTheme.expenseRed,
                side:const BorderSide(color:AppTheme.expenseRed)),
              onPressed:()async{
                Navigator.pop(context);
                if(isExp)await p.deleteExpense((t as Expense).id!);
                else await p.deleteIncome((t as Income).id!);
              })),
          ]),
          TextButton.icon(
            icon:const Icon(Icons.copy_outlined,size:16),
            label:const Text('Duplicate Transaction'),
            style:TextButton.styleFrom(foregroundColor:AppTheme.textSecondary),
            onPressed:(){
              Navigator.pop(context);
              showModalBottomSheet(context:context,isScrollControlled:true,
                backgroundColor:Colors.transparent,
                builder:(_)=>AddTransactionSheet(
                  editExpense:isExp?(t as Expense).copyWith(id:null):null,
                  editIncome:!isExp?(t as Income).copyWith(id:null):null));
            }),
        ])));
  }
}

Widget _DR(String l,String v)=>Padding(
  padding:const EdgeInsets.symmetric(vertical:6),
  child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
    Text(l,style:const TextStyle(color:AppTheme.textSecondary)),
    Text(v,style:const TextStyle(fontWeight:FontWeight.w500)),
  ]));

String _f(double v){
  if(v>=1000)return '${(v/1000).toStringAsFixed(1)}k';
  return v%1==0?v.toInt().toString():v.toStringAsFixed(1);
}
