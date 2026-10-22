import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';

class BudgetsGoalsScreen extends StatefulWidget {
  final int initialTab;
  const BudgetsGoalsScreen({super.key,this.initialTab=0});
  @override State<BudgetsGoalsScreen> createState()=>_State();
}
class _State extends State<BudgetsGoalsScreen>
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
      appBar:AppBar(
        title:Text('Budgets & Goals — ${DateFormat('MMM yyyy').format(DateTime(p.selectedYear,p.selectedMonth))}'),
        bottom:TabBar(controller:_tab,
          indicatorColor:AppTheme.primary,
          labelColor:AppTheme.primary,
          unselectedLabelColor:AppTheme.textSecondary,
          tabs:const[Tab(text:'Monthly'),Tab(text:'Weekly'),Tab(text:'Goals')])),
      body:TabBarView(controller:_tab,children:[
        _BudgetTab(p:p,weekly:false),
        _BudgetTab(p:p,weekly:true),
        _GoalsTab(p:p),
      ]));
  }
}

class _BudgetTab extends StatelessWidget{
  final AppProvider p; final bool weekly;
  const _BudgetTab({required this.p,required this.weekly});

  @override
  Widget build(BuildContext context){
    final progress=p.getBudgetProgress();
    // filter by type
    final entries=progress.entries.where((e)=>
      weekly?(e.value['weekly_limit']??0)>0:
             (e.value['monthly_limit']??0)>0).toList();

    return Scaffold(
      backgroundColor:Colors.transparent,
      body:entries.isEmpty
        ?Center(child:Column(mainAxisSize:MainAxisSize.min,children:[
            Icon(weekly?Icons.calendar_view_week:Icons.calendar_month,
              size:56,color:AppTheme.textSecondary),
            const SizedBox(height:12),
            Text('No ${weekly?"weekly":"monthly"} budgets',
              style:const TextStyle(fontSize:16,fontWeight:FontWeight.w600)),
            const SizedBox(height:6),
            const Text('Tap + to set a budget',
              style:TextStyle(color:AppTheme.textSecondary)),
          ]))
        :ListView(padding:const EdgeInsets.all(16),
          children:entries.map((e){
            final limit=weekly?(e.value['weekly_limit']??0):
              (e.value['monthly_limit']??0);
            // for weekly, divide monthly spent by ~4
            final spent=weekly?e.value['spent']!/4:e.value['spent']!;
            final pct=limit>0?spent/limit*100:0.0;
            final color=pct>=100?AppTheme.expenseRed
              :pct>=80?Colors.orange:AppTheme.primary;
            final catColor=AppTheme.getCategoryColor(e.key);

            return Container(margin:const EdgeInsets.only(bottom:10),
              padding:const EdgeInsets.all(16),
              decoration:BoxDecoration(color:AppTheme.cardDark,
                borderRadius:BorderRadius.circular(14)),
              child:Column(children:[
                Row(children:[
                  Container(width:36,height:36,
                    decoration:BoxDecoration(
                      color:catColor.withOpacity(0.15),
                      borderRadius:BorderRadius.circular(10)),
                    child:Icon(categoryIconData(p.getCategoryIcon(e.key)),color:catColor,size:18)),
                  const SizedBox(width:12),
                  Expanded(child:Text(e.key,
                    style:const TextStyle(fontWeight:FontWeight.w600,
                      fontSize:14))),
                  Text('₹${_f(spent)} / ₹${_f(limit)}',
                    style:TextStyle(color:color,fontSize:12)),
                ]),
                const SizedBox(height:10),
                BudgetBar(pct:pct),
                const SizedBox(height:6),
                Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,
                  children:[
                  Text('${pct.toStringAsFixed(0)}% used',
                    style:TextStyle(color:color,fontSize:11)),
                  Text('₹${_f((limit-spent).clamp(0,double.infinity))} left',
                    style:const TextStyle(color:AppTheme.textSecondary,
                      fontSize:11)),
                ]),
              ]));
          }).toList()),
      floatingActionButton:FloatingActionButton(
        backgroundColor:AppTheme.primary,
        onPressed:()=>showModalBottomSheet(context:context,
          isScrollControlled:true,backgroundColor:Colors.transparent,
          builder:(_)=>_BudgetSheet(p:p)),
        child:const Icon(Icons.add,color:Colors.black)));
  }
}

