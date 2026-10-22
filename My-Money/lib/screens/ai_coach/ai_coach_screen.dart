import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/ai_coach_service.dart';
import '../../services/financial_context_builder.dart';
import '../../utils/theme.dart';

class AiCoachScreen extends StatefulWidget {
  final String? initialQuery;
  const AiCoachScreen({super.key, this.initialQuery});

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final String? provider;
  final String? model;
  final bool isOfflineFallback;
  final DateTime timestamp;

  _ChatMessage({
    required this.text,
    required this.isUser,
    this.provider,
    this.model,
    this.isOfflineFallback = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class _AiCoachScreenState extends State<AiCoachScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final AiCoachService _aiService = AiCoachService();

  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _lastError;
  String? _lastFailedQuestion;
  AiBackendStatus? _backendStatus;

  // Insights tab state
  bool _loadingInsights = false;
  String? _insightsContent;
  String? _insightsProvider;
  bool _insightsIsOffline = false;

  // Savings tab state
  bool _loadingSavings = false;
  String? _savingsContent;
  String? _savingsProvider;
  bool _savingsIsOffline = false;

  static const List<String> _quickPrompts = [
    'Summarize this month\'s spending',
    'Where can I cut expenses?',
    'Am I on track for my savings goals?',
    'Explain my top expense category',
    'Any unusual spending patterns?',
    'How does my savings rate look?',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _checkBackendStatus();

    // Add initial friendly welcome message
    _messages.add(_ChatMessage(
      text: 'Hello! I am your **MONEY AI Financial Coach**.\n\n'
          'I analyze your verified financial activity to provide personalized spending insights, '
          'savings recommendations, and answer any financial questions you have.\n\n'
          'Tap any prompt above or ask me a question below!',
      isUser: false,
      provider: 'MONEY Coach',
      model: 'Verified Engine',
    ));

    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage(widget.initialQuery!);
      });
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkBackendStatus() async {
    final status = await _aiService.checkStatus();
    if (mounted) {
      setState(() => _backendStatus = status);
    }
  }

  Future<void> _sendMessage(String text) async {
    final q = text.trim();
    if (q.isEmpty || _isLoading) return;

    _inputCtrl.clear();
    setState(() {
      _messages.add(_ChatMessage(text: q, isUser: true));
      _isLoading = true;
      _lastError = null;
      _lastFailedQuestion = null;
    });
    _scrollToBottom();

    final provider = context.read<AppProvider>();
    final financialContext = FinancialContextBuilder.buildContext(provider);

    // Build recent conversation history
    final history = _messages
        .take(_messages.length - 1)
        .map((m) => {
              'sender': m.isUser ? 'User' : 'Coach',
              'text': m.text,
            })
        .toList();

    final res = await _aiService.askCoach(q, financialContext, history: history);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (res.success) {
        _messages.add(_ChatMessage(
          text: res.content,
          isUser: false,
          provider: res.provider,
          model: res.model,
          isOfflineFallback: res.isOfflineFallback,
        ));
      } else {
        _lastError = res.error ?? 'Request failed.';
        _lastFailedQuestion = q;
      }
    });

    _scrollToBottom();
    _checkBackendStatus();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _loadInsights() async {
    setState(() => _loadingInsights = true);
    final provider = context.read<AppProvider>();
    final ctx = FinancialContextBuilder.buildContext(provider);
    final res = await _aiService.getInsights(ctx);

    if (mounted) {
      setState(() {
        _loadingInsights = false;
        if (res.success) {
          _insightsContent = res.content;
          _insightsProvider = res.provider;
          _insightsIsOffline = res.isOfflineFallback;
        }
      });
    }
  }

