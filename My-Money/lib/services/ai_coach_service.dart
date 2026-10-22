import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_budget_plan.dart';
import 'ai_budget_planner_fallback.dart';

class AiCoachResponse {
  final bool success;
  final String content;
  final String provider;
  final String model;
  final bool isOfflineFallback;
  final String? error;
  final String? warning;

  const AiCoachResponse({
    required this.success,
    required this.content,
    this.provider = 'gemini',
    this.model = 'gemini-1.5-flash',
    this.isOfflineFallback = false,
    this.error,
    this.warning,
  });

  factory AiCoachResponse.fromMap(Map<String, dynamic> map) {
    return AiCoachResponse(
      success: map['success'] ?? false,
      content: map['reply'] ?? map['insights'] ?? map['recommendations'] ?? map['content'] ?? '',
      provider: map['provider'] ?? 'gemini',
      model: map['model'] ?? 'gemini-1.5-flash',
      isOfflineFallback: map['is_offline_fallback'] ?? false,
      error: map['error'],
      warning: map['warning'],
    );
  }

  factory AiCoachResponse.failure(String errorMsg) {
    return AiCoachResponse(
      success: false,
      content: '',
      error: errorMsg,
    );
  }
}

class AiBackendStatus {
  final bool isOnline;
  final String provider;
  final String model;
  final bool isConfigured;
  final String? errorMessage;

  const AiBackendStatus({
    required this.isOnline,
    this.provider = 'gemini',
    this.model = 'gemini-1.5-flash',
    this.isConfigured = false,
    this.errorMessage,
  });
}

class AiCoachService {
  static final AiCoachService _instance = AiCoachService._internal();
  factory AiCoachService() => _instance;
  AiCoachService._internal();

  static const String kBackendUrlKey = 'ai_backend_url';
  static const Duration _kTimeout = Duration(seconds: 25);

  String? _customBaseUrl;

  String get defaultBaseUrl {
    if (kIsWeb) return 'http://127.0.0.1:5005';
    try {
      if (Platform.isAndroid) {
        // Android emulator connects to host via 10.0.2.2
        return 'http://10.0.2.2:5005';
      }
    } catch (_) {}
    return 'http://127.0.0.1:5005';
  }