class _BudgetSheet extends StatefulWidget{
  final AppProvider p;
  const _BudgetSheet({required this.p});
  @override State<_BudgetSheet> createState()=>_BSState();
}
class _BSState extends State<_BudgetSheet>{
  final _mCtrl=TextEditingController();
  final _wCtrl=TextEditingController();
  String _category='';
  @override void dispose(){_mCtrl.dispose();_wCtrl.dispose();super.dispose();}

  @override
  Widget build(BuildContext context){
    final cats=widget.p.expenseCategories();
    if(_category.isEmpty&&cats.isNotEmpty)_category=cats.first.name;
    return Container(
      decoration:const BoxDecoration(color:AppTheme.cardDark,
        borderRadius:BorderRadius.vertical(top:Radius.circular(24))),
      padding:EdgeInsets.only(bottom:MediaQuery.of(context).viewInsets.bottom),
      child:SingleChildScrollView(padding:const EdgeInsets.all(20),
        child:Column(mainAxisSize:MainAxisSize.min,children:[
        Center(child:Container(width:40,height:4,
          decoration:BoxDecoration(color:AppTheme.divider,
            borderRadius:BorderRadius.circular(2)))),
        const SizedBox(height:16),
        const Text('Set Budget',style:TextStyle(fontSize:18,
          fontWeight:FontWeight.bold)),
        const SizedBox(height:16),
        const Text('CATEGORY',style:TextStyle(color:AppTheme.textSecondary,
          fontSize:11,fontWeight:FontWeight.w600)),
        const SizedBox(height:8),
        SizedBox(height:64,child:ListView.separated(
          scrollDirection:Axis.horizontal,itemCount:cats.length,
          separatorBuilder:(_,__)=>const SizedBox(width:8),
          itemBuilder:(_,i){
            final c=cats[i];final sel=c.name==_category;
            final color=AppTheme.fromHex(c.color);
            return GestureDetector(onTap:()=>setState(()=>_category=c.name),
              child:Container(
                padding:const EdgeInsets.symmetric(horizontal:12,vertical:8),
                decoration:BoxDecoration(
                  color:sel?color.withOpacity(0.2):AppTheme.cardDark2,
                  borderRadius:BorderRadius.circular(14),
                  border:sel?Border.all(color:color):null),
                child:Column(mainAxisSize:MainAxisSize.min,children:[
                  Icon(categoryIconData(c.icon),
                    color:sel?color:AppTheme.textSecondary,size:20),
                  const SizedBox(height:4),
                  Text(c.name,style:TextStyle(
                    color:sel?color:AppTheme.textSecondary,
                    fontSize:11,fontWeight:sel?FontWeight.w600:FontWeight.normal)),
                ])));
          })),
        const SizedBox(height:14),
        TextField(controller:_mCtrl,keyboardType:TextInputType.number,
          decoration:const InputDecoration(labelText:'Monthly Limit (₹)',
            prefixIcon:Icon(Icons.calendar_month,color:AppTheme.textSecondary))),
        const SizedBox(height:10),
        TextField(controller:_wCtrl,keyboardType:TextInputType.number,
          decoration:const InputDecoration(labelText:'Weekly Limit (₹)',
            prefixIcon:Icon(Icons.calendar_view_week,
              color:AppTheme.textSecondary))),
        const SizedBox(height:20),
        PrimaryButton(label:'Set Budget',onTap:()async{
          final m=double.tryParse(_mCtrl.text)??0;
          final w=double.tryParse(_wCtrl.text)??0;
          if((m<=0&&w<=0)||_category.isEmpty)return;
          final p=widget.p;
          await p.addBudget(Budget(category:_category,
            monthlyLimit:m,weeklyLimit:w,
            month:p.selectedMonth,year:p.selectedYear,
            createdAt:DateTime.now()));
          if(mounted)Navigator.pop(context);
        }),
        const SizedBox(height:8),
      ])));
  }
}

