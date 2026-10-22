import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/ai_budget_plan.dart';
import '../../services/ai_coach_service.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';

class AiBudgetPlannerScreen extends StatefulWidget {
  final AiBudgetPlan? initialPlan;
  final bool startAtForm;

  const AiBudgetPlannerScreen({
    super.key,
    this.initialPlan,
    this.startAtForm = false,
  });

  @override
  State<AiBudgetPlannerScreen> createState() => _AiBudgetPlannerScreenState();
}

class _AiBudgetPlannerScreenState extends State<AiBudgetPlannerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form Controllers
  final _nameCtrl = TextEditingController();
  final _incomeCtrl = TextEditingController();
  final _rentCtrl = TextEditingController();
  final _educationCtrl = TextEditingController();
  final _savingsCtrl = TextEditingController();
  final _goalsCtrl = TextEditingController();
  final _savingsTargetCtrl = TextEditingController();
  final _dependentsCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _otherExpensesCtrl = TextEditingController();

  String _occupation = 'student';
  String _currency = 'INR';
  bool _isGenerating = false;
  String? _errorMessage;

  // Active Plan and Original AI Proposal
  AiBudgetPlan? _currentPlan;
  AiBudgetPlan? _originalAiPlan;

  final List<String> _occupations = [
    'student',
    'salaried employee',
    'freelancer',
    'business owner',
    'self-employed',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    final provider = context.read<AppProvider>();
    _currentPlan = widget.initialPlan ?? provider.activeBudgetPlan;
    if (_currentPlan != null) {
      _originalAiPlan = _currentPlan;
      _populateFormFromPlan(_currentPlan!);
    } else {
      // Default sample values for rapid onboarding
      _nameCtrl.text = 'Rahul';
      _incomeCtrl.text = '15000';
      _rentCtrl.text = '3000';
      _educationCtrl.text = '2000';
      _savingsTargetCtrl.text = '2000';
      _goalsCtrl.text = 'Save for college laptop';
    }
  }

  void _populateFormFromPlan(AiBudgetPlan plan) {
    if (plan.input != null) {
      final inp = plan.input!;
      _nameCtrl.text = inp.name;
      _incomeCtrl.text = inp.monthlyIncome > 0 ? inp.monthlyIncome.toStringAsFixed(0) : '';
      _occupation = inp.occupation;
      _currency = inp.currency;
      _rentCtrl.text = inp.rentHousing > 0 ? inp.rentHousing.toStringAsFixed(0) : '';
      _educationCtrl.text = inp.educationLoans > 0 ? inp.educationLoans.toStringAsFixed(0) : '';
      _savingsCtrl.text = inp.existingSavings > 0 ? inp.existingSavings.toStringAsFixed(0) : '';
      _goalsCtrl.text = inp.financialGoals;
      _savingsTargetCtrl.text = inp.savingsTarget > 0 ? inp.savingsTarget.toStringAsFixed(0) : '';
      _dependentsCtrl.text = inp.dependents > 0 ? inp.dependents.toString() : '';
      _cityCtrl.text = inp.cityContext;
      _otherExpensesCtrl.text = inp.otherExpenses > 0 ? inp.otherExpenses.toStringAsFixed(0) : '';
    } else {
      _incomeCtrl.text = plan.monthlyIncome.toStringAsFixed(0);
      _currency = plan.currency;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _incomeCtrl.dispose();
    _rentCtrl.dispose();
    _educationCtrl.dispose();
    _savingsCtrl.dispose();
    _goalsCtrl.dispose();
    _savingsTargetCtrl.dispose();
    _dependentsCtrl.dispose();
    _cityCtrl.dispose();
    _otherExpensesCtrl.dispose();
    super.dispose();
  }

  Future<void> _generateBudget() async {
    final income = double.tryParse(_incomeCtrl.text.trim()) ?? 0.0;
    final rent = double.tryParse(_rentCtrl.text.trim()) ?? 0.0;
    final edu = double.tryParse(_educationCtrl.text.trim()) ?? 0.0;
    final savings = double.tryParse(_savingsCtrl.text.trim()) ?? 0.0;
    final target = double.tryParse(_savingsTargetCtrl.text.trim()) ?? 0.0;
    final dependents = int.tryParse(_dependentsCtrl.text.trim()) ?? 0;
    final other = double.tryParse(_otherExpensesCtrl.text.trim()) ?? 0.0;

    final input = AiBudgetInput(
      name: _nameCtrl.text.trim(),
      occupation: _occupation,
      monthlyIncome: income,
      currency: _currency,
      rentHousing: rent,
      educationLoans: edu,
      existingSavings: savings,
      financialGoals: _goalsCtrl.text.trim(),
      savingsTarget: target,
      dependents: dependents,
      cityContext: _cityCtrl.text.trim(),
      otherExpenses: other,
    );

    final validationError = input.validate();
    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError), backgroundColor: AppTheme.expenseRed),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final plan = await AiCoachService().generateBudgetPlan(input);
      setState(() {
        _currentPlan = plan;
        _originalAiPlan = plan;
        _isGenerating = false;
      });

      // Switch to Planner Results Tab
      _tabController.animateTo(0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              plan.isOfflineFallback
                  ? 'Budget generated using analytical engine (offline).'
                  : 'AI Monthly Budget generated successfully!',
            ),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _errorMessage = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Generation failed: $e'), backgroundColor: AppTheme.expenseRed),
        );
      }
    }
  }

  void _loadPreset(String preset) {
    if (preset == 'student') {
      _nameCtrl.text = 'Rahul';
      _occupation = 'student';
      _incomeCtrl.text = '15000';
      _rentCtrl.text = '3000';
      _educationCtrl.text = '2000';
      _savingsCtrl.text = '0';
      _goalsCtrl.text = 'Save for college laptop';
      _savingsTargetCtrl.text = '2000';
      _dependentsCtrl.text = '0';
      _cityCtrl.text = 'Tier 2 City';
      _otherExpensesCtrl.text = '0';
    } else if (preset == 'salaried') {
      _nameCtrl.text = 'Priya';
      _occupation = 'salaried employee';
      _incomeCtrl.text = '65000';
      _rentCtrl.text = '18000';
      _educationCtrl.text = '5000';
      _savingsCtrl.text = '150000';
      _goalsCtrl.text = 'Emergency fund & vacation';
      _savingsTargetCtrl.text = '15000';
      _dependentsCtrl.text = '0';
      _cityCtrl.text = 'Bengaluru (Metro)';
      _otherExpensesCtrl.text = '2000';
    } else if (preset == 'freelancer') {
      _nameCtrl.text = 'Anand';
      _occupation = 'freelancer';
      _incomeCtrl.text = '45000';
      _rentCtrl.text = '10000';
      _educationCtrl.text = '0';
      _savingsCtrl.text = '30000';
      _goalsCtrl.text = '6 months emergency cushion';
      _savingsTargetCtrl.text = '10000';
      _dependentsCtrl.text = '1';
      _cityCtrl.text = 'Pune';
      _otherExpensesCtrl.text = '1500';
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppTheme.primary, size: 20),
            SizedBox(width: 8),
            Text(
              'AI Monthly Budget Planner',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: [
            Tab(
              icon: const Icon(Icons.dashboard_customize_outlined, size: 18),
              text: _currentPlan == null ? 'Plan Overview' : 'Budget Dashboard',
            ),
            const Tab(
              icon: Icon(Icons.tune, size: 18),
              text: 'Financial Form',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Results & Interactive Dashboard
          _currentPlan == null
              ? _buildEmptyState()
              : _buildResultsDashboard(_currentPlan!, provider),

          // Tab 2: Financial Input Form
          _buildInputForm(),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 1: EMPTY STATE
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 54),
            ),
            const SizedBox(height: 20),
            const Text(
              'Smart AI Budget Planner',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Distribute your monthly income intelligently across essentials, lifestyle, and savings tailored to your occupation and constraints.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ActionChip(
                  label: const Text('Student Preset (₹15k)'),
                  avatar: const Icon(Icons.school, size: 16, color: AppTheme.primary),
                  backgroundColor: AppTheme.cardDark2,
                  onPressed: () {
                    _loadPreset('student');
                    _tabController.animateTo(1);
                  },
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('Salaried (₹65k)'),
                  avatar: const Icon(Icons.work, size: 16, color: AppTheme.primary),
                  backgroundColor: AppTheme.cardDark2,
                  onPressed: () {
                    _loadPreset('salaried');
                    _tabController.animateTo(1);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Fill Financial Details',
              onTap: () => _tabController.animateTo(1),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 1: RESULTS DASHBOARD & INTERACTIVE EDITOR
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildResultsDashboard(AiBudgetPlan plan, AppProvider provider) {
    final sym = plan.currencySymbol;
    final isShortfall = plan.feasibilityStatus == 'shortfall';
    final isTight = plan.feasibilityStatus == 'tight';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Feasibility Status Banner ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isShortfall
                  ? AppTheme.expenseRed.withOpacity(0.15)
                  : isTight
                      ? Colors.orange.withOpacity(0.15)
                      : AppTheme.incomeGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isShortfall
                    ? AppTheme.expenseRed.withOpacity(0.5)
                    : isTight
                        ? Colors.orange.withOpacity(0.5)
                        : AppTheme.incomeGreen.withOpacity(0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isShortfall
                      ? Icons.error_outline
                      : isTight
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline,
                  color: isShortfall
                      ? AppTheme.expenseRed
                      : isTight
                          ? Colors.orange
                          : AppTheme.incomeGreen,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isShortfall
                            ? 'BUDGET DEFICIT (Shortfall)'
                            : isTight
                                ? 'TIGHT BUDGET (High Essentials)'
                                : 'BALANCED & FEASIBLE BUDGET',
                        style: TextStyle(
                          color: isShortfall
                              ? AppTheme.expenseRed
                              : isTight
                                  ? Colors.orange
                                  : AppTheme.incomeGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isShortfall
                            ? 'Fixed obligations exceed income by $sym${plan.deficit.toStringAsFixed(2)}. Restructuring required.'
                            : isTight
                                ? 'Essentials consume >70% of income. Discretionary spending should be minimized.'
                                : 'All monthly income is 100% accounted for with verified ground truth math.',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (plan.isOfflineFallback)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Offline Rule Engine', style: TextStyle(fontSize: 9, color: Colors.white70)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 2. Summary Metric Cards ──
          Row(
            children: [
              _buildMetricCard(
                'Available Budget',
                '$sym${plan.monthlyIncome.toStringAsFixed(0)}',
                '100%',
                Colors.white,
                Icons.account_balance_wallet_outlined,
              ),
              const SizedBox(width: 10),
              _buildMetricCard(
                'Essential Spend',
                '$sym${plan.totalEssential.toStringAsFixed(0)}',
                '${((plan.totalEssential / plan.monthlyIncome) * 100).toStringAsFixed(0)}%',
                const Color(0xFF42A5F5),
                Icons.home_outlined,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildMetricCard(
                'Lifestyle / Disc.',
                '$sym${plan.totalLifestyle.toStringAsFixed(0)}',
                '${((plan.totalLifestyle / plan.monthlyIncome) * 100).toStringAsFixed(0)}%',
                const Color(0xFFFFB74D),
                Icons.shopping_bag_outlined,
              ),
              const SizedBox(width: 10),
              _buildMetricCard(
                'Planned Savings',
                '$sym${plan.totalSavings.toStringAsFixed(0)}',
                '${plan.savingsPercentage.toStringAsFixed(0)}%',
                AppTheme.primary,
                Icons.savings_outlined,
              ),
            ],
          ),

          // ── 3. Unallocated / Overallocated Notification Bar ──
          if (!plan.isBalanced) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: plan.isOverallocated
                    ? AppTheme.expenseRed.withOpacity(0.15)
                    : Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: plan.isOverallocated ? AppTheme.expenseRed : Colors.amber,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    plan.isOverallocated ? Icons.warning : Icons.info_outline,
                    color: plan.isOverallocated ? AppTheme.expenseRed : Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      plan.isOverallocated
                          ? 'Overallocated by $sym${(plan.totalAllocated - plan.monthlyIncome).toStringAsFixed(2)}'
                          : 'Unallocated balance: $sym${plan.unallocatedBalance.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: plan.isOverallocated ? AppTheme.expenseRed : Colors.amber,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _currentPlan = _currentPlan!.rebalanceDiscretionary();
                      });
                    },
                    icon: const Icon(Icons.balance, size: 14, color: AppTheme.primary),
                    label: const Text('Rebalance', style: TextStyle(color: AppTheme.primary, fontSize: 11)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          // ── 4. Donut Chart Visualization ──
          _buildChartSection(plan),
          const SizedBox(height: 20),

          // ── 5. Category Breakdown & Interactive Editor ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Category Allocations',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary, size: 22),
                    tooltip: 'Add Custom Category',
                    onPressed: () => _showAddCategoryDialog(plan),
                  ),
                  if (_originalAiPlan != null)
                    IconButton(
                      icon: const Icon(Icons.restart_alt, color: AppTheme.textSecondary, size: 22),
                      tooltip: 'Reset to AI Proposal',
                      onPressed: () {
                        setState(() {
                          _currentPlan = _originalAiPlan;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reset to original AI distribution.')),
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          ...plan.allocations.map((alloc) => _buildAllocationTile(alloc, plan)),
          const SizedBox(height: 20),

          // ── 6. AI Strategic Explanation Card ──
          _buildAiExplanationCard(plan),
          const SizedBox(height: 24),

          // ── 7. Primary Action Buttons ──
          PrimaryButton(
            label: 'Accept & Apply to Budget Tracker',
            onTap: () async {
              await provider.applyAiBudgetPlanToBudgets(
                plan,
                month: provider.selectedMonth,
                year: provider.selectedYear,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Budget applied! Tracking ${plan.allocations.length} categories for ${DateFormat('MMM yyyy').format(DateTime(provider.selectedYear, provider.selectedMonth))}.',
                    ),
                    backgroundColor: AppTheme.incomeGreen,
                  ),
                );
                Navigator.pop(context);
              }
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await provider.saveAiBudgetPlan(plan);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('AI Budget Plan saved successfully!')),
                      );
                    }
                  },
                  icon: const Icon(Icons.bookmark_outline, size: 16, color: AppTheme.primary),
                  label: const Text('Save Plan', style: TextStyle(color: AppTheme.primary)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _tabController.animateTo(1),
                  icon: const Icon(Icons.edit_note, size: 16, color: Colors.white),
                  label: const Text('Adjust Inputs', style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 2: FINANCIAL INPUT FORM
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildInputForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.cardDark2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.divider),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: AppTheme.primary, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your financial numbers are processed securely. Required fields are marked with (*).',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Preset Quick Chips ──
          Row(
            children: [
              const Text('Quick Fill:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _loadPreset('student'),
                child: Chip(
                  label: const Text('Student ₹15k', style: TextStyle(fontSize: 10)),
                  backgroundColor: AppTheme.cardDark2,
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _loadPreset('salaried'),
                child: Chip(
                  label: const Text('Salaried ₹65k', style: TextStyle(fontSize: 10)),
                  backgroundColor: AppTheme.cardDark2,
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _loadPreset('freelancer'),
                child: Chip(
                  label: const Text('Freelancer ₹45k', style: TextStyle(fontSize: 10)),
                  backgroundColor: AppTheme.cardDark2,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Personal Information ──
          const Text(
            'REQUIRED INFORMATION',
            style: TextStyle(
              color: AppTheme.primary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: 'Full Name *',
              hintText: 'e.g. Rahul',
              prefixIcon: const Icon(Icons.person_outline, color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.cardDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),

          // Occupation Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _occupation,
                isExpanded: true,
                dropdownColor: AppTheme.cardDark,
                items: _occupations.map((o) {
                  return DropdownMenuItem(
                    value: o,
                    child: Text(
                      o.toUpperCase(),
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _occupation = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Total Monthly Income (Required)
          TextField(
            controller: _incomeCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Total Monthly Income / Available Budget *',
              hintText: 'e.g. 15000',
              prefixIcon: const Icon(Icons.currency_rupee, color: AppTheme.primary),
              filled: true,
              fillColor: AppTheme.cardDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),

          // ── Optional Details Accordion ──
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: true,
              backgroundColor: AppTheme.cardDark,
              collapsedBackgroundColor: AppTheme.cardDark,
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              title: const Text(
                'Financial Constraints & Goals (Optional)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              subtitle: const Text(
                'Rent, education loans, savings targets, and dependents',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      const Divider(color: AppTheme.divider, height: 1),
                      const SizedBox(height: 14),

                      TextField(
                        controller: _rentCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Monthly Rent or Housing Cost (₹)',
                          hintText: '0 if living with family',
                          prefixIcon: const Icon(Icons.home_outlined, color: AppTheme.textSecondary),
                          filled: true,
                          fillColor: AppTheme.cardDark2,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 10),

                      TextField(
                        controller: _educationCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Education Fees or Loan Payments (₹)',
                          hintText: 'e.g. 2000',
                          prefixIcon: const Icon(Icons.school_outlined, color: AppTheme.textSecondary),
                          filled: true,
                          fillColor: AppTheme.cardDark2,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 10),

                      TextField(
                        controller: _savingsTargetCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Preferred Monthly Savings Target (₹)',
                          hintText: 'e.g. 2000',
                          prefixIcon: const Icon(Icons.savings_outlined, color: AppTheme.textSecondary),
                          filled: true,
                          fillColor: AppTheme.cardDark2,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 10),

                      TextField(
                        controller: _goalsCtrl,
                        decoration: InputDecoration(
                          labelText: 'Financial Goals',
                          hintText: 'e.g. Save for laptop, trip, emergency fund',
                          prefixIcon: const Icon(Icons.flag_outlined, color: AppTheme.textSecondary),
                          filled: true,
                          fillColor: AppTheme.cardDark2,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _dependentsCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Dependents',
                                hintText: '0',
                                prefixIcon: const Icon(Icons.people_outline, color: AppTheme.textSecondary),
                                filled: true,
                                fillColor: AppTheme.cardDark2,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _cityCtrl,
                              decoration: InputDecoration(
                                labelText: 'City / Tier Context',
                                hintText: 'e.g. Tier 2, Metro',
                                prefixIcon: const Icon(Icons.location_city_outlined, color: AppTheme.textSecondary),
                                filled: true,
                                fillColor: AppTheme.cardDark2,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      TextField(
                        controller: _otherExpensesCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Other Recurring Commitments (₹)',
                          hintText: 'e.g. Insurance premium',
                          prefixIcon: const Icon(Icons.receipt_outlined, color: AppTheme.textSecondary),
                          filled: true,
                          fillColor: AppTheme.cardDark2,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: AppTheme.expenseRed, fontSize: 12),
              ),
            ),

          PrimaryButton(
            label: _isGenerating ? 'Generating Budget...' : 'Generate AI Budget Plan',
            loading: _isGenerating,
            onTap: _generateBudget,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildMetricCard(String title, String value, String subtitle, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(AiBudgetPlan plan) {
    final essential = plan.totalEssential;
    final lifestyle = plan.totalLifestyle;
    final savings = plan.totalSavings;
    final total = plan.totalAllocated;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Allocation Breakdown',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 50,
                sections: [
                  if (essential > 0)
                    PieChartSectionData(
                      color: const Color(0xFF42A5F5),
                      value: essential,
                      title: '${((essential / total) * 100).toStringAsFixed(0)}%',
                      radius: 40,
                      titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  if (lifestyle > 0)
                    PieChartSectionData(
                      color: const Color(0xFFFFB74D),
                      value: lifestyle,
                      title: '${((lifestyle / total) * 100).toStringAsFixed(0)}%',
                      radius: 40,
                      titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  if (savings > 0)
                    PieChartSectionData(
                      color: AppTheme.primary,
                      value: savings,
                      title: '${((savings / total) * 100).toStringAsFixed(0)}%',
                      radius: 40,
                      titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend('Essentials', const Color(0xFF42A5F5)),
              const SizedBox(width: 16),
              _buildLegend('Lifestyle', const Color(0xFFFFB74D)),
              const SizedBox(width: 16),
              _buildLegend('Savings', AppTheme.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildAllocationTile(AiBudgetAllocation alloc, AiBudgetPlan plan) {
    final sym = plan.currencySymbol;
    Color typeColor = Colors.grey;
    if (alloc.type == 'essential') typeColor = const Color(0xFF42A5F5);
    if (alloc.type == 'debt') typeColor = const Color(0xFFE57373);
    if (alloc.type == 'savings') typeColor = AppTheme.primary;
    if (alloc.type == 'discretionary') typeColor = const Color(0xFFFFB74D);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: alloc.isFixed ? AppTheme.primary.withOpacity(0.3) : AppTheme.divider,
          width: alloc.isFixed ? 1 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  alloc.type.toUpperCase(),
                  style: TextStyle(color: typeColor, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
              if (alloc.isFixed) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, size: 10, color: Colors.white70),
                      SizedBox(width: 3),
                      Text('Fixed', style: TextStyle(color: Colors.white70, fontSize: 9)),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              // Tappable Amount for inline editing
              InkWell(
                onTap: () => _showEditAmountDialog(alloc),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        '$sym${alloc.amount.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit, size: 13, color: AppTheme.textSecondary),
                    ],
                  ),
                ),
              ),
              if (!alloc.isFixed)
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: AppTheme.textSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    setState(() {
                      _currentPlan = _currentPlan!.removeCategory(alloc.category);
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  alloc.category,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
                ),
              ),
              Text(
                '${alloc.percentage.toStringAsFixed(1)}%',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: (alloc.percentage / 100).clamp(0.0, 1.0),
            backgroundColor: AppTheme.divider,
            valueColor: AlwaysStoppedAnimation(typeColor),
            minHeight: 4,
          ),
          if (alloc.explanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              alloc.explanation,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAiExplanationCard(AiBudgetPlan plan) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: AppTheme.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'AI Financial Rationale & Coaching',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            plan.aiExplanation,
            style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.45),
          ),
          if (plan.savingsRecommendation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: AppTheme.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      plan.savingsRecommendation,
                      style: const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DIALOGS: EDIT AMOUNT & ADD CATEGORY
  // ══════════════════════════════════════════════════════════════════════════

  void _showEditAmountDialog(AiBudgetAllocation alloc) {
    final ctrl = TextEditingController(text: alloc.amount.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: Text('Edit ${alloc.category} Limit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Monthly Amount (${_currentPlan?.currencySymbol ?? '₹'})',
                filled: true,
                fillColor: AppTheme.cardDark2,
              ),
            ),
            if (alloc.isFixed)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Note: This is a user-confirmed fixed expense constraint.',
                  style: TextStyle(color: Colors.orange, fontSize: 11),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () {
              final newAmt = double.tryParse(ctrl.text.trim()) ?? alloc.amount;
              Navigator.pop(ctx);
              setState(() {
                _currentPlan = _currentPlan!.updateCategoryAmount(alloc.category, newAmt);
              });
            },
            child: const Text('Update', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(AiBudgetPlan plan) {
    final nameCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    String type = 'discretionary';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          backgroundColor: AppTheme.cardDark,
          title: const Text('Add Custom Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  filled: true,
                  fillColor: AppTheme.cardDark2,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amtCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Monthly Amount (${plan.currencySymbol})',
                  filled: true,
                  fillColor: AppTheme.cardDark2,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: type,
                dropdownColor: AppTheme.cardDark2,
                decoration: InputDecoration(
                  labelText: 'Category Type',
                  filled: true,
                  fillColor: AppTheme.cardDark2,
                ),
                items: const [
                  DropdownMenuItem(value: 'essential', child: Text('Essential')),
                  DropdownMenuItem(value: 'discretionary', child: Text('Discretionary / Lifestyle')),
                  DropdownMenuItem(value: 'debt', child: Text('Debt / Loan Payment')),
                  DropdownMenuItem(value: 'savings', child: Text('Savings / Goal')),
                ],
                onChanged: (v) {
                  if (v != null) setDState(() => type = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              onPressed: () {
                final catName = nameCtrl.text.trim();
                final amt = double.tryParse(amtCtrl.text.trim()) ?? 0.0;
                if (catName.isEmpty || amt <= 0) return;

                Navigator.pop(ctx);
                setState(() {
                  _currentPlan = _currentPlan!.addCategory(AiBudgetAllocation(
                    category: catName,
                    amount: amt,
                    percentage: (amt / plan.monthlyIncome) * 100,
                    type: type,
                    explanation: 'Custom category added by user',
                    isCustom: true,
                  ));
                });
              },
              child: const Text('Add', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
