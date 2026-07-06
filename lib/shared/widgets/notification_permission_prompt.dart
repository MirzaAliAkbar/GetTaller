import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/notification_service.dart';

/// A full-screen permission prompt shown on first dashboard visit.
///
/// Uses the Peak-End Rule: user just finished onboarding (Peak) — this
/// prompt arrives right after, framed as the natural "next step" to
/// protect their investment. Shows concrete value props + social proof.
Future<void> showNotificationPermissionPrompt(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (_) => const _NotificationPermissionSheet(),
  );
}

class _NotificationPermissionSheet extends ConsumerStatefulWidget {
  const _NotificationPermissionSheet();

  @override
  ConsumerState<_NotificationPermissionSheet> createState() =>
      _NotificationPermissionSheetState();
}

class _NotificationPermissionSheetState
    extends ConsumerState<_NotificationPermissionSheet> {
  bool _isEnabling = false;
  bool _isDismissing = false;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_display_name') ?? '';
    if (mounted) setState(() => _userName = name);
  }


  Future<void> _enable() async {
    if (_isEnabling) return;
    setState(() => _isEnabling = true);

    final service = ref.read(notificationServiceProvider);

    // Request Android 13+ system permission, then enable our system
    await service.requestPermission();
    await service.setEnabled(true);

    // Schedule all notification types
    await service.scheduleAllAfterOnboarding();

    // Fire a test notification so the user sees it working immediately
    await service.sendTestNotification();

    // Reset "Ask Later" / "Don't Show Again" state
    await service.resetPromptState();

    if (!mounted) return;
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔔 Notifications enabled! Check your notification tray.'),
        backgroundColor: AppTheme.success,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _maybeLater() async {
    if (_isDismissing) return;
    setState(() => _isDismissing = true);

    // Mark that we've shown the prompt so it doesn't show every visit
    await ref.read(notificationServiceProvider).markPromptShown();

    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _dontShowAgain() async {
    if (_isDismissing) return;
    setState(() => _isDismissing = true);

    final service = ref.read(notificationServiceProvider);
    await service.markPromptDismissed();
    await service.markPromptShown();

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Icon
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryDark, AppTheme.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.notifications_active_rounded, color: Colors.white, size: 40),
              ),
            ),
            const SizedBox(height: 20),

            // Headline
            Text(
              _userName.isNotEmpty
                  ? 'Stay on Track, $_userName!'
                  : 'Stay on Track with Notifications',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              _userName.isNotEmpty
                  ? '$_userName, your personalized growth plan works best with reminders. '
                      'We\'ll nudge you at the right moments — no spam, just progress.'
                  : 'Your personalized growth plan works best with reminders. '
                      'We\'ll nudge you at the right moments — no spam, just progress.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary.withOpacity(0.8),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Stats Row — social proof
            Row(
              children: [
                _StatCard(
                  icon: '🔥',
                  value: '3×',
                  label: 'More consistent',
                ),
                const SizedBox(width: 12),
                _StatCard(
                  icon: '🏆',
                  value: '87%',
                  label: 'Streak retention',
                ),
                const SizedBox(width: 12),
                _StatCard(
                  icon: '📈',
                  value: '2×',
                  label: 'Progress tracking',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // What you'll get
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You\'ll receive:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _BulletItem(icon: '🏋️', text: 'Daily workout reminders'),
                  const SizedBox(height: 6),
                  _BulletItem(icon: '🌙', text: 'Bedtime wind-down alerts'),
                  const SizedBox(height: 6),
                  _BulletItem(icon: '⚡', text: 'Streak-saving warnings'),
                  const SizedBox(height: 6),
                  _BulletItem(icon: '📊', text: 'Weekly progress summaries'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Enable button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isEnabling ? null : _enable,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isEnabling
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Enable Notifications',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Later
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _isDismissing ? null : _maybeLater,
                child: Text(
                  'Ask Me Later',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ),

            // Don't show again
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _isDismissing ? null : _dontShowAgain,
                child: Text(
                  "Don't Show Again",
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textTertiary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.primary.withOpacity(0.08)),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String icon;
  final String text;

  const _BulletItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
