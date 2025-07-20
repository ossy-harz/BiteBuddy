import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:bitebuddy/models/recipe.dart';

class RecipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Box<Map> _recipeBox;

  RecipeService(this._recipeBox);

  // Get recipes with offline support
  Future<List<Recipe>> getRecipes({
    int limit = 10,
    String? category,
    List<String>? tags,
    bool featured = false,
  }) async {
    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    final bool isConnected = connectivityResult != ConnectivityResult.none;

    if (isConnected) {
      try {
        // Online: Fetch from Firestore
        Query query = _firestore.collection('recipes');

        if (featured) {
          query = query.where('featured', isEqualTo: true);
        }

        if (category != null) {
          query = query.where('category', isEqualTo: category);
        }

        if (tags != null && tags.isNotEmpty) {
          query = query.where('tags', arrayContainsAny: tags);
        }

        query = query.orderBy('createdAt', descending: true).limit(limit);

        final snapshot = await query.get();
        final recipes = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Recipe.fromMap(data, doc.id);
        }).toList();

        // Cache recipes locally
        for (final recipe in recipes) {
          _recipeBox.put(recipe.id, recipe.toMap());
        }

        return recipes;
      } catch (e) {
        // If online fetch fails, fall back to cached data
        return _getCachedRecipes();
      }
    } else {
      // Offline: Use cached data
      return _getCachedRecipes();
    }
  }

  // Get cached recipes from Hive
  List<Recipe> _getCachedRecipes() {
    return _recipeBox.values.map((map) {
      final id = map['id'] as String? ?? '';
      return Recipe.fromMap(Map<String, dynamic>.from(map), id);
    }).toList();
  }

  // Get a single recipe with offline support
  Future<Recipe?> getRecipe(String recipeId) async {
    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    final bool isConnected = connectivityResult != ConnectivityResult.none;

    if (isConnected) {
      try {
        // Online: Fetch from Firestore
        final doc = await _firestore.collection('recipes').doc(recipeId).get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final recipe = Recipe.fromMap(data, doc.id);

          // Cache recipe locally
          _recipeBox.put(recipe.id, recipe.toMap());

          return recipe;
        }
        return null;
      } catch (e) {
        // If online fetch fails, fall back to cached data
        return _getCachedRecipe(recipeId);
      }
    } else {
      // Offline: Use cached data
      return _getCachedRecipe(recipeId);
    }
  }

  // Get a cached recipe from Hive
  Recipe? _getCachedRecipe(String recipeId) {
    final cachedData = _recipeBox.get(recipeId);
    if (cachedData != null) {
      // Fix: Explicitly cast the map to Map<String, dynamic>
      return Recipe.fromMap(Map<String, dynamic>.from(cachedData), recipeId);
    }
    return null;
  }

  // Add or update a recipe with offline sync
  Future<void> saveRecipe(Recipe recipe, {bool isNew = false}) async {
    // Save to local cache first
    _recipeBox.put(recipe.id, recipe.toMap());

    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    final bool isConnected = connectivityResult != ConnectivityResult.none;

    if (isConnected) {
      try {
        // Online: Save to Firestore
        if (isNew) {
          await _firestore.collection('recipes').add(recipe.toMap());
        } else {
          await _firestore.collection('recipes').doc(recipe.id).update(recipe.toMap());
        }
      } catch (e) {
        // If online save fails, mark for sync later
        _markForSync(recipe.id);
      }
    } else {
      // Offline: Mark for sync later
      _markForSync(recipe.id);
    }
  }

  // Mark a recipe for sync when online
  void _markForSync(String recipeId) {
    // Store IDs of recipes that need to be synced
    final syncBox = Hive.box<List<String>>('sync_box');
    final pendingSync = syncBox.get('pending_recipes') ?? <String>[];

    if (!pendingSync.contains(recipeId)) {
      pendingSync.add(recipeId);
      syncBox.put('pending_recipes', pendingSync);
    }
  }

  // Sync pending recipes when online
  Future<void> syncPendingRecipes() async {
    final syncBox = Hive.box<List<String>>('sync_box');
    final pendingSync = syncBox.get('pending_recipes') ?? <String>[];

    if (pendingSync.isEmpty) return;

    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    final bool isConnected = connectivityResult != ConnectivityResult.none;

    if (!isConnected) return;

    // Process each pending recipe
    for (final recipeId in List<String>.from(pendingSync)) {
      final cachedData = _recipeBox.get(recipeId);

      if (cachedData != null) {
        try {
          // Check if recipe exists in Firestore
          final docRef = _firestore.collection('recipes').doc(recipeId);
          final docSnapshot = await docRef.get();

          if (docSnapshot.exists) {
            // Update existing recipe
            // Fix: Explicitly cast the map to Map<String, dynamic>
            await docRef.update(Map<String, dynamic>.from(cachedData));
          } else {
            // Create new recipe
            // Fix: Explicitly cast the map to Map<String, dynamic>
            await _firestore.collection('recipes').add(Map<String, dynamic>.from(cachedData));
          }

          // Remove from pending sync
          pendingSync.remove(recipeId);
          syncBox.put('pending_recipes', pendingSync);
        } catch (e) {
          // Failed to sync, will try again later
          continue;
        }
      }
    }
  }
}