class _GoalsTab extends StatelessWidget{
  final AppProvider p;
  const _GoalsTab({required this.p});

  @override
  Widget build(BuildContext context){
    return Scaffold(backgroundColor:Colors.transparent,
      body:p.goals.isEmpty
        ?const EmptyState(icon:Icons.savings_outlined,
            title:'No goals yet',subtitle:'Tap + to create a savings goal')
        :ListView(padding:const EdgeInsets.all(16),
          children:p.goals.map((g){
            final color=AppTheme.fromHex(g.color);
            return Container(margin:const EdgeInsets.only(bottom:10),
              padding:const EdgeInsets.all(16),
              decoration:BoxDecoration(color:AppTheme.cardDark,
                borderRadius:BorderRadius.circular(14)),
              child:Column(children:[
                Row(children:[
                  Container(width:44,height:44,
                    decoration:BoxDecoration(color:color.withOpacity(0.15),
                      borderRadius:BorderRadius.circular(12)),
                    child:Icon(categoryIconData(g.icon),color:color,size:22)),
                  const SizedBox(width:12),
                  Expanded(child:Column(
                    crossAxisAlignment:CrossAxisAlignment.start,children:[
                    Text(g.name,style:const TextStyle(fontWeight:FontWeight.w600,
                      fontSize:15)),
                    const SizedBox(height:2),
                    Text('₹${_f(g.savedAmount)} saved of ₹${_f(g.targetAmount)}',
                      style:const TextStyle(color:AppTheme.textSecondary,
                        fontSize:12)),
                  ])),
                  Column(crossAxisAlignment:CrossAxisAlignment.end,children:[
                    Text('${(g.progress*100).toStringAsFixed(0)}%',
                      style:TextStyle(color:color,fontWeight:FontWeight.bold,
                        fontSize:16)),
                    Text('₹${_f(g.remaining)} left',
                      style:const TextStyle(color:AppTheme.textSecondary,
                        fontSize:11)),
                  ]),
                ]),
                const SizedBox(height:10),
                ClipRRect(borderRadius:BorderRadius.circular(6),
                  child:LinearProgressIndicator(value:g.progress,
                    backgroundColor:AppTheme.divider,
                    valueColor:AlwaysStoppedAnimation(color),minHeight:8)),
                if(g.deadline!=null)...[
                  const SizedBox(height:6),
                  Row(children:[
                    const Icon(Icons.flag_outlined,size:12,
                      color:AppTheme.textSecondary),
                    const SizedBox(width:4),
                    Text('Deadline: ${formatDate(g.deadline!)}',
                      style:const TextStyle(color:AppTheme.textSecondary,
                        fontSize:11)),
                  ]),
                ],
              ]));
          }).toList()),
      floatingActionButton:FloatingActionButton(
        backgroundColor:AppTheme.primary,
        onPressed:()=>showModalBottomSheet(context:context,
          isScrollControlled:true,backgroundColor:Colors.transparent,
          builder:(_)=>_GoalSheet(p:p)),
        child:const Icon(Icons.add,color:Colors.black)));
  }
}

class _GoalSheet extends StatefulWidget{
  final AppProvider p;
  const _GoalSheet({required this.p});
  @override State<_GoalSheet> createState()=>_GSState();
}
class _GSState extends State<_GoalSheet>{
  final _nameCtrl=TextEditingController();
  final _targetCtrl=TextEditingController();
  final _savedCtrl=TextEditingController();
  String _color='#00C6A2',_icon='star';
  DateTime? _deadline;

