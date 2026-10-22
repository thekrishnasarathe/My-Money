import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/debt.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});
  @override State<DebtsScreen> createState() => _State();
}
class _State extends State<DebtsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  @override void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); }
  @override void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final totalPending = p.pendingDebts.fold(0.0, (s, d) => s + d.remaining);
    final totalPaid = p.paidDebts.fold(0.0, (s, d) => s + d.amount);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(child: Column(children: [
        // Header
        Padding(padding: const EdgeInsets.fromLTRB(20,16,20,0),
          child: Row(children: [
            const Icon(Icons.handshake_outlined, color: AppTheme.primary, size: 22),
            const SizedBox(width: 8),
            const Text('Lender / Debt Tracker',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ])),
        const SizedBox(height: 12),
        // Summary cards
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Expanded(child: _SumCard('Total Borrowed', totalPending + totalPaid,
              AppTheme.expenseRed, Icons.arrow_upward)),
            const SizedBox(width: 10),
            Expanded(child: _SumCard('Pending', totalPending,
              Colors.orange, Icons.hourglass_empty)),
            const SizedBox(width: 10),
            Expanded(child: _SumCard('Paid', totalPaid,
              AppTheme.incomeGreen, Icons.check_circle_outline)),
          ])),
        const SizedBox(height: 12),
        TabBar(controller: _tab,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: [
            Tab(text: 'Pending (${p.pendingDebts.length})'),
            Tab(text: 'Paid (${p.paidDebts.length})'),
          ]),
        Expanded(child: TabBarView(controller: _tab, children: [
          _DebtList(debts: p.pendingDebts, isPending: true),
          _DebtList(debts: p.paidDebts, isPending: false),
        ])),
      ])),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: () => showModalBottomSheet(context: context,
          isScrollControlled: true, backgroundColor: Colors.transparent,
          builder: (_) => const _AddDebtSheet()),
        child: const Icon(Icons.add, color: Colors.black)),
    );
  }
}

class _SumCard extends StatelessWidget {
  final String label; final double value;
  final Color color; final IconData icon;
  const _SumCard(this.label, this.value, this.color, this.icon);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
    decoration: BoxDecoration(color: AppTheme.cardDark,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.divider, width: 0.5)),
    child: Column(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(height: 4),
      Text('₹${_f(value)}', style: TextStyle(color: color,
        fontWeight: FontWeight.bold, fontSize: 13)),
      Text(label, style: const TextStyle(color: AppTheme.textSecondary,
        fontSize: 9), textAlign: TextAlign.center),
    ]));
}

class _DebtList extends StatelessWidget {
  final List<Debt> debts; final bool isPending;
  const _DebtList({required this.debts, required this.isPending});

  @override
  Widget build(BuildContext context) {
    if (debts.isEmpty) return EmptyState(
      icon: isPending ? Icons.hourglass_empty : Icons.check_circle_outline,
      title: isPending ? 'No pending debts' : 'No paid debts',
      subtitle: isPending ? 'Tap + to record a debt' : '');

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: debts.length,
      itemBuilder: (_, i) => _DebtCard(debt: debts[i], isPending: isPending));
  }
}

class _DebtCard extends StatelessWidget {
  final Debt debt; final bool isPending;
  const _DebtCard({required this.debt, required this.isPending});

  @override
  Widget build(BuildContext context) {
    final p = context.read<AppProvider>();
    final pct = debt.amount > 0 ? debt.paidAmount / debt.amount : 0.0;
    final isOverdue = isPending && debt.dueDate != null &&
      debt.dueDate!.isBefore(DateTime.now());
    final statusColor = isPending
      ? (isOverdue ? AppTheme.expenseRed : Colors.orange)
      : AppTheme.incomeGreen;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: isOverdue
          ? Border.all(color: AppTheme.expenseRed.withOpacity(0.4)) : null),
      child: Padding(padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 42, height: 42,
            decoration: BoxDecoration(color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(
              debt.lenderName.isNotEmpty ? debt.lenderName[0].toUpperCase() : '?',
              style: TextStyle(color: statusColor, fontSize: 18,
                fontWeight: FontWeight.bold)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(debt.lenderName, style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 15)),
            if (debt.purpose != null && debt.purpose!.isNotEmpty)
              Text(debt.purpose!, style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 12)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('₹${_f(debt.amount)}', style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold)),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6)),
              child: Text(isOverdue ? 'OVERDUE' : debt.status,
                style: TextStyle(color: statusColor, fontSize: 10,
                  fontWeight: FontWeight.w600))),
          ]),
        ]),
        if (debt.amount > 0 && isPending) ...[
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Paid: ₹${_f(debt.paidAmount)}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            Text('Remaining: ₹${_f(debt.remaining)}',
              style: TextStyle(color: statusColor, fontSize: 12,
                fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: pct.clamp(0,1),
              backgroundColor: AppTheme.divider,
              valueColor: AlwaysStoppedAnimation(statusColor), minHeight: 5)),
        ],
        // Dates row
        if (debt.borrowedDate != null || debt.dueDate != null) ...[
          const SizedBox(height: 8),
          Row(children: [
            if (debt.borrowedDate != null) ...[
              const Icon(Icons.calendar_today_outlined,
                size: 12, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text('Borrowed: ${formatDateShort(debt.borrowedDate!)}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ],
            if (debt.dueDate != null) ...[
              const SizedBox(width: 12),
              Icon(Icons.event, size: 12,
                color: isOverdue ? AppTheme.expenseRed : AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text('Due: ${formatDateShort(debt.dueDate!)}',
                style: TextStyle(
                  color: isOverdue ? AppTheme.expenseRed : AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal)),
            ],
          ]),
        ],
        if (isPending) ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              icon: const Icon(Icons.payments_outlined, size: 14),
              label: const Text('Pay'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.incomeGreen,
                side: const BorderSide(color: AppTheme.incomeGreen),
                padding: const EdgeInsets.symmetric(vertical: 8)),
              onPressed: () => _paySheet(context, p))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(
              icon: const Icon(Icons.edit_outlined, size: 14),
              label: const Text('Edit'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
                padding: const EdgeInsets.symmetric(vertical: 8)),
              onPressed: () => showModalBottomSheet(context: context,
                isScrollControlled: true, backgroundColor: Colors.transparent,
                builder: (_) => _AddDebtSheet(edit: debt)))),
            const SizedBox(width: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.expenseRed,
                side: const BorderSide(color: AppTheme.expenseRed),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10)),
              onPressed: () => p.deleteDebt(debt.id!),
              child: const Icon(Icons.delete_outline, size: 18)),
          ]),
        ],
      ])));
  }

  void _paySheet(BuildContext ctx, AppProvider p) {
    final ctrl = TextEditingController();
    showModalBottomSheet(context: ctx,
      backgroundColor: AppTheme.cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Padding(padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Pay for ${debt.lenderName}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Remaining: ₹${_f(debt.remaining)}',
            style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 14),
          TextField(controller: ctrl, keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Payment Amount (₹)')),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Record Payment', onTap: () async {
            final amt = double.tryParse(ctrl.text);
            if (amt != null && amt > 0) {
              await p.makeDebtPayment(debt.id!, amt);
              if (ctx.mounted) Navigator.pop(ctx);
            }
          }),
          const SizedBox(height: 8),
        ]))));
  }
}

