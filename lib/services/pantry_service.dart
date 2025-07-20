import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:bitebuddy/models/pantry_item.dart';

class PantryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Box<Map> _pantryBox;

  PantryService(this._pantryBox);

  // Get pantry items with offline support
  Future<List<PantryItem>> getPantryItems({
    required String userId,
    String? category,
  }) async {
    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    final bool isConnected = connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.mobile);

    if (isConnected) {
      try {
        // Online: Fetch from Firestore
        Query query = _firestore.collection('pantry_items').where('userId', isEqualTo: userId);

        if (category != null && category != 'All') {
          query = query.where('category', isEqualTo: category);
        }

        final snapshot = await query.get();
        final pantryItems = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return PantryItem.fromMap(data, doc.id);
        }).toList();

        // Cache pantry items locally
        for (final item in pantryItems) {
          _pantryBox.put(item.id, item.toMap());
        }

        return pantryItems;
      } catch (e) {
        // If online fetch fails, fall back to cached data
        return _getCachedPantryItems(userId, category);
      }
    } else {
      // Offline: Use cached data
      return _getCachedPantryItems(userId, category);
    }
  }

  // Get cached pantry items from Hive
  List<PantryItem> _getCachedPantryItems(String userId, String? category) {
    final items = _pantryBox.values.map((map) {
      final id = map['id'] as String? ?? '';
      return PantryItem.fromMap(Map<String, dynamic>.from(map), id);
    }).where((item) => item.userId == userId).toList();

    if (category != null && category != 'All') {
      return items.where((item) => item.category == category).toList();
    }

    return items;
  }

  // Add or update a pantry item with offline sync
  Future<void> savePantryItem(PantryItem item, {bool isNew = false}) async {
    // Save to local cache first
    _pantryBox.put(item.id, item.toMap());

    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    final bool isConnected = connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.mobile);

    if (isConnected) {
      try {
        // Online: Save to Firestore
        if (isNew) {
          await _firestore.collection('pantry_items').add(item.toMap());
        } else {
          await _firestore.collection('pantry_items').doc(item.id).update(item.toMap());
        }
      } catch (e) {
        // If online save fails, mark for sync later
        _markForSync(item.id);
      }
    } else {
      // Offline: Mark for sync later
      _markForSync(item.id);
    }
  }

  // Delete a pantry item with offline sync
  Future<void> deletePantryItem(String itemId) async {
    // Remove from local cache first
    _pantryBox.delete(itemId);

    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    final bool isConnected = connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.mobile);

    if (isConnected) {
      try {
        // Online: Delete from Firestore
        await _firestore.collection('pantry_items').doc(itemId).delete();
      } catch (e) {
        // If online delete fails, mark for deletion later
        _markForDeletion(itemId);
      }
    } else {
      // Offline: Mark for deletion later
      _markForDeletion(itemId);
    }
  }

  // Mark a pantry item for sync when online
  void _markForSync(String itemId) {
    // Store IDs of pantry items that need to be synced
    final syncBox = Hive.box<List<String>>('sync_box');
    final pendingSync = syncBox.get('pending_pantry_items') ?? <String>[];

    if (!pendingSync.contains(itemId)) {
      pendingSync.add(itemId);
      syncBox.put('pending_pantry_items', pendingSync);
    }
  }

  // Mark a pantry item for deletion when online
  void _markForDeletion(String itemId) {
    // Store IDs of pantry items that need to be deleted
    final syncBox = Hive.box<List<String>>('sync_box');
    final pendingDeletion = syncBox.get('pending_pantry_deletions') ?? <String>[];

    if (!pendingDeletion.contains(itemId)) {
      pendingDeletion.add(itemId);
      syncBox.put('pending_pantry_deletions', pendingDeletion);
    }
  }

  // Sync pending pantry items when online
  Future<void> syncPendingPantryItems() async {
    final syncBox = Hive.box<List<String>>('sync_box');
    final pendingSync = syncBox.get('pending_pantry_items') ?? <String>[];
    final pendingDeletion = syncBox.get('pending_pantry_deletions') ?? <String>[];

    if (pendingSync.isEmpty && pendingDeletion.isEmpty) return;

    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    final bool isConnected = connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.mobile);

    if (!isConnected) return;

    // Process each pending pantry item
    for (final itemId in List<String>.from(pendingSync)) {
      final cachedData = _pantryBox.get(itemId);

      if (cachedData != null) {
        try {
          // Check if pantry item exists in Firestore
          final docRef = _firestore.collection('pantry_items').doc(itemId);
          final docSnapshot = await docRef.get();

          if (docSnapshot.exists) {
            // Update existing pantry item
            await docRef.update(Map<String, dynamic>.from(cachedData));
          } else {
            // Create new pantry item
            await _firestore.collection('pantry_items').add(Map<String, dynamic>.from(cachedData));
          }

          // Remove from pending sync
          pendingSync.remove(itemId);
          syncBox.put('pending_pantry_items', pendingSync);
        } catch (e) {
          // Failed to sync, will try again later
          continue;
        }
      }
    }

    // Process each pending deletion
    for (final itemId in List<String>.from(pendingDeletion)) {
      try {
        // Delete from Firestore
        await _firestore.collection('pantry_items').doc(itemId).delete();

        // Remove from pending deletion
        pendingDeletion.remove(itemId);
        syncBox.put('pending_pantry_deletions', pendingDeletion);
      } catch (e) {
        // Failed to delete, will try again later
        continue;
      }
    }
  }
}

