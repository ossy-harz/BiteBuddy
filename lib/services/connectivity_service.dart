import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:bitebuddy/services/recipe_service.dart';
import 'package:bitebuddy/services/hive_service.dart';
import 'package:bitebuddy/services/pantry_service.dart';
import 'package:bitebuddy/services/meal_plan_service.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  late RecipeService _recipeService;
  late PantryService _pantryService;
  late MealPlanService _mealPlanService;

  ConnectivityService() {
    _recipeService = RecipeService(HiveService.getRecipeBox());
    _pantryService = PantryService(HiveService.getPantryBox());
    _mealPlanService = MealPlanService(HiveService.getMealPlanBox());
  }

  void initialize() {
    _subscription = _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
  }

  void dispose() {
    _subscription.cancel();
  }

  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    // Check if any of the connectivity results is not "none"
    final hasConnection = results.any((result) => result != ConnectivityResult.none);

    if (hasConnection) {
      // Device is online, sync pending data
      await _syncData();
    }
  }

  Future<void> _syncData() async {
    // Sync recipes
    await _recipeService.syncPendingRecipes();

    // Sync pantry items
    await _pantryService.syncPendingPantryItems();

    // Sync meal plans
    await _mealPlanService.syncPendingMealPlans();
  }
}