  static const _icons=['star','savings','home','directions_car','school',
    'flight','shopping_bag','medical_services','business','card_giftcard',
    'account_balance','trending_up','attach_money','emoji_events','category'];

  @override void dispose(){
    _nameCtrl.dispose();_targetCtrl.dispose();_savedCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context)=>Container(
    decoration:const BoxDecoration(color:AppTheme.cardDark,
      borderRadius:BorderRadius.vertical(top:Radius.circular(24))),
    padding:EdgeInsets.only(bottom:MediaQuery.of(context).viewInsets.bottom),
    child:SingleChildScrollView(padding:const EdgeInsets.all(20),
      child:Column(mainAxisSize:MainAxisSize.min,children:[
      Center(child:Container(width:40,height:4,
        decoration:BoxDecoration(color:AppTheme.divider,
          borderRadius:BorderRadius.circular(2)))),
      const SizedBox(height:16),
      Center(child:Container(width:64,height:64,
        decoration:BoxDecoration(
          color:AppTheme.fromHex(_color).withOpacity(0.2),
          borderRadius:BorderRadius.circular(18)),
        child:Icon(categoryIconData(_icon),
          color:AppTheme.fromHex(_color),size:32))),
      const SizedBox(height:16),
      TextField(controller:_nameCtrl,
        decoration:const InputDecoration(hintText:'Goal Name',
          prefixIcon:Icon(Icons.flag_outlined,
            color:AppTheme.textSecondary))),
      const SizedBox(height:10),
      TextField(controller:_targetCtrl,keyboardType:TextInputType.number,
        decoration:const InputDecoration(labelText:'Target Amount (₹)',
          prefixIcon:Icon(Icons.track_changes,
            color:AppTheme.textSecondary))),
      const SizedBox(height:10),
      TextField(controller:_savedCtrl,keyboardType:TextInputType.number,
        decoration:const InputDecoration(labelText:'Already Saved (₹)',
          prefixIcon:Icon(Icons.savings_outlined,
            color:AppTheme.textSecondary))),
      const SizedBox(height:14),
      const Text('COLOR',style:TextStyle(color:AppTheme.textSecondary,
        fontSize:11,fontWeight:FontWeight.w600)),
      const SizedBox(height:8),
      ColorPickerRow(selected:_color,onSelect:(c)=>setState(()=>_color=c)),
      const SizedBox(height:14),
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
      const SizedBox(height:12),
      ListTile(contentPadding:EdgeInsets.zero,
        title:const Text('Deadline (optional)',
          style:TextStyle(color:AppTheme.textSecondary,fontSize:13)),
        trailing:Text(_deadline==null?'No deadline':formatDate(_deadline!),
          style:const TextStyle(color:AppTheme.primary)),
        onTap:()async{
          final d=await showDatePicker(context:context,
            initialDate:DateTime.now().add(const Duration(days:30)),
            firstDate:DateTime.now(),lastDate:DateTime(2035));
          if(d!=null)setState(()=>_deadline=d);
        }),
      const SizedBox(height:16),
      PrimaryButton(label:'Create Goal',onTap:()async{
        final t=double.tryParse(_targetCtrl.text);
        if(t==null||_nameCtrl.text.trim().isEmpty)return;
        final saved=double.tryParse(_savedCtrl.text)??0;
        await widget.p.addGoal(SavingsGoal(
          name:_nameCtrl.text.trim(),targetAmount:t,savedAmount:saved,
          color:_color,icon:_icon,deadline:_deadline,
          createdAt:DateTime.now()));
        if(mounted)Navigator.pop(context);
      }),
      const SizedBox(height:8),
    ])));
}

String _f(double v){
  if(v>=100000)return '${(v/100000).toStringAsFixed(1)}L';
  if(v>=1000)return '${(v/1000).toStringAsFixed(1)}k';
  return v%1==0?v.toInt().toString():v.toStringAsFixed(1);
}
