import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../utils/security_utils.dart';
import '../../utils/secure_store.dart';
import '../../widgets/common_widgets.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});
  @override State<SecurityScreen> createState() => _State();
}

class _State extends State<SecurityScreen> {
  bool _pinEnabled = false;
  bool _loaded = false;
  final _newPin = TextEditingController();
  final _confirmPin = TextEditingController();
  bool _showNew = false, _showConfirm = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _pinEnabled = p.getBool(AppConstants.kPinEnabled) ?? false;
      _loaded = true;
    });
  }

  @override
  void dispose() { _newPin.dispose(); _confirmPin.dispose(); super.dispose(); }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    if (_pinEnabled) {
      if (_newPin.text.length != 4) { _msg('PIN must be 4 digits', error: true); return; }
      if (_newPin.text != _confirmPin.text) { _msg('PINs do not match', error: true); return; }

      // Generate random cryptographic salt and SHA-256 hash
      final salt = SecurityUtils.generateSalt();
      final hash = SecurityUtils.hashPin(_newPin.text, salt);

      await p.setBool(AppConstants.kPinEnabled, true);
      await SecureStore.writePinCredentials(hash, salt);

      _newPin.clear(); _confirmPin.clear();
      _msg('PIN secured with SHA-256 hashing');
    } else {
      await p.setBool(AppConstants.kPinEnabled, false);
      await SecureStore.clearPinCredentials();
      _msg('PIN disabled');
    }
    if (mounted) setState(() {});
  }

  void _msg(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m),
      backgroundColor: error ? AppTheme.expenseRed : AppTheme.primary));
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(title: const Text('Security & PIN')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Container(width: 42, height: 42,
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.shield_outlined, color: AppTheme.primary)),
              const SizedBox(width: 14),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('App Lock Protection', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('Require 4-digit PIN to open MONEY app', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ])),
              Switch(
                value: _pinEnabled,
                activeColor: AppTheme.primary,
                onChanged: (v) => setState(() => _pinEnabled = v),
              ),
            ]),
          ),
          if (_pinEnabled) ...[
            const SizedBox(height: 24),
            const Text('SET 4-DIGIT PIN', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            const SizedBox(height: 12),
            TextField(
              controller: _newPin,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: !_showNew,
              decoration: InputDecoration(
                labelText: 'New 4-digit PIN',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_showNew ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _showNew = !_showNew),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPin,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: !_showConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm 4-digit PIN',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_showConfirm ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _showConfirm = !_showConfirm),
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
          PrimaryButton(label: 'Save Security Settings', onTap: _save),
        ]),
      ),
    );
  }
}
