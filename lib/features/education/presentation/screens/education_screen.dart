import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';

/// Education Hub — Blueprint §8.2
class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Education Hub'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          children: [
            _ArticleCard(
              emoji: '🧬',
              title: 'Genetics & Height Potential',
              subtitle: 'How much of your height is determined by DNA?',
              readTime: '5 min',
              content: _geneticsContent,
            ),
            _ArticleCard(
              emoji: '🥗',
              title: 'Nutrition for Growth',
              subtitle: 'Essential nutrients for maximizing height',
              readTime: '6 min',
              content: _nutritionContent,
            ),
            _ArticleCard(
              emoji: '💤',
              title: 'HGH & Sleep Optimization',
              subtitle: 'Growth hormone release and deep sleep',
              readTime: '4 min',
              content: _sleepContent,
            ),
            _ArticleCard(
              emoji: '🏃',
              title: 'Exercise & Growth Plates',
              subtitle: 'How movement stimulates height growth',
              readTime: '5 min',
              content: _exerciseContent,
            ),
            _ArticleCard(
              emoji: '🧍',
              title: 'Posture Correction',
              subtitle: 'Add visible height through better alignment',
              readTime: '3 min',
              content: _postureContent,
            ),
            _ArticleCard(
              emoji: '🔬',
              title: 'Growth Plate Biology',
              subtitle: 'Understanding epiphyseal plates',
              readTime: '7 min',
              content: _biologyContent,
            ),
          ],
        ),
      ),
    );
  }

  void _showArticle(BuildContext context, String title, List<String> paragraphs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: ListView(
                controller: scrollController,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  ...paragraphs.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      p,
                      style: const TextStyle(fontSize: 15, height: 1.6, color: AppTheme.textPrimary),
                    ),
                  )),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static const _geneticsContent = [
    "Your height is influenced by hundreds of genes, with approximately 60-80% of your height determined by your DNA. This is known as heritability — the proportion of variation in height that can be attributed to genetic factors.",
    "The mid-parental height method (Tanner method) estimates your genetic potential: for boys, add 13 cm to the average of your parents' heights; for girls, subtract 13 cm. This gives you a rough idea of your genetic height target.",
    "However, genes are not destiny. The remaining 20-40% of your height is influenced by environmental factors like nutrition, sleep, exercise, and overall health. This means you can optimize these factors to reach your full genetic potential.",
    "Some people have 'tall genes' from one parent and 'shorter genes' from the other. In these cases, lifestyle factors become even more important for maximizing height.",
  ];

  static const _nutritionContent = [
    "Proper nutrition is crucial for reaching your height potential. Key nutrients include protein, calcium, vitamin D, zinc, magnesium, and phosphorus — all essential for bone growth and development.",
    "Calcium is the building block of bones. Aim for 1,000-1,300 mg daily from sources like milk, yogurt, cheese, leafy greens, and fortified foods. Vitamin D helps your body absorb calcium — get 600-800 IU daily from sunlight, fatty fish, or supplements.",
    "Protein provides the amino acids needed for tissue growth. Teenagers need about 0.85 grams of protein per kilogram of body weight daily. Good sources include lean meats, eggs, fish, legumes, and dairy.",
    "Zinc deficiency has been linked to stunted growth in children. Include zinc-rich foods like pumpkin seeds, beef, chickpeas, and cashews in your diet.",
    "Avoid excessive sugar, junk food, and soda — they can interfere with growth hormone production and reduce appetite for nutrient-dense foods.",
  ];

  static const _sleepContent = [
    "Human Growth Hormone (HGH) is primarily released during deep sleep stages, especially during the first few hours of sleep. This is why getting enough quality sleep is critical for height growth.",
    "The optimal sleep duration for teenagers is 8-10 hours per night. Going to bed before midnight is particularly important because the largest HGH pulse occurs during the first deep sleep cycle.",
    "To optimize your sleep for HGH production: maintain a consistent sleep schedule (even on weekends), avoid screens 1 hour before bed, keep your bedroom cool (18-22°C), and avoid caffeine after 3 PM.",
    "Melatonin supplements can help with sleep onset, but consult a doctor before taking any supplements. Natural sleep aids include chamomile tea, magnesium, and relaxation techniques.",
  ];

  static const _exerciseContent = [
    "Exercise stimulates bone growth through mechanical loading and increased blood flow to growth plates. Weight-bearing exercises like jumping, running, and strength training are particularly effective.",
    "Hanging exercises (dead hangs, pull-ups) decompress the spine and can help improve posture, potentially adding 1-3 cm to your height by straightening your spinal column.",
    "Swimming, cycling, and yoga promote full body stretching and can improve spinal flexibility. The key is consistency — aim for at least 30-60 minutes of physical activity daily.",
    "High-intensity interval training (HIIT) has been shown to boost HGH production more than steady-state cardio. Include short bursts of intense activity in your routine.",
    "Caution: avoid heavy weightlifting that compresses the spine before your growth plates close (typically age 18-21). Focus on bodyweight exercises, stretching, and moderate resistance training.",
  ];

  static const _postureContent = [
    "Poor posture can make you appear 2-5 cm shorter than your actual height. Slouching, forward head posture, and rounded shoulders compress your spine and reduce your visible height.",
    "Fix your posture with these daily habits: stand against a wall for 5 minutes daily (heels, butt, shoulders, and head touching the wall), strengthen your core muscles, and keep your shoulders back and down.",
    "When sitting, keep both feet flat on the floor, your back against the chair, and your computer screen at eye level. Take breaks every 30 minutes to stand and stretch.",
    "Yoga poses like Mountain Pose (Tadasana), Cobra Pose (Bhujangasana), and Child's Pose (Balasana) can help improve spinal alignment and posture over time.",
  ];

  static const _biologyContent = [
    "Growth plates (epiphyseal plates) are areas of developing cartilage tissue at the ends of long bones. These plates are where bone growth occurs during childhood and adolescence.",
    "Growth plates remain open (active) throughout childhood, typically closing between ages 18-21 for males and 16-18 for females. Once closed, the bones can no longer grow in length.",
    "The order of growth plate closure follows a pattern: first in the hands and feet, then arms and legs, and finally in the spine. This is why limb growth usually stops before torso growth.",
    "X-rays of growth plates can determine how much growth potential remains. A doctor can assess your 'bone age' versus your chronological age to estimate remaining growth.",
    "While you can't reopen closed growth plates, you can maximize growth before they close through optimal nutrition, sleep, exercise, and avoiding factors that accelerate closure (like smoking, excessive alcohol, and certain medications).",
  ];
}

class _ArticleCard extends StatelessWidget {
  final String emoji, title, subtitle, readTime;
  final List<String> content;

  const _ArticleCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.readTime,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: InkWell(
        onTap: () => _buildShowArticle(context),
        borderRadius: BorderRadius.circular(20),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 13, color: AppTheme.textTertiary)),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.schedule_rounded, size: 14, color: AppTheme.textTertiary),
              const SizedBox(width: 4),
              Text('$readTime read', style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
            ]),
          ])),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.textTertiary),
        ]),
      ),
    );
  }

  void _buildShowArticle(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: ListView(
                controller: scrollController,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  ...content.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      p,
                      style: const TextStyle(fontSize: 15, height: 1.6, color: AppTheme.textPrimary),
                    ),
                  )),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
