import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class SecurityUtils {
  /// Generates a cryptographically secure random 32-byte salt, base64url-encoded.
  static String generateSalt() {
    final rand = Random.secure();
    final values = List<int>.generate(32, (i) => rand.nextInt(256));
    return base64Url.encode(values);
  }

  /// Returns a salted SHA-256 hash of the given PIN.
  /// Formula: SHA256(salt + "_" + pin) — no static prefix.
  static String hashPin(String pin, String salt) {
    final bytes = utf8.encode('${salt}_$pin');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifies if an entered PIN matches the stored hash given its salt.
  static bool verifyPin(String enteredPin, String storedHash, String storedSalt) {
    if (enteredPin.isEmpty || storedHash.isEmpty || storedSalt.isEmpty) {
      return false;
    }
    final hash = hashPin(enteredPin, storedSalt);
    return hash == storedHash;
  }
}
