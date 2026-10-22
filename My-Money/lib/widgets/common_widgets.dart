import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/theme.dart';

// ── Amount text ──
class AmountText extends StatelessWidget {
  final double amount;
  final bool isExpense;
  final double fontSize;
  final FontWeight fontWeight;
  const AmountText(this.amount, {super.key, this.isExpense = true,
    this.fontSize = 14, this.fontWeight = FontWeight.w600});

  @override
  Widget build(BuildContext context) {
    final color = isExpense ? AppTheme.expenseRed : AppTheme.incomeGreen;
    final prefix = isExpense ? '-₹' : '₹';
    return Text('$prefix${_fmt(amount)}',
      style: TextStyle(color: color, fontSize: fontSize,
        fontWeight: fontWeight));
  }
}

String formatCompactNumber(double v) {
  if (v >= 10000000) return '${(v/10000000).toStringAsFixed(1)}Cr';
  if (v >= 100000) return '${(v/100000).toStringAsFixed(1)}L';
  if (v >= 1000) return NumberFormat('#,##0.##').format(v);
  return NumberFormat('#,##0.##').format(v);
}

String _fmt(double v) => formatCompactNumber(v);

String formatAmount(double v) => '₹${_fmt(v)}';
String formatDate(DateTime d) => DateFormat('d MMM yyyy').format(d);
String formatDateShort(DateTime d) => DateFormat('d MMM').format(d);
String formatMonthYear(DateTime d) => DateFormat('MMMM yyyy').format(d);
String formatMonthShort(DateTime d) => DateFormat('MMM').format(d);

// ── Stat card (used in dashboard header) ──
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const StatTile({super.key, required this.label,
    required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: AppTheme.textSecondary,
        fontSize: 11)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(color: color, fontSize: 16,
        fontWeight: FontWeight.bold)),
    ]);
  }
}

// ── Section card wrapper ──
class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Border? border;
  const SectionCard({super.key, required this.child, this.padding, this.border});

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).cardTheme.color ?? AppTheme.cardDark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: border ?? Border.all(color: AppTheme.borderForest, width: 0.75),
      ),
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );
  }
}

// ── Category icon circle ──
class CategoryIcon extends StatelessWidget {
  final String colorHex;
  final IconData icon;
  final double size;
  const CategoryIcon({super.key, required this.colorHex,
    required this.icon, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.fromHex(colorHex);
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(size / 2.5),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

// ── Progress bar ──
class BudgetBar extends StatelessWidget {
  final double pct; // 0-100
  const BudgetBar({super.key, required this.pct});

  @override
  Widget build(BuildContext context) {
    final color = pct >= 100 ? AppTheme.expenseRed
      : pct >= 80 ? const Color(0xFFFFB547) : AppTheme.primary;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: (pct / 100).clamp(0, 1),
        backgroundColor: AppTheme.forestGreen,
        valueColor: AlwaysStoppedAnimation(color),
        minHeight: 6,
      ),
    );
  }
}

// ── Month navigator ──
class MonthNavigator extends StatelessWidget {
  final int month, year;
  final VoidCallback onPrev, onNext;
  const MonthNavigator({super.key, required this.month, required this.year,
    required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final d = DateTime(year, month);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(
        onPressed: onPrev,
        icon: const Icon(Icons.chevron_left, color: AppTheme.champagneGold, size: 20),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      ),
      Text(
        DateFormat('MMMM yyyy').format(d),
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppTheme.paleChampagne,
          letterSpacing: 0.3,
        ),
      ),
      IconButton(
        onPressed: onNext,
        icon: const Icon(Icons.chevron_right, color: AppTheme.champagneGold, size: 20),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      ),
    ]);
  }
}

// ── Empty state ──
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Widget? action;
  final Color? iconColor;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle = '',
    this.action,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.charcoalGrey,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.antiqueGold, width: 1),
              ),
              child: Icon(icon, size: 44, color: iconColor ?? AppTheme.champagneGold),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.paleChampagne,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// ── Teal action button ──
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool loading;
  const PrimaryButton({super.key, required this.label,
    required this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        child: loading
          ? const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2,
                color: Colors.white))
          : Text(label),
      ),
    );
  }
}

// ── Category icon mapper ──
IconData categoryIconData(String iconName) {
  const map = {
    'restaurant': Icons.restaurant,
    'local_cafe': Icons.local_cafe,
    'directions_car': Icons.directions_car,
    'local_taxi': Icons.local_taxi,
    'local_bar': Icons.local_bar,
    'menu_book': Icons.menu_book,
    'checkroom': Icons.checkroom,
    'movie': Icons.movie,
    'local_hospital': Icons.local_hospital,
    'bolt': Icons.bolt,
    'home': Icons.home,
    'shopping_bag': Icons.shopping_bag,
    'local_gas_station': Icons.local_gas_station,
    'outdoor_grill': Icons.outdoor_grill,
    'child_care': Icons.child_care,
    'school': Icons.school,
    'payments': Icons.payments,
    'card_giftcard': Icons.card_giftcard,
    'business': Icons.business,
    'cached': Icons.cached,
    'work': Icons.work,
    'family_restroom': Icons.family_restroom,
    'account_balance': Icons.account_balance,
    'history': Icons.history,
    'trending_up': Icons.trending_up,
    'category': Icons.category,
    'wallet': Icons.account_balance_wallet,
    'star': Icons.star,
    'savings': Icons.savings,
    'attach_money': Icons.attach_money,
    'medical_services': Icons.medical_services,
    'flight': Icons.flight,
    'emoji_events': Icons.emoji_events,
    'track_changes': Icons.track_changes,
    'credit_card': Icons.credit_card,
  };
  return map[iconName] ?? Icons.category;
}

// ── Color picker row ──
class ColorPickerRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  static const colors = [
    '#E53935','#E91E63','#7C6FFF','#AB47BC','#3F51B5',
    '#1E88E5','#00ACC1','#00C6A2','#43A047','#8BC34A',
    '#CDDC39','#FFB547','#FF9800','#FF7043','#795548','#9E9E9E',
    '#607D8B','#FF5B5B',
  ];

  const ColorPickerRow({super.key, required this.selected,
    required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 8, children: colors.map((c) {
      final isSelected = c == selected;
      return GestureDetector(
        onTap: () => onSelect(c),
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: AppTheme.fromHex(c),
            shape: BoxShape.circle,
            border: isSelected ? Border.all(color: Colors.white, width: 2.5) : null,
          ),
          child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : null,
        ),
      );
    }).toList());
  }
}
