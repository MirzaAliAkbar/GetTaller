import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/user_data_service.dart';
import '../../../../core/utils/nutrition_goals.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/ads/ad_service.dart';
import '../../../../shared/widgets/banner_ad_widget.dart';
import '../../../exercises/data/exercise_database.dart';

/// Daily Plan tab — Blueprint §4.3
/// Three sub-tabs: Exercises, Nutrition, Sleep
/// Anchored by a persistent Banner Ad at the bottom.
class DailyPlanTab extends ConsumerStatefulWidget {
  const DailyPlanTab({super.key});

  @override
  ConsumerState<DailyPlanTab> createState() => _DailyPlanTabState();
}

class _DailyPlanTabState extends ConsumerState<DailyPlanTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Weekly recap is no longer auto-shown here — it's surfaced via a Monday
    // badge on the dashboard (see weeklyRecapBadgeProvider).
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dayNumberAsync = ref.watch(currentDayNumberProvider);

    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daily Plan', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  dayNumberAsync.when(
                    data: (day) => Text('Day $day of 90',
                        style: Theme.of(context).textTheme.bodyMedium),
                    loading: () => Text('Loading...',
                        style: Theme.of(context).textTheme.bodyMedium),
                    error: (_, __) => Text('Day 1 of 90',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          ),

          // Tab bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Exercises'),
                  Tab(text: 'Nutrition'),
                  Tab(text: 'Sleep'),
                ],
              ),
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ExercisesTab(),
                _NutritionTab(),
                _SleepTab(),
              ],
            ),
          ),

          // Anchored Banner Ad — Blueprint §4.3
          const BannerAdWidget(),
        ],
      ),
    );
  }
}

// ── Levels Tab ──

class _ExercisesTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ExercisesTab> createState() => _ExercisesTabState();
}

class _ExercisesTabState extends ConsumerState<_ExercisesTab> {
  bool _hasShownCompletion = false;

