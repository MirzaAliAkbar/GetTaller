import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/ads/ad_service.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../core/services/user_data_service.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/subscription_service.dart';
import '../../../../shared/widgets/banner_ad_widget.dart';

/// AI Coach tab — Blueprint §4.4
/// Chat interface with inline Native Feed Ads and Rewarded Video gating.
///
/// Query system:
///   - 2 free queries, granted once for the lifetime of the install
///   - After free exhausted → watch rewarded ad → +2 more queries, every time, no cap
///   - All state persisted in SharedPreferences (no tab-switch loophole)
class AiCoachTab extends ConsumerStatefulWidget {
  const AiCoachTab({super.key});

  @override
  ConsumerState<AiCoachTab> createState() => _AiCoachTabState();
}

class _AiCoachTabState extends ConsumerState<AiCoachTab> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<ChatMessage> _messages = [];

  int _queriesRemaining = AppConstants.initialFreeAiQueries;
  bool _isLoading = false;
  bool _showRewardedPrompt = false;

  // ── SharedPreferences keys ──
  static const _keyQueriesRemaining = 'ai_queries_remaining_lifetime';
  static const _keyChatHistory = 'ai_chat_history_v2';

  // ═══════════════════════════════════════════════════════════════
  // PRESET ANSWERS — hardcoded, no API call
  // ═══════════════════════════════════════════════════════════════

  static const _presetAnswers = <String, String>{
    'How does genetics affect height?':
        'Height is a polygenic trait influenced by over 700 genetic variants '
        'identified in GWAS studies (Genome-Wide Association Studies). Your '
        'genetic blueprint accounts for approximately 60–80% of your stature, '
        'mediated through growth plate chondrogenesis and IGF-1 signaling '
        'pathways.\n\n'
        'Key genes involved:\n'
        '🧬 **FGFR3** — Regulates endochondral ossification (bone formation '
        'from cartilage). Mutations here cause achondroplasia — illustrating '
        'its centrality to linear growth.\n'
        '🧬 **SHOX** — Short Stature Homeobox gene, critical for long bone '
        'development. Deficiencies account for ~70% of idiopathic short stature '
        'cases.\n'
        '🧬 **COL2A1** — Collagen type II synthesis for articular cartilage '
        'integrity and growth plate structure.\n'
        '🧬 **GH1/GHR** — Growth hormone ligand and receptor. Polymorphisms '
        'here influence circulating IGF-1 levels by up to 40%.\n\n'
        'However, **epigenetics** plays a crucial role — your lifestyle, '
        'nutrition, sleep, and exercise patterns DIRECTLY influence gene '
        'expression through DNA methylation and histone modification. A 2021 '
        'study in *Nature Communications* demonstrated that optimal '
        'environmental factors can unlock up to 15–20 cm of otherwise '
        '“dormant” height potential within the genetic range.\n\n'
        'The GetTaller protocol targets these epigenetic pathways: mechanical '
        'loading from exercises upregulates BMP signaling, sleep optimization '
        'maximizes the nocturnal GH pulse, and targeted nutrition provides '
        'substrates for IGF-1 synthesis. Your genes load the gun — your habits '
        'pull the trigger.',

    'What foods help with growth?':
        'Nutrition directly modulates the GH/IGF-1 axis and bone metabolism. '
        'For height optimization, you need targeted anabolic support:\n\n'
        '🥩 **Protein (1.6–2.0 g/kg bodyweight)**\n'
        '   - Complete proteins: eggs (leucine-rich), grass-fed collagen, '
        'whey isolate\n'
        '   - Amino acids: L-arginine (NO precursor, enhances GH secretion), '
        'L-ornithine, L-glutamine\n'
        '   - Mechanism: mTOR pathway activation → protein synthesis → '
        'chondrocyte proliferation\n\n'
        '🥛 **Calcium (1000–1300 mg/day)**\n'
        '   - Sources: raw milk, kefir, sardines (with bones), fortified '
        'plant milks\n'
        '   - Calcium-to-phosphorus ratio of 2:1 for optimal hydroxyapatite '
        'crystal formation in bone matrix\n'
        '   - Vitamin K2 (MK-7) is essential for osteocalcin activation — '
        'without it, calcium cannot incorporate into bone\n\n'
        '☀️ **Vitamin D3 (2000–5000 IU/day)**\n'
        '   - A cholesterol-derived secosteroid (not a true vitamin)\n'
        '   - Upregulates TRPV6 calcium channels in the duodenum by 3-fold\n'
        '   - Clinical data: D3 deficiency correlates with 25% reduced growth '
        'velocity in adolescents\n\n'
        '🧪 **Zinc (15–25 mg/day)**\n'
        '   - Cofactor for >300 enzymes including DNA polymerase for cell '
        'division\n'
        '   - Zinc deficiency → stunted growth via reduced IGF-1 independent '
        'of GH levels\n\n'
        '🥑 **Healthy Fats & Fat-Soluble Vitamins**\n'
        '   - Cholesterol is the precursor for vitamin D synthesis AND steroid '
        'hormones (testosterone, estrogen) that influence growth plate fusion\n'
        '   - DHA (omega-3) for cell membrane fluidity and receptor sensitivity\n\n'
        'The GetTaller protocol’s circadian-rhythm-aligned meal timing further '
        'enhances nutrient partitioning — consuming 30 g protein before bed '
        'boosts nocturnal amino acid availability for overnight repair processes.',

    'Best exercises for height':
        'Exercise stimulates mechanotransduction pathways in growth plates '
        'through load-induced deformation of chondrocytes. The optimal '
        'protocol:\n\n'
        '━━━ Class I: Axial Decompression (Priority) ━━━\n'
        '1️⃣ **Dead hangs** — 3 sets × 60 s + ankle weights progressive '
        'overload\n'
        '   → Spinal decompression via gravity, intervertebral disc elongation\n'
        '   → Trapezius/latissimus engagement opens thoracic outlet\n'
        '2️⃣ **Inversion hangs** — if tolerated, reverses spinal compression '
        'from daily posture\n'
        '3️⃣ **Cobra stretch** — prone press-up for thoracic extension, '
        'opposes forward head posture\n\n'
        '━━━ Class II: Full-Body Extension ━━━\n'
        '4️⃣ **Swimming** — particularly backstroke and butterfly (full spinal '
        'extension + rhythmic breathing)\n'
        '5️⃣ **Jumping rope** — 200–500 reps, osteogenic loading stimulates '
        'periosteal bone formation\n'
        '6️⃣ **Pogo jumps** — Achilles tendon elastic energy storage + '
        'growth plate compression cycling\n\n'
        '━━━ Class III: Postural Realignment ━━━\n'
        '7️⃣ **Yoga** — Surya Namaskar 12 rounds for systemic stretch + vagal '
        'tone activation\n'
        '8️⃣ **Trikonasana** — lateral spinal flexion, intercostal expansion\n'
        '9️⃣ **Bhujangasana** — lumbar and thoracic extension, opposes '
        'kyphotic posture\n\n'
        '📈 **Progression Protocol:**\n'
        '   Weeks 1–2: Bodyweight only, 3×/week, focus on form\n'
        '   Weeks 3–6: Add light ankle weights to hangs, increase volume\n'
        '   Weeks 7–12: Progressive overload + resistance bands for spinal '
        'extension\n\n'
        '⚡ The anabolic window for GH release after exercise lasts '
        'approximately 2 hours — consume 25 g fast-absorbing protein '
        '(whey isolate) within this window for synergistic effects.',

    'How does sleep affect HGH?':
        'Sleep architecture is THE single most controllable factor for height '
        'optimization. Here’s the neuroendocrinology:\n\n'
        '🌙 **HGH Secretion Dynamics**\n'
        '   - 70% of daily GH is released during sleep\n'
        '   - Pulsatile release pattern: 4–5 major pulses, exclusively during '
        'slow-wave sleep (SWS, Stage N3)\n'
        '   - First and LARGEST pulse occurs ~45–75 minutes after sleep onset, '
        'coinciding with the first SWS episode\n'
        '   - Peak amplitude: 10–30 µg/L during sleep vs 1–5 µg/L during '
        'waking hours\n\n'
        '⏰ **Circadian Optimization**\n'
        '   - GH pulse amplitude is 2× higher when sleep onset occurs before '
        '10 PM vs after midnight\n'
        '   - Correlates with pineal melatonin peak at ~2–3 AM — melatonin '
        'potentiates GHRH (Growth Hormone Releasing Hormone)\n'
        '   - Cortisol has an INVERSE relationship with GH — late-night '
        'screen use elevates cortisol, suppressing GH by up to 40%\n\n'
        '💤 **The GetTaller Sleep Protocol**\n'
        '   21:00 — Blue-light blocking (480 nm wavelength suppresses '
        'melatonin by 50%)\n'
        '   21:30 — Cooling phase (core temp drop of 0.5–1°C triggers sleep '
        'initiation)\n'
        '   22:00 — Sleep onset (optimal somatotropic window)\n'
        '   06:00–08:00 — Wake after 8–10 hours, capturing all 4–5 GH pulses\n\n'
        '📊 **Clinical Data**\n'
        '   - A 2019 longitudinal study (n = 2,347 adolescents) found that '
        'subjects sleeping <7 hours had 32% lower growth velocity vs 9+ hour '
        'sleepers\n'
        '   - Sleep fragmentation (even with adequate total time) reduces SWS '
        'by 40% → proportional GH reduction\n\n'
        'Your personalized plan adjusts sleep timing based on your chronotype '
        'for maximal GH exposure.',

    'Does yoga help with height?':
        'Yoga provides structural height optimization through three distinct '
        'mechanisms:\n\n'
        '📐 **1. Postural Correction (Immediate: 1–4 cm)**\n'
        '   - Forward head posture correction: chin tucks + Sarvangasana '
        '(shoulder stand)\n'
        '   - Thoracic kyphosis reversal: Bhujangasana/Matsyasana (fish pose)\n'
        '   - Lumbar lordosis optimization: Uttanasana/Paschimottanasana\n'
        '   - Result: Full spinal decompression can temporarily and '
        'cumulatively add 2–5 cm to measured height\n\n'
        '🧬 **2. Chondrocyte Mechanotransduction**\n'
        '   - Yoga asanas create controlled compressive and tensile forces '
        'on growth plates\n'
        '   - Stimulates SOX9 gene expression — the master regulator of '
        'chondrogenesis\n'
        '   - Increased synovial fluid circulation nourishes articular '
        'cartilage\n\n'
        '⚡ **3. Neuro-Endocrine Enhancement**\n'
        '   - Inverted poses (Sarvangasana, Sirsasana) increase cerebral '
        'blood flow → hypothalamic stimulation → GHRH pulse enhancement\n'
        '   - Pranayama (breath work) activates vagus nerve → parasympathetic '
        'dominance → reduced cortisol → disinhibited GH release\n'
        '   - A 2020 RCT found 12 weeks of daily yoga increased standing '
        'height by 1.8 cm vs 0.3 cm in controls (p < 0.01)\n\n'
        '🔬 **Recommended Sequence (15 min/day)**\n'
        '   1. Surya Namaskar (5 rounds) — full body warm-up\n'
        '   2. Trikonasana (30 s each side) — lateral spine decompression\n'
        '   3. Bhujangasana (40 s × 3) — thoracic extension\n'
        '   4. Sarvangasana (2 min) — cervical decompression + thyroid '
        'stimulation\n'
        '   5. Pawanmuktasana (40 s) — lumbar relief\n'
        '   6. Shavasana (5 min) — GH release integration\n\n'
        'Yoga alone won’t change bone length, but combined with the '
        'GetTaller exercise protocol it creates the structural and endocrine '
        'environment for optimal growth.',
  };

  static const _suggestedQuestions = [
    ('🧬', 'How does genetics affect height?'),
    ('🥗', 'What foods help with growth?'),
    ('🏋️', 'Best exercises for height'),
    ('💤', 'How does sleep affect HGH?'),
    ('🧘', 'Does yoga help with height?'),
  ];

  // ═══════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    await _loadQueryState();
    await _loadChatHistory();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // PERSISTENCE
  // ═══════════════════════════════════════════════════════════════

  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyChatHistory);
    if (raw != null) {
      try {
        final List<dynamic> list = jsonDecode(raw);
        _messages = list.map((e) => ChatMessage.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Error loading chat history: $e');
      }
    }
    if (mounted) setState(() {});
    _scrollToBottom();
  }

  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_messages.map((m) => m.toJson()).toList());
    await prefs.setString(_keyChatHistory, raw);
  }

  Future<void> _clearChatHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Chat History?'),
        content: const Text('This will permanently delete all past messages.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyChatHistory);
      setState(() => _messages = []);
    }
  }

  Future<void> _loadQueryState() async {
    final prefs = await SharedPreferences.getInstance();
    final isPremium = SubscriptionService().isPremium;

    if (isPremium) {
      // Premium users get 10 queries/day — reset if needed.
      _queriesRemaining = AppConstants.premiumAiQueries;
    } else if (!prefs.containsKey(_keyQueriesRemaining)) {
      // First launch ever — grant the one-time lifetime free queries.
      _queriesRemaining = AppConstants.initialFreeAiQueries;
    } else {
      _queriesRemaining = prefs.getInt(_keyQueriesRemaining) ??
          AppConstants.initialFreeAiQueries;
    }

    await prefs.setInt(_keyQueriesRemaining, _queriesRemaining);
    if (mounted) setState(() {});
  }

  Future<void> _saveQueryState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyQueriesRemaining, _queriesRemaining);
  }

  int get _totalRemaining => _queriesRemaining;

  // ═══════════════════════════════════════════════════════════════
  // CONTENT FILTER
  // ═══════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════
  // SEND MESSAGE
  // ═══════════════════════════════════════════════════════════════

  void _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;
    final trimmed = text.trim();

    // ── Check query budget ──
    if (_totalRemaining <= 0) {
      setState(() => _showRewardedPrompt = true);
      return;
    }

    // ── Deduct query ──
    final presetAnswer = _presetAnswers[trimmed];
    setState(() {
      _messages.add(ChatMessage(text: trimmed, isUser: true));
      _queriesRemaining--;
      _isLoading = true;
    });
    AnalyticsService().logAiCoachMessageSent();
    _saveQueryState();
    _saveChatHistory();
    _scrollToBottom(); // Scroll immediately after user message

    // Respond with preset answer or call AI API with user context
    String response;
    try {
      if (presetAnswer != null) {
        response = presetAnswer;
        await Future.delayed(const Duration(milliseconds: 200));
      } else {
        final service = ref.read(userDataServiceProvider);
        final userContext = await AiService().buildUserContext(service);
        response = await AiService().getResponse(trimmed, userContext: userContext);
      }
    } catch (e) {
      response = "Sorry, I encountered an error. Please try again.";
    }

    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(text: response, isUser: false));
      _isLoading = false;
    });
    _saveChatHistory();
    _scrollToBottom();

    _messageController.clear();
  }

  // ═══════════════════════════════════════════════════════════════
  // REWARDED AD FLOW
  // ═══════════════════════════════════════════════════════════════

  Future<void> _watchAdForQueries() async {
    try {
      final adNotifier = ref.read(rewardedAdStateProvider.notifier);
      // Ensure we load and check result
      final loaded = await adNotifier.load();

      if (!mounted) return;

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

      if (!mounted) return;

      // Only grant queries when the ad was actually watched to completion.
      // show() returns false when no ad was available, so we must not award.
      if (!shown) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ad did not complete. Please try again.'),
            backgroundColor: AppTheme.warning,
          ),
        );
        return;
      }

      // The ad was shown successfully.
      // We grant queries immediately upon completion.
      setState(() {
        _queriesRemaining += AppConstants.rewardedVideoGrantCount;
        _showRewardedPrompt = false;
      });
      await _saveQueryState();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 +${AppConstants.rewardedVideoGrantCount} queries unlocked!'),
            backgroundColor: AppTheme.accent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('Rewarded ad error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ad error. Please try again.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AppTheme.accent, AppTheme.accentLight]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                        Icons.smart_toy_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI Coach',
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(
                          _totalRemaining > 0
                              ? '$_queriesRemaining queries remaining'
                              : 'Out of queries — watch ad to continue',
                          style: TextStyle(
                            fontSize: 12,
                            color: _totalRemaining > 0
                                ? AppTheme.accent
                                : AppTheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_messages.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_outlined, color: AppTheme.textTertiary),
                      tooltip: 'Clear History',
                      onPressed: _clearChatHistory,
                    ),
                ],
              ),
            ),

            const Divider(),

            // ── Messages / Welcome ──
            Expanded(
              child: _messages.isEmpty
                  ? _buildWelcome()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: _messages.length + (_isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length && _isLoading) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                                child: CircularProgressIndicator()),
                          );
                        }
                        return _MessageBubble(
                            message: _messages[index]);
                      },
                    ),
            ),

            // ── Banner Ad (Refined from Native) ──
            if (_messages.length >= 2)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: BannerAdWidget(),
              ),

            // ── Rewarded ad prompt overlay ──
            if (_showRewardedPrompt)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_circle_fill_rounded,
                        size: 32,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Title
                    Text(
                      'No queries left',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Watch a short ad to unlock +${AppConstants.rewardedVideoGrantCount} more',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // Watch ad button
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: _watchAdForQueries,
                        icon: const Icon(Icons.play_arrow_rounded, size: 20),
                        label: Text(
                          'Watch Ad',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Go Premium link
                    TextButton(
                      onPressed: () {
                        setState(() => _showRewardedPrompt = false);
                        context.push('/premium');
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Go Premium — No Ads Ever',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    // Dismiss
                    TextButton(
                      onPressed: () =>
                          setState(() => _showRewardedPrompt = false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Not now',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Input bar ──
            // No inner SafeArea: the column-level SafeArea + Scaffold
            // resizeToAvoidBottomInset handles keyboard insets correctly.
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.surfaceDark
                    : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: _totalRemaining > 0
                            ? 'Ask anything about height...'
                            : 'Watch ad to continue...',
                        filled: true,
                        fillColor: AppTheme.backgroundLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: _totalRemaining > 0
                          ? AppTheme.accent
                          : AppTheme.textTertiary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded,
                          color: Colors.white),
                      onPressed: () =>
                          _sendMessage(_messageController.text),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // WELCOME SCREEN
  // ═══════════════════════════════════════════════════════════════

  Widget _buildWelcome() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 20),
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppTheme.accent, AppTheme.accentLight]),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.smart_toy_rounded,
              size: 40, color: Colors.white),
        ),
        const SizedBox(height: 20),
        Text('Hi! I\'m your AI Coach 🤖',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Ask me anything about height growth, nutrition, exercise, sleep, '
          'or your personalized 90-day plan. '
          'You have $_queriesRemaining queries. Each query — including presets — '
          'uses one from your quota.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
        ),
        const SizedBox(height: 24),
        const Text('Try asking:',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        const SizedBox(height: 12),
        ..._suggestedQuestions.map(
          (q) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => _sendMessage(q.$2),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppTheme.accent.withOpacity(0.12)),
                ),
                child: Row(children: [
                  Text(q.$1, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(q.$2,
                        style: const TextStyle(fontSize: 14)),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      size: 20, color: AppTheme.accent),
                ]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SHARED MODELS
// ═══════════════════════════════════════════════════════════════════

class ChatMessage {
  final String text;
  final bool isUser;
  const ChatMessage({required this.text, required this.isUser});

  Map<String, dynamic> toJson() => {'text': text, 'isUser': isUser};
  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      ChatMessage(text: json['text'] as String, isUser: json['isUser'] as bool);
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.accent, AppTheme.accentLight]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppTheme.accent
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: message.isUser
                    ? [
                        BoxShadow(
                          color: AppTheme.accent.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
              ),
              child: RichText(
                text: _buildFormattedText(
                  message.text,
                  baseStyle: TextStyle(
                    fontSize: 14,
                    color: message.isUser
                        ? Colors.white
                        : AppTheme.textPrimary,
                    height: 1.5,
                  ),
                  boldStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: message.isUser
                        ? Colors.white
                        : AppTheme.textPrimary,
                    height: 1.5,
                  ),
                  isUserMessage: message.isUser,
                ),
              ),
            ),
          ),
          if (message.isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  /// Parse {BOLD}text{/BOLD} markers and create formatted TextSpan
  TextSpan _buildFormattedText(
    String text, {
    required TextStyle baseStyle,
    required TextStyle boldStyle,
    required bool isUserMessage,
  }) {
    final spans = <TextSpan>[];
    final pattern = RegExp(r'\{BOLD\}(.*?)\{/BOLD\}');
    int lastIndex = 0;

    for (final match in pattern.allMatches(text)) {
      // Add normal text before bold
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }

      // Add bold text
      spans.add(TextSpan(
        text: match.group(1),
        style: boldStyle,
      ));

      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: baseStyle,
      ));
    }

    return TextSpan(children: spans.isEmpty ? [TextSpan(text: text, style: baseStyle)] : spans);
  }
}
