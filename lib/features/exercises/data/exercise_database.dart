/// Central exercise database — Blueprint §23.
/// 36 exercises across all categories for the 90-day plan.
class ExerciseDatabase {
  ExerciseDatabase._();

  /// All available exercises with instructions, breathing, and metadata.
  static const List<ExerciseInfo> exercises = [
    // ── Spine & Posture (5) ──
    ExerciseInfo(
      id: 'spine_1',
      name: 'Jefferson Curl',
      category: 'spine',
      icon: '🦴',
      durationSeconds: 45,
      setsCount: 3,
      restSeconds: 30,
      difficulty: 'Medium',
      videoId: 'lM9_l9Sc1Fg',
      description: 'A controlled spinal flexion that sequentially bends each vertebra.',
      steps: [
        'Stand with feet shoulder-width apart, knees slightly bent',
        'Tuck your chin and slowly curl your head toward your chest',
        'Continue curling down one vertebra at a time, reaching toward the floor',
        'Hold the bottom position for 3 seconds, feeling the stretch along your spine',
        'Slowly reverse the movement, stacking vertebrae one at a time back up',
      ],
      breathing: [
        'Inhale deeply as you stand tall before starting',
        'Exhale slowly as you curl down',
        'Inhale as you hold at the bottom',
        'Exhale as you roll back up',
      ],
    ),
    ExerciseInfo(
      id: 'spine_2',
      name: 'Cat-Cow Stretch',
      category: 'spine',
      icon: '🐱',
      durationSeconds: 60,
      setsCount: 3,
      restSeconds: 20,
      difficulty: 'Easy',
      videoId: 'kqn0oNsnvgY',
      description: 'Alternates between arching and rounding the spine for flexibility.',
      steps: [
        'Start on hands and knees in tabletop position',
        'Inhale, drop your belly, lift your head and tailbone (Cow pose)',
        'Exhale, round your spine toward the ceiling, tuck chin (Cat pose)',
        'Move slowly with your breath, feeling each vertebra',
        'Repeat for the full duration, moving smoothly between poses',
      ],
      breathing: [
        'Inhale into Cow pose (belly drops, gaze up)',
        'Exhale into Cat pose (spine rounds, chin tucks)',
      ],
    ),
    ExerciseInfo(
      id: 'spine_3',
      name: 'Cobra Stretch',
      category: 'spine',
      icon: '🐍',
      durationSeconds: 30,
      setsCount: 3,
      restSeconds: 20,
      difficulty: 'Easy',
      videoId: '0WXAL1WjIYk',
      description: 'A gentle backbend that strengthens the spine and opens the chest.',
      steps: [
        'Lie face down on the mat, legs extended, tops of feet on floor',
        'Place hands under shoulders, elbows close to body',
        'Inhale and gently lift your chest off the floor using back muscles',
        'Keep your lower ribs on the mat — don\'t overextend your neck',
        'Hold for 15-30 seconds, then slowly lower back down',
      ],
      breathing: [
        'Inhale as you lift your chest',
        'Breathe steadily while holding',
        'Exhale as you lower back down',
      ],
    ),
    ExerciseInfo(
      id: 'spine_4',
      name: 'Pelvic Tilt',
      category: 'spine',
      icon: '🔄',
      durationSeconds: 30,
      setsCount: 3,
      restSeconds: 15,
      difficulty: 'Easy',
      videoId: '7FaN3fWxI1A',
      description: 'Gentle spinal mobilization that releases lower back tension.',
      steps: [
        'Lie on your back with knees bent, feet flat on the floor',
        'Keep your arms at your sides with palms facing down',
        'Gently tilt your pelvis upward, pressing your lower back into the mat',
        'Hold for 2 seconds, then release back to neutral',
        'Repeat in a slow, controlled rhythm',
      ],
      breathing: [
        'Exhale as you tilt your pelvis up',
        'Inhale as you release back to neutral',
      ],
    ),
    ExerciseInfo(
      id: 'spine_5',
      name: 'Cat-Camel Stretch',
      category: 'spine',
      icon: '🐪',
      durationSeconds: 40,
      setsCount: 3,
      restSeconds: 20,
      difficulty: 'Easy',
      videoId: 'rv3T1q1KALg',
      description: 'A broader spinal wave that combines full flexion and extension.',
      steps: [
        'Begin on hands and knees in tabletop position',
        'Slowly round your spine up like a cat, tucking chin and tailbone',
        'Hold the rounded position for a moment',
        'Slowly reverse, arching your back and lifting head and tailbone',
        'Move continuously with your breath in a wave-like motion',
      ],
      breathing: [
        'Exhale as you round your spine upward',
        'Inhale as you arch and open the front body',
      ],
    ),

    // ── Hanging / Decompression (3) ──
    ExerciseInfo(
      id: 'hanging_1',
      name: 'Dead Hang',
      category: 'hanging',
      icon: '🤸',
      durationSeconds: 30,
      setsCount: 3,
      restSeconds: 45,
      difficulty: 'Hard',
      videoId: 'XxvDx4qB6ig',
      description: 'A passive hang from a bar to decompress the spine and strengthen grip.',
      steps: [
        'Grip an overhead bar with hands shoulder-width apart, palms facing forward',
        'Lift your feet off the ground and let your body hang freely',
        'Keep your shoulders engaged by pulling them down away from your ears',
        'Relax your lower body completely, letting gravity stretch your spine',
        'Hold for 30 seconds, breathing steadily',
        'Lower yourself down gently when done',
      ],
      breathing: [
        'Take deep belly breaths throughout the hang',
        'Inhale for 4 seconds, exhale for 4 seconds',
      ],
    ),
    ExerciseInfo(
      id: 'hanging_2',
      name: 'Active Hang',
      category: 'hanging',
      icon: '💪',
      durationSeconds: 20,
      setsCount: 3,
      restSeconds: 40,
      difficulty: 'Hard',
      videoId: 'eGo4Icw1mnA',
      description: 'An active shoulder engagement hang for upper body strength.',
      steps: [
        'Start in a dead hang position on a bar',
        'Pull your shoulder blades down and back (depress + retract)',
        'Hold this active position with shoulders engaged',
        'Keep your body stable — avoid swinging',
        'Breathe steadily and maintain the engagement',
      ],
      breathing: [
        'Inhale as you engage your shoulders',
        'Exhale and hold the engaged position',
      ],
    ),
    ExerciseInfo(
      id: 'hanging_3',
      name: 'Scapular Pull-ups',
      category: 'hanging',
      icon: '🏋️',
      durationSeconds: 15,
      setsCount: 2,
      restSeconds: 40,
      difficulty: 'Hard',
      videoId: 'NKJ7mR7AKis',
      description: 'Isolated scapular retraction and depression on the bar.',
      steps: [
        'Hang from a bar with arms fully extended',
        'Without bending your elbows, pull your shoulder blades down and together',
        'Your body should rise slightly as your shoulders engage',
        'Hold the retracted position for 2 seconds',
        'Slowly release back to the dead hang position',
      ],
      breathing: [
        'Inhale at the bottom dead hang',
        'Exhale as you retract your shoulder blades and rise',
      ],
    ),

    // ── Hip Openers (3) ──
    ExerciseInfo(
      id: 'hip_1',
      name: 'Deep Lunge with Rotation',
      category: 'hip',
      icon: '🦵',
      durationSeconds: 45,
      setsCount: 2,
      restSeconds: 20,
      difficulty: 'Medium',
      videoId: 'Dh9C6cYz7Dg',
      description: 'Opens the hip flexors and improves spinal rotation.',
      steps: [
        'Step your right foot forward into a deep lunge position',
        'Lower your left knee to the mat (pad if needed)',
        'Place your right hand on the floor inside your right foot',
        'Reach your left arm toward the ceiling, rotating your torso open',
        'Hold for 20 seconds, then switch sides',
      ],
      breathing: [
        'Inhale as you rotate and reach upward',
        'Exhale to deepen the lunge',
      ],
    ),
    ExerciseInfo(
      id: 'hip_2',
      name: '90/90 Hip Stretch',
      category: 'hip',
      icon: '📐',
      durationSeconds: 60,
      setsCount: 2,
      restSeconds: 20,
      difficulty: 'Medium',
      videoId: 'bmC7Mc7OMbM',
      description: 'Deep external and internal hip rotation stretch.',
      steps: [
        'Sit on the floor with both knees bent at 90 degrees',
        'Front leg: shin parallel to your hips, knee at 90°',
        'Back leg: shin perpendicular to hips, knee at 90°',
        'Keep your torso upright — lean forward slightly to deepen',
        'Hold for 30 seconds, then switch leg positions',
      ],
      breathing: [
        'Breathe deeply and relax into the stretch',
        'Exhale as you lean forward to deepen',
      ],
    ),
    ExerciseInfo(
      id: 'hip_3',
      name: 'Figure 4 Stretch',
      category: 'hip',
      icon: '4️⃣',
      durationSeconds: 30,
      setsCount: 3,
      restSeconds: 15,
      difficulty: 'Easy',
      videoId: 'jcUoYq67Hlk',
      description: 'Piriformis and deep hip rotator stretch.',
      steps: [
        'Lie on your back with both knees bent, feet flat',
        'Cross your right ankle over your left knee (Figure 4 shape)',
        'Reach through and pull your left thigh toward your chest',
        'Hold for 15 seconds, feeling the stretch in your right glute',
        'Switch legs and repeat',
      ],
      breathing: [
        'Inhale to prepare',
        'Exhale as you pull the leg toward your chest',
      ],
    ),

    // ── Leg / Hamstring (2) ──
    ExerciseInfo(
      id: 'leg_1',
      name: 'PNF Hamstring Stretch',
      category: 'leg',
      icon: '🧘',
      durationSeconds: 60,
      setsCount: 2,
      restSeconds: 20,
      difficulty: 'Medium',
      videoId: 'Uqs8oM0YobY',
      description: 'Proprioceptive Neuromuscular Facilitation for deep hamstring release.',
      steps: [
        'Lie on your back with one leg extended, other lifted',
        'Loop a band or towel around your lifted foot',
        'Pull your leg toward you until you feel a mild stretch',
        'Contract your hamstring by pushing against the band for 5 seconds',
        'Relax and push the stretch a little further — hold 15 seconds',
        'Repeat 3 times per leg',
      ],
      breathing: [
        'Inhale before the contraction phase',
        'Exhale as you contract the hamstring',
        'Breathe steadily during the relaxation phase',
      ],
    ),
    ExerciseInfo(
      id: 'leg_2',
      name: 'Calf Raises',
      category: 'leg',
      icon: '🦿',
      durationSeconds: 30,
      setsCount: 3,
      restSeconds: 15,
      difficulty: 'Easy',
      videoId: '7L2N7STH99M',
      description: 'Strengthens the calves and improves ankle stability.',
      steps: [
        'Stand on the edge of a step or sturdy platform',
        'Lower your heels below the step level for a stretch',
        'Push up onto your tiptoes as high as possible',
        'Hold at the top for 1 second',
        'Slowly lower back down below the step',
      ],
      breathing: [
        'Exhale as you rise up',
        'Inhale as you lower back down',
      ],
    ),

    // ── Core (3) ──
    ExerciseInfo(
      id: 'core_1',
      name: 'Plank Hold',
      category: 'core',
      icon: '💪',
      durationSeconds: 45,
      setsCount: 3,
      restSeconds: 30,
      difficulty: 'Medium',
      videoId: 'BQu26ABu1PE',
      description: 'A full-body isometric core exercise.',
      steps: [
        'Start in a push-up position with hands under shoulders',
        'Engage your core by pulling your belly button toward your spine',
        'Keep your body in a straight line from head to heels',
        'Squeeze your glutes and quads to maintain stability',
        'Hold the position without letting your hips sag or pike up',
        'Breathe steadily throughout the hold',
      ],
      breathing: [
        'Take steady, controlled breaths',
        'Inhale through your nose, exhale through your mouth',
      ],
    ),
    ExerciseInfo(
      id: 'core_2',
      name: 'Leg Raises',
      category: 'core',
      icon: '🦵',
      durationSeconds: 30,
      setsCount: 3,
      restSeconds: 30,
      difficulty: 'Medium',
      videoId: 'JB2oyawG9KI',
      description: 'Lower abdominal exercise that targets the hip flexors and core.',
      steps: [
        'Lie flat on your back, legs straight, arms at sides or under hips',
        'Press your lower back into the mat',
        'Keeping legs straight, lift them to 90 degrees',
        'Slowly lower them back down without touching the floor',
        'Stop when your back starts to arch, then raise again',
      ],
      breathing: [
        'Exhale as you lift your legs up',
        'Inhale as you lower them down',
      ],
    ),
    ExerciseInfo(
      id: 'core_3',
      name: 'Bird Dog',
      category: 'core',
      icon: '🐕',
      durationSeconds: 30,
      setsCount: 2,
      restSeconds: 20,
      difficulty: 'Easy',
      videoId: 'CgM3Yta6aQ4',
      description: 'Core stability exercise that strengthens the lower back and glutes.',
      steps: [
        'Start on hands and knees in tabletop position',
        'Simultaneously extend your right arm forward and left leg back',
        'Keep your hips and shoulders square to the floor',
        'Hold for 2 seconds at full extension',
        'Slowly return to start and switch sides',
      ],
      breathing: [
        'Exhale as you extend your arm and leg',
        'Inhale as you return to start',
      ],
    ),

    // ── Posture (3) ──
    ExerciseInfo(
      id: 'posture_1',
      name: 'Wall Angels',
      category: 'posture',
      icon: '👼',
      durationSeconds: 45,
      setsCount: 3,
      restSeconds: 20,
      difficulty: 'Easy',
      videoId: 'VNjR45lCMtA',
      description: 'Opens the chest and corrects rounded shoulders.',
      steps: [
        'Stand with your back against a wall, feet 6 inches out',
        'Press your lower back, upper back, and head against the wall',
        'Raise your arms to form a W shape against the wall',
        'Slowly slide your arms up into a Y shape, keeping contact',
        'Lower back down to W position — repeat slowly',
      ],
      breathing: [
        'Inhale as you raise your arms up',
        'Exhale as you lower them down',
      ],
    ),
    ExerciseInfo(
      id: 'posture_2',
      name: 'Superman Hold',
      category: 'posture',
      icon: '🦸',
      durationSeconds: 30,
      setsCount: 3,
      restSeconds: 20,
      difficulty: 'Medium',
      videoId: 'z6PJSRqR0Yc',
      description: 'Strengthens the entire posterior chain to improve posture.',
      steps: [
        'Lie face down with arms extended overhead',
        'Simultaneously lift your arms, chest, and legs off the floor',
        'Keep your neck neutral — gaze at the floor',
        'Hold at the top for 2 seconds, squeezing your back muscles',
        'Slowly lower back to the floor',
      ],
      breathing: [
        'Inhale as you lift up',
        'Exhale as you lower back down',
        'Breathe steadily during holds',
      ],
    ),
    ExerciseInfo(
      id: 'posture_3',
      name: 'Thoracic Extension',
      category: 'posture',
      icon: '🔙',
      durationSeconds: 45,
      setsCount: 2,
      restSeconds: 20,
      difficulty: 'Medium',
      videoId: 'cVw0zFOZFHM',
      description: 'Opens the upper back using a foam roller.',
      steps: [
        'Place a foam roller under your upper back',
        'Support your head with your hands, elbows pointing forward',
        'Gently extend your upper spine over the roller',
        'Roll slowly from the top to mid-back',
        'Pause and breathe at any tight spots',
      ],
      breathing: [
        'Inhale as you extend over the roller',
        'Exhale as you relax into the stretch',
      ],
    ),

    // ── Neck (2) ──
    ExerciseInfo(
      id: 'neck_1',
      name: 'Chin Tucks',
      category: 'neck',
      icon: '🤨',
      durationSeconds: 15,
      setsCount: 3,
      restSeconds: 10,
      difficulty: 'Easy',
      videoId: '6SFYhYvoXUw',
      description: 'Strengthens deep neck flexors and corrects forward head posture.',
      steps: [
        'Sit or stand with your back straight',
        'Keep your eyes level and pull your chin straight back',
        'You should feel a stretch at the base of your skull',
        'Hold for 3 seconds, then release',
        'Repeat in a slow, controlled motion',
      ],
      breathing: [
        'Breathe normally throughout the movement',
        'Do not hold your breath',
      ],
    ),
    ExerciseInfo(
      id: 'neck_2',
      name: 'Neck Isometric',
      category: 'neck',
      icon: '🧘',
      durationSeconds: 10,
      setsCount: 3,
      restSeconds: 10,
      difficulty: 'Easy',
      videoId: '4TYjJRMK6fM',
      description: 'Isometric neck strengthening for better posture support.',
      steps: [
        'Place your palm against your forehead',
        'Press your head forward into your hand without moving your head',
        'Hold for 5 seconds, then release',
        'Repeat with your hand on each side of your head',
        'Finally with your hand on the back of your head',
      ],
      breathing: [
        'Breathe steadily throughout the holds',
        'Never hold your breath during isometric contractions',
      ],
    ),

    // ── Breathing (2) ──
    ExerciseInfo(
      id: 'breathing_1',
      name: 'Diaphragmatic Breathing',
      category: 'breathing',
      icon: '🌬️',
      durationSeconds: 60,
      setsCount: 3,
      restSeconds: 15,
      difficulty: 'Easy',
      videoId: '4FazJnvzVvE',
      description: 'Deep belly breathing to activate the diaphragm and reduce stress.',
      steps: [
        'Lie on your back with knees bent or sit comfortably',
        'Place one hand on your chest and one on your belly',
        'Inhale slowly through your nose — feel your belly rise',
        'Keep your chest relatively still',
        'Exhale slowly through pursed lips — feel your belly fall',
      ],
      breathing: [
        'Inhale for 4 seconds, expanding your belly',
        'Exhale for 6 seconds through pursed lips',
        'Focus on the hand on your belly rising and falling',
      ],
    ),
    ExerciseInfo(
      id: 'breathing_2',
      name: 'Box Breathing',
      category: 'breathing',
      icon: '🔲',
      durationSeconds: 60,
      setsCount: 3,
      restSeconds: 10,
      difficulty: 'Easy',
      videoId: 'JFkR3y5B6KY',
      description: 'A 4-4-4-4 breathing pattern for focus and relaxation.',
      steps: [
        'Sit upright in a comfortable position',
        'Inhale through your nose for 4 counts',
        'Hold your breath for 4 counts',
        'Exhale through your mouth for 4 counts',
        'Hold your lungs empty for 4 counts',
        'Repeat the square pattern',
      ],
      breathing: [
        'Inhale 4 seconds — hold 4 seconds',
        'Exhale 4 seconds — hold empty 4 seconds',
        'Imagine tracing a square with your breath',
      ],
    ),

    // ── Yoga (3) ──
    ExerciseInfo(
      id: 'yoga_1',
      name: 'Sun Salutation A',
      category: 'yoga',
      icon: '🌅',
      durationSeconds: 90,
      setsCount: 4,
      restSeconds: 20,
      difficulty: 'Easy',
      videoId: 'VpWoWxPksXk',
      description: 'A flowing sequence of yoga poses that warms up the entire body.',
      steps: [
        'Stand at front of mat, hands together at chest (Mountain Pose)',
        'Inhale, sweep arms up and slightly back (Upward Salute)',
        'Exhale, fold forward from hips (Forward Fold)',
        'Inhale, lift halfway with a flat back (Halfway Lift)',
        'Exhale, step or jump back to Plank, lower to Chaturanga',
        'Inhale into Upward-Facing Dog (or Cobra)',
        'Exhale into Downward-Facing Dog, hold for 5 breaths',
        'Jump or step forward to Forward Fold, then inhale all the way up',
      ],
      breathing: [
        'Each movement flows with one breath',
        'Inhale on upward/backward movements, exhale on forward/downward movements',
      ],
    ),
    ExerciseInfo(
      id: 'yoga_2',
      name: 'Cobra Pose',
      category: 'yoga',
      icon: '🐍',
      durationSeconds: 30,
      setsCount: 3,
      restSeconds: 20,
      difficulty: 'Easy',
      videoId: 'kh9_C3sE3pc',
      description: 'A gentle backbend that strengthens the spine and opens the chest.',
      steps: [
        'Lie face down on the mat, legs extended, tops of feet on floor',
        'Place hands under shoulders, elbows close to body',
        'Inhale and gently lift your chest off the floor using back muscles',
        'Keep your lower ribs on the mat, don\'t overextend your neck',
        'Hold for 15-30 seconds, then slowly lower back down',
      ],
      breathing: [
        'Inhale as you lift your chest',
        'Breathe steadily while holding',
        'Exhale as you lower back down',
      ],
    ),
    ExerciseInfo(
      id: 'yoga_3',
      name: 'Mountain Pose',
      category: 'yoga',
      icon: '🗻',
      durationSeconds: 30,
      setsCount: 2,
      restSeconds: 15,
      difficulty: 'Easy',
      videoId: '8bQfL63hH3M',
      description: 'A foundational standing pose that improves posture and body awareness.',
      steps: [
        'Stand with feet together, big toes touching, heels slightly apart',
        'Distribute weight evenly across both feet',
        'Engage your thighs and lift your kneecaps',
        'Lengthen your tailbone toward the floor',
        'Reach the crown of your head toward the ceiling',
        'Arms at sides with palms facing forward',
        'Hold for 5-8 deep breaths',
      ],
      breathing: [
        'Inhale as you lengthen through the spine',
        'Exhale as you ground through your feet',
      ],
    ),

    // ── Stretching (6) ──
    ExerciseInfo(
      id: 'stretching_1',
      name: 'Full Body Stretch',
      category: 'stretching',
      icon: '🙆',
      durationSeconds: 60,
      setsCount: 2,
      restSeconds: 20,
      difficulty: 'Easy',
      videoId: '3SEWkAKVUt0',
      description: 'A complete full-body stretching routine for flexibility and recovery.',
      steps: [
        'Stand tall and reach both arms overhead, interlacing fingers',
        'Lean to the right for a side stretch, hold 10 seconds',
        'Lean to the left for a side stretch, hold 10 seconds',
        'Reach forward and slowly fold at the hips (Forward Fold)',
        'Walk hands out to a plank position, then lower to the floor',
        'Lie on your back and hug your knees to your chest',
        'Roll onto your side and use your hand to push up to sitting',
      ],
      breathing: [
        'Inhale as you reach up and lengthen',
        'Exhale as you fold and release tension',
      ],
    ),
    ExerciseInfo(
      id: 'stretching_2',
      name: 'Butterfly Stretch',
      category: 'stretching',
      icon: '🦋',
      durationSeconds: 45,
      setsCount: 2,
      restSeconds: 20,
      difficulty: 'Easy',
      videoId: '0USanDql-CY',
      description: 'Opens the hips and stretches the inner thighs.',
      steps: [
        'Sit on the floor with your back straight',
        'Bring the soles of your feet together, knees dropping to sides',
        'Hold your feet with your hands',
        'Gently press your knees toward the floor with your elbows',
        'Hold the stretch, breathing deeply',
        'Slowly release and straighten your legs',
      ],
      breathing: [
        'Inhale to lengthen your spine',
        'Exhale to gently press knees down',
      ],
    ),
    ExerciseInfo(
      id: 'stretching_3',
      name: 'Pike Walk',
      category: 'stretching',
      icon: '🚶',
      durationSeconds: 30,
      setsCount: 2,
      restSeconds: 20,
      difficulty: 'Medium',
      videoId: '8hIfIBygvS8',
      description: 'Dynamic hamstring and lower back stretch.',
      steps: [
        'Start in a forward fold with hands on the floor',
        'Walk your hands forward while keeping your legs as straight as possible',
        'Walk your feet toward your hands, keeping your legs straight',
        'Continue alternating hand and foot walks',
        'Move slowly to feel a deep stretch in your hamstrings',
      ],
      breathing: [
        'Inhale as you walk your hands forward',
        'Exhale as you walk your feet in',
      ],
    ),
    ExerciseInfo(
      id: 'stretching_4',
      name: 'Standing Forward Fold',
      category: 'stretching',
      icon: '⬇️',
      durationSeconds: 30,
      setsCount: 2,
      restSeconds: 15,
      difficulty: 'Easy',
      videoId: 'M-O2eH5wEL4',
      description: 'Passive hamstring and lower back stretch with gravity.',
      steps: [
        'Stand with feet hip-width apart',
        'Hinge at your hips and fold forward',
        'Let your head and arms hang loose toward the floor',
        'Bend your knees slightly if needed',
        'Hold for 30 seconds, breathing deeply',
        'Slowly roll back up one vertebra at a time',
      ],
      breathing: [
        'Inhale to lengthen the spine slightly',
        'Exhale to relax deeper into the fold',
      ],
    ),
    ExerciseInfo(
      id: 'stretching_5',
      name: 'Standing Quad Stretch',
      category: 'stretching',
      icon: '🦵',
      durationSeconds: 30,
      setsCount: 2,
      restSeconds: 15,
      difficulty: 'Easy',
      videoId: 'k9V6KBbNA-k',
      description: 'Stretches the quadriceps and hip flexors.',
      steps: [
        'Stand tall holding a wall or chair for balance',
        'Bend your right knee, bringing your heel toward your glute',
        'Grab your right ankle with your right hand',
        'Pull your heel closer while keeping your knees together',
        'Hold for 15 seconds, then switch legs',
      ],
      breathing: [
        'Inhale as you stand tall',
        'Exhale as you pull your heel closer',
      ],
    ),
    ExerciseInfo(
      id: 'stretching_6',
      name: 'Doorway Chest Stretch',
      category: 'stretching',
      icon: '🚪',
      durationSeconds: 30,
      setsCount: 2,
      restSeconds: 15,
      difficulty: 'Easy',
      videoId: 'i1b7u5fUSSU',
      description: 'Opens the chest and corrects rounded shoulders.',
      steps: [
        'Stand in an open doorway',
        'Place both forearms on the door frame at shoulder height',
        'Gently lean forward until you feel a stretch in your chest',
        'Keep your back straight and core engaged',
        'Hold for 15 seconds',
        'Try placing arms higher or lower for different angles',
      ],
      breathing: [
        'Inhale to prepare',
        'Exhale as you lean forward into the stretch',
      ],
    ),

    // ── Advanced (2) ──
    ExerciseInfo(
      id: 'advanced_1',
      name: 'Full Bridge',
      category: 'advanced',
      icon: '🌉',
      durationSeconds: 20,
      setsCount: 2,
      restSeconds: 30,
      difficulty: 'Hard',
      videoId: 'dNjlh8pWp_U',
      description: 'A full body backbend that builds spinal flexibility and strength.',
      steps: [
        'Lie on your back with knees bent, feet flat on the floor',
        'Place your hands flat on the floor beside your ears, fingers pointing toward shoulders',
        'Press into your hands and feet, lifting your entire body into a bridge',
        'Straighten your arms as much as comfortable',
        'Hold for 10-20 seconds, then slowly lower back down',
      ],
      breathing: [
        'Inhale as you lift into the bridge',
        'Breathe steadily while holding',
        'Exhale as you lower down',
      ],
    ),
    ExerciseInfo(
      id: 'advanced_2',
      name: 'L-Sit Hold',
      category: 'advanced',
      icon: '🏋️',
      durationSeconds: 10,
      setsCount: 2,
      restSeconds: 30,
      difficulty: 'Hard',
      videoId: 'D1C0QYmtDO0',
      description: 'Advanced core and hip flexor strength hold.',
      steps: [
        'Sit on the floor with legs extended',
        'Place your palms flat on the floor beside your hips',
        'Press down and lift your entire body off the floor',
        'Extend your legs forward to form an L shape',
        'Hold for 5-10 seconds, then lower with control',
      ],
      breathing: [
        'Inhale before lifting',
        'Hold your breath briefly during the lift',
        'Exhale slowly as you lower down',
      ],
    ),

    // ── Balance (2) ──
    ExerciseInfo(
      id: 'balance_1',
      name: 'Single Leg Stand',
      category: 'balance',
      icon: '🦩',
      durationSeconds: 30,
      setsCount: 2,
      restSeconds: 15,
      difficulty: 'Easy',
      videoId: '8E2Qm6hDp3E',
      description: 'Builds ankle stability and proprioception.',
      steps: [
        'Stand tall with feet together',
        'Lift your right foot off the floor, balancing on your left',
        'Keep your standing leg slightly soft at the knee',
        'Focus your gaze on a fixed point ahead',
        'Hold for 15 seconds, then switch legs',
      ],
      breathing: [
        'Breathe steadily throughout the hold',
        'Keep your breath calm and even',
      ],
    ),
    ExerciseInfo(
      id: 'balance_2',
      name: 'Tree Pose',
      category: 'balance',
      icon: '🌳',
      durationSeconds: 30,
      setsCount: 2,
      restSeconds: 15,
      difficulty: 'Easy',
      videoId: 'Vq1AAJmsO9E',
      description: 'Classic yoga balance pose that strengthens the ankles and core.',
      steps: [
        'Stand tall with feet together (Mountain Pose)',
        'Shift weight to your left foot',
        'Place the sole of your right foot on your left inner thigh or calf',
        'Avoid placing it directly on the knee',
        'Bring your hands to prayer position at your chest or reach overhead',
        'Hold for 15 seconds, then switch sides',
      ],
      breathing: [
        'Inhale as you reach your arms overhead',
        'Exhale as you ground through your standing foot',
      ],
    ),

    // ── Fascia / Recovery (1) ──
    ExerciseInfo(
      id: 'fascia_1',
      name: 'Foam Roller Back',
      category: 'fascia',
      icon: '🔄',
      durationSeconds: 60,
      setsCount: 1,
      restSeconds: 0,
      difficulty: 'Easy',
      videoId: 'K3wbI0DM46c',
      description: 'Myofascial release for the back using a foam roller.',
      steps: [
        'Sit on the floor with a foam roller placed horizontally behind your lower back',
        'Lie back onto the roller, supporting your head with your hands',
        'Lift your hips slightly and roll gently from your lower back to mid-back',
        'Pause on any tight spots for 20-30 seconds',
        'Breathe deeply into the tight areas',
      ],
      breathing: [
        'Take deep belly breaths while rolling',
        'Exhale as you roll over tight spots',
      ],
    ),

    // ── Shoulder (1) ──
    ExerciseInfo(
      id: 'shoulder_1',
      name: 'Shoulder Dislocations',
      category: 'shoulder',
      icon: '🔁',
      durationSeconds: 30,
      setsCount: 2,
      restSeconds: 20,
      difficulty: 'Medium',
      videoId: 'wHeVLx8Mrxo',
      description: 'Dynamic shoulder mobility drill using a band or towel.',
      steps: [
        'Hold a resistance band or towel with a wide grip in front of your hips',
        'Raise your arms overhead and continue behind your body',
        'Keep your arms straight throughout the movement',
        'Return to the starting position the same way',
        'Gradually narrow your grip as mobility improves',
      ],
      breathing: [
        'Inhale as you raise the band overhead',
        'Exhale as you lower it behind your body',
      ],
    ),
  ];

