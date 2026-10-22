import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/app_provider.dart';
import '../services/firebase_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../utils/secure_store.dart';
import '../utils/security_utils.dart';
import 'pin_screen.dart';
import 'home_screen.dart';
import 'blocked_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _State();
}

class _State extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade, _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 1200));
    _fade = Tween<double>(begin:0,end:1).animate(
      CurvedAnimation(parent:_ctrl,
        curve:const Interval(0.0,0.6,curve:Curves.easeIn)));
    _scale = Tween<double>(begin:0.6,end:1).animate(
      CurvedAnimation(parent:_ctrl,curve:Curves.elasticOut));
    _ctrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _init();
    });
  }

  void _init() async {
    await Future.wait([
      Future.delayed(const Duration(seconds: 2)),
      context.read<AppProvider>().init(),
      SecureStore.initAndMigrate(), // Detect & purge old plaintext PIN credentials
    ]);
    if (!mounted) return;

    // ── Firebase Remote Lock Check ──
    DeviceStatusResult statusResult = const DeviceStatusResult(
      isBlocked: false, blockReason: '', isFromCache: false);

    try {
      final firebaseService = FirebaseService();
      statusResult = await firebaseService.checkDeviceStatusResult();
    } catch (e) {
      debugPrint('Splash screen remote lock check error: $e');
      try {
        final prefs = await SharedPreferences.getInstance();
        if (prefs.containsKey(FirebaseService.kLastKnownBlocked)) {
          final isBlocked = prefs.getBool(FirebaseService.kLastKnownBlocked) ?? false;
          final reason = prefs.getString(FirebaseService.kLastKnownReason) ?? '';
          final ms = prefs.getInt(FirebaseService.kLastKnownTimestamp);
          statusResult = DeviceStatusResult(
            isBlocked: isBlocked,
            blockReason: reason,
            isFromCache: true,
            lastCheckedAt: ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null,
          );
        }
      } catch (_) {}
    }

    if (!mounted) return;

    if (statusResult.isBlocked) {
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) =>
          BlockedScreen(
            reason: statusResult.blockReason.isNotEmpty
              ? statusResult.blockReason
              : 'This device has been blocked by the owner.',
            isFromCache: statusResult.isFromCache,
            lastCheckedAt: statusResult.lastCheckedAt,
          )));
      return;
    }

    // ── PIN Check ──
    final prefs = await SharedPreferences.getInstance();
    final pinEnabled = prefs.getBool(AppConstants.kPinEnabled) ?? false;
    final migrationNeeded = prefs.getBool(AppConstants.kPinMigrationNeeded) ?? false;
    if (!mounted) return;

    if (pinEnabled && migrationNeeded) {
      // Old PIN was hashed with removed static salt — force re-set
      _showSecurityMigration();
    } else if (pinEnabled) {
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const PinScreen()));
    } else {
      context.read<AppProvider>().unlockApp();
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  /// Shows a one-time security migration dialog forcing PIN re-set.
  void _showSecurityMigration() {
    final pinCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.security_update_good, color: AppTheme.primary, size: 28),
          SizedBox(width: 10),
          Expanded(child: Text('Security Update', style: TextStyle(fontSize: 18))),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text(
            'MONEY has been updated with stronger PIN security. '
            'Your old PIN has been cleared. Please set a new one.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: pinCtrl,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'New 4-digit PIN',
              prefixIcon: Icon(Icons.lock_outline),
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: confirmCtrl,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirm PIN',
              prefixIcon: Icon(Icons.lock_outline),
              counterText: '',
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () async {
              if (pinCtrl.text.length != 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN must be 4 digits'),
                    backgroundColor: AppTheme.expenseRed));
                return;
              }
              if (pinCtrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PINs do not match'),
                    backgroundColor: AppTheme.expenseRed));
                return;
              }

              // Hash with new formula (no static prefix) and store securely
              final salt = SecurityUtils.generateSalt();
              final hash = SecurityUtils.hashPin(pinCtrl.text, salt);
              await SecureStore.writePinCredentials(hash, salt);

              pinCtrl.dispose();
              confirmCtrl.dispose();

              if (!mounted) return;
              Navigator.of(ctx).pop();

              // Now route to normal PIN screen to verify
              Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const PinScreen()));
            },
            child: const Text('Set New PIN',
              style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Center(child: FadeTransition(opacity: _fade,
        child: ScaleTransition(scale: _scale,
          child: Column(mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Container(width:110,height:110,
              decoration:BoxDecoration(
                color:Colors.white,
                borderRadius:BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Image.asset('assets/images/app_logo.png', fit: BoxFit.contain),
                ),
              ),
            ),
            const SizedBox(height:24),
            Text(AppConstants.appName,style:const TextStyle(fontSize:32,
              fontWeight:FontWeight.bold,color:Colors.white)),
            const SizedBox(height:6),
            Text(AppConstants.appTagline,
              style:TextStyle(fontSize:13,
                color:Colors.white.withOpacity(0.5))),
            const SizedBox(height:60),
            const SizedBox(width:24,height:24,
              child:CircularProgressIndicator(strokeWidth:2,
                color:AppTheme.primary)),
            const SizedBox(height:40),
            Text('by ${AppConstants.ownerName}',
              style:TextStyle(fontSize:11,
                color:Colors.white.withOpacity(0.4))),
          ])))));
  }
}
