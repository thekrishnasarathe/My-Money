import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';
import '../ai_coach/ai_coach_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _State();
}

class _State extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  @override
  void initState() { super.initState(); _tab = TabController(length:4,vsync:this); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20,16,16,0),
          child: Row(children: [
            Expanded(child: MonthNavigator(
              month: p.selectedMonth, year: p.selectedYear,
              onPrev: () { int m=p.selectedMonth-1,y=p.selectedYear;
                if(m<1){m=12;y--;} p.setSelectedMonthYear(m,y); },
              onNext: () { int m=p.selectedMonth+1,y=p.selectedYear;
                if(m>12){m=1;y++;} p.setSelectedMonthYear(m,y); },
            )),
          ]),
        ),
        const SizedBox(height:12),
        TabBar(
          controller: _tab,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text:'Breakdown'), Tab(text:'Trends'),
            Tab(text:'Insights'), Tab(text:'Top Spends'),
          ],
        ),
        Expanded(child: TabBarView(controller: _tab, children: [
          _BreakdownTab(p: p),
          _TrendsTab(p: p),
          _InsightsTab(p: p),
          _TopSpendsTab(p: p),
        ])),
      ])),
    );
  }
}

// ══════════════════════════════════════════
// BREAKDOWN TAB
// ══════════════════════════════════════════
class _BreakdownTab extends StatefulWidget {
  final AppProvider p;
  const _BreakdownTab({required this.p});
  @override
  State<_BreakdownTab> createState() => _BState();
}
class _BState extends State<_BreakdownTab> {
  bool _showExpense = true;
  int _touchedIdx = -1;

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final data = _showExpense ? p.categoryBreakdown : p.incomeCategoryBreakdown;
    final total = _showExpense ? p.totalExpensesThisMonth : p.totalIncomeThisMonth;
    final entries = data.entries.toList()
      ..sort((a,b)=>b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Toggle
        Container(
          decoration: BoxDecoration(color:AppTheme.cardDark2,
            borderRadius:BorderRadius.circular(12)),
          child: Row(children: [
            _TTab('Expenses',_showExpense,()=>setState(()=>_showExpense=true)),
            _TTab('Income',!_showExpense,()=>setState(()=>_showExpense=false)),
          ]),
        ),
        const SizedBox(height:20),
        // Total
        Text(_showExpense?'₹${_f(total)} Total Expenses'
          :'₹${_f(total)} Total Income',
          style: const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
        const SizedBox(height:4),
        Text('Total ${_showExpense?"Expenses":"Income"}',
          style:const TextStyle(color:AppTheme.textSecondary,fontSize:13)),
        const SizedBox(height:24),
        // Donut chart
        if (entries.isEmpty)
          const EmptyState(icon:Icons.pie_chart_outline,
            title:'No data this month')
        else SizedBox(height:220, child:PieChart(PieChartData(
          sectionsSpace: 2, centerSpaceRadius: 60,
          pieTouchData: PieTouchData(touchCallback:(e,r){
            setState((){
              _touchedIdx = r?.touchedSection?.touchedSectionIndex ?? -1;
            });
          }),
          sections: entries.asMap().entries.map((e){
            final isTouched = e.key == _touchedIdx;
            final color = AppTheme.chartColor(e.key);
            final pct = total>0 ? e.value.value/total*100 : 0;
            return PieChartSectionData(
              color: color, value: e.value.value,
              radius: isTouched ? 65 : 55,
              title: '${pct.toStringAsFixed(0)}%',
              titleStyle: TextStyle(fontSize:isTouched?13:11,
                fontWeight:FontWeight.bold,color:Colors.white),
            );
          }).toList(),
        ))),
        const SizedBox(height:20),
        // Legend list
        ...entries.asMap().entries.map((e) {
          final color = AppTheme.chartColor(e.key);
          final pct = total>0 ? e.value.value/total*100 : 0;
          return Column(children:[
            Row(children:[
              Container(width:12,height:12,
                decoration:BoxDecoration(color:color,shape:BoxShape.circle)),
              const SizedBox(width:10),
              Expanded(child:Text(e.value.key,
                style:const TextStyle(fontSize:13))),
              Text('₹${_f(e.value.value)}',
                style:TextStyle(color:color,fontWeight:FontWeight.w600)),
              const SizedBox(width:8),
              Text('${pct.toStringAsFixed(1)}%',
                style:const TextStyle(color:AppTheme.textSecondary,fontSize:12)),
            ]),
            const SizedBox(height:6),
            LinearProgressIndicator(value:(pct/100).clamp(0,1),
              backgroundColor:AppTheme.divider,
              valueColor:AlwaysStoppedAnimation(color),minHeight:4),
            const SizedBox(height:10),
          ]);
        }),
        // By payment method
        const SizedBox(height:8),
        const Align(alignment:Alignment.centerLeft,
          child:Text('By Payment Method',
            style:TextStyle(fontSize:15,fontWeight:FontWeight.bold))),
        const SizedBox(height:12),
        ...p.paymentMethodBreakdown.entries.map((e){
          final pct = total>0?e.value/total*100:0;
          return Padding(padding:const EdgeInsets.only(bottom:10),
            child:Column(children:[
              Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
                Text(e.key,style:const TextStyle(fontSize:13)),
                Text('${pct.toStringAsFixed(0)}%',
                  style:const TextStyle(color:AppTheme.textSecondary,fontSize:12)),
              ]),
              const SizedBox(height:4),
              LinearProgressIndicator(value:(pct/100).clamp(0,1),
                backgroundColor:AppTheme.divider,
                valueColor:const AlwaysStoppedAnimation(AppTheme.primary),
                minHeight:5),
            ]));
        }),
        const SizedBox(height:80),
      ]),
    );
  }
}