  /// Get an exercise by its ID.
  static ExerciseInfo? getById(String id) {
    try {
      return exercises.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get all exercises in a specific category.
  static List<ExerciseInfo> getByCategory(String category) {
    return exercises.where((e) => e.category == category).toList();
  }

  /// Get exercises by a list of IDs (in order).
  static List<ExerciseInfo> getByIds(List<String> ids) {
    return ids.map((id) => getById(id)).whereType<ExerciseInfo>().toList();
  }

  // ── Phase-Based Workout Plans (Blueprint §15.1) ──

  /// Foundation phase (Weeks 1-4): 15-20 min, spine mobility + breathing + light hanging
  static const List<String> foundationExercises = [
    'spine_1', 'spine_2', 'spine_4',       // spine mobility
    'breathing_1', 'breathing_2',            // breathing
    'hanging_1',                             // light hanging
    'stretching_4', 'stretching_5',          // light stretching
    'core_1',                                // core stability
    'posture_1', 'neck_1',                   // posture & neck
  ];

  /// Progression phase (Weeks 5-8): 20-30 min, advanced spine + hanging + core
  static const List<String> progressionExercises = [
    'spine_1', 'spine_3', 'spine_5',         // advanced spine
    'hanging_1', 'hanging_2',                 // hanging progression
    'core_1', 'core_2', 'core_3',            // core series
    'hip_1', 'hip_2', 'hip_3',               // hip openers
    'leg_1', 'leg_2',                        // leg work
    'posture_2', 'neck_2',                   // advanced posture
  ];

  /// Intensification phase (Weeks 9-12): 30-40 min, full routine
  static const List<String> intensificationExercises = [
    'spine_1', 'spine_2', 'spine_3', 'spine_4', 'spine_5', // full spine
    'hanging_1', 'hanging_2', 'hanging_3',                  // all hanging
    'yoga_1', 'yoga_2', 'yoga_3',                            // yoga series
    'core_1', 'core_2', 'core_3',                            // full core
    'hip_1', 'hip_3', 'leg_1',                               // mobility
    'posture_1', 'posture_2', 'posture_3',                   // full posture
    'stretching_1', 'stretching_3', 'stretching_6',          // deep stretches
    'advanced_1',                                            // advanced
  ];

  /// Maintenance phase (Weeks 13+): 25-35 min, rotating schedule
  static const List<String> maintenanceExercises = [
    'spine_1', 'spine_5',                    // key spine
    'hanging_2',                              // active hang
    'yoga_3', 'breathing_2',                 // yoga + breath
    'core_3', 'posture_1',                   // stability
    'stretching_2', 'stretching_4',          // flexibility
    'balance_1', 'balance_2',                // balance
    'fascia_1', 'shoulder_1',                // recovery
  ];

  /// Get today's recommended exercises based on the current phase.
  static List<ExerciseInfo> getExercisesForDay(int dayNumber) {
    final phase = getPhaseForDay(dayNumber);
    final pool = _getPhaseExercisePool(phase);
    if (pool.isEmpty) return todaysWorkout;

    // Use the day number to select a consistent subset from the pool
    final count = 5; // 5 exercises per day
    final startIndex = (dayNumber * 7) % pool.length;

    final selected = <ExerciseInfo>[];
    for (int i = 0; i < count; i++) {
      final idx = (startIndex + i) % pool.length;
      final ex = getById(pool[idx]);
      if (ex != null) selected.add(ex);
    }
    return selected;
  }

  /// Get the phase name for a given day number.
  static String getPhaseName(int dayNumber) {
    if (dayNumber <= 28) return 'Foundation';
    if (dayNumber <= 56) return 'Progression';
    if (dayNumber <= 84) return 'Intensification';
    return 'Maintenance';
  }

  /// Get the week number within the current phase.
  static int getWeekInPhase(int dayNumber) {
    if (dayNumber <= 28) return ((dayNumber - 1) ~/ 7) + 1;
    if (dayNumber <= 56) return ((dayNumber - 29) ~/ 7) + 1;
    if (dayNumber <= 84) return ((dayNumber - 57) ~/ 7) + 1;
    return ((dayNumber - 85) ~/ 7) + 1;
  }

  /// Get total weeks in the current phase.
  static int getPhaseWeekCount(int dayNumber) {
    if (dayNumber <= 28) return 4;
    if (dayNumber <= 56) return 4;
    if (dayNumber <= 84) return 4;
    return 52; // maintenance continues indefinitely
  }

  /// Determine which phase a given day number falls into.
  static String getPhaseForDay(int dayNumber) {
    if (dayNumber <= 28) return 'foundation';
    if (dayNumber <= 56) return 'progression';
    if (dayNumber <= 84) return 'intensification';
    return 'maintenance';
  }

  static List<String> _getPhaseExercisePool(String phase) {
    switch (phase) {
      case 'foundation':
        return foundationExercises;
      case 'progression':
        return progressionExercises;
      case 'intensification':
        return intensificationExercises;
      case 'maintenance':
        return maintenanceExercises;
      default:
        return [];
    }
  }

  /// Get today's fixed workout (used as fallback / initial reference).
  static List<ExerciseInfo> get todaysWorkout {
    return getByIds(['spine_1', 'hanging_1', 'yoga_1', 'core_1', 'stretching_1']);
  }
}

/// Exercise metadata from the database.
class ExerciseInfo {
  final String id;
  final String name;
  final String category;
  final String icon;
  final int durationSeconds;
  final int setsCount;
  final int restSeconds;
  final String difficulty;
  final String videoId;
  final String description;
  final List<String> steps;
  final List<String> breathing;

  const ExerciseInfo({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    required this.durationSeconds,
    required this.setsCount,
    required this.restSeconds,
    required this.difficulty,
    required this.videoId,
    required this.description,
    required this.steps,
    required this.breathing,
  });

  String get videoUrl => 'https://www.youtube.com/watch?v=$videoId';
}
