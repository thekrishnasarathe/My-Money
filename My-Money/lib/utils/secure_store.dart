import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

/// Thin wrapper around FlutterSecureStorage for PIN credential management.
///
/// On first access, auto-migrates any existing pin_hash / pin_salt values
/// from plain SharedPreferences into EncryptedSharedPreferences (Android)
/// or Keychain (iOS), then deletes the plaintext copies.
///
/// Because the hash formula changed (static salt prefix removed), migrated
/// hashes are NOT carried over — they're purged, and the caller is expected
/// to detect [kPinMigrationNeeded] and force a PIN re-set.
class SecureStore {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ── Keys used inside secure storage ──
  static const _kHash = 'pin_hash';
  static const _kSalt = 'pin_salt';

  /// Must be called once during app startup (e.g., in splash screen).
  /// Detects old plaintext PIN credentials, purges them, and sets
  /// a migration flag so the app can force a PIN re-set.
  static Future<void> initAndMigrate() async {
    final prefs = await SharedPreferences.getInstance();

    final oldHash = prefs.getString(AppConstants.kPinHash);
    final oldSalt = prefs.getString(AppConstants.kPinSalt);
    final pinEnabled = prefs.getBool(AppConstants.kPinEnabled) ?? false;

    if (pinEnabled && oldHash != null && oldHash.isNotEmpty) {
      // Old credentials exist in plaintext SharedPreferences.
      // These were hashed with the removed static prefix — can't be reused.
      // Purge them and flag for re-set.
      await prefs.remove(AppConstants.kPinHash);
      await prefs.remove(AppConstants.kPinSalt);
      await prefs.remove(AppConstants.kPinCode); // legacy plaintext, if any
      await _storage.delete(key: _kHash);
      await _storage.delete(key: _kSalt);
      await prefs.setBool(AppConstants.kPinMigrationNeeded, true);
    }

    // If secure storage already has credentials, nothing to do.
  }

  /// Read the stored PIN hash from secure storage. Returns empty string if unset.
  static Future<String> readPinHash() async {
    return await _storage.read(key: _kHash) ?? '';
  }

  /// Read the stored PIN salt from secure storage. Returns empty string if unset.
  static Future<String> readPinSalt() async {
    return await _storage.read(key: _kSalt) ?? '';
  }

  /// Write new PIN hash + salt to secure storage. Also clears the migration flag.
  static Future<void> writePinCredentials(String hash, String salt) async {
    await _storage.write(key: _kHash, value: hash);
    await _storage.write(key: _kSalt, value: salt);

    // Clear migration flag and any leftover plaintext
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.kPinMigrationNeeded);
    await prefs.remove(AppConstants.kPinHash);
    await prefs.remove(AppConstants.kPinSalt);
    await prefs.remove(AppConstants.kPinCode);
  }

  /// Clear all PIN credentials from secure storage and shared prefs.
  static Future<void> clearPinCredentials() async {
    await _storage.delete(key: _kHash);
    await _storage.delete(key: _kSalt);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.kPinMigrationNeeded);
    await prefs.remove(AppConstants.kPinHash);
    await prefs.remove(AppConstants.kPinSalt);
    await prefs.remove(AppConstants.kPinCode);
  }
}
