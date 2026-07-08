import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/user_data_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/analytics_service.dart';
import '../../data/exercise_database.dart';
import '../../data/exercise_images.dart';

/// Workout Player — Blueprint §22
/// Multi-exercise flow with circular countdown, rest timer, completion screen.
class WorkoutPlayerScreen extends ConsumerStatefulWidget {
  final List<String> exerciseIds;
  final int? levelNumber; // Level to mark completed on finish
  const WorkoutPlayerScreen({super.key, required this.exerciseIds, this.levelNumber});

  @override
  ConsumerState<WorkoutPlayerScreen> createState() => _WorkoutPlayerScreenState();
}

class _WorkoutPlayerScreenState extends ConsumerState<WorkoutPlayerScreen>
    with TickerProviderStateMixin {
  // ── Workout state ──
  late final List<ExerciseInfo> _exercises;
  int _currentIndex = 0;
  int _currentSet = 1;
  bool _isCompleted = false;

  // ── Timer state ──
  bool _isPlaying = false;
  bool _isResting = false;
  int _remainingSeconds = 0;
  int _restRemainingSeconds = 0;
  String _currentRestTip = '';
  Timer? _countdownTimer;
  Timer? _restTimer;

  // ── Animations ──
  late AnimationController _pulseController;
  late AnimationController _completionController;
  late Animation<double> _completionScale;

  // ── Rest tips (Blueprint §22.2) ──
  static const List<String> _restTips = [
    'Breathe deeply to lower your heart rate',
    'Hydrate between sets — water supports joint health',
    'Focus on form for the next exercise',
    'Keep your core engaged throughout',
    'Visualize the movement before starting',
    'Shake out your arms and legs to release tension',
    'Check your posture in the mirror',
    'Roll your shoulders back to reset alignment',
    'Take slow, controlled breaths',
    'Prepare equipment for the next movement',
  ];

  ExerciseInfo get _ex => _exercises[_currentIndex];

  @override
  void initState() {
    super.initState();
    _exercises = ExerciseDatabase.getByIds(widget.exerciseIds);
    if (_exercises.isNotEmpty) _remainingSeconds = _exercises.first.durationSeconds;
    AnalyticsService().logWorkoutStarted(widget.levelNumber ?? 0);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _completionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _completionScale = CurvedAnimation(
      parent: _completionController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _restTimer?.cancel();
    _pulseController.dispose();
    _completionController.dispose();
    super.dispose();
  }

  // ── Timer controls ──

  void _togglePlay() {
    if (_isResting) return;
    if (_isPlaying) {
      _countdownTimer?.cancel();
      _pulseController.stop();
      setState(() => _isPlaying = false);
    } else {
      if (_remainingSeconds <= 0) _remainingSeconds = _ex.durationSeconds;
      setState(() => _isPlaying = true);
      _pulseController.repeat(reverse: true);
      _startCountdown();
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      _remainingSeconds--;
      if (_remainingSeconds <= 0 && !_isResting) {
        t.cancel();
        _pulseController.stop();
        _isPlaying = false;
        _remainingSeconds = _ex.durationSeconds;
        // Auto-complete the set when timer runs out
        if (_currentSet < _ex.setsCount) {
          _currentSet++;
          if (mounted) _startRest();
        } else {
          if (mounted) _nextExercise();
        }
      }
      if (mounted) setState(() {});
    });
  }

  void _startRest() {
    _currentRestTip = _restTips[DateTime.now().millisecondsSinceEpoch % _restTips.length];
    setState(() {
      _isResting = true;
      _isPlaying = false;
      _restRemainingSeconds = _ex.restSeconds;
    });
    _countdownTimer?.cancel();
    _pulseController.stop();
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _restRemainingSeconds--;
        if (_restRemainingSeconds <= 0) {
          t.cancel();
          _isResting = false;
          _remainingSeconds = _ex.durationSeconds;
          _isPlaying = true;
          _pulseController.repeat(reverse: true);
          _startCountdown();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚡ Rest over! Ready for set $_currentSet?'),
              backgroundColor: AppTheme.info,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      });
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _isPlaying = true;
      _remainingSeconds = _ex.durationSeconds;
    });
    _pulseController.repeat(reverse: true);
    _startCountdown();
  }

  void _completeSet() {
    if (_isResting || _isCompleted) return;
    _countdownTimer?.cancel();
    _pulseController.stop();

    if (_currentSet < _ex.setsCount) {
      setState(() => _currentSet++);
      _startRest();
    } else {
      _nextExercise();
    }
  }

  void _nextExercise() {
    if (_currentIndex + 1 < _exercises.length) {
      setState(() {
        _currentIndex++;
        _currentSet = 1;
        _isPlaying = false;
        _isResting = false;
        _remainingSeconds = _ex.durationSeconds;
      });
      _countdownTimer?.cancel();
      _restTimer?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('➡️ Next: ${_ex.name}'),
          backgroundColor: AppTheme.info,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      _finishWorkout();
    }
  }

  void _finishWorkout() {
    // Mark level as completed
    final level = widget.levelNumber;
    if (level != null) {
      ref.read(userDataServiceProvider).markLevelCompleted(level);
    }
    AnalyticsService().logWorkoutCompleted(level ?? 0);
    // Fire streak milestone if applicable
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notif = ref.read(notificationServiceProvider);
      final userDataService = ref.read(userDataServiceProvider);
      await notif.markTodayActive();
      final streak = await userDataService.getCurrentStreak();
      final milestones = [3, 7, 14, 21, 30, 60, 90];
      if (milestones.contains(streak)) {
        await notif.fireStreakMilestone(streak);
      }
    });
    setState(() => _isCompleted = true);
    _completionController.forward();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Workout complete! Great work!'),
        backgroundColor: AppTheme.success,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _openDemo() {
    launchUrl(
      Uri.parse('https://www.google.com/search?q=${_ex.name}+exercise+demonstration'),
      mode: LaunchMode.externalApplication,
    );
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    if (_exercises.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
          title: const Text('No exercises'),
        ),
        body: const Center(child: Text('No exercises found for today.')),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: _isCompleted ? _buildCompletionView() : _buildWorkoutView(),
      ),
    );
  }

  // ══════════════════════════════════════════════════
  //  WORKOUT VIEW
  // ══════════════════════════════════════════════════

  Widget _buildWorkoutView() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildMainContent()),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildHeader() {
    final progress = (_currentIndex + 1) / _exercises.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // Top row
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => context.pop(),
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                padding: EdgeInsets.zero,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exercise ${_currentIndex + 1} of ${_exercises.length}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textTertiary),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppTheme.primary.withOpacity(0.08),
                        valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Phase/Week badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_currentSet/${_ex.setsCount} sets',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary),
                ),
              ),
            ],
          ),
          // Exercise name row
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Row(
              children: [
                Text(_ex.icon, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _ex.name,
                    style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _diffColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _ex.difficulty,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _diffColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Main content area ──

  Widget _buildMainContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          // ═══ TIMER CIRCLE ═══
          _buildTimerSection(),
          const SizedBox(height: 20),

          // ═══ EXERCISE INFO CARDS ═══
          _buildActionButtons(),
          const SizedBox(height: 16),
          _buildInfoCards(),
          const SizedBox(height: 16),

          // ═══ EXERCISE IMAGE ═══
          _buildExerciseImage(_ex.id),
          const SizedBox(height: 16),

          // ═══ INSTRUCTIONS ═══
          _buildInstructions(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Timer Circle ──

  Widget _buildTimerSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _isResting ? AppTheme.warning.withOpacity(0.15) : AppTheme.primary.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: (_isResting ? AppTheme.warning : AppTheme.primary).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Circular countdown
              GestureDetector(
                onTap: _togglePlay,
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background ring
                      CustomPaint(
                        size: const Size(120, 120),
                        painter: _ArcPainter(
                          progress: 1.0,
                          color: _isResting ? AppTheme.warning.withOpacity(0.1) : AppTheme.primary.withOpacity(0.06),
                          strokeWidth: 8,
                        ),
                      ),
                      // Progress ring
                      AnimatedBuilder(
                        animation: Listenable.merge([_pulseController, ValueNotifier(0)]),
                        builder: (context, _) {
                          final fraction = _isResting
                              ? 1.0 - (_restRemainingSeconds / _ex.restSeconds)
                              : _ex.durationSeconds > 0
                                  ? 1.0 - (_remainingSeconds / _ex.durationSeconds)
                                  : 0.0;
                          return CustomPaint(
                            size: const Size(120, 120),
                            painter: _ArcPainter(
                              progress: fraction,
                              color: _isResting
                                  ? AppTheme.warning
                                  : _isPlaying
                                      ? AppTheme.success
                                      : AppTheme.primary,
                              strokeWidth: 8,
                            ),
                          );
                        },
                      ),
                      // Center text
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isResting ? Icons.coffee_rounded : (_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                            color: _isResting ? AppTheme.warning : (_isPlaying ? AppTheme.success : AppTheme.primary),
                            size: 22,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isResting ? '$_restRemainingSeconds' : '$_remainingSeconds',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: _isResting ? AppTheme.warning : (_isPlaying ? AppTheme.success : AppTheme.primary),
                              height: 1,
                            ),
                          ),
                          Text(
                            _isResting ? 'rest' : 'sec',
                            style: TextStyle(
                              fontSize: 11,
                              color: (_isResting ? AppTheme.warning : AppTheme.primary).withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Stats beside timer
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Set counter
                    _StatRow(
                      icon: Icons.fitness_center_rounded,
                      label: 'Set $_currentSet of ${_ex.setsCount}',
                      color: AppTheme.primary,
                    ),
                    const SizedBox(height: 8),
                    // Duration badge
                    _StatRow(
                      icon: Icons.timer_outlined,
                      label: '${_ex.durationSeconds}s per set',
                      color: AppTheme.info,
                    ),
                    const SizedBox(height: 8),
                    // Rest badge
                    _StatRow(
                      icon: Icons.hourglass_empty_rounded,
                      label: 'Rest ${_ex.restSeconds}s betw sets',
                      color: AppTheme.warning,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Rest tip ──
          if (_isResting) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, color: AppTheme.warning, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentRestTip,
                      style: const TextStyle(fontSize: 12, color: AppTheme.warning, fontWeight: FontWeight.w500),
                    ),
                  ),
                  GestureDetector(
                    onTap: _skipRest,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Skip', style: TextStyle(fontSize: 11, color: AppTheme.warning, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Action buttons ──

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Watch Demo
        Expanded(
          child: _ActionCard(
            icon: Icons.play_circle_outline_rounded,
            label: 'Watch Demo',
            color: AppTheme.primary,
            onTap: _openDemo,
          ),
        ),
        const SizedBox(width: 12),
        // Complete Set
        Expanded(
          child: _ActionCard(
            icon: Icons.check_circle_outline_rounded,
            label: _isResting
                ? 'Resting...'
                : _currentSet < _ex.setsCount
                    ? 'Complete Set $_currentSet'
                    : _currentIndex < _exercises.length - 1
                        ? 'Next Exercise →'
                        : 'Finish Workout',
            color: _isResting ? AppTheme.textTertiary : AppTheme.success,
            onTap: _completeSet,
            backgroundColor: _isResting ? AppTheme.textTertiary.withOpacity(0.05) : null,
          ),
        ),
      ],
    );
  }

  // ── Info cards ──

  Widget _buildInfoCards() {
    return Column(
      children: [
        // Quick stats
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primary.withOpacity(0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'About this exercise',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _ex.description,
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _MiniBadge(icon: Icons.repeat_rounded, label: '${_ex.setsCount} sets'),
                  const SizedBox(width: 12),
                  _MiniBadge(icon: Icons.timer_outlined, label: '${_ex.durationSeconds}s × ${_ex.setsCount}'),
                  const SizedBox(width: 12),
                  _MiniBadge(icon: Icons.hourglass_empty_rounded, label: '${_ex.restSeconds}s rest'),
                ],
              ),
            ],
          ),
        ),

        // Breathing tip
        if (_ex.breathing.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.success.withOpacity(0.08)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.air_rounded, color: AppTheme.success, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _ex.breathing.first,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Exercise image ──

  Widget _buildExerciseImage(String exerciseId) {
    final imagePath = ExerciseImages.getImagePath(exerciseId);

    if (imagePath == null) {
      // Fallback placeholder for exercises without a dedicated image
      return AspectRatio(
        aspectRatio: 1024 / 733,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F6FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primary.withOpacity(0.08)),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.image_outlined, size: 40, color: AppTheme.primary.withOpacity(0.2)),
                const SizedBox(height: 8),
                Text(
                  'Image coming soon',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primary.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Actual exercise image — BoxFit.cover with slight up-left alignment
    // crops the bottom-right GetTaller logo from the 1024×733 source images.
    return AspectRatio(
      aspectRatio: 1024 / 733,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          alignment: const Alignment(-0.08, -0.12),
          errorBuilder: (context, error, stackTrace) => Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F6FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Icon(Icons.broken_image_outlined, color: AppTheme.primary.withOpacity(0.2)),
            ),
          ),
        ),
      ),
    );
  }

  // ── Step-by-step instructions ──

  Widget _buildInstructions() {
    if (_ex.steps.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_rounded, size: 16, color: AppTheme.primary),
              const SizedBox(width: 6),
              Text(
                'Step-by-Step',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._ex.steps.asMap().entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24, height: 24, alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${e.key + 1}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(e.value, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.4))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Bottom bar ──

  Widget _buildBottomBar() {
    final ex = _ex;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          // Current exercise info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(ex.icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 2),
              Text('${_currentIndex + 1}/${_exercises.length}', style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(ex.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(
                  _isResting ? 'Rest $_restRemainingSeconds' : 'Set $_currentSet • ${_remainingSeconds}s',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary),
                ),
              ],
            ),
          ),
          // Complete button
          SizedBox(
            height: 42,
            child: ElevatedButton(
              onPressed: _isResting ? null : _completeSet,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                backgroundColor: _isResting ? AppTheme.textTertiary.withOpacity(0.2) : AppTheme.primary,
                foregroundColor: _isResting ? AppTheme.textTertiary : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _isResting
                    ? 'Rest $_restRemainingSeconds'
                    : _currentSet < ex.setsCount
                        ? 'Complete Set'
                        : _currentIndex < _exercises.length - 1
                            ? 'Next'
                            : 'Finish',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════
  //  COMPLETION VIEW
  // ══════════════════════════════════════════════════

  Widget _buildCompletionView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(4, 8, 20, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => context.pop(),
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                padding: EdgeInsets.zero,
              ),
              Text('Workout Complete', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        Expanded(
          child: ScaleTransition(
            scale: _completionScale,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Trophy
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA726)]),
                        boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 8))],
                      ),
                      child: const Center(child: Text('🏆', style: TextStyle(fontSize: 48))),
                    ),
                    const SizedBox(height: 24),
                    Text('Workout Complete!',
                        style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                    const SizedBox(height: 8),
                    Text('You completed ${_exercises.length} exercises today.',
                        style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary)),
                    const SizedBox(height: 4),
                    Text('Every workout brings you closer to your goal. Keep it up! 💪',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textTertiary)),
                    const SizedBox(height: 32),
                    ..._exercises.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 18),
                          const SizedBox(width: 8),
                          Text('${e.icon}  ${e.name}', style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                        ],
                      ),
                    )),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.pop(),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: const Text('Back to Daily Plan'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color get _diffColor {
    switch (_ex.difficulty) {
      case 'Easy': return AppTheme.success;
      case 'Medium': return AppTheme.warning;
      default: return AppTheme.error;
    }
  }
}

// ══════════════════════════════════════════════════
//  HELPER WIDGETS
// ══════════════════════════════════════════════════

/// Circular countdown arc painter
class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _ArcPainter({required this.progress, required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) => old.progress != progress || old.color != color;
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatRow({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(label, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final Color? backgroundColor;

  const _ActionCard({
    required this.icon, required this.label, required this.color,
    required this.onTap, this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor ?? color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.textTertiary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
        ],
      ),
    );
  }
}
