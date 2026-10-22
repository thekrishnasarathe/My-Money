import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../providers/app_provider.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import 'home_screen.dart';

class BlockedScreen extends StatefulWidget {
  final String reason;
  final bool isFromCache;
  final DateTime? lastCheckedAt;

  const BlockedScreen({
    super.key,
    this.reason = 'This device has been blocked by the owner.',
    this.isFromCache = false,
    this.lastCheckedAt,
  });
  @override State<BlockedScreen> createState() => _State();
}
class _State extends State<BlockedScreen> {
  bool _checking = false;

  Future<void> _retry() async {
    setState(() => _checking = true);
    try {
      final fb = FirebaseService();
      final statusRes = await fb.checkDeviceStatusResult();
      if (!mounted) return;
      if (!statusRes.isBlocked) {
        context.read<AppProvider>().unlockApp();
        Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        setState(() => _checking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(statusRes.isFromCache
            ? 'Offline check complete. Still blocked from cached status.'
            : 'Still blocked. Contact owner.')));
      }
    } catch (_) {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = widget.lastCheckedAt != null
      ? DateFormat('d MMM yyyy, h:mm a').format(widget.lastCheckedAt!)
      : 'previous check';

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(child: Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.expenseRed.withOpacity(0.1),
              shape: BoxShape.circle),
            child: const Icon(Icons.lock_outline,
              color: AppTheme.expenseRed, size: 56)),
          const SizedBox(height: 24),
          const Text('Access Blocked', style: TextStyle(fontSize: 22,
            fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.expenseRed.withOpacity(0.3))),
            child: Text(widget.reason, style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center)),
          if (widget.isFromCache) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withOpacity(0.4)),
              ),
              child: Row(children: [
                const Icon(Icons.wifi_off_outlined, color: Colors.amber, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This device was locked as of $timeStr. Connect to the internet to verify current status.',
                    style: const TextStyle(color: Colors.amber, fontSize: 12, height: 1.4),
                  ),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 16),
          const Text('Contact the owner to get access.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text(AppConstants.ownerEmail,
            style: const TextStyle(color: AppTheme.primary, fontSize: 13)),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity,
            child: ElevatedButton.icon(
              icon: _checking
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2,
                      color: Colors.black))
                : const Icon(Icons.refresh, size: 18),
              label: Text(_checking ? 'Checking...' : 'Try Again'),
              onPressed: _checking ? null : _retry)),
        ])))));
  }
}