// ══════════════════════════════════════════
// TRENDS TAB
// ══════════════════════════════════════════
class _TrendsTab extends StatelessWidget {
  final AppProvider p;
  const _TrendsTab({required this.p});

  @override
  Widget build(BuildContext context) {
    final overview = p.sixMonthOverview;
    final daily = p.dailySpendingMap;
    final maxDaily = daily.values.isEmpty ? 1.0
      : daily.values.reduce((a,b)=>a>b?a:b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
        // 6-month line chart
        const Text('6-Month Overview',
          style:TextStyle(fontSize:15,fontWeight:FontWeight.bold)),
        const SizedBox(height:4),
        Row(children:[
          _Dot(AppTheme.expenseRed,'Expense'),
          const SizedBox(width:16),
          _Dot(AppTheme.incomeGreen,'Income'),
        ]),
        const SizedBox(height:12),
        SizedBox(height:180, child:LineChart(LineChartData(
          gridData:FlGridData(show:true,
            getDrawingHorizontalLine:(_)=>FlLine(
              color:AppTheme.divider,strokeWidth:0.5),
            drawVerticalLine:false),
          borderData:FlBorderData(show:false),
          titlesData:FlTitlesData(
            bottomTitles:AxisTitles(sideTitles:SideTitles(
              showTitles:true,reservedSize:22,
              getTitlesWidget:(v,_){
                final i=v.toInt();
                if(i<0||i>=overview.length)return const SizedBox.shrink();
                return Text(DateFormat('MMM').format(overview[i]['month']),
                  style:const TextStyle(color:AppTheme.textSecondary,fontSize:10));
              })),
            leftTitles:AxisTitles(sideTitles:SideTitles(showTitles:false)),
            topTitles:AxisTitles(sideTitles:SideTitles(showTitles:false)),
            rightTitles:AxisTitles(sideTitles:SideTitles(showTitles:false)),
          ),
          lineBarsData:[
            LineChartBarData(
              spots:overview.asMap().entries.map((e)=>
                FlSpot(e.key.toDouble(),(e.value['expense'] as double))).toList(),
              isCurved:true,color:AppTheme.expenseRed,
              barWidth:2,dotData:FlDotData(show:false),
              belowBarData:BarAreaData(show:true,
                color:AppTheme.expenseRed.withOpacity(0.1))),
            LineChartBarData(
              spots:overview.asMap().entries.map((e)=>
                FlSpot(e.key.toDouble(),(e.value['income'] as double))).toList(),
              isCurved:true,color:AppTheme.incomeGreen,
              barWidth:2,dotData:FlDotData(show:false),
              belowBarData:BarAreaData(show:true,
                color:AppTheme.incomeGreen.withOpacity(0.1))),
          ],
        ))),
        const SizedBox(height:8),
        // Month table
        ...overview.reversed.take(3).map((o){
          final m = o['month'] as DateTime;
          final exp = o['expense'] as double;
          final inc = o['income'] as double;
          final saved = inc>0?(inc-exp)/inc*100:0.0;
          return Padding(padding:const EdgeInsets.symmetric(vertical:4),
            child:Row(children:[
              SizedBox(width:40,child:Text(DateFormat('MMM').format(m),
                style:const TextStyle(color:AppTheme.textSecondary,fontSize:12))),
              Expanded(child:Text('₹${_f(exp)}',
                style:const TextStyle(color:AppTheme.expenseRed,fontSize:12))),
              Expanded(child:Text('₹${_f(inc)}',
                style:const TextStyle(color:AppTheme.incomeGreen,fontSize:12))),
              Text('${saved.toStringAsFixed(0)}% saved',
                style:const TextStyle(color:AppTheme.textSecondary,fontSize:11)),
            ]));
        }),
        const SizedBox(height:24),
        // Daily spending bar chart
        const Text('Daily Spending',
          style:TextStyle(fontSize:15,fontWeight:FontWeight.bold)),
        const SizedBox(height:12),
        SizedBox(height:140,child:BarChart(BarChartData(
          gridData:FlGridData(show:false),
          borderData:FlBorderData(show:false),
          titlesData:FlTitlesData(
            bottomTitles:AxisTitles(sideTitles:SideTitles(
              showTitles:true,reservedSize:18,
              getTitlesWidget:(v,_){
                final d=v.toInt();
                if(d%5!=0&&d!=1)return const SizedBox.shrink();
                return Text('$d',style:const TextStyle(
                  color:AppTheme.textSecondary,fontSize:9));
              })),
            leftTitles:AxisTitles(sideTitles:SideTitles(showTitles:false)),
            topTitles:AxisTitles(sideTitles:SideTitles(showTitles:false)),
            rightTitles:AxisTitles(sideTitles:SideTitles(showTitles:false)),
          ),
          barGroups: List.generate(31,(i){
            final day=i+1;
            final val=daily[day]??0.0;
            return BarChartGroupData(x:day,barRods:[
              BarChartRodData(toY:val,
                color:val==maxDaily?AppTheme.expenseRed:AppTheme.primary,
                width:6,borderRadius:BorderRadius.circular(3)),
            ]);
          }),
        ))),
        const SizedBox(height:80),
      ]),
    );
  }
}

