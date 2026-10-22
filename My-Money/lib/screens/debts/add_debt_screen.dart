// lib/screens/debts/add_debt_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/debt.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

class AddDebtScreen extends StatefulWidget {
  final Debt? debt;
  const AddDebtScreen({super.key, this.debt});
  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lenderCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  final _paidCtrl = TextEditingController();
  String _status = AppConstants.debtStatus.first;
  DateTime? _borrowedDate;
  DateTime? _dueDate;
  int? _accountId;
  bool _isSaving = false;

  bool get _isEditing => widget.debt != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final d = widget.debt!;
      _lenderCtrl.text = d.lenderName;
      _amountCtrl.text = d.amount.toString();
      _purposeCtrl.text = d.purpose ?? '';
      _paidCtrl.text = d.paidAmount > 0 ? d.paidAmount.toString() : '';
      _status = d.status;
      _borrowedDate = d.borrowedDate;
      _dueDate = d.dueDate;
      _accountId = d.accountId;
    } else {
      _borrowedDate = DateTime.now();
    }
  }

  @override
  void dispose() { _lenderCtrl.dispose(); _amountCtrl.dispose(); _purposeCtrl.dispose(); _paidCtrl.dispose(); super.dispose(); }

  final _df = DateFormat('d MMM yyyy');

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final provider = context.read<AppProvider>();
    final paidAmt = double.tryParse(_paidCtrl.text) ?? 0.0;
    final totalAmt = double.parse(_amountCtrl.text.trim());
    String autoStatus = _status;
    if (paidAmt >= totalAmt && totalAmt > 0) autoStatus = 'Paid';
    else if (paidAmt > 0) autoStatus = 'Partially Paid';

    final debt = Debt(
      id: widget.debt?.id,
      lenderName: _lenderCtrl.text.trim(),
      amount: totalAmt,
      purpose: _purposeCtrl.text.trim().isEmpty ? null : _purposeCtrl.text.trim(),
      borrowedDate: _borrowedDate,
      dueDate: _dueDate,
      status: autoStatus,
      paidAmount: paidAmt,
      accountId: _accountId,
      createdAt: widget.debt?.createdAt ?? DateTime.now(),
    );
    try {
      if (_isEditing) { await provider.updateDebt(debt); if (mounted) showSuccess(context, 'Debt updated'); }
      else { await provider.addDebt(debt); if (mounted) showSuccess(context, 'Debt added'); }
      if (mounted) Navigator.pop(context);
    } catch (e) { if (mounted) showError(context, 'Error: $e'); }
    finally { if (mounted) setState(() => _isSaving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AppProvider>().accounts;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Debt' : 'Add Debt'),
        actions: [
          if (_isEditing) IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await showDeleteConfirm(context, widget.debt!.lenderName);
              if (ok && mounted) { await context.read<AppProvider>().deleteDebt(widget.debt!.id!); if (mounted) Navigator.pop(context); }
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Amount card
            Card(child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                const Text('Total Amount Borrowed', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.orange),
                  decoration: InputDecoration(
                    prefixText: AppConstants.defaultCurrency,
                    prefixStyle: const TextStyle(fontSize: 28, color: Colors.orange, fontWeight: FontWeight.bold),
                    border: InputBorder.none, filled: false, hintText: '0.00',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter amount';
                    if (double.tryParse(v) == null) return 'Invalid amount';
                    if (double.parse(v) <= 0) return 'Must be > 0';
                    return null;
                  },
                ),
              ]),
            )),
            const SizedBox(height: 16),
            AppTextField(controller: _lenderCtrl, label: 'Lender Name', hint: 'Who did you borrow from?', prefix: const Icon(Icons.person_outline)),
            const SizedBox(height: 12),
            AppTextField(controller: _purposeCtrl, label: 'Purpose (optional)', hint: 'e.g. For single bed, Dinner together', validator: (_) => null),
            const SizedBox(height: 12),

            // Borrowed Date
            Card(child: ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.blue),
              title: Text(_borrowedDate != null ? _df.format(_borrowedDate!) : 'Set Borrowed Date'),
              subtitle: const Text('Borrowed Date (optional)'),
              trailing: _borrowedDate != null
                  ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _borrowedDate = null))
                  : const Icon(Icons.chevron_right),
              onTap: () async { final d = await pickDate(context, initial: _borrowedDate); if (d != null) setState(() => _borrowedDate = d); },
            )),
            const SizedBox(height: 8),

            // Due Date
            Card(child: ListTile(
              leading: Icon(Icons.event, color: _dueDate != null && DateTime.now().isAfter(_dueDate!) ? AppTheme.errorRed : Colors.orange),
              title: Text(_dueDate != null ? _df.format(_dueDate!) : 'Set Due Date (optional)'),
              subtitle: _dueDate != null && DateTime.now().isAfter(_dueDate!) && _status != 'Paid'
                  ? const Text('OVERDUE!', style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.bold, fontSize: 11))
                  : const Text('When to return the money'),
              trailing: _dueDate != null
                  ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _dueDate = null))
                  : const Icon(Icons.chevron_right),
              onTap: () async { final d = await pickDate(context, initial: _dueDate); if (d != null) setState(() => _dueDate = d); },
            )),
            const SizedBox(height: 12),

            // Amount already paid
            AppTextField(
              controller: _paidCtrl,
              label: 'Amount Already Paid (optional)',
              hint: '0',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefix: const Icon(Icons.payments_outlined),
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                if (double.tryParse(v) == null) return 'Invalid';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Status
            const Text('Status', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: AppConstants.debtStatus.map((s) {
                Color color;
                switch (s) { case 'Paid': color = AppTheme.successGreen; break; case 'Partially Paid': color = Colors.blue; break; default: color = Colors.orange; }
                return ChoiceChip(
                  label: Text(s), selected: s == _status,
                  selectedColor: color.withOpacity(0.2),
                  labelStyle: TextStyle(color: s == _status ? color : Colors.grey),
                  side: BorderSide(color: s == _status ? color : Colors.grey[300]!),
                  onSelected: (_) => setState(() => _status = s),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            if (accounts.isNotEmpty) ...[
              DropdownButtonFormField<int?>(
                value: _accountId,
                decoration: const InputDecoration(labelText: 'Account (optional)'),
                items: [const DropdownMenuItem(value: null, child: Text('No account')),
                  ...accounts.map((a) => DropdownMenuItem(value: a.id, child: Text('${a.name} (${a.type})')))],
                onChanged: (v) => setState(() => _accountId = v),
                validator: null,
              ),
              const SizedBox(height: 12),
            ],

            SizedBox(height: 50, child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: _isSaving ? const CircularProgressIndicator(color: Colors.white)
                  : Text(_isEditing ? 'Update Debt' : 'Save Debt',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            )),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

void showSuccess(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: AppTheme.incomeGreen),
  );
}

void showError(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: AppTheme.expenseRed),
  );
}

Future<bool> showDeleteConfirm(BuildContext context, String name) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete Debt'),
      content: Text('Are you sure you want to delete debt from "$name"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete', style: TextStyle(color: AppTheme.expenseRed)),
        ),
      ],
    ),
  );
  return res ?? false;
}

Future<DateTime?> pickDate(BuildContext context, {DateTime? initial}) async {
  return showDatePicker(
    context: context,
    initialDate: initial ?? DateTime.now(),
    firstDate: DateTime(2020),
    lastDate: DateTime(2035),
  );
}

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final Widget? prefix;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefix,
    this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator ?? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefix,
      ),
    );
  }
}