class _AddDebtSheet extends StatefulWidget {
  final Debt? edit;
  const _AddDebtSheet({this.edit});
  @override State<_AddDebtSheet> createState() => _ADState();
}
class _ADState extends State<_AddDebtSheet> {
  final _nameCtrl = TextEditingController();
  final _amtCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  DateTime? _borrowed, _due;

  @override
  void initState() {
    super.initState();
    if (widget.edit != null) {
      final d = widget.edit!;
      _nameCtrl.text = d.lenderName;
      _amtCtrl.text = d.amount.toString();
      _purposeCtrl.text = d.purpose ?? '';
      _borrowed = d.borrowedDate;
      _due = d.dueDate;
    } else {
      _borrowed = DateTime.now();
    }
  }
  @override void dispose() {
    _nameCtrl.dispose(); _amtCtrl.dispose(); _purposeCtrl.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.read<AppProvider>();
    return Container(
      decoration: const BoxDecoration(color: AppTheme.cardDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 40, height: 4,
          decoration: BoxDecoration(color: AppTheme.divider,
            borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(widget.edit != null ? 'Edit Debt' : 'Add Debt',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          IconButton(onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close)),
        ]),
        const SizedBox(height: 14),
        TextField(controller: _nameCtrl,
          decoration: const InputDecoration(labelText: 'Lender Name *',
            prefixIcon: Icon(Icons.person_outline, color: AppTheme.textSecondary))),
        const SizedBox(height: 10),
        TextField(controller: _amtCtrl, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount (₹) *',
            prefixIcon: Icon(Icons.currency_rupee, color: AppTheme.textSecondary))),
        const SizedBox(height: 10),
        TextField(controller: _purposeCtrl,
          decoration: const InputDecoration(labelText: 'Purpose (optional)',
            prefixIcon: Icon(Icons.notes_outlined, color: AppTheme.textSecondary))),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _DatePick('Borrowed Date', _borrowed,
            (d) => setState(() => _borrowed = d))),
          const SizedBox(width: 10),
          Expanded(child: _DatePick('Due Date', _due,
            (d) => setState(() => _due = d))),
        ]),
        const SizedBox(height: 20),
        PrimaryButton(
          label: widget.edit != null ? 'Update Debt' : 'Add Debt',
          onTap: () async {
            final amt = double.tryParse(_amtCtrl.text);
            if (_nameCtrl.text.trim().isEmpty || amt == null) return;
            final now = DateTime.now();
            final d = Debt(
              id: widget.edit?.id,
              lenderName: _nameCtrl.text.trim(),
              amount: amt,
              purpose: _purposeCtrl.text.trim(),
              borrowedDate: _borrowed,
              dueDate: _due,
              status: widget.edit?.status ?? 'Pending',
              paidAmount: widget.edit?.paidAmount ?? 0,
              createdAt: widget.edit?.createdAt ?? now,
            );
            if (widget.edit != null) await p.updateDebt(d);
            else await p.addDebt(d);
            if (mounted) Navigator.pop(context);
          }),
        const SizedBox(height: 8),
      ])));
  }
}

Widget _DatePick(String label, DateTime? val, ValueChanged<DateTime> onPick) {
  return Builder(builder: (ctx) => GestureDetector(
    onTap: () async {
      final d = await showDatePicker(context: ctx,
        initialDate: val ?? DateTime.now(),
        firstDate: DateTime(2020), lastDate: DateTime(2035));
      if (d != null) onPick(d);
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(color: AppTheme.cardDark2,
        borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        const Icon(Icons.calendar_today_outlined,
          color: AppTheme.textSecondary, size: 14),
        const SizedBox(width: 6),
        Expanded(child: Text(
          val != null ? DateFormat('d MMM yyyy').format(val) : label,
          style: TextStyle(fontSize: 12,
            color: val != null ? Colors.white : AppTheme.textSecondary))),
      ]))));
}

String _f(double v) {
  if (v >= 100000) return '${(v/100000).toStringAsFixed(1)}L';
  if (v >= 1000) return '${(v/1000).toStringAsFixed(1)}k';
  return v%1==0 ? v.toInt().toString() : v.toStringAsFixed(1);
}
