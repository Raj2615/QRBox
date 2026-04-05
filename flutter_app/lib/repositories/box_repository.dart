import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/box_model.dart';
import '../services/firestore_service.dart';
import '../core/utils/pin_utils.dart';

final boxRepositoryProvider = Provider<BoxRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return BoxRepository(firestoreService);
});

class BoxRepository {
  final FirestoreService _firestoreService;

  BoxRepository(this._firestoreService);

  Stream<List<BoxModel>> getUserBoxes(String userId) {
    return _firestoreService.getUserBoxes(userId);
  }

  Future<BoxModel?> getBox(String boxId) {
    return _firestoreService.getBox(boxId);
  }

  Future<void> createBox({
    required String boxId,
    required String ownerId,
    required String name,
    required String location,
    required String pin,
    String? description,
  }) async {
    final box = BoxModel(
      id: boxId,
      ownerId: ownerId,
      name: name,
      location: location,
      pinHash: PinUtils.hashPin(pin),
      description: description,
      createdAt: DateTime.now(),
      isConfigured: true,
      itemCount: 0,
    );
    await _firestoreService.createBox(box);
  }

  Future<void> updateBox(BoxModel box, {String? newPin}) async {
    BoxModel updated = box;
    if (newPin != null && newPin.isNotEmpty) {
      updated = box.copyWith(pinHash: PinUtils.hashPin(newPin));
    }
    await _firestoreService.updateBox(updated);
  }

  Future<void> deleteBox(String boxId) {
    return _firestoreService.deleteBox(boxId);
  }

  Future<int> getNextBoxNumber(String userId) {
    return _firestoreService.getNextBoxNumber(userId);
  }

  Future<Map<String, int>> getUserStats(String userId) {
    return _firestoreService.getUserStats(userId);
  }

  Stream<List<BoxModel>> getRecentBoxes(String userId) {
    return _firestoreService.getRecentBoxes(userId);
  }

  Future<List<String>> reserveBoxIds(
      String userId, int count, int startNumber) {
    return _firestoreService.reserveBoxIds(userId, count, startNumber);
  }
}