  Future<void> _loadSavingsRecommendations() async {
    setState(() => _loadingSavings = true);
    final provider = context.read<AppProvider>();
    final ctx = FinancialContextBuilder.buildContext(provider);
    final res = await _aiService.getSavingsRecommendations(ctx);

    if (mounted) {
      setState(() {
        _loadingSavings = false;
        if (res.success) {
          _savingsContent = res.content;
          _savingsProvider = res.provider;
          _savingsIsOffline = res.isOfflineFallback;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Financial Coach',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Powered by Gemini & Groq',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          _buildStatusBadge(),
          IconButton(
            icon: const Icon(Icons.info_outline, size: 20),
            tooltip: 'About AI Coach',
            onPressed: _showInfoDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.chat_outlined, size: 18), text: 'Coach Q&A'),
            Tab(icon: Icon(Icons.insights_outlined, size: 18), text: 'Insights'),
            Tab(icon: Icon(Icons.savings_outlined, size: 18), text: 'Savings Goals'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildChatTab(),
          _buildInsightsTab(),
          _buildSavingsTab(),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final isOnline = _backendStatus?.isOnline ?? false;
    final isConfigured = _backendStatus?.isConfigured ?? false;
    final providerName = _backendStatus?.provider.toUpperCase() ?? 'AI';

    final Color color = !isOnline
        ? Colors.grey
        : isConfigured
            ? AppTheme.primary
            : Colors.amber;

    final String label = !isOnline
        ? 'Offline'
        : isConfigured
            ? providerName
            : 'Analytical';

    return GestureDetector(
      onTap: _showConnectionSettingsDialog,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // TAB 1: CONVERSATIONAL COACH Q&A
  // ══════════════════════════════════════════════════════════

  Widget _buildChatTab() {
    return Column(
      children: [
        // Quick Prompt Pills
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _quickPrompts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final p = _quickPrompts[i];
              return ActionChip(
                label: Text(p, style: const TextStyle(fontSize: 12)),
                backgroundColor: AppTheme.cardDark2,
                side: const BorderSide(color: AppTheme.divider, width: 0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onPressed: () => _sendMessage(p),
              );
            },
          ),
        ),

        // Messages list
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: _messages.length,
            itemBuilder: (ctx, i) => _buildMessageBubble(_messages[i]),
          ),
        ),

        // Thinking indicator
        if (_isLoading)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                ),
                const SizedBox(width: 12),
                Text(
                  'Coach is analyzing your verified financial metrics...',
                  style: TextStyle(fontSize: 12, color: AppTheme.primary.withOpacity(0.9)),
                ),
              ],
            ),
          ),

        // Error message & retry
        if (_lastError != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.expenseRed.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.expenseRed.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppTheme.expenseRed, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _lastError!,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ),
                if (_lastFailedQuestion != null)
                  TextButton(
                    onPressed: () => _sendMessage(_lastFailedQuestion!),
                    child: const Text('Retry', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),

        // Input bar
        _buildInputBar(),
      ],
    );
  }

  Widget _buildMessageBubble(_ChatMessage m) {
    final isUser = m.isUser;
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bg = isUser ? AppTheme.primary.withOpacity(0.18) : AppTheme.cardDark;
    final border = isUser
        ? Border.all(color: AppTheme.primary.withOpacity(0.4), width: 1)
        : Border.all(color: AppTheme.divider, width: 0.5);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: align,
        children: [
          // Header / Provider tag
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, size: 12, color: AppTheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    m.isOfflineFallback
                        ? 'Analytical Engine (Offline Rule Mode)'
                        : ' ()',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: m.isOfflineFallback ? Colors.amber : AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),

          // Message bubble
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
            ),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
                bottomLeft: !isUser ? const Radius.circular(0) : const Radius.circular(16),
              ),
              border: border,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  m.text,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ':',
                      style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                    ),
                    if (!isUser) ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: m.text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Response copied to clipboard'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: const Icon(Icons.copy, size: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        8 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.cardDark,
        border: Border(top: BorderSide(color: AppTheme.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              textInputAction: TextInputAction.send,
              onSubmitted: _sendMessage,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Ask a financial question...',
                hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                filled: true,
                fillColor: AppTheme.bgDark,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _inputCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () => setState(() => _inputCtrl.clear()),
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.black, size: 18),
              onPressed: () => _sendMessage(_inputCtrl.text),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // TAB 2: SPENDING INSIGHTS & ANOMALIES
  // ══════════════════════════════════════════════════════════

  Widget _buildInsightsTab() {
    if (_loadingInsights) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primary),
            SizedBox(height: 16),
            Text('Analyzing monthly spending & anomalies...', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    if (_insightsContent == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.analytics_outlined, size: 64, color: AppTheme.primary),
              const SizedBox(height: 16),
              const Text(
                'AI Spending Audit & Anomalies',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Generate an instant, context-aware analysis of your cash flow, category concentrations, and spending spikes.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.auto_awesome, size: 18, color: Colors.black),
                label: const Text('Generate Spending Audit', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: _loadInsights,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _insightsIsOffline ? 'Analytical Summary (Offline)' : 'Live AI Audit (${_insightsProvider?.toUpperCase() ?? "AI"})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _insightsIsOffline ? Colors.amber : AppTheme.primary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18, color: AppTheme.primary),
                tooltip: 'Refresh Analysis',
                onPressed: _loadInsights,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.divider, width: 0.5),
            ),
            child: SelectableText(
              _insightsContent!,
              style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.chat_outlined, size: 16, color: AppTheme.primary),
              label: const Text('Discuss this audit with Coach in Q&A', style: TextStyle(color: AppTheme.primary)),
              onPressed: () {
                _tabCtrl.animateTo(0);
                _sendMessage('Please elaborate on the spending audit recommendations.');
              },
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // TAB 3: SAVINGS GOALS STRATEGIST
  // ══════════════════════════════════════════════════════════

  Widget _buildSavingsTab() {
    if (_loadingSavings) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primary),
            SizedBox(height: 16),
            Text('Calculating optimal savings strategy...', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    if (_savingsContent == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.savings_outlined, size: 64, color: AppTheme.primary),
              const SizedBox(height: 16),
              const Text(
                'Personalized Savings Strategist',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Receive customized advice on accelerating your savings goals, benchmark comparisons (e.g. 50/30/20 rule), and budget caps.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.auto_awesome, size: 18, color: Colors.black),
                label: const Text('Build Savings Strategy', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: _loadSavingsRecommendations,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _savingsIsOffline ? 'Analytical Plan (Offline)' : 'Live Strategy (${_savingsProvider?.toUpperCase() ?? "AI"})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _savingsIsOffline ? Colors.amber : AppTheme.primary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18, color: AppTheme.primary),
                tooltip: 'Refresh Strategy',
                onPressed: _loadSavingsRecommendations,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.divider, width: 0.5),
            ),
            child: SelectableText(
              _savingsContent!,
              style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // DIALOGS & INFO
  // ══════════════════════════════════════════════════════════

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.security, color: AppTheme.primary, size: 24),
            SizedBox(width: 10),
            Text('AI Coach Architecture', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. Secure Server-Side Credentials:\n'
              'Private API keys are stored strictly on your backend server (server/.env). They are NEVER bundled into client source files or app binaries.',
              style: TextStyle(fontSize: 12, height: 1.4, color: AppTheme.textSecondary),
            ),
            SizedBox(height: 12),
            Text(
              '2. Verified Arithmetic Ground Truth:\n'
              'All calculations (totals, savings rates, averages, breakdowns) are calculated by MONEY\'s local engine beforehand to prevent mathematical hallucination.',
              style: TextStyle(fontSize: 12, height: 1.4, color: AppTheme.textSecondary),
            ),
            SizedBox(height: 12),
            Text(
              '3. Dual Provider Support:\n'
              'Configurable between Google Gemini and Groq via LLM_PROVIDER in server/.env.',
              style: TextStyle(fontSize: 12, height: 1.4, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showConnectionSettingsDialog() {
    final urlCtrl = TextEditingController();
    _aiService.getBaseUrl().then((url) => urlCtrl.text = url);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('AI Backend Connection', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Specify your AI backend endpoint address:',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'Backend URL',
                hintText: 'http://127.0.0.1:5005',
                prefixIcon: Icon(Icons.link, size: 20),
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
            onPressed: () async {
              if (urlCtrl.text.trim().isNotEmpty) {
                await _aiService.setCustomBaseUrl(urlCtrl.text.trim());
                await _checkBackendStatus();
              }
              if (mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Save & Test', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
