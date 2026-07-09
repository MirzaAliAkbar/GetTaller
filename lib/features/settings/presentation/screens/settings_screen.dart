import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_review/in_app_review.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../../core/services/user_data_service.dart';
import '../../../../core/services/notification_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isMetric = true;
  String _language = 'en';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isMetric = prefs.getBool(AppConstants.prefUnitSystem) ?? true;
      _language = prefs.getString(AppConstants.prefLanguage) ?? 'en';
    });
  }

  Future<void> _saveUnitSystem(bool isMetric) async {
    await UnitConverter.setMetric(isMetric);
    setState(() => _isMetric = isMetric);
    // Invalidate providers so dashboard rebuilds with new units
    ref.invalidate(persistedUserDataProvider);
    ref.invalidate(heightMeasurementsProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          children: [
            // Profile section
            const Text('Profile', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.height_rounded,
              title: 'Update Measurements',
              subtitle: 'Log your height, weight, parent heights',
              onTap: () => _showUpdateMeasurements(context),
            ),
            _SettingsTile(
              icon: Icons.person_rounded,
              title: 'Personal Info',
              subtitle: 'Gender, age, activity level',
              onTap: () => _showPersonalInfo(context),
            ),

            const SizedBox(height: 24),
            const Text('Preferences', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),

            // Unit system
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF0F0F0)),
              ),
              child: Row(children: [
                const Icon(Icons.straighten_rounded, color: AppTheme.textSecondary),
                const SizedBox(width: 14),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Unit System', style: TextStyle(fontWeight: FontWeight.w500)),
                  Text('Metric (cm/kg) or Imperial (ft/in/lbs)', style: TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
                ])),
                Switch(
                  value: _isMetric,
                  activeColor: AppTheme.accent,
                  onChanged: _saveUnitSystem,
                ),
              ]),
            ),

            const SizedBox(height: 8),

            _SettingsTile(
              icon: Icons.language_rounded,
              title: 'Language',
              subtitle: _language == 'en' ? 'English' : 'English',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('More languages coming soon!'), backgroundColor: AppTheme.info),
                );
              },
            ),

            const SizedBox(height: 24),
            const Text('App', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),

            _NotificationTile(),
            _SettingsTile(
              icon: Icons.article_outlined,
              title: 'Medical Disclaimer',
              subtitle: 'Important health information',
              onTap: () => _showDisclaimer(context),
            ),
            _SettingsTile(
              icon: Icons.star_outline_rounded,
              title: 'Rate the App',
              subtitle: 'Your feedback helps us grow',
              onTap: () => _showRateApp(context),
            ),
            _SettingsTile(
              icon: Icons.feedback_outlined,
              title: 'About & Privacy',
              subtitle: 'How we protect your data',
              onTap: () => _showAboutPrivacy(context),
            ),
            _SettingsTile(
              icon: Icons.delete_outline_rounded,
              title: 'Delete Data',
              subtitle: 'Remove all local data',
              onTap: () => _confirmDeleteData(context),
            ),

            const SizedBox(height: 32),
            Center(
              child: Text(
                'GetTaller v${AppConstants.appVersionName}',
                style: const TextStyle(fontSize: 13, color: AppTheme.textTertiary),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                '100% Free • Ad-Supported • Privacy Protected',
                style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showUpdateMeasurements(BuildContext context) {
    final heightController = TextEditingController();
    final weightController = TextEditingController();
    final service = ref.read(userDataServiceProvider);

    service.loadUserData().then((userData) {
      if (userData != null) {
        heightController.text = userData.currentHeightCm.toStringAsFixed(1);
        weightController.text = userData.currentWeightKg.toStringAsFixed(1);
      }
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Update Measurements',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                TextField(
                  controller: heightController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Height (${UnitConverter.heightUnit()})',
                  suffixText: UnitConverter.heightUnit(),
                ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: weightController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Weight (${UnitConverter.weightUnit()})',
                  suffixText: UnitConverter.weightUnit(),
                ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      final h = double.tryParse(heightController.text);
                      final w = double.tryParse(weightController.text);
                      if (h == null || w == null || h < 100 || h > 250 || w < 20 || w > 250) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Please enter valid values')),
                        );
                        return;
                      }

                      // Check 30-day countdown
                      final canMeasure = await service.canMeasureHeight();
                      if (!canMeasure) {
                        final daysLeft = await service.getDaysUntilNextMeasurement();
                        final proceed = await showDialog<bool>(
                          context: ctx,
                          builder: (dCtx) => AlertDialog(
                            title: const Text('Wait — 30-day cycle not complete?'),
                            content: Text(
                              'Bone remodeling cycles suggest measuring every 30 days '
                              'for consistent tracking. You have $daysLeft days remaining.\n\n'
                              'Measuring too often can give misleading results. '
                              'Would you still like to update now?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dCtx, false),
                                child: const Text('Wait'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(dCtx, true),
                                child: const Text('Update Anyway'),
                              ),
                            ],
                          ),
                        );
                        if (proceed != true) return;
                      }

                      // Confirmation
                      final confirm = await showDialog<bool>(
                        context: ctx,
                        builder: (cCtx) => AlertDialog(
                          title: const Text('Update Measurements?'),
                          content: Text(
                            'Set height to ${UnitConverter.formatHeight(h)} '
                            'and weight to ${UnitConverter.formatWeight(w)}?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(cCtx, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(cCtx, true),
                              child: const Text('Confirm'),
                            ),
                          ],
                        ),
                      );
                      if (confirm != true) return;

                      // Calculate growth for progress notification
                      final currentData = await service.loadUserData();
                      final oldHeight = currentData?.currentHeightCm ?? h;
                      final cmGrown = h - oldHeight;

                      // Save
                      await service.addHeightMeasurement(h);
                      await service.updateCurrentHeight(h);

                      // Fire progress milestone if growth detected
                      if (cmGrown > 0) {
                        final notif = ref.read(notificationServiceProvider);
                        await notif.fireProgressMilestone(cmGrown);
                      }

                      // Invalidate providers so chart/header update everywhere
                      ref.invalidate(persistedUserDataProvider);
                      ref.invalidate(heightMeasurementsProvider);
                      ref.invalidate(daysUntilNextMeasurementProvider);
                      ref.invalidate(canMeasureHeightProvider);

                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      setState(() {});
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Measurements updated!'),
                          backgroundColor: AppTheme.accent,
                        ),
                      );
                    },
                    child: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPersonalInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Personal Info',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              ref.watch(persistedUserDataProvider).when(
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
                data: (userData) {
                  if (userData == null) return const Text('No data available');
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow('Gender', userData.isMale ? 'Male' : 'Female'),
                      const Divider(height: 24),
                      _infoRow('Birth Year', '${userData.birthYear}'),
                      const Divider(height: 24),
                      _infoRow('Current Height', UnitConverter.formatHeight(userData.currentHeightCm)),
                      const Divider(height: 24),
                      _infoRow('Current Weight', UnitConverter.formatWeight(userData.currentWeightKg)),
                      const Divider(height: 24),
                      _infoRow('Activity Level', '${userData.activityDaysPerWeek} days/week'),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }

  void _showDisclaimer(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Medical Disclaimer'),
        content: const SingleChildScrollView(
          child: Text(
            'GetTaller is for informational and educational purposes only. '
            'It is not a medical device and does not diagnose, treat, cure, or prevent any disease.\n\n'
            'Height growth is influenced by genetics, nutrition, sleep, and exercise. '
            'Results vary from person to person. The predictions and suggestions provided '
            'are estimates based on scientific averages and should not be taken as guarantees.\n\n'
            'Note: Predictions include a small motivational adjustment intended to '
            'encourage consistent adherence to the plan. All height projections are '
            'approximate and not a guarantee of future results.\n\n'
            'Always consult with a qualified healthcare provider before starting any '
            'nutrition, exercise, or sleep program, especially for growing children and teenagers.\n\n'
            'If you have concerns about your growth or development, please consult an '
            'endocrinologist or pediatrician.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  void _showRateApp(BuildContext context) async {
    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      inAppReview.requestReview();
    } else {
      inAppReview.openStoreListing(appStoreId: 'com.grayonix.GetTaller');
    }
  }

  void _showAboutPrivacy(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🔒 Privacy First'),
        content: const SingleChildScrollView(
          child: Text(
            'GetTaller is designed with your privacy as a top priority.\n\n'
            '• 100% Free — No hidden costs, no subscriptions\n'
            '• No Account Required — Start using immediately\n'
            '• No Tracking — We don\'t collect or sell your data\n'
            '• All data stays on your device\n'
            '• Ad-supported only — no premium upsells\n'
            '• You can delete all your data anytime\n\n'
            'Predictions include a small motivational adjustment. '
            'Height estimates are intentionally set 1-3 cm above '
            'the raw calculation to encourage adherence to the plan. '
            'This is based on the principle that belief and consistency '
            'can improve real-world outcomes.\n\n'
            'We believe health information should be private '
            'and accessible to everyone.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteData(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Data?'),
        content: const Text(
          'This will remove all your measurements, profile data, and preferences. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data cleared')),
              );
              context.go('/splash');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;

  const _SettingsTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.textSecondary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textTertiary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFF0F0F0)),
        ),
        tileColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: onTap,
      ),
    );
  }
}

