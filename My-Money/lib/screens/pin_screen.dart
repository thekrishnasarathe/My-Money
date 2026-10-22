import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import '../utils/security_utils.dart';
import '../utils/secure_store.dart';
import 'home_screen.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});
  @override State<PinScreen> createState() => _State();
}

class _State extends State<PinScreen> {
  String _entered = '';
  String _storedHash = '';
  String _storedSalt = '';
  bool _error = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPin();
  }

  Future<void> _loadPin() async {
    final hash = await SecureStore.readPinHash();
    final salt = await SecureStore.readPinSalt();
    if (!mounted) return;
    setState(() {
      _storedHash = hash;
      _storedSalt = salt;
      _loaded = true;
    });
  }

  void _onKey(String k) {
    if (_entered.length >= 4) return;
    setState(() { _entered += k; _error = false; });
    if (_entered.length == 4) _verify();
  }

  void _onDel() => setState(() {
    if (_entered.isNotEmpty) _entered = _entered.substring(0, _entered.length - 1);
  });

  Future<void> _verify() async {
    bool isValid = false;
    if (_storedHash.isNotEmpty && _storedSalt.isNotEmpty) {
      isValid = SecurityUtils.verifyPin(_entered, _storedHash, _storedSalt);
    }

    if (isValid && mounted) {
      context.read<AppProvider>().unlockApp();
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else if (mounted) {
      setState(() { _error = true; _entered = ''; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, color: AppTheme.primary, size: 48),
          const SizedBox(height: 16),
          const Text('Enter PIN', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          Row(mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 16, height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < _entered.length ? AppTheme.primary : AppTheme.divider),
            ))),
          if (_error) ...[
            const SizedBox(height: 12),
            const Text('Incorrect PIN', style: TextStyle(color: AppTheme.expenseRed)),
          ],
          const SizedBox(height: 40),
          ...[ ['1','2','3'],['4','5','6'],['7','8','9'],['','0','⌫'] ]
            .map((row) => Row(mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((k) => GestureDetector(
                onTap: () => k == '⌫' ? _onDel() : k.isEmpty ? null : _onKey(k),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: k.isEmpty ? Colors.transparent : AppTheme.cardDark,
                    shape: BoxShape.circle),
                  child: Center(child: Text(k,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500))),
                ))).toList())),
        ])));
  }
}