// ══════════════════════════════════════════
// INSIGHTS TAB
// ══════════════════════════════════════════
class _InsightsTab extends StatelessWidget {
  final AppProvider p;
  const _InsightsTab({required this.p});

  @override
  Widget build(BuildContext context) {
    final wdMap = p.weekdaySpendingMap;
    final wdLabels = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    final maxWd = wdMap.values.isEmpty ? 1.0
      : wdMap.values.reduce((a,b)=>a>b?a:b);
    final allTime = p.expenses.fold(0.0,(s,e)=>s+e.amount);
    final allInc = p.incomes.fold(0.0,(s,i)=>s+i.amount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        // Spending by weekday
        const Text('Spending by Weekday',
          style:TextStyle(fontSize:15,fontWeight:FontWeight.bold)),
        const SizedBox(height:12),
        SizedBox(height:160,child:BarChart(BarChartData(
          gridData:FlGridData(show:false),
          borderData:FlBorderData(show:false),
          titlesData:FlTitlesData(
            bottomTitles:AxisTitles(sideTitles:SideTitles(
              showTitles:true,reservedSize:20,
              getTitlesWidget:(v,_){
                final i=v.toInt();
                if(i<0||i>6)return const SizedBox.shrink();
                return Text(wdLabels[i],style:const TextStyle(
                  color:AppTheme.textSecondary,fontSize:10));
              })),
            leftTitles:AxisTitles(sideTitles:SideTitles(showTitles:false)),
            topTitles:AxisTitles(sideTitles:SideTitles(showTitles:false)),
            rightTitles:AxisTitles(sideTitles:SideTitles(showTitles:false)),
          ),
          barGroups:List.generate(7,(i){
            final val=wdMap[i]??0.0;
            return BarChartGroupData(x:i,barRods:[
              BarChartRodData(toY:val,
                color:val==maxWd?AppTheme.primary:AppTheme.primary.withOpacity(0.5),
                width:28,borderRadius:BorderRadius.circular(6)),
            ]);
          }),
        ))),
        // Weekday detail rows
        ...List.generate(7,(i){
          final val=wdMap[i]??0.0;
          return Padding(padding:const EdgeInsets.symmetric(vertical:3),
            child:Row(children:[
              SizedBox(width:40,child:Text(wdLabels[i],
                style:const TextStyle(color:AppTheme.textSecondary,fontSize:12))),
              Expanded(child:LinearProgressIndicator(
                value:maxWd>0?(val/maxWd).clamp(0,1):0,
                backgroundColor:AppTheme.divider,
                valueColor:AlwaysStoppedAnimation(
                  val==maxWd?AppTheme.primary:AppTheme.primary.withOpacity(0.5)),
                minHeight:4)),
              const SizedBox(width:8),
              Text(val>0?'₹${_f(val)}':'—',
                style:const TextStyle(color:AppTheme.textSecondary,fontSize:12)),
            ]));
        }),
        const SizedBox(height:24),
        // All-time stats
        const Text('All-Time Stats',
          style:TextStyle(fontSize:15,fontWeight:FontWeight.bold)),
        const SizedBox(height:12),
        Row(children:[
          Expanded(child:_StatBox('Total Spent','₹${_f(allTime)}',
            AppTheme.expenseRed)),
          const SizedBox(width:12),
          Expanded(child:_StatBox('Total Income','₹${_f(allInc)}',
            AppTheme.incomeGreen)),
        ]),
        const SizedBox(height:12),
        Row(children:[
          Expanded(child:_StatBox('Transactions',
            '${p.expenses.length+p.incomes.length}',AppTheme.primary)),
          const SizedBox(width:12),
          Expanded(child:_StatBox('Avg/Month',
            '₹${_f(allTime/6)}',const Color(0xFFFFB547))),
        ]),
        const SizedBox(height:20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primary.withOpacity(0.14), AppTheme.cardDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primary.withOpacity(0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: AppTheme.primary, size: 18),
                  SizedBox(width: 8),
                  Text('AI Spending Analytics & Anomalies',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Let the AI Financial Coach analyze your category distribution, weekday habits, and detect spending spikes.',
                style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.35),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Explain Trends & Anomalies with AI ✨',
                onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AiCoachScreen(
                    initialQuery: 'Explain my spending analytics, category breakdown, and any anomalies for this month.',
                  ))),
              ),
            ],
          ),
        ),
        const SizedBox(height:80),
      ]),
    );
  }
}

