// lib/services/export_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/expense.dart';
import '../models/income.dart';
import '../models/debt.dart';
import '../utils/constants.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  final _dateFormat = DateFormat('dd MMM yyyy');
  final _currencyFormat = NumberFormat('#,##0.00');
  String get _cur => AppConstants.defaultCurrency;

  // ────────────────── CSV EXPORT ──────────────────

  Future<String?> exportExpensesToCSV(List<Expense> expenses, {String? month}) async {
    try {
      final rows = [
        ['#', 'Name', 'Amount', 'Category', 'Status', 'Type', 'Date'],
        ...expenses.asMap().entries.map((e) => [
          e.key + 1,
          e.value.name,
          e.value.amount,
          e.value.category,
          e.value.status,
          e.value.type,
          _dateFormat.format(e.value.date),
        ]),
        ['', 'TOTAL', expenses.fold(0.0, (s, e) => s + e.amount), '', '', '', ''],
      ];

      final csv = const ListToCsvConverter().convert(rows);
      final fileName = 'expenses_${month ?? _dateFormat.format(DateTime.now())}.csv';
      return await _saveAndShare(csv, fileName, 'text/csv');
    } catch (e) {
      debugPrint('CSV export error: $e');
      return null;
    }
  }

  Future<String?> exportIncomesToCSV(List<Income> incomes, {String? month}) async {
    try {
      final rows = [
        ['#', 'Source', 'Amount', 'Category', 'Notes', 'Date'],
        ...incomes.asMap().entries.map((i) => [
          i.key + 1,
          i.value.source,
          i.value.amount,
          i.value.category,
          i.value.notes,
          _dateFormat.format(i.value.date),
        ]),
        ['', 'TOTAL', incomes.fold(0.0, (s, i) => s + i.amount), '', '', ''],
      ];

      final csv = const ListToCsvConverter().convert(rows);
      final fileName = 'income_${month ?? _dateFormat.format(DateTime.now())}.csv';
      return await _saveAndShare(csv, fileName, 'text/csv');
    } catch (e) {
      return null;
    }
  }

  Future<String?> exportDebtsToCSV(List<Debt> debts) async {
    try {
      final rows = [
        ['#', 'Lender', 'Amount', 'Purpose', 'Borrowed', 'Due Date', 'Paid', 'Remaining', 'Status'],
        ...debts.asMap().entries.map((d) => [
          d.key + 1,
          d.value.lenderName,
          d.value.amount,
          d.value.purpose ?? '',
          d.value.borrowedDate != null ? _dateFormat.format(d.value.borrowedDate!) : '',
          d.value.dueDate != null ? _dateFormat.format(d.value.dueDate!) : '',
          d.value.paidAmount,
          d.value.remaining,
          d.value.status,
        ]),
      ];

      final csv = const ListToCsvConverter().convert(rows);
      return await _saveAndShare(csv, 'debts_${DateTime.now().millisecondsSinceEpoch}.csv', 'text/csv');
    } catch (e) {
      return null;
    }
  }

  // ────────────────── PDF EXPORT ──────────────────

  Future<String?> exportMonthlyReportPDF({
    required List<Expense> expenses,
    required List<Income> incomes,
    required List<Debt> pendingDebts,
    required int month,
    required int year,
  }) async {
    try {
      final pdf = pw.Document();
      final monthName = DateFormat('MMMM yyyy').format(DateTime(year, month));
      final totalExpenses = expenses.fold(0.0, (s, e) => s + e.amount);
      final totalIncome = incomes.fold(0.0, (s, i) => s + i.amount);
      final netBalance = totalIncome - totalExpenses;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    AppConstants.appName,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                  pw.Text(
                    AppConstants.ownerName,
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ],
              ),
              pw.Text(
                'Monthly Report — $monthName',
                style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
              ),
              pw.Divider(color: PdfColors.green800),
            ],
          ),
          build: (context) => [
            // Summary box
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _pdfSummaryItem('Total Income', '$_cur${_currencyFormat.format(totalIncome)}', PdfColors.green700),
                  _pdfSummaryItem('Total Expenses', '$_cur${_currencyFormat.format(totalExpenses)}', PdfColors.red700),
                  _pdfSummaryItem('Net Balance', '$_cur${_currencyFormat.format(netBalance)}',
                      netBalance >= 0 ? PdfColors.green700 : PdfColors.red700),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Expenses table
            if (expenses.isNotEmpty) ...[
              pw.Text('EXPENSES', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.5),
                  4: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.red50),
                    children: ['Name', 'Amount', 'Category', 'Type', 'Date']
                        .map((h) => pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(h, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))))
                        .toList(),
                  ),
                  ...expenses.map((e) => pw.TableRow(
                    children: [
                      e.name, '$_cur${_currencyFormat.format(e.amount)}', e.category, e.type, _dateFormat.format(e.date),
                    ].map((c) => pw.Padding(padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(c.toString(), style: const pw.TextStyle(fontSize: 9)))).toList(),
                  )),
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.red100),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('$_cur${_currencyFormat.format(totalExpenses)}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.red700))),
                      pw.Container(), pw.Container(), pw.Container(),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
            ],

            // Income table
            if (incomes.isNotEmpty) ...[
              pw.Text('INCOME', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.green50),
                    children: ['Source', 'Amount', 'Category', 'Date']
                        .map((h) => pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(h, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))))
                        .toList(),
                  ),
                  ...incomes.map((i) => pw.TableRow(
                    children: [i.source, '$_cur${_currencyFormat.format(i.amount)}', i.category, _dateFormat.format(i.date)]
                        .map((c) => pw.Padding(padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(c, style: const pw.TextStyle(fontSize: 9)))).toList(),
                  )),
                ],
              ),
              pw.SizedBox(height: 8),
            ],

            // Footer
            pw.Divider(),
            pw.Text(AppConstants.copyright, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
          ],
        ),
      );

      final bytes = await pdf.save();
      final fileName = 'money_report_${monthName.replaceAll(' ', '_')}.pdf';
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Monthly Report - $monthName');
      return file.path;
    } catch (e) {
      debugPrint('PDF export error: $e');
      return null;
    }
  }

  pw.Widget _pdfSummaryItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }

  // ────────────────── HELPER ──────────────────

  Future<String?> _saveAndShare(String content, String fileName, String mimeType) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(content);
      await Share.shareXFiles([XFile(file.path)], text: 'Exported from ${AppConstants.appName}');
      return file.path;
    } catch (e) {
      debugPrint('Save and share error: $e');
      return null;
    }
  }
}
