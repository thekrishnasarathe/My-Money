import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/expense.dart';
import '../../models/income.dart';
import '../../models/models.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../widgets/common_widgets.dart';
import '../../services/ai_coach_service.dart';

class AddTransactionSheet extends StatefulWidget {
  final Expense? editExpense;
  final Income? editIncome;
  const AddTransactionSheet({super.key, this.editExpense, this.editIncome});
  @override State<AddTransactionSheet> createState() => _State();
}

class _State extends State<AddTransactionSheet> {
  bool _isExpense = true;
  final _amtCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  String _category = '';
  String _paymentMethod = 'UPI';
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.editExpense != null) {
      final e = widget.editExpense!;
      _isExpense = true; _amtCtrl.text = e.amount.toString();
      _nameCtrl.text = e.name; _descCtrl.text = e.description;
      _tagsCtrl.text = e.tags; _category = e.category;
      _paymentMethod = e.paymentMethod; _date = e.date;
    } else if (widget.editIncome != null) {
      final i = widget.editIncome!;
      _isExpense = false; _amtCtrl.text = i.amount.toString();
      _nameCtrl.text = i.source; _descCtrl.text = i.description;
      _tagsCtrl.text = i.tags; _category = i.category;
      _paymentMethod = i.paymentMethod; _date = i.date;
    }
  }

  @override
  void dispose() {
    _amtCtrl.dispose(); _nameCtrl.dispose();
    _descCtrl.dispose(); _tagsCtrl.dispose(); super.dispose();
  }

  List<AppCategory> _cats(AppProvider p) {
    final cats = _isExpense ? p.expenseCategories() : p.incomeCategories();
    return cats;
  }

  Future<void> _save(AppProvider p) async {
    final amt = double.tryParse(_amtCtrl.text.trim());
    if (amt == null || amt <= 0) { _snack('Enter a valid amount'); return; }
    if (_nameCtrl.text.trim().isEmpty) { _snack('Enter a title'); return; }
    if (_category.isEmpty) { _snack('Select a category'); return; }
    setState(() => _saving = true);
    final now = DateTime.now();
    if (_isExpense) {
      final e = Expense(id: widget.editExpense?.id,
        name: _nameCtrl.text.trim(), amount: amt, category: _category,
        paymentMethod: _paymentMethod, description: _descCtrl.text.trim(),
        tags: _tagsCtrl.text.trim(), date: _date,
        createdAt: widget.editExpense?.createdAt ?? now);
      if (widget.editExpense != null) await p.updateExpense(e);
      else await p.addExpense(e);
    } else {
      final i = Income(id: widget.editIncome?.id,
        source: _nameCtrl.text.trim(), amount: amt, category: _category,
        paymentMethod: _paymentMethod, description: _descCtrl.text.trim(),
        tags: _tagsCtrl.text.trim(), date: _date,
        createdAt: widget.editIncome?.createdAt ?? now);
      if (widget.editIncome != null) await p.updateIncome(i);
      else await p.addIncome(i);
    }
    if (mounted) Navigator.pop(context);
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
    .showSnackBar(SnackBar(content: Text(msg)));

  bool _isAutoCategorizing = false;

  Future<void> _autoCategorize(List<AppCategory> cats) async {
    final title = _nameCtrl.text.trim();
    if (title.isEmpty) {
      _snack('Enter a title first to auto-categorize');
      return;
    }
    setState(() => _isAutoCategorizing = true);
    final amt = double.tryParse(_amtCtrl.text.trim()) ?? 0.0;
    final catNames = cats.map((c) => c.name).toList();
    final suggested = await AiCoachService().suggestCategory(
      name: title,
      amount: amt,
      paymentMethod: _paymentMethod,
      categories: catNames,
    );
    if (!mounted) return;
    setState(() => _isAutoCategorizing = false);
    if (suggested != null && catNames.contains(suggested)) {
      setState(() => _category = suggested);
      _snack('AI suggested: $suggested');
    } else {
      _snack('No automatic match found. Please choose below.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final cats = _cats(p);
    if ((_category.isEmpty || !cats.any((c) => c.name == _category)) && cats.isNotEmpty) {
      _category = cats.first.name;
    }

    return Container(
      decoration: const BoxDecoration(color: AppTheme.cardDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20,12,20,24),
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width:40,height:4,
            decoration: BoxDecoration(color:AppTheme.divider,
              borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height:16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(widget.editExpense!=null||widget.editIncome!=null
              ?'Edit Transaction':'Add Transaction',
              style: const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
            IconButton(onPressed:()=>Navigator.pop(context),
              icon:const Icon(Icons.close)),
          ]),
          const SizedBox(height:12),
          // Toggle
          Container(
            decoration: BoxDecoration(color:AppTheme.cardDark2,
              borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              _TBtn('Expense',Icons.arrow_upward,_isExpense,AppTheme.expenseRed,
                ()=>setState((){_isExpense=true;_category='';})),
              _TBtn('Income',Icons.arrow_downward,!_isExpense,AppTheme.incomeGreen,
                ()=>setState((){_isExpense=false;_category='';})),
            ])),
          const SizedBox(height:16),
          // Amount display
          Center(child: Text(
            _amtCtrl.text.isEmpty?'0.00':_amtCtrl.text,
            style: TextStyle(fontSize:34,fontWeight:FontWeight.bold,
              color:_isExpense?AppTheme.expenseRed:AppTheme.incomeGreen))),
          const SizedBox(height:8),
          TextField(controller:_amtCtrl,
            keyboardType:const TextInputType.numberWithOptions(decimal:true),
            textAlign:TextAlign.center,
            style:const TextStyle(fontSize:18),
            decoration:const InputDecoration(hintText:'Amount',prefixText:'₹ '),
            onChanged:(_)=>setState((){})),
          const SizedBox(height:12),
          TextField(controller:_nameCtrl,
            decoration: InputDecoration(
              hintText:_isExpense?'e.g. Lunch at canteen':'e.g. Monthly salary',
              prefixIcon:const Icon(Icons.title_outlined,
                color:AppTheme.textSecondary))),
          const SizedBox(height:14),
          // Category with icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('CATEGORY', style: TextStyle(color: AppTheme.textSecondary,
                fontSize: 11, fontWeight: FontWeight.w600)),
              GestureDetector(
                onTap: _isAutoCategorizing ? null : () => _autoCategorize(cats),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.4), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isAutoCategorizing) ...[
                        const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.primary),
                        ),
                        const SizedBox(width: 4),
                      ] else ...[
                        const Icon(Icons.auto_awesome, size: 11, color: AppTheme.primary),
                        const SizedBox(width: 4),
                      ],
                      const Text(
                        'AI Auto-Detect',
                        style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height:8),
          SizedBox(height:64,
            child: cats.isEmpty
              ? const Center(child:Text('No categories',
                  style:TextStyle(color:AppTheme.textSecondary)))
              : ListView.separated(
                scrollDirection:Axis.horizontal,
                itemCount:cats.length,
                separatorBuilder:(_,__)=>const SizedBox(width:8),
                itemBuilder:(_,i){
                  final c=cats[i]; final sel=c.name==_category;
                  final color=AppTheme.fromHex(c.color);
                  return GestureDetector(
                    onTap:()=>setState(()=>_category=c.name),
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
                          fontSize:11,
                          fontWeight:sel?FontWeight.w600:FontWeight.normal)),
                      ])));
                })),
          const SizedBox(height:14),
          // Date + Payment
          Row(children:[
            Expanded(child:GestureDetector(
              onTap:()async{
                final d=await showDatePicker(context:context,
                  initialDate:_date,firstDate:DateTime(2020),
                  lastDate:DateTime(2030));
                if(d!=null)setState(()=>_date=d);
              },
              child:Container(
                padding:const EdgeInsets.symmetric(horizontal:14,vertical:14),
                decoration:BoxDecoration(color:AppTheme.cardDark2,
                  borderRadius:BorderRadius.circular(12)),
                child:Row(children:[
                  const Icon(Icons.calendar_today_outlined,
                    color:AppTheme.textSecondary,size:16),
                  const SizedBox(width:8),
                  Text(DateFormat('d MMM yyyy').format(_date),
                    style:const TextStyle(fontSize:13))])))),
            const SizedBox(width:10),
            Expanded(child:Container(
              padding:const EdgeInsets.symmetric(horizontal:14),
              decoration:BoxDecoration(color:AppTheme.cardDark2,
                borderRadius:BorderRadius.circular(12)),
              child:DropdownButtonHideUnderline(child:DropdownButton<String>(
                value:_paymentMethod,isExpanded:true,
                dropdownColor:AppTheme.cardDark2,
                style:const TextStyle(color:Colors.white,fontSize:13),
                items:AppConstants.paymentMethods.map((m)=>
                  DropdownMenuItem(value:m,child:Text(m))).toList(),
                onChanged:(v)=>setState(()=>_paymentMethod=v!))))),
          ]),
          const SizedBox(height:12),
          TextField(controller:_descCtrl,
            decoration:const InputDecoration(hintText:'Description (optional)',
              prefixIcon:Icon(Icons.notes_outlined,color:AppTheme.textSecondary))),
          const SizedBox(height:10),
          TextField(controller:_tagsCtrl,
            decoration:const InputDecoration(
              hintText:'Tags (optional, comma separated)',
              prefixIcon:Icon(Icons.label_outline,color:AppTheme.textSecondary))),
          const SizedBox(height:20),
          PrimaryButton(
            label:widget.editExpense!=null||widget.editIncome!=null
              ?'Update Transaction':'Add Transaction',
            onTap:()=>_save(p),loading:_saving),
        ])));
  }
}

class _TBtn extends StatelessWidget {
  final String label; final IconData icon;
  final bool active; final Color color; final VoidCallback onTap;
  const _TBtn(this.label,this.icon,this.active,this.color,this.onTap);
  @override
  Widget build(BuildContext context)=>Expanded(child:GestureDetector(
    onTap:onTap,
    child:Container(
      padding:const EdgeInsets.symmetric(vertical:12),
      decoration:BoxDecoration(
        color:active?color.withOpacity(0.15):Colors.transparent,
        borderRadius:BorderRadius.circular(12)),
      child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[
        Icon(icon,color:active?color:AppTheme.textSecondary,size:16),
        const SizedBox(width:6),
        Text(label,style:TextStyle(color:active?color:AppTheme.textSecondary,
          fontWeight:active?FontWeight.bold:FontWeight.normal,fontSize:14)),
      ]))));
}
