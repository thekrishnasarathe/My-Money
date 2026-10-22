import 'package:flutter_test/flutter_test.dart';
import 'package:my_money/services/ai_coach_service.dart';
import 'package:my_money/services/financial_context_builder.dart';
import 'package:my_money/providers/app_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AI Coach Models & Context Builder Unit Tests', () {
    test('AiCoachResponse parses successful Gemini response correctly', () {
      final map = {
        'success': true,
        'reply': 'Your monthly savings rate is 35.5%. Good job!',
        'provider': 'gemini',
        'model': 'gemini-1.5-flash',
        'is_offline_fallback': false,
      };

      final res = AiCoachResponse.fromMap(map);
      expect(res.success, true);
      expect(res.content, 'Your monthly savings rate is 35.5%. Good job!');
      expect(res.provider, 'gemini');
      expect(res.model, 'gemini-1.5-flash');
      expect(res.isOfflineFallback, false);
      expect(res.error, isNull);
    });

    test('AiCoachResponse parses Groq responses and alternative keys', () {
      final map = {
        'success': true,
        'insights': 'Top spending category is Food & Dining.',
        'provider': 'groq',
        'model': 'llama-3.3-70b-versatile',
        'is_offline_fallback': false,
      };

      final res = AiCoachResponse.fromMap(map);
      expect(res.success, true);
      expect(res.content, 'Top spending category is Food & Dining.');
      expect(res.provider, 'groq');
      expect(res.model, 'llama-3.3-70b-versatile');
      expect(res.isOfflineFallback, false);
    });

    test('AiCoachResponse marks offline analytical fallback clearly', () {
      final map = {
        'success': true,
        'reply': 'Verified Financial Summary for this Month: Total Income: 50,000',
        'provider': 'offline-rule-engine',
        'model': 'deterministic-analyzer',
        'is_offline_fallback': true,
        'warning': 'Live LLM request failed. Displaying verified analytical summary.',
      };

      final res = AiCoachResponse.fromMap(map);
      expect(res.success, true);
      expect(res.isOfflineFallback, true);
      expect(res.provider, 'offline-rule-engine');
      expect(res.warning, contains('Live LLM request failed'));
    });

    test('AiCoachResponse failure constructor creates valid error object', () {
      final res = AiCoachResponse.failure('Unable to connect to AI Coach backend');
      expect(res.success, false);
      expect(res.content, isEmpty);
      expect(res.error, 'Unable to connect to AI Coach backend');
    });

    test('FinancialContextBuilder extracts structured metrics safely without crashing', () {
      final p = AppProvider();
      final context = FinancialContextBuilder.buildContext(p);

      expect(context, isA<Map<String, dynamic>>());
      expect(context.containsKey('period'), true);
      expect(context.containsKey('verified_financial_totals'), true);
      expect(context.containsKey('category_breakdown'), true);
      expect(context.containsKey('savings_goals'), true);
      expect(context.containsKey('currency'), true);

      final totals = context['verified_financial_totals'] as Map<String, dynamic>;
      expect(totals.containsKey('total_income_this_month'), true);
      expect(totals.containsKey('total_expenses_this_month'), true);
      expect(totals.containsKey('net_balance_this_month'), true);
      expect(totals.containsKey('savings_rate_percent'), true);
      expect(totals.containsKey('all_time_balance'), true);
    });

    test('AiCoachService base URL defaults to valid address', () {
      final service = AiCoachService();
      expect(service.defaultBaseUrl, contains('5005'));
    });
  });
}