// ══════════════════════════════════════════
// TOP SPENDS TAB
// ══════════════════════════════════════════
class _TopSpendsTab extends StatelessWidget {
  final AppProvider p;
  const _TopSpendsTab({required this.p});

  @override
  Widget build(BuildContext context) {
    final top = p.topSpends;
    const medals = ['🥇','🥈','🥉'];

    return top.isEmpty
      ? const EmptyState(icon:Icons.trending_up,
          title:'No expenses this month')
      : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: top.length,
          itemBuilder: (_,i) {
            final e = top[i];
            final color = AppTheme.getCategoryColor(e.category);
            final pct = p.totalExpensesThisMonth>0
              ? e.amount/p.totalExpensesThisMonth*100 : 0;
            return Container(
              margin: const EdgeInsets.only(bottom:10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color:AppTheme.cardDark,
                borderRadius:BorderRadius.circular(14)),
              child: Row(children:[
                Text(i<3?medals[i]:'${i+1}',
                  style:const TextStyle(fontSize:18)),
                const SizedBox(width:12),
                Container(width:38,height:38,
                  decoration:BoxDecoration(color:color.withOpacity(0.15),
                    borderRadius:BorderRadius.circular(10)),
                  child:Icon(categoryIconData(p.getCategoryIcon(e.category)),color:color,size:18)),
                const SizedBox(width:12),
                Expanded(child:Column(
                  crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Text(e.name,style:const TextStyle(fontSize:14,
                    fontWeight:FontWeight.w500)),
                  Text('${e.category} · ${formatDateShort(e.date)}',
                    style:const TextStyle(color:AppTheme.textSecondary,
                      fontSize:11)),
                  const SizedBox(height:4),
                  LinearProgressIndicator(
                    value:(pct/100).clamp(0,1),
                    backgroundColor:AppTheme.divider,
                    valueColor:AlwaysStoppedAnimation(color),minHeight:3),
                ])),
                const SizedBox(width:12),
                Column(crossAxisAlignment:CrossAxisAlignment.end,children:[
                  AmountText(e.amount,isExpense:true,fontSize:14),
                  Text('${pct.toStringAsFixed(1)}%',
                    style:const TextStyle(color:AppTheme.textSecondary,
                      fontSize:11)),
                ]),
              ]),
            );
          });
  }
}

