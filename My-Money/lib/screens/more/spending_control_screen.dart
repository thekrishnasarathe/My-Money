import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';

class SpendingControlScreen extends StatefulWidget {
  const SpendingControlScreen({super.key});
  @override State<SpendingControlScreen> createState()=>_State();
}
class _State extends State<SpendingControlScreen>{
  final _mCtrl=TextEditingController();
  final _wCtrl=TextEditingController();
  @override
  void initState(){
    super.initState();
    final p=context.read<AppProvider>();
    _mCtrl.text=p.monthlySpendLimit>0?p.monthlySpendLimit.toString():'';
    _wCtrl.text=p.weeklySpendLimit>0?p.weeklySpendLimit.toString():'';
  }
  @override void dispose(){_mCtrl.dispose();_wCtrl.dispose();super.dispose();}

  @override
  Widget build(BuildContext context){
    final p=context.watch<AppProvider>();
    final mPct=p.monthlySpendLimit>0
      ?p.totalExpensesThisMonth/p.monthlySpendLimit*100:0.0;
    return Scaffold(
      backgroundColor:AppTheme.bgDark,
      appBar:AppBar(title:const Text('Spending Control')),
      body:Padding(padding:const EdgeInsets.all(20),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        if(p.monthlySpendLimit>0)...[
          SectionCard(child:Column(
            crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('This Month',
              style:TextStyle(color:AppTheme.textSecondary,fontSize:12)),
            const SizedBox(height:8),
            Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
              Text('₹${_f(p.totalExpensesThisMonth)}',
                style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
              Text('/ ₹${_f(p.monthlySpendLimit)}',
                style:const TextStyle(color:AppTheme.textSecondary)),
            ]),
            const SizedBox(height:10),
            BudgetBar(pct:mPct),
            const SizedBox(height:6),
            Text('${mPct.toStringAsFixed(1)}% of monthly limit used',
              style:const TextStyle(color:AppTheme.textSecondary,fontSize:12)),
          ])),
          const SizedBox(height:20),
        ],
        const Text('Monthly Limit (₹)',
          style:TextStyle(fontWeight:FontWeight.w600)),
        const SizedBox(height:8),
        TextField(controller:_mCtrl,keyboardType:TextInputType.number,
          decoration:const InputDecoration(hintText:'e.g. 10000')),
        const SizedBox(height:16),
        const Text('Weekly Limit (₹)',
          style:TextStyle(fontWeight:FontWeight.w600)),
        const SizedBox(height:8),
        TextField(controller:_wCtrl,keyboardType:TextInputType.number,
          decoration:const InputDecoration(hintText:'e.g. 2500')),
        const SizedBox(height:24),
        PrimaryButton(label:'Save Limits',onTap:()async{
          final m=double.tryParse(_mCtrl.text)??0;
          final w=double.tryParse(_wCtrl.text)??0;
          await p.setSpendLimits(m,w);
          if(mounted)ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content:Text('Limits saved')));
        }),
      ])));
  }
}
String _f(double v)=>v>=1000?'${(v/1000).toStringAsFixed(1)}k':
  v%1==0?v.toInt().toString():v.toStringAsFixed(1);
