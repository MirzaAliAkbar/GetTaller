/// Mapping from exercise IDs to their illustration image assets.
///
/// 37 illustrations at 1024×733 (≈7:5 ratio).
/// Images are stored in assets/exercises/ with BoxFit.cover and a slight
/// left+up alignment to crop the bottom-right GetTaller logo.
class ExerciseImages {
  ExerciseImages._();

  static const String _basePath = 'assets/exercises';

  /// Maps each exercise ID to its image asset path.
  /// Exercises without a dedicated image return null.
  static String? getImagePath(String exerciseId) {
    final filename = _mapping[exerciseId];
    if (filename == null) return null;
    return '$_basePath/$filename';
  }

  static const Map<String, String> _mapping = {
    // ── Spine & Posture ──
    'spine_1': 'Jeffreson-curls.jpeg',
    'spine_2': 'CatCow.jpeg',
    'spine_3': 'Cobra-Stretch.jpeg',
    'spine_4': 'Pelvic-Tilt.jpeg',
    'spine_5': 'Cat-Camel.jpeg',

    // ── Hanging / Decompression ──
    'hanging_1': 'Deadhang.jpeg',
    'hanging_2': 'Active-Hang.jpeg',
    'hanging_3': 'Scapular-Pullup.jpeg',

    // ── Hip Openers ──
    'hip_1': 'DeepLunge-WithRotation.jpeg',
    'hip_2': '90HipStretch.jpeg',
    'hip_3': 'figure4-glutestretch.jpeg',

    // ── Leg / Hamstring ──
    'leg_1': 'PNFHamstringstretch.jpeg',
    'leg_2': 'CalfRaises.jpeg',

    // ── Core ──
    'core_1': 'plankhold.jpeg',
    'core_2': 'deadbug-excercise.jpeg',     // Dead bug = core / leg raise analogue
    'core_3': 'Bird-DogExcercise.jpeg',

    // ── Posture ──
    'posture_1': 'wall-angels.jpeg',
    'posture_2': 'Superman-hold.jpeg',
    'posture_3': 'Thoratic-extension-on-foam-roller.jpeg',

    // ── Neck ──
    'neck_1': 'Chin-tuck.jpeg',
    'neck_2': 'neckisometric-forhead.jpeg',

    // ── Breathing ──
    'breathing_1': 'Diaphgramatic-breathing.jpeg',
    'breathing_2': 'boxbreathingdiagram.jpeg',

    // ── Yoga ──
    'yoga_1': 'DownwardDog.jpeg',           // Sun Salutation includes Downward Dog
    'yoga_2': 'Cobra-Stretch.jpeg',         // Cobra Pose (yoga) — reuses spine_3 image
    'yoga_3': 'mountainpose(tadasana).jpeg',

    // ── Stretching ──
    'stretching_1': 'childspose.jpeg',      // Child's pose is a full-body stretch
    'stretching_2': 'butterflystretch.jpeg',
    'stretching_3': 'pikewalk.jpeg',
    'stretching_4': 'standingforwardfold(uttanasana).jpeg',
    'stretching_5': 'standingQuadstretch.jpeg',
    'stretching_6': 'doorwaychestframe.jpeg',

    // ── Advanced ──
    'advanced_1': 'fullbridge(wheel-pose).jpeg',
    'advanced_2': 'L-Sit-Hold.jpeg',

    // ── Balance ──
    'balance_1': 'single-leg-stand.jpeg',
    'balance_2': 'treepose.jpeg',

    // ── Fascia / Recovery ──
    'fascia_1': 'Foam-roller-upperback.jpeg',

    // ── Shoulder ──
    'shoulder_1': 'ShoulderDislocations(bandstretch).jpeg',
  };

  /// All 36 mapped images for verification / logging.
  static int get mappedCount => _mapping.length;
}
