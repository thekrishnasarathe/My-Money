// lib/services/firebase_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../utils/constants.dart';

class DeviceStatusResult {
  final bool isBlocked;
  final String blockReason;
  final bool isFromCache;
  final DateTime? lastCheckedAt;

  const DeviceStatusResult({
    required this.isBlocked,
    required this.blockReason,
    required this.isFromCache,
    this.lastCheckedAt,
  });
}

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  static const String kLastKnownBlocked = 'last_known_device_blocked';
  static const String kLastKnownReason = 'last_known_block_reason';
  static const String kLastKnownTimestamp = 'last_known_check_timestamp';

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  bool _isConfigured = false;
  bool _isBlocked = false;
  String _blockReason = '';
  String _deviceId = '';

  bool get isConfigured => _isConfigured;
  bool get isBlocked => _isBlocked;
  String get blockReason => _blockReason;
  String get deviceId => _deviceId;

  // ── Initialize Firebase & register device ──
  Future<void> initialize() async {
    try {
      _isConfigured = true;
      _deviceId = await _getOrCreateDeviceId();
      await _registerDevice();
      await _checkDeviceStatus();
    } catch (e) {
      debugPrint('Firebase service init error: $e');
      _isConfigured = false;
    }
  }

  // ── Get or create unique device ID ──
  Future<String> _getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(AppConstants.kDeviceId);
    if (id != null && id.isNotEmpty) return id;

    id = const Uuid().v4();
    await prefs.setString(AppConstants.kDeviceId, id);
    return id;
  }

  // ── Ensure authenticated via Anonymous Firebase Auth ──
  Future<void> _ensureAuthenticated() async {
    try {
      if (_auth.currentUser == null) {
        if (kDebugMode) debugPrint('[MONEY Auth] Signing in anonymously...');
        await _auth.signInAnonymously().timeout(const Duration(milliseconds: 3000));
        if (kDebugMode) debugPrint('[MONEY Auth] Anonymous sign-in success. UID: ${_auth.currentUser?.uid}');
      } else {
        if (kDebugMode) debugPrint('[MONEY Auth] Already authenticated with UID: ${_auth.currentUser?.uid}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[MONEY Auth] Anonymous sign-in warning/timeout: $e');
    }
  }

  // ── Register this device in Firestore ──
  Future<void> _registerDevice() async {
    try {
      await _ensureAuthenticated();

      final deviceInfo = DeviceInfoPlugin();
      String deviceModel = 'Unknown';
      String androidVersion = '';

      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        deviceModel = '${info.brand} ${info.model}';
        androidVersion = 'Android ${info.version.release}';
      }

      final docRef = _firestore
          .collection(AppConstants.fcDevices)
          .doc(_deviceId);

      final doc = await docRef.get();

      if (!doc.exists) {
        // New device — register it (default: active)
        final uid = _auth.currentUser?.uid ?? '';
        await docRef.set({
          'device_id': _deviceId,
          'device_model': deviceModel,
          'android_version': androidVersion,
          'ownerUid': uid,
          'registered_at': FieldValue.serverTimestamp(),
          'last_seen': FieldValue.serverTimestamp(),
          'status': 'active', // active | blocked
          'block_reason': '',
        });
      } else {
        // Existing device — update last_seen + backfill ownerUid if missing
        final data = doc.data();
        final updates = <String, dynamic>{
          'last_seen': FieldValue.serverTimestamp(),
        };
        if (data != null && (!data.containsKey('ownerUid') || data['ownerUid'] == '' || data['ownerUid'] == null)) {
          final uid = _auth.currentUser?.uid;
          if (uid != null && uid.isNotEmpty) {
            updates['ownerUid'] = uid;
          }
        }
        await docRef.update(updates);
      }
    } catch (e) {
      debugPrint('Firebase register device error: $e');
    }
  }

  // ── Check if this device is blocked (with fail-safe caching) ──
  Future<bool> checkDeviceStatus() async {
    final res = await checkDeviceStatusResult();
    return res.isBlocked;
  }

  Future<DeviceStatusResult> checkDeviceStatusResult() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasCachedStatus = prefs.containsKey(kLastKnownBlocked);
      final cachedBlocked = prefs.getBool(kLastKnownBlocked) ?? false;
      final cachedReason = prefs.getString(kLastKnownReason) ?? 'This device has been blocked by the owner.';
      final cachedTimeMs = prefs.getInt(kLastKnownTimestamp);
      final cachedTime = cachedTimeMs != null ? DateTime.fromMillisecondsSinceEpoch(cachedTimeMs) : null;

      try {
        final res = await _performLiveCheck().timeout(const Duration(milliseconds: 6000));
        _isBlocked = res['isBlocked'] as bool;
        _blockReason = res['blockReason'] as String;
        if (kDebugMode) debugPrint('[MONEY Remote Lock Check] Live check SUCCESS. device_id=$_deviceId, isBlocked=$_isBlocked, reason=$_blockReason');

        await prefs.setBool(kLastKnownBlocked, _isBlocked);
        await prefs.setString(kLastKnownReason, _blockReason);
        await prefs.setInt(kLastKnownTimestamp, DateTime.now().millisecondsSinceEpoch);

        return DeviceStatusResult(
          isBlocked: _isBlocked,
          blockReason: _blockReason,
          isFromCache: false,
          lastCheckedAt: DateTime.now(),
        );
      } catch (e) {
        if (kDebugMode) debugPrint('[MONEY Remote Lock Check] Live check EXCEPTION/TIMEOUT: $e');

        if (hasCachedStatus) {
          _isBlocked = cachedBlocked;
          _blockReason = _isBlocked ? cachedReason : '';
          if (kDebugMode) debugPrint('[MONEY Remote Lock Check] Fallback to CACHED status. isBlocked=$_isBlocked');
          return DeviceStatusResult(
            isBlocked: _isBlocked,
            blockReason: _blockReason,
            isFromCache: true,
            lastCheckedAt: cachedTime,
          );
        } else {
          _isBlocked = false;
          _blockReason = '';
          if (kDebugMode) debugPrint('[MONEY Remote Lock Check] No cached status available. Defaulting to isBlocked=false');
          return DeviceStatusResult(
            isBlocked: false,
            blockReason: '',
            isFromCache: true,
            lastCheckedAt: null,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[MONEY Remote Lock Check] Outer check error: $e');
      return const DeviceStatusResult(
        isBlocked: false,
        blockReason: '',
        isFromCache: true,
      );
    }
  }

  Future<Map<String, dynamic>> _performLiveCheck() async {
    _isConfigured = true;
    _deviceId = await _getOrCreateDeviceId();
    if (kDebugMode) debugPrint('[MONEY Remote Lock Check] Initiating parallel live check for device_id: $_deviceId');

    // Fire device registration asynchronously without blocking status check
    _registerDevice().catchError((e) {
      if (kDebugMode) debugPrint('[MONEY Remote Lock Check] Register device background error: $e');
    });

    // Execute direct doc lookup, field query lookup, and global settings concurrently from SERVER
    List<dynamic> results = [];
    try {
      results = await Future.wait([
        _firestore.collection(AppConstants.fcSettings).doc(AppConstants.fcDocSettings).get(const GetOptions(source: Source.server)),
        _firestore.collection(AppConstants.fcDevices).doc(_deviceId).get(const GetOptions(source: Source.server)),
        _firestore.collection(AppConstants.fcDevices).where('device_id', isEqualTo: _deviceId).get(const GetOptions(source: Source.server)),
      ]);
    } catch (e) {
      if (kDebugMode) debugPrint('[MONEY Remote Lock Check] Parallel Future.wait server check error: $e');
      throw Exception('Live server check failed or device is offline: $e');
    }

    if (results.length == 3) {
      final settingsDoc = results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final deviceDoc = results[1] as DocumentSnapshot<Map<String, dynamic>>;
      final querySnap = results[2] as QuerySnapshot<Map<String, dynamic>>;

      // 1. Global kill switch check
      if (settingsDoc.exists) {
        final data = settingsDoc.data();
        if (data != null && data['app_active'] == false) {
          return {
            'isBlocked': true,
            'blockReason': data['message'] ?? 'App has been disabled by the owner.',
          };
        }
      }

      // 2. Direct document ID lookup
      if (deviceDoc.exists) {
        final data = deviceDoc.data();
        if (kDebugMode) debugPrint('[MONEY Remote Lock Check] Direct doc ID ${deviceDoc.id} data: $data');
        if (data != null && data['status'] == 'blocked') {
          return {
            'isBlocked': true,
            'blockReason': data['block_reason'] ?? 'This device has been blocked by the owner.',
          };
        }
      }

      // 3. Field query lookup (matches any doc with device_id field equal to _deviceId)
      for (final doc in querySnap.docs) {
        final data = doc.data();
        if (kDebugMode) debugPrint('[MONEY Remote Lock Check] Matched field query doc ${doc.id} data: $data');
        if (data['status'] == 'blocked') {
          return {
            'isBlocked': true,
            'blockReason': data['block_reason'] ?? 'This device has been blocked by the owner.',
          };
        }
      }
    } else {
      throw Exception('Live server check incomplete');
    }

    return {
      'isBlocked': false,
      'blockReason': '',
    };
  }

  Future<void> _checkDeviceStatus() async {
    await checkDeviceStatusResult();
  }

  // ── Owner Login (to access admin panel) ──
  Future<bool> ownerLogin(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return _auth.currentUser != null;
    } catch (e) {
      debugPrint('Owner login error: $e');
      return false;
    }
  }

  // ── Owner Logout ──
  Future<void> ownerLogout() async {
    await _auth.signOut();
  }

  bool get isOwnerLoggedIn => _auth.currentUser != null;
  String? get ownerEmail => _auth.currentUser?.email;

  // ── Admin: Get all registered devices ──
  Future<List<Map<String, dynamic>>> getAllDevices() async {
    if (!isOwnerLoggedIn) return [];
    try {
      final snapshot = await _firestore
          .collection(AppConstants.fcDevices)
          .orderBy('registered_at', descending: true)
          .get();
      return snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (e) {
      debugPrint('Get all devices error: $e');
      return [];
    }
  }

  // ── Admin: Block a device ──
  Future<bool> blockDevice(String deviceId, String reason) async {
    if (!isOwnerLoggedIn) return false;
    try {
      await _firestore
          .collection(AppConstants.fcDevices)
          .doc(deviceId)
          .update({'status': 'blocked', 'block_reason': reason});
      return true;
    } catch (e) {
      debugPrint('Block device error: $e');
      return false;
    }
  }

  // ── Admin: Unblock a device ──
  Future<bool> unblockDevice(String deviceId) async {
    if (!isOwnerLoggedIn) return false;
    try {
      await _firestore
          .collection(AppConstants.fcDevices)
          .doc(deviceId)
          .update({'status': 'active', 'block_reason': ''});
      return true;
    } catch (e) {
      debugPrint('Unblock device error: $e');
      return false;
    }
  }

  // ── Admin: Disable app globally ──
  Future<bool> setGlobalAppStatus(bool isActive, {String message = ''}) async {
    if (!isOwnerLoggedIn) return false;
    try {
      await _firestore
          .collection(AppConstants.fcSettings)
          .doc(AppConstants.fcDocSettings)
          .set({
        'app_active': isActive,
        'message': message,
        'updated_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Set global status error: $e');
      return false;
    }
  }
}
