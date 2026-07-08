import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String heightBoxName = 'height_measurements_v2';
  static const String mealsBoxName = 'meal_entries_v2';
  static const String sleepBoxName = 'sleep_entries_v2';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters
    // Note: In a full implementation, we would generate these using hive_generator.
    // For this migration, we'll use a manual adapter or Map-based storage 
    // to keep it simple and avoid build_runner dependency if possible.
    
    await Hive.openBox(heightBoxName);
    await Hive.openBox(mealsBoxName);
    await Hive.openBox(sleepBoxName);
  }

  static Box get heightBox => Hive.box(heightBoxName);
  static Box get mealsBox => Hive.box(mealsBoxName);
  static Box get sleepBox => Hive.box(sleepBoxName);
  
  static Future<void> clearAll() async {
    await heightBox.clear();
    await mealsBox.clear();
    await sleepBox.clear();
  }
}