  @override
  Widget build(BuildContext context) {
    final dayNumberAsync = ref.watch(currentDayNumberProvider);
    final completedAsync = ref.watch(completedLevelsProvider);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══ PROGRESS BAR ═══
          dayNumberAsync.when(
            data: (day) {
              // Show completion screen when day 90 is reached
              if (day >= 90 && !_hasShownCompletion) {
                _hasShownCompletion = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    context.push('/plan-complete');
                  }
                });
              }
              return _buildProgressHeader(context, day);
            },
            loading: () => const SizedBox(height: 40),
            error: (_, __) => const SizedBox(height: 40),
          ),
          const SizedBox(height: 24),

          // ═══ TODAY'S LEVEL (Hero) ═══
          dayNumberAsync.when(
            data: (day) {
              final exercises = ExerciseDatabase.getExercisesForDay(day);
              final phaseName = ExerciseDatabase.getPhaseName(day);
              final week = ExerciseDatabase.getWeekInPhase(day);
              return completedAsync.when(
                data: (completed) => _buildTodayLevel(
                  context, ref, day, phaseName, week, exercises, completed.contains(day),
                ),
                loading: () => _buildTodayLevel(context, ref, day, phaseName, week, exercises, false),
                error: (_, __) => _buildTodayLevel(context, ref, day, phaseName, week, exercises, false),
              );
            },
            loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const Center(child: Text('Could not load your plan')),
          ),
          const SizedBox(height: 28),

          // ═══ PREVIOUS LEVELS ═══
          dayNumberAsync.when(
            data: (day) => completedAsync.when(
              data: (completed) => _buildPreviousLevels(context, ref, day, completed),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // ═══ COMING UP ═══
          dayNumberAsync.when(
            data: (day) => _buildComingUp(context, day),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ── Repeat Workout: rewarded-ad gate ──
  // Each repeat attempt requires its own ad watch — no persistent unlock.

  Future<void> _watchAdThenRepeat(
    BuildContext context, WidgetRef ref, List<String> ids, int level,
  ) async {
    final adNotifier = ref.read(rewardedAdStateProvider.notifier);
    final loaded = await adNotifier.load(
        adUnitId: AppConstants.rewardedRepeatWorkoutAdUnitId);

    if (!context.mounted) return;

    if (!loaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ad failed to load. Please try again.'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    final shown = await adNotifier.show();

    if (!context.mounted) return;

    // Only proceed to the workout when the ad was actually watched — otherwise
    // a failed ad would hand out the repeat for free.
    if (!shown) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ad did not complete. Please try again.'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    context.push('/workout', extra: {'ids': ids, 'level': level});
  }

  // ── Progress Header ──

  Widget _buildProgressHeader(BuildContext context, int dayNumber) {
    final completion = dayNumber / 90;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                '90-Day Journey',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Level $dayNumber',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: completion,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD700)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$dayNumber of 90 days complete',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  // ── Today's Level (Hero) ──

  Widget _buildTodayLevel(
    BuildContext context, WidgetRef ref,
    int dayNumber, String phaseName, int week,
    List<ExerciseInfo> exercises, bool isCompleted,
  ) {
    final totalDuration = exercises.fold<int>(0, (s, e) => s + e.durationSeconds * e.setsCount);
    final double totalMinutes = ((totalDuration / 60.0) + (exercises.length.toDouble() * 0.5)).ceilToDouble(); // exercise + rest approx

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCompleted ? AppTheme.success.withOpacity(0.3) : AppTheme.primary.withOpacity(0.15),
          width: isCompleted ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isCompleted ? AppTheme.success : AppTheme.primary).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isCompleted
                        ? [AppTheme.success, const Color(0xFF43A047)]
                        : [AppTheme.primary, AppTheme.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: (isCompleted ? AppTheme.success : AppTheme.primary).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCompleted ? Icons.check_circle_rounded : Icons.star_rounded,
                      color: Colors.white, size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isCompleted ? 'Completed' : "Today's Workout",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$phaseName · Week $week',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Exercise list
          ...exercises.map((ex) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: Text(ex.icon, style: const TextStyle(fontSize: 18))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ex.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(
                        '${ex.setsCount}× ${ex.durationSeconds}s',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _diffColor(ex.difficulty).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(ex.difficulty, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: _diffColor(ex.difficulty))),
                ),
              ],
            ),
          )),

          const SizedBox(height: 8),
          // Duration & rest info
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 14, color: AppTheme.textTertiary),
              const SizedBox(width: 4),
              Text('~${totalMinutes.toInt()} min total', style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
              const SizedBox(width: 16),
              Icon(Icons.hourglass_empty_rounded, size: 14, color: AppTheme.textTertiary),
              const SizedBox(width: 4),
              Text('${exercises.length} exercises', style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
            ],
          ),
          const SizedBox(height: 16),

          // Action button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                if (isCompleted) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Row(
                        children: [
                          const Icon(Icons.replay_rounded, color: AppTheme.success, size: 24),
                          const SizedBox(width: 8),
                          Text('Repeat Level $dayNumber?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 18)),
                        ],
                      ),
                      content: const Text('You\'ve already completed this workout. Watch a quick ad to unlock a repeat — it\'ll re-mark this level as complete.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel', style: TextStyle(color: AppTheme.textTertiary)),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _watchAdThenRepeat(
                              context, ref,
                              exercises.map((e) => e.id).toList(),
                              dayNumber,
                            );
                          },
                          icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
                          label: const Text('Watch Ad & Repeat'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  context.push('/workout', extra: {
                    'ids': exercises.map((e) => e.id).toList(),
                    'level': dayNumber,
                  });
                }
              },
              icon: Icon(
                isCompleted ? Icons.replay_rounded : Icons.play_arrow_rounded,
                size: 22,
              ),
              label: Text(
                isCompleted ? 'Repeat Workout' : 'Start Workout',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCompleted ? AppTheme.success : AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Previous Levels ──

  Widget _buildPreviousLevels(BuildContext context, WidgetRef ref, int today, List<int> completed) {
    if (today <= 1) return const SizedBox.shrink();

    // Show the latest 8 completed/available levels — NOT one card per previous
    // day. (the old count of `today - 1` produced a huge unlocked-looking wall,
    // e.g. days 20–46 when today was 28.)
    final count = min(8, today - 1);
    final start = today - count;
    final levels = List.generate(count, (i) => start + i);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history_rounded, size: 18, color: AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text(
              'Previous Levels',
              style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
            const Spacer(),
            Text(
              '${completed.where((l) => l < today).length}/${levels.length} done',
              style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: levels.length,
            itemBuilder: (context, index) {
              final level = levels[index];
              final done = completed.contains(level);
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => _showLevelDetail(context, ref, level, done),
                  child: Container(
                    width: 80,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: done ? AppTheme.success.withOpacity(0.06) : AppTheme.textTertiary.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: done ? AppTheme.success.withOpacity(0.2) : AppTheme.textTertiary.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Lv $level',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: done ? AppTheme.success : AppTheme.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Icon(
                          done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          size: 18,
                          color: done ? AppTheme.success : AppTheme.textTertiary.withOpacity(0.3),
                        ),
                        if (done) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Repeat',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.success,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Coming Up ──

  Widget _buildComingUp(BuildContext context, int today) {
    if (today >= 90) return const SizedBox.shrink();

    final levels = List.generate(min(5, 90 - today), (i) => today + 1 + i);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.lock_rounded, size: 18, color: AppTheme.textTertiary),
            const SizedBox(width: 6),
            Text(
              'Coming Up',
              style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: levels.length,
            itemBuilder: (context, index) {
              final level = levels[index];
              final daysLeft = level - today;
              return Container(
                width: 72,
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.textTertiary.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.textTertiary.withOpacity(0.08)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_rounded, size: 16, color: AppTheme.textTertiary),
                    const SizedBox(height: 4),
                    Text(
                      '$level',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textTertiary,
                      ),
                    ),
                    Text(
                      daysLeft == 1 ? 'Tomorrow' : '${daysLeft}d',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9, fontWeight: FontWeight.w500, color: AppTheme.textTertiary.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  void _showLevelDetail(BuildContext context, WidgetRef ref, int level, bool done) {
    final exercises = ExerciseDatabase.getExercisesForDay(level);
    final phaseName = ExerciseDatabase.getPhaseName(level);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Level $level',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      phaseName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...exercises.map((ex) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(child: Text(ex.icon, style: const TextStyle(fontSize: 16))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(ex.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14))),
                    Text('${ex.setsCount}× ${ex.durationSeconds}s', style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
                  ],
                ),
              )),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    showDialog(
                      context: context,
                      builder: (dCtx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: Row(
                          children: [
                            Icon(done ? Icons.replay_rounded : Icons.play_arrow_rounded,
                                color: done ? AppTheme.success : AppTheme.primary, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              done ? 'Repeat Level $level?' : 'Catch up: Level $level?',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 18),
                            ),
                          ],
                        ),
                        content: Text(done
                            ? 'Watch a quick ad to replay this workout — it\'ll mark the level as complete again.'
                            : 'You missed this day. Watch a quick ad to do it now — it\'ll count as complete.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dCtx),
                            child: const Text('Cancel', style: TextStyle(color: AppTheme.textTertiary)),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(dCtx);
                              _watchAdThenRepeat(
                                context, ref,
                                exercises.map((e) => e.id).toList(),
                                level,
                              );
                            },
                            icon: Icon(done ? Icons.replay_rounded : Icons.play_arrow_rounded, size: 18),
                            label: Text(done ? 'Watch Ad & Repeat' : 'Watch Ad & Start'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.success,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: Icon(done ? Icons.replay_rounded : Icons.play_arrow_rounded, size: 20),
                  label: Text(done ? 'Repeat Workout' : 'Start Workout'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Color _diffColor(String d) {
    switch (d) {
      case 'Easy': return AppTheme.success;
      case 'Medium': return AppTheme.warning;
      default: return AppTheme.error;
    }
  }
}

// ── Nutrition Tab ──

class _NutritionTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealsAsync = ref.watch(todayMealEntriesProvider);

    // Personalized daily goals based on the user's age, sex, weight & activity.
    final userData = ref.watch(persistedUserDataProvider).asData?.value;
    final goals = userData != null
        ? NutritionGoals.forUser(
            ageYears: userData.ageYears,
            isMale: userData.isMale,
            weightKg: userData.currentWeightKg,
            activityDaysPerWeek: userData.activityDaysPerWeek,
          )
        : NutritionGoals.fallback;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // Today's summary
        mealsAsync.when(
          data: (meals) {
            final totalCal = meals.fold<int>(0, (s, m) => s + m.calories);
            final double totalProtein = meals.fold<double>(0, (s, m) => s + m.protein);
            final double totalCalcium = meals.fold<double>(0, (s, m) => s + m.calcium);
            return _buildSummary(totalCal, totalProtein, totalCalcium, goals);
          },
          loading: () => _buildSummary(0, 0.0, 0.0, goals),
          error: (_, __) => _buildSummary(0, 0.0, 0.0, goals),
        ),
        const SizedBox(height: 16),

        // Today's meals
        mealsAsync.when(
          data: (meals) {
            if (meals.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text('No meals logged today yet.',
                      style: TextStyle(color: AppTheme.textTertiary)),
                ),
              );
            }
            return Column(
              children: meals.asMap().entries.map((e) {
                final m = e.value;
                final emoji = _mealEmoji(e.key);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MealCard(
                    emoji: emoji,
                    title: m.description,
                    subtitle: '${m.calories} cal • ${m.protein}g protein • ${m.calcium}mg calcium',
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        const SizedBox(height: 16),

        // Log a Meal button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showLogMealSheet(context, ref),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Log a Meal'),
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(int totalCal, double totalProtein, double totalCalcium, NutritionGoals goals) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.energyOrange.withOpacity(0.1), AppTheme.energyOrange.withOpacity(0.02)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.energyOrange.withOpacity(0.15)),
      ),
      child: Column(children: [
        const Text('Today\'s Nutrition', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        if (goals.bandLabel.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            'Goals tuned for ${goals.bandLabel}',
            style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary, fontWeight: FontWeight.w500),
          ),
        ],
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _NutrientBadge(
            label: 'Calories',
            value: '$totalCal',
            target: NutritionGoals.withThousands(goals.calories),
            color: AppTheme.energyOrange,
          ),
          _NutrientBadge(
            label: 'Protein',
            value: '${totalProtein.toStringAsFixed(0)}g',
            target: '${goals.protein}g',
            color: AppTheme.accent,
          ),
          _NutrientBadge(
            label: 'Calcium',
            value: '${totalCalcium.toStringAsFixed(0)}mg',
            target: '${NutritionGoals.withThousands(goals.calcium)}mg',
            color: AppTheme.info,
          ),
        ]),
      ]),
    );
  }

  String _mealEmoji(int index) {
    const emojis = ['🍳', '🥗', '🍝', '🥤', '🍎', '🥪'];
    return emojis[index % emojis.length];
  }

  void _showLogMealSheet(BuildContext context, WidgetRef ref) {
    final descController = TextEditingController();
    final calController = TextEditingController();
    final proteinController = TextEditingController();
    final calciumController = TextEditingController();

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
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Log a Meal',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text('Describe what you ate, then ask AI for nutritional estimates.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(height: 20),

                // Food description
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'What did you eat?',
                    hintText: 'e.g., 2 eggs, oatmeal with banana, glass of milk',
                  ),
                ),
                const SizedBox(height: 12),

                // Ask AI button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final text = descController.text.trim();
                      if (text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please describe what you ate first.'),
                              backgroundColor: AppTheme.warning),
                        );
                        return;
                      }
                      final prompt = Uri.encodeComponent(
                        'Estimate the protein (g), calories (kcal), and calcium (mg) in this food: $text. '
                        'Give me only the numbers with short units.',
                      );
                      launchUrl(
                        Uri.parse('https://www.google.com/search?q=$prompt'),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                    icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                    label: const Text('Ask AI'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Estimated values
                Text('Enter estimated values from AI:',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: calController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Calories',
                          hintText: 'e.g., 450',
                          prefixText: '🔥 ',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: proteinController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Protein (g)',
                          hintText: 'e.g., 25',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: calciumController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Calcium (mg)',
                          hintText: 'e.g., 300',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final desc = descController.text.trim();
                      if (desc.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please describe your meal.'),
                              backgroundColor: AppTheme.warning),
                        );
                        return;
                      }
                      final cal = int.tryParse(calController.text.trim()) ?? 0;
                      final protein = double.tryParse(proteinController.text.trim()) ?? 0;
                      final calcium = double.tryParse(calciumController.text.trim()) ?? 0;

                      final service = ref.read(userDataServiceProvider);
                      await service.saveMealEntry(MealEntry(
                        date: DateTime.now(),
                        description: desc,
                        calories: cal,
                        protein: protein,
                        calcium: calcium,
                      ));
                      ref.invalidate(todayMealEntriesProvider);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ Meal logged!'),
                              backgroundColor: AppTheme.success),
                        );
                      }
                    },
                    child: const Text('Save Meal'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NutrientBadge extends StatelessWidget {
  final String label, value, target;
  final Color color;

  const _NutrientBadge({required this.label, required this.value, required this.target, required this.color});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
    Text('/ $target', style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
    const SizedBox(height: 4),
    Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
  ]);
}

