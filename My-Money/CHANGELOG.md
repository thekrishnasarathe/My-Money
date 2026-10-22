# Changelog

All notable changes to the MONEY project will be documented in this file.

## [1.1.0+2] - 2026-08-09

### Added
- Total Balance (all-time) aggregation view alongside existing monthly view, calculated as `SUM(incomes) - SUM(expenses)` without date or category filter constraints.

### Fixed
- Resolved issue where category icons rendered the same fallback icon (`restaurant`/`circle_outlined`) across transaction list tiles by binding dynamic `categoryIconData` lookups in row widgets.
- Fixed app hanging indefinitely on splash screen when offline by adding a 1.5-second timeout and fail-safe handling to remote lock status checks.

### Security
- Removed static salt prefix (`MONEY_SALT_2026_`) from PIN hashing; PINs are now hashed using pure 32-byte secure random salts (`SHA256(salt_pin)`).
- Migrated PIN hash and salt storage from plaintext `SharedPreferences` to hardware-backed `flutter_secure_storage` (`EncryptedSharedPreferences` on Android, `Keychain` on iOS).
- Disabled ADB backup extraction by setting `android:allowBackup="false"` in `AndroidManifest.xml`.
- Hardened remote device lock to fail safe when offline (enforces last known `isBlocked` status from local cache rather than failing open to unblocked).
- Corrected documentation and UI claims regarding backup status ("planned, not yet implemented") and PIN security ("SHA-256 hashing").

### Removed
- Removed unreferenced and non-functional `lib/screens/admin_screen.dart` source file.