  Future<String> getBaseUrl() async {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(kBackendUrlKey);
      if (saved != null && saved.isNotEmpty) {
        _customBaseUrl = saved;
        return saved;
      }
    } catch (_) {}
    return defaultBaseUrl;
  }

  Future<void> setCustomBaseUrl(String url) async {
    _customBaseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kBackendUrlKey, _customBaseUrl!);
    } catch (_) {}
  }

  /// Check backend health & active LLM configuration
  Future<AiBackendStatus> checkStatus() async {
    try {
      final base = await getBaseUrl();
      final uri = Uri.parse('$base/api/health');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        return AiBackendStatus(
          isOnline: true,
          provider: data['provider'] ?? 'gemini',
          model: data['model'] ?? 'gemini-1.5-flash',
          isConfigured: data['is_configured'] ?? false,
        );
      }
      return AiBackendStatus(
        isOnline: false,
        errorMessage: 'Server returned HTTP ${res.statusCode}',
      );
    } catch (e) {
      return AiBackendStatus(
        isOnline: false,
        errorMessage: 'Backend unavailable: $e',
      );
    }
  }

  /// Conversational Financial Q&A with context and conversation history
  Future<AiCoachResponse> askCoach(
    String question,
    Map<String, dynamic> financialContext, {
    List<Map<String, String>>? history,
  }) async {
    if (question.trim().isEmpty) {
      return AiCoachResponse.failure('Please enter a question for your financial coach.');
    }

    try {
      final base = await getBaseUrl();
      final uri = Uri.parse('$base/api/ai/chat');
      final payload = json.encode({
        'message': question.trim(),
        'context': financialContext,
        'history': history ?? [],
      });

      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: payload,
      ).timeout(_kTimeout);

      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        return AiCoachResponse.fromMap(data);
      } else {
        final err = _parseError(res.body);
        return AiCoachResponse.failure('Server error (${res.statusCode}): $err');
      }
    } catch (e) {
      return _handleNetworkError(e);
    }
  }

  /// Get comprehensive spending insights & anomaly explanations
  Future<AiCoachResponse> getInsights(Map<String, dynamic> financialContext) async {
    try {
      final base = await getBaseUrl();
      final uri = Uri.parse('$base/api/ai/insights');
      final payload = json.encode({'context': financialContext});

      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: payload,
      ).timeout(_kTimeout);

      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        return AiCoachResponse.fromMap(data);
      } else {
        final err = _parseError(res.body);
        return AiCoachResponse.failure('Server error (${res.statusCode}): $err');
      }
    } catch (e) {
      return _handleNetworkError(e);
    }
  }

  /// Get personalized savings goals & budget recommendations
  Future<AiCoachResponse> getSavingsRecommendations(Map<String, dynamic> financialContext) async {
    try {
      final base = await getBaseUrl();
      final uri = Uri.parse('$base/api/ai/savings-recommendations');
      final payload = json.encode({'context': financialContext});

      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: payload,
      ).timeout(_kTimeout);

      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        return AiCoachResponse.fromMap(data);
      } else {
        final err = _parseError(res.body);
        return AiCoachResponse.failure('Server error (${res.statusCode}): $err');
      }
    } catch (e) {
      return _handleNetworkError(e);
    }
  }

  /// Intelligent categorization assistance
  Future<String?> suggestCategory({
    required String name,
    required double amount,
    String paymentMethod = 'UPI',
    required List<String> categories,
  }) async {
    if (name.trim().isEmpty || categories.isEmpty) return null;

    try {
      final base = await getBaseUrl();
      final uri = Uri.parse('$base/api/ai/categorize');
      final payload = json.encode({
        'name': name.trim(),
        'amount': amount,
        'payment_method': paymentMethod,
        'categories': categories,
      });

      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: payload,
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        return data['suggested_category'];
      }
    } catch (e) {
      debugPrint('AI Categorization skip/fallback: ');
    }
    return null;
  }

  /// AI-Powered Monthly Budget Planner:
  /// Connects to POST /api/ai/budget-planner on the backend server.
  /// Falls back smoothly to AiBudgetPlannerFallbackEngine if offline or unreachable.
  Future<AiBudgetPlan> generateBudgetPlan(AiBudgetInput input) async {
    final validationError = input.validate();
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    try {
      final base = await getBaseUrl();
      final uri = Uri.parse('$base/api/ai/budget-planner');
      final payload = json.encode(input.toMap());

      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: payload,
      ).timeout(_kTimeout);

      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        if (data['success'] == true) {
          return AiBudgetPlan.fromMap(data).copyWith(input: input);
        } else {
          final err = data['error'] ?? 'AI budget generation failed';
          debugPrint('Backend budget planner returned error: $err. Falling back to local engine.');
          return AiBudgetPlannerFallbackEngine.generate(input, reason: err);
        }
      } else {
        debugPrint('Backend HTTP ${res.statusCode}. Falling back to local engine.');
        return AiBudgetPlannerFallbackEngine.generate(
          input,
          reason: 'Server error (${res.statusCode}): ${res.body}',
        );
      }
    } catch (e) {
      debugPrint('Backend connection error: $e. Falling back to local deterministic engine.');
      return AiBudgetPlannerFallbackEngine.generate(input, reason: e.toString());
    }
  }

  String _parseError(String body) {
    try {
      final m = json.decode(body);
      return m['error'] ?? m['message'] ?? body;
    } catch (_) {
      return body.isNotEmpty ? body : 'Unknown error';
    }
  }

  AiCoachResponse _handleNetworkError(dynamic e) {
    debugPrint('AiCoachService Network Error: ');
    return AiCoachResponse.failure(
      'Unable to connect to AI Coach backend.\n\n'
      '• Ensure the AI backend is running: run "run_ai_backend.bat" or "python server/server.py".\n'
      '• Your financial data remains completely safe locally.',
    );
  }
}