class _NotificationTile extends ConsumerStatefulWidget {
  @override
  ConsumerState<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends ConsumerState<_NotificationTile> {
  bool _enabled = false;
  int _hour = 9;
  int _minute = 0;
  int _sleepHour = 22;
  int _sleepMinute = 0;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final service = ref.read(notificationServiceProvider);
    final enabled = await service.isEnabled;
    final time = await service.notificationTime;
    final sleep = await service.sleepTime;
    if (mounted) {
      setState(() {
        _enabled = enabled;
        _hour = time['hour'] ?? 9;
        _minute = time['minute'] ?? 0;
        _sleepHour = sleep['hour'] ?? 22;
        _sleepMinute = sleep['minute'] ?? 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.notifications_rounded, color: AppTheme.textSecondary),
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
        subtitle: Text(
          _enabled
              ? 'Workout ${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')} · Bedtime ${_sleepHour.toString().padLeft(2, '0')}:${_sleepMinute.toString().padLeft(2, '0')}'
              : 'Reminders, streaks, tips',
          style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary),
        ),
        trailing: Switch(
          value: _enabled,
          activeColor: AppTheme.accent,
          onChanged: (v) async {
            final service = ref.read(notificationServiceProvider);
            if (v) {
              // Check if system permission is granted (Android 13+)
              final hadPermission = await service.hasPermission();
              if (!hadPermission) {
                await service.requestPermission(); // OS system dialog
              }
              // Check again after request
              final hasPermissionNow = await service.hasPermission();

              await service.setEnabled(true);
              await service.resetPromptState();
              await service.scheduleAllAfterOnboarding();
              await service.sendTestNotification();

              if (!mounted) return;

              if (!hasPermissionNow) {
                // Android 13+: user denied the system prompt — guide them
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Notifications scheduled. Enable in System Settings → Notifications for alerts to appear.'),
                    backgroundColor: AppTheme.warning,
                    duration: const Duration(seconds: 5),
                    action: SnackBarAction(
                      label: 'Settings',
                      textColor: Colors.white,
                      onPressed: () async {
                        // Open app system settings
                        await launchUrl(
                          Uri.parse('package:${AppConstants.packageName}'),
                          mode: LaunchMode.externalApplication,
                        );
                      },
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🔔 Check your notification tray!'),
                    backgroundColor: AppTheme.accent,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            } else {
              await service.setEnabled(false);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications turned off'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
            if (mounted) setState(() => _enabled = v);
          },
        ),
        onTap: _enabled ? _showSettings : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFF0F0F0)),
        ),
        tileColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Future<void> _showSettings() async {
    final workoutHourCtrl = TextEditingController(text: _hour.toString().padLeft(2, '0'));
    final workoutMinCtrl = TextEditingController(text: _minute.toString().padLeft(2, '0'));
    final sleepHourCtrl = TextEditingController(text: _sleepHour.toString().padLeft(2, '0'));
    final sleepMinCtrl = TextEditingController(text: _sleepMinute.toString().padLeft(2, '0'));

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notification Settings'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Workout Reminder',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: workoutHourCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Hour', hintText: '09'),
                      maxLength: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(':', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: workoutMinCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Minute', hintText: '00'),
                      maxLength: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Bedtime Reminder',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              const SizedBox(height: 4),
              const Text('(HGH peaks during deep sleep)',
                  style: TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: sleepHourCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Hour', hintText: '22'),
                      maxLength: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(':', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: sleepMinCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Minute', hintText: '00'),
                      maxLength: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Notifications include: workouts, streak alerts, bedtime reminders, weekly summaries, and progress updates.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textTertiary, height: 1.4)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );

    if (result == true) {
      final service = ref.read(notificationServiceProvider);
      final wh = int.tryParse(workoutHourCtrl.text)?.clamp(0, 23) ?? _hour;
      final wm = int.tryParse(workoutMinCtrl.text)?.clamp(0, 59) ?? _minute;
      final sh = int.tryParse(sleepHourCtrl.text)?.clamp(0, 23) ?? _sleepHour;
      final sm = int.tryParse(sleepMinCtrl.text)?.clamp(0, 59) ?? _sleepMinute;

      await service.setNotificationTime(wh, wm);
      await service.setSleepTime(sh, sm);

      if (mounted) setState(() {
        _hour = wh;
        _minute = wm;
        _sleepHour = sh;
        _sleepMinute = sm;
      });
    }
  }
}