class _MealCard extends StatelessWidget {
  final String emoji, title, subtitle;

  const _MealCard({required this.emoji, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        ])),
      ]),
    );
  }
}

// ── Sleep Tab ──

class _SleepTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sleepAsync = ref.watch(thisWeekSleepEntriesProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // Last night's sleep summary
        sleepAsync.when(
          data: (entries) {
            final lastNight = entries.isNotEmpty ? entries.last : null;
            return _buildSleepSummary(context, lastNight, ref);
          },
          loading: () => _buildSleepSummary(context, null, ref),
          error: (_, __) => _buildSleepSummary(context, null, ref),
        ),

        const SizedBox(height: 20),

        // This week header
        const Text('This Week', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),

        // Weekly sleep chart
        sleepAsync.when(
          data: (entries) => _buildWeeklyChart(context, entries),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Could not load sleep data')),
        ),

        const SizedBox(height: 20),

        // Log sleep button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showLogSleepSheet(context, ref),
            icon: const Icon(Icons.bedtime_rounded),
            label: const Text('Log Tonight\'s Sleep'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.sleepIndigo,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSleepSummary(BuildContext context, SleepEntry? lastNight, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.sleepIndigo.withOpacity(0.15), AppTheme.sleepIndigo.withOpacity(0.05)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.sleepIndigo.withOpacity(0.15)),
      ),
      child: Column(children: [
        const Text('💤', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 12),
        Text(
          lastNight != null ? 'Last Night\'s Sleep' : 'No Sleep Logged Yet',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 16),
        if (lastNight != null) ...[
          // Sleep circle
          Container(
            width: 140, height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.sleepIndigo.withOpacity(0.3), width: 6),
            ),
            child: Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(lastNight.hoursSlept.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppTheme.sleepIndigo)),
                const Text('hours', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Text('Bed: ${_formatTime(lastNight.bedTime)} • Wake: ${_formatTime(lastNight.wakeTime)}',
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) => Icon(
              i < lastNight.quality ? Icons.star_rounded : Icons.star_border_rounded,
              color: AppTheme.sleepIndigo, size: 22,
            )),
          ),
        ] else ...[
          const SizedBox(height: 8),
          const Text('Tap the button below to log your first night.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        ],
      ]),
    );
  }

  Widget _buildWeeklyChart(BuildContext context, List<SleepEntry> entries) {
    // Build day labels for the past 7 days
    final today = DateTime.now();
    final days = List.generate(7, (i) {
      final d = today.subtract(Duration(days: 6 - i));
      const abbrev = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return abbrev[d.weekday - 1];
    });

    return Column(
      children: List.generate(7, (index) {
        final dayDate = today.subtract(Duration(days: 6 - index));
        final dayStr = dayDate.toIso8601String().split('T').first;
        final entry = entries.where((e) => e.date.toIso8601String().split('T').first == dayStr).firstOrNull;
        final hours = entry?.hoursSlept ?? 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            SizedBox(width: 30, child: Text(days[index],
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
            const SizedBox(width: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: hours / 9,
                  backgroundColor: AppTheme.sleepIndigo.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation(
                    hours >= 7 ? AppTheme.accent : AppTheme.warning),
                  minHeight: 10,
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 30,
              child: Text(hours > 0 ? '${hours.toStringAsFixed(0)}h' : '--',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            ),
          ]),
        );
      }),
    );
  }

  String _formatTime(String t) {
    final parts = t.split(':');
    if (parts.length != 2) return t;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts[1];
    final amPm = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m $amPm';
  }

  void _showLogSleepSheet(BuildContext context, WidgetRef ref) {
    // List of segments: each is [TimeOfDay bed, TimeOfDay wake]
    final segments = <List<TimeOfDay>>[
      [const TimeOfDay(hour: 22, minute: 0), const TimeOfDay(hour: 6, minute: 0)],
    ];
    int quality = 3;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            double totalHours = 0;
            for (final seg in segments) {
              totalHours += SleepSegment.calculateHours(
                '${seg[0].hour.toString().padLeft(2, '0')}:${seg[0].minute.toString().padLeft(2, '0')}',
                '${seg[1].hour.toString().padLeft(2, '0')}:${seg[1].minute.toString().padLeft(2, '0')}',
              );
            }

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
                    Text('Log Sleep',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Add multiple sleep segments if you sleep in shifts',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    const SizedBox(height: 16),

                    // Sleep segments
                    ...List.generate(segments.length, (index) {
                      final seg = segments[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.sleepIndigo.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.sleepIndigo.withOpacity(0.15)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 28, height: 28,
                                  decoration: BoxDecoration(
                                    color: AppTheme.sleepIndigo,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text('${index + 1}',
                                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text('Segment ${index + 1}',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                const Spacer(),
                                if (segments.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 20, color: AppTheme.error),
                                    onPressed: () => setSheetState(() => segments.removeAt(index)),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _TimePickerTile(
                                    icon: Icons.bedtime_rounded,
                                    label: 'Bed',
                                    time: seg[0],
                                    color: AppTheme.sleepIndigo,
                                    onTap: () async {
                                      final picked = await showTimePicker(context: context, initialTime: seg[0]);
                                      if (picked != null) setSheetState(() => seg[0] = picked);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 18, color: AppTheme.textTertiary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _TimePickerTile(
                                    icon: Icons.wb_sunny_rounded,
                                    label: 'Wake',
                                    time: seg[1],
                                    color: AppTheme.energyOrange,
                                    onTap: () async {
                                      final picked = await showTimePicker(context: context, initialTime: seg[1]);
                                      if (picked != null) setSheetState(() => seg[1] = picked);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),

                    // Add segment button
                    GestureDetector(
                      onTap: () => setSheetState(() {
                        segments.add([
                          const TimeOfDay(hour: 6, minute: 0),
                          const TimeOfDay(hour: 8, minute: 0),
                        ]);
                      }),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.sleepIndigo.withOpacity(0.3), width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_rounded, size: 18, color: AppTheme.sleepIndigo),
                            const SizedBox(width: 6),
                            Text('Add Sleep Segment',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.sleepIndigo)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Total hours
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.sleepIndigo.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.access_time_rounded, size: 18, color: AppTheme.sleepIndigo),
                          const SizedBox(width: 8),
                          Text('Total: ${totalHours.toStringAsFixed(1)} hours',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.sleepIndigo)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Quality rating
                    const Text('Sleep Quality', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        return IconButton(
                          icon: Icon(
                            i < quality ? Icons.star_rounded : Icons.star_border_rounded,
                            color: AppTheme.sleepIndigo,
                            size: 36,
                          ),
                          onPressed: () => setSheetState(() => quality = i + 1),
                        );
                      }),
                    ),

                    const SizedBox(height: 16),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final sleepSegments = segments.map((seg) {
                            final bedStr = '${seg[0].hour.toString().padLeft(2, '0')}:${seg[0].minute.toString().padLeft(2, '0')}';
                            final wakeStr = '${seg[1].hour.toString().padLeft(2, '0')}:${seg[1].minute.toString().padLeft(2, '0')}';
                            return SleepSegment(
                              bedTime: bedStr,
                              wakeTime: wakeStr,
                              hours: SleepSegment.calculateHours(bedStr, wakeStr),
                            );
                          }).toList();

                          final firstBed = sleepSegments.first.bedTime;
                          final lastWake = sleepSegments.last.wakeTime;

                          final service = ref.read(userDataServiceProvider);
                          await service.saveSleepEntry(SleepEntry(
                            date: DateTime.now(),
                            bedTime: firstBed,
                            wakeTime: lastWake,
                            quality: quality,
                            hoursSlept: double.parse(totalHours.toStringAsFixed(1)),
                            segments: sleepSegments,
                          ));
                          ref.invalidate(thisWeekSleepEntriesProvider);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('✅ Sleep logged! (${totalHours.toStringAsFixed(1)}h)'),
                                  backgroundColor: AppTheme.success),
                            );
                          }
                        },
                        child: const Text('Save'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.sleepIndigo,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final TimeOfDay time;
  final Color color;
  final VoidCallback onTap;

  const _TimePickerTile({
    required this.icon,
    required this.label,
    required this.time,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Column(
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
                Text(time.format(context),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