// ── Helpers ──
Widget _TTab(String label,bool active,VoidCallback onTap)=>
  Expanded(child:GestureDetector(onTap:onTap,child:Container(
    padding:const EdgeInsets.symmetric(vertical:10),
    decoration:BoxDecoration(
      color:active?AppTheme.primary.withOpacity(0.15):Colors.transparent,
      borderRadius:BorderRadius.circular(12),
      border:active?Border.all(color:AppTheme.primary):null),
    child:Center(child:Text(label,style:TextStyle(
      color:active?AppTheme.primary:AppTheme.textSecondary,
      fontWeight:active?FontWeight.bold:FontWeight.normal,fontSize:13))))));

Widget _Dot(Color c,String label)=>Row(mainAxisSize:MainAxisSize.min,children:[
  Container(width:10,height:10,decoration:BoxDecoration(color:c,shape:BoxShape.circle)),
  const SizedBox(width:4),
  Text(label,style:const TextStyle(color:AppTheme.textSecondary,fontSize:12)),
]);

Widget _StatBox(String label,String value,Color color)=>Container(
  padding:const EdgeInsets.all(14),
  decoration:BoxDecoration(color:AppTheme.cardDark,
    borderRadius:BorderRadius.circular(12)),
  child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(label,style:const TextStyle(color:AppTheme.textSecondary,fontSize:12)),
    const SizedBox(height:6),
    Text(value,style:TextStyle(color:color,fontSize:18,
      fontWeight:FontWeight.bold)),
  ]));

String _f(double v){
  if(v>=100000)return '${(v/100000).toStringAsFixed(1)}L';
  if(v>=1000)return '${(v/1000).toStringAsFixed(1)}k';
  return v%1==0?v.toInt().toString():v.toStringAsFixed(1);
}
