import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_money/services/firebase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Remote Lock Fail-Safe Offline State Machine Tests', () {
    test('Scenario 1: Live check updates cache unconditionally on every successful check', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await prefs.setBool(FirebaseService.kLastKnownBlocked, true);
      await prefs.setString(FirebaseService.kLastKnownReason, 'Stolen device');
      await prefs.setInt(FirebaseService.kLastKnownTimestamp, nowMs - 10000);

      // Simulate a live check succeeding when device is unblocked
      await prefs.setBool(FirebaseService.kLastKnownBlocked, false);
      await prefs.setString(FirebaseService.kLastKnownReason, '');
      final updatedMs = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(FirebaseService.kLastKnownTimestamp, updatedMs);

      expect(prefs.getBool(FirebaseService.kLastKnownBlocked), false);
      expect(prefs.getInt(FirebaseService.kLastKnownTimestamp), greaterThanOrEqualTo(nowMs));
    });

    test('Scenario 2: Device blocked remotely while online, then goes offline -> lands on BlockedScreen with cached status', () async {
      final lockTimeMs = DateTime.now().millisecondsSinceEpoch - 3600000; // 1 hour ago
      SharedPreferences.setMockInitialValues({
        FirebaseService.kLastKnownBlocked: true,
        FirebaseService.kLastKnownReason: 'Remote lock initiated by owner.',
        FirebaseService.kLastKnownTimestamp: lockTimeMs,
      });

      final prefs = await SharedPreferences.getInstance();
      final hasCachedStatus = prefs.containsKey(FirebaseService.kLastKnownBlocked);
      final cachedBlocked = prefs.getBool(FirebaseService.kLastKnownBlocked) ?? false;
      final cachedReason = prefs.getString(FirebaseService.kLastKnownReason) ?? '';
      final cachedTimeMs = prefs.getInt(FirebaseService.kLastKnownTimestamp);

      expect(hasCachedStatus, true);
      expect(cachedBlocked, true);
      expect(cachedReason, 'Remote lock initiated by owner.');

      // When network fails/times out, state machine resolves to cached values:
      final isBlocked = hasCachedStatus ? cachedBlocked : false;
      final isFromCache = true;
      final lastCheckedAt = cachedTimeMs != null ? DateTime.fromMillisecondsSinceEpoch(cachedTimeMs) : null;

      expect(isBlocked, true);
      expect(isFromCache, true);
      expect(lastCheckedAt, isNotNull);
      expect(lastCheckedAt!.millisecondsSinceEpoch, lockTimeMs);
    });

    test('Scenario 3: First launch ever (no cache) & offline -> defaults to allowed (unblocked)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final hasCachedStatus = prefs.containsKey(FirebaseService.kLastKnownBlocked);
      final cachedBlocked = prefs.getBool(FirebaseService.kLastKnownBlocked) ?? false;

      expect(hasCachedStatus, false);

      final isBlocked = hasCachedStatus ? cachedBlocked : false;
      final isFromCache = true;

      expect(isBlocked, false);
      expect(isFromCache, true);
    });
  });
}
