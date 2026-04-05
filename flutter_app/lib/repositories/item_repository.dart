import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  return ItemRepository(firestoreService, storageService);
});

class ItemRepository {
  final FirestoreService _firestoreService;
  final StorageService _storageService;

  ItemRepository(this._firestoreService, this._storageService);

  Stream<List<ItemModel>> getBoxItems(String boxId) {
    return _firestoreService.getBoxItems(boxId);
  }

  Future<String> addItem({
    required String boxId,
    required String ownerId,
    required String name,
    required int quantity,
    String? description,
    File? imageFile,
  }) async {
    String? imageUrl;

    // Use a temp ID for upload, then update with real ID
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();

    if (imageFile != null) {
      imageUrl = await _storageService.uploadItemImage(tempId, imageFile);
    }

    final item = ItemModel(
      id: '',
      boxId: boxId,
      ownerId: ownerId,
      name: name,
      quantity: quantity,
      description: description,
      imageUrl: imageUrl,
    );

    final itemId = await _firestoreService.addItem(item);

    // If we uploaded an image with temp ID, re-upload with real ID
    if (imageFile != null) {
      final realUrl =
          await _storageService.uploadItemImage(itemId, imageFile);
      await _firestoreService
          .updateItem(item.copyWith(id: itemId, imageUrl: realUrl));
    }

    return itemId;
  }

  Future<void> updateItem(ItemModel item, {File? newImageFile}) async {
    ItemModel updated = item;
    if (newImageFile != null) {
      final imageUrl =
          await _storageService.uploadItemImage(item.id, newImageFile);
      updated = item.copyWith(imageUrl: imageUrl);
    }
    await _firestoreService.updateItem(updated);
  }

  Future<void> deleteItem(String itemId, String boxId) async {
    await _storageService.deleteItemImage(itemId);
    await _firestoreService.deleteItem(itemId, boxId);
  }

  Future<List<ItemModel>> searchItems(String userId, String query) {
    return _firestoreService.searchItems(userId, query);
  }
}
