import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:bitebuddy/models/meal_plan.dart';
import 'package:intl/intl.dart';

class MealPlanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Box<Map> _mealPlanBox;

  MealPlanService(this._mealPlanBox);

  // Get meal plan for a specific date with offline support
  Future<MealPlan?> getMealPlan({
    required String userId,
    required DateTime date,
  }) async {
    final docId = '${userId}_${DateFormat('yyyy-MM-dd').format(date)}';

    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    final bool isConnected = connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.mobile);

    if (isConnected) {
      try {
        // Online: Fetch from Firestore
        final doc = await _firestore.collection('meal_plans').doc(docId).get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final mealPlan = MealPlan.fromMap(data, doc.id);

          // Cache meal plan locally
          _mealPlanBox.put(mealPlan.id, mealPlan.toMap());

          return mealPlan;
        }
        return null;
      } catch (e) {
        // If online fetch fails, fall back to cached data
        return _getCachedMealPlan(docId);
      }
    } else {
      // Offline: Use cached data
      return _getCachedMealPlan(docId);
    }
  }

  // Get cached meal plan from Hive
  MealPlan? _getCachedMealPlan(String docId) {
    final cachedData = _mealPlanBox.get(docId);
    if (cachedData != null) {
      return MealPlan.fromMap(Map<String, dynamic>.from(cachedData), docId);
    }
    return null;
  }

  // Save or update a meal plan with offline sync
  Future<void> saveMealPlan(MealPlan mealPlan) async {
    // Save to local cache first
    _mealPlanBox.put(mealPlan.id, mealPlan.toMap());

    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    final bool isConnected = connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.mobile);

    if (isConnected) {
      try {
        // Online: Save to Firestore
        await _firestore.collection('meal_plans').doc(mealPlan.id).set(mealPlan.toMap());
      } catch (e) {
        // If online save fails, mark for sync later
        _markForSync(mealPlan.id);
      }
    } else {
      // Offline: Mark for sync later
      _markForSync(mealPlan.id);
    }
  }

  // Mark a meal plan for sync when online
  void _markForSync(String mealPlanId) {
    // Store IDs of meal plans that need to be synced
    final syncBox = Hive.box<List<String>>('sync_box');
    final pendingSync = syncBox.get('pending_meal_plans') ?? <String>[];

    if (!pendingSync.contains(mealPlanId)) {
      pendingSync.add(mealPlanId);
      syncBox.put('pending_meal_plans', pendingSync);
    }
  }

  // Sync pending meal plans when online
  Future<void> syncPendingMealPlans() async {
    final syncBox = Hive.box<List<String>>('sync_box');
    final pendingSync = syncBox.get('pending_meal_plans') ?? <String>[];

    if (pendingSync.isEmpty) return;

    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    final bool isConnected = connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.mobile);

    if (!isConnected) return;

    // Process each pending meal plan
    for (final mealPlanId in List<String>.from(pendingSync)) {
      final cachedData = _mealPlanBox.get(mealPlanId);

      if (cachedData != null) {
        try {
          // Save to Firestore
          await _firestore.collection('meal_plans').doc(mealPlanId).set(Map<String, dynamic>.from(cachedData));

          // Remove from pending sync
          pendingSync.remove(mealPlanId);
          syncBox.put('pending_meal_plans', pendingSync);
        } catch (e) {
          // Failed to sync, will try again later
          continue;
        }
      }
    }
  }
}

