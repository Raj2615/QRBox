import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../models/box_model.dart';
import '../models/item_model.dart';

final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── BOXES ───────────────────────────────────────────────────────────

  /// Get all boxes for a user (real-time stream)
  Stream<List<BoxModel>> getUserBoxes(String userId) {
    return _db
        .collection(AppConstants.boxesCollection)
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => BoxModel.fromFirestore(doc)).toList());
  }

  /// Get a single box by ID
  Future<BoxModel?> getBox(String boxId) async {
    final doc =
        await _db.collection(AppConstants.boxesCollection).doc(boxId).get();
    if (!doc.exists) return null;
    return BoxModel.fromFirestore(doc);
  }

  /// Create a new box
  Future<void> createBox(BoxModel box) async {
    await _db
        .collection(AppConstants.boxesCollection)
        .doc(box.id)
        .set(box.toFirestore());
  }

  /// Update a box
  Future<void> updateBox(BoxModel box) async {
    await _db
        .collection(AppConstants.boxesCollection)
        .doc(box.id)
        .update(box.toFirestore());
  }

  /// Delete a box and all its items
  Future<void> deleteBox(String boxId) async {
    final batch = _db.batch();

    // Delete all items in the box
    final items = await _db
        .collection(AppConstants.itemsCollection)
        .where('boxId', isEqualTo: boxId)
        .get();
    for (final doc in items.docs) {
      batch.delete(doc.reference);
    }

    // Delete the box
    batch.delete(_db.collection(AppConstants.boxesCollection).doc(boxId));

    await batch.commit();
  }

  /// Get the next available box number for QR generation (GLOBAL across all users)
  Future<int> getNextBoxNumber(String userId) async {
    // Query ALL boxes globally (not just user's) to avoid ID collisions
    final snapshot = await _db
        .collection(AppConstants.boxesCollection)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return 1;

    // Find the highest numbered box across ALL users
    final allBoxes = await _db
        .collection(AppConstants.boxesCollection)
        .get();

    int maxNumber = 0;
    for (final doc in allBoxes.docs) {
      final parts = doc.id.split('-');
      if (parts.length == 2) {
        final num = int.tryParse(parts[1]);
        if (num != null && num > maxNumber) {
          maxNumber = num;
        }
      }
    }
    return maxNumber + 1;
  }

  /// Get user stats (total boxes, total items)
  Future<Map<String, int>> getUserStats(String userId) async {
    final boxesSnap = await _db
        .collection(AppConstants.boxesCollection)
        .where('ownerId', isEqualTo: userId)
        .count()
        .get();

    final itemsSnap = await _db
        .collection(AppConstants.itemsCollection)
        .where('ownerId', isEqualTo: userId)
        .count()
        .get();

    return {
      'totalBoxes': boxesSnap.count ?? 0,
      'totalItems': itemsSnap.count ?? 0,
    };
  }

  /// Get recent boxes for dashboard
  Stream<List<BoxModel>> getRecentBoxes(String userId, {int limit = 5}) {
    return _db
        .collection(AppConstants.boxesCollection)
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => BoxModel.fromFirestore(doc)).toList());
  }

  // ─── ITEMS ───────────────────────────────────────────────────────────

  /// Get all items in a box (real-time stream)
  Stream<List<ItemModel>> getBoxItems(String boxId) {
    return _db
        .collection(AppConstants.itemsCollection)
        .where('boxId', isEqualTo: boxId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ItemModel.fromFirestore(doc)).toList());
  }

  /// Add an item to a box
  Future<String> addItem(ItemModel item) async {
    final docRef =
        await _db.collection(AppConstants.itemsCollection).add(item.toFirestore());

    // Increment box item count
    await _db
        .collection(AppConstants.boxesCollection)
        .doc(item.boxId)
        .update({'itemCount': FieldValue.increment(1)});

    return docRef.id;
  }

  /// Update an item
  Future<void> updateItem(ItemModel item) async {
    await _db
        .collection(AppConstants.itemsCollection)
        .doc(item.id)
        .update(item.toFirestore());
  }

  /// Delete an item
  Future<void> deleteItem(String itemId, String boxId) async {
    await _db.collection(AppConstants.itemsCollection).doc(itemId).delete();

    // Decrement box item count
    await _db
        .collection(AppConstants.boxesCollection)
        .doc(boxId)
        .update({'itemCount': FieldValue.increment(-1)});
  }

  /// Search items across all boxes for a user
  Future<List<ItemModel>> searchItems(String userId, String query) async {
    final queryLower = query.toLowerCase();

    final snapshot = await _db
        .collection(AppConstants.itemsCollection)
        .where('ownerId', isEqualTo: userId)
        .get();

    return snapshot.docs
        .map((doc) => ItemModel.fromFirestore(doc))
        .where((item) => item.name.toLowerCase().contains(queryLower))
        .toList();
  }

  // ─── BATCH QR GENERATION ────────────────────────────────────────────

  /// Reserve a batch of box IDs for QR generation
  Future<List<String>> reserveBoxIds(
    String userId,
    int count,
    int startNumber,
  ) async {
    final batch = _db.batch();
    final ids = <String>[];

    for (int i = 0; i < count; i++) {
      final boxId = BoxModel.generateBoxId(startNumber + i);
      ids.add(boxId);

      batch.set(
        _db.collection(AppConstants.boxesCollection).doc(boxId),
        {
          'ownerId': userId,
          'name': '',
          'location': '',
          'pinHash': '',
          'description': '',
          'createdAt': FieldValue.serverTimestamp(),
          'isConfigured': false,
          'itemCount': 0,
        },
      );
    }

    await batch.commit();
    return ids;
  }
}
