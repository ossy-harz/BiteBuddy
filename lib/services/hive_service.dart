import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class HiveService {
  static Future<void> init() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);
    
    // Open boxes
    await Hive.openBox<Map>('recipe_box');
    await Hive.openBox<Map>('pantry_box');
    await Hive.openBox<Map>('meal_plan_box');
    await Hive.openBox<List<String>>('sync_box');
  }
  
  static Box<Map> getRecipeBox() {
    return Hive.box<Map>('recipe_box');
  }
  
  static Box<Map> getPantryBox() {
    return Hive.box<Map>('pantry_box');
  }
  
  static Box<Map> getMealPlanBox() {
    return Hive.box<Map>('meal_plan_box');
  }
}

