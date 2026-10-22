import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../widgets/common_widgets.dart';

class RecurringSheet extends StatefulWidget {
  const RecurringSheet({super.key});
  @override
  State<RecurringSheet> createState() => _State();
}

class _State extends State<RecurringSheet> {
  bool _adding = false;
  final _nameCtrl = TextEditingController();
  final _amtCtrl = TextEditingController();
  String _type = 'Expense';
  String _category = '';
  String _frequency = 'Monthly';

  @override
  void dispose() { _nameCtrl.dispose(); _amtCtrl.dispose(); super.dispose(); }

  Future<void> _save(AppProvider p) async {
    final amt = double.tryParse(_amtCtrl.text);
    if (amt == null || _nameCtrl.text.trim().isEmpty || _category.isEmpty) return;
    await p.addRecurring(RecurringExpense(
      name: _nameCtrl.text.trim(), amount: amt,
      category: _category, transactionType: _type,
      frequency: _frequency, createdAt: DateTime.now(),
    ));
    setState(() { _adding = false; _nameCtrl.clear(); _amtCtrl.clear(); });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final cats = (_type == 'Expense' ? p.expenseCategories() : p.incomeCategories())
      .map((c) => c.name).toList();
    if (_category.isEmpty && cats.isNotEmpty) _category = cats.first;

    return Container(
      decoration: const BoxDecoration(color: AppTheme.cardDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width:40,height:4,
            decoration: BoxDecoration(color:AppTheme.divider,
              borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height:16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Recurring Transactions',
              style: TextStyle(fontSize:18, fontWeight:FontWeight.bold)),
            IconButton(onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close)),
          ]),
          const SizedBox(height:12),
          // List existing
          ...p.recurring.map((r) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(width:40,height:40,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
              child: Icon(r.transactionType=='Income'
                ? Icons.arrow_downward : Icons.repeat,
                color: r.transactionType=='Income'
                  ? AppTheme.incomeGreen : AppTheme.expenseRed, size:18)),
            title: Text(r.name, style: const TextStyle(fontSize:14)),
            subtitle: Text('${r.category} · ${r.frequency}',
              style: const TextStyle(color:AppTheme.textSecondary, fontSize:11)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('₹${r.amount}', style: TextStyle(
                color: r.transactionType=='Income'
                  ? AppTheme.incomeGreen : AppTheme.expenseRed,
                fontWeight: FontWeight.bold)),
              const SizedBox(width:8),
              IconButton(icon: const Icon(Icons.delete_outline,
                color: AppTheme.expenseRed, size:18),
                onPressed: () => p.deleteRecurring(r.id!)),
            ]),
          )),
          if (p.recurring.isEmpty && !_adding)
            const Padding(padding: EdgeInsets.symmetric(vertical:16),
              child: EmptyState(icon: Icons.repeat,
                title: 'No recurring transactions')),
          const SizedBox(height:8),
          if (!_adding) PrimaryButton(
            label: '+ Add Recurring', onTap: () => setState(() => _adding=true))
          else _AddForm(
            nameCtrl: _nameCtrl, amtCtrl: _amtCtrl,
            type: _type, category: _category, frequency: _frequency,
            cats: cats,
            onTypeChange: (v) => setState(() { _type=v!; _category=''; }),
            onCatChange: (v) => setState(() => _category=v!),
            onFreqChange: (v) => setState(() => _frequency=v!),
            onSave: () => _save(p),
            onCancel: () => setState(() => _adding=false),
          ),
        ]),
      ),
    );
  }
}

class _AddForm extends StatelessWidget {
  final TextEditingController nameCtrl, amtCtrl;
  final String type, category, frequency;
  final List<String> cats;
  final ValueChanged<String?> onTypeChange, onCatChange, onFreqChange;
  final VoidCallback onSave, onCancel;
  const _AddForm({required this.nameCtrl, required this.amtCtrl,
    required this.type, required this.category, required this.frequency,
    required this.cats, required this.onTypeChange, required this.onCatChange,
    required this.onFreqChange, required this.onSave, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Divider(color: AppTheme.divider),
      const SizedBox(height:12),
      Row(children: [
        _TypeBtn('Expense', type=='Expense', AppTheme.expenseRed,
          () => onTypeChange('Expense')),
        const SizedBox(width:8),
        _TypeBtn('Income', type=='Income', AppTheme.incomeGreen,
          () => onTypeChange('Income')),
      ]),
      const SizedBox(height:12),
      TextField(controller: nameCtrl,
        decoration: const InputDecoration(hintText: 'Title')),
      const SizedBox(height:10),
      TextField(controller: amtCtrl,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(hintText: 'Amount', prefixText: '₹ ')),
      const SizedBox(height:10),
      DropdownButtonFormField<String>(
        value: cats.contains(category) ? category : (cats.isNotEmpty ? cats.first : null),
        decoration: const InputDecoration(labelText: 'Category'),
        dropdownColor: AppTheme.cardDark2,
        items: cats.map((c) => DropdownMenuItem(value:c, child:Text(c))).toList(),
        onChanged: onCatChange,
      ),
      const SizedBox(height:10),
      Row(children: AppConstants.recurringFrequencies.map((f) {
        final sel = f == frequency;
        return Padding(
          padding: const EdgeInsets.only(right:8),
          child: GestureDetector(
            onTap: () => onFreqChange(f),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal:14, vertical:8),
              decoration: BoxDecoration(
                color: sel ? AppTheme.primary.withOpacity(0.2) : AppTheme.cardDark2,
                borderRadius: BorderRadius.circular(20),
                border: sel ? Border.all(color:AppTheme.primary) : null),
              child: Text(f, style: TextStyle(
                color: sel ? AppTheme.primary : AppTheme.textSecondary,
                fontSize:13)),
            ),
          ),
        );
      }).toList()),
      const SizedBox(height:16),
      Row(children: [
        Expanded(child: OutlinedButton(
          onPressed: onCancel,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color:AppTheme.divider)),
          child: const Text('Cancel'))),
        const SizedBox(width:10),
        Expanded(child: PrimaryButton(label:'Save', onTap:onSave)),
      ]),
    ]);
  }
}

Widget _TypeBtn(String label, bool active, Color color, VoidCallback onTap) {
  return Expanded(child: GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical:10),
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.15) : AppTheme.cardDark2,
        borderRadius: BorderRadius.circular(10),
        border: active ? Border.all(color:color) : null),
      child: Center(child: Text(label, style: TextStyle(
        color: active ? color : AppTheme.textSecondary,
        fontWeight: active ? FontWeight.bold : FontWeight.normal))),
    ),
  ));
}
