import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item_model.dart';
import '../repositories/item_repository.dart';

/// Stream of items for a specific box
final boxItemsProvider =
    StreamProvider.family<List<ItemModel>, String>((ref, boxId) {
  final repo = ref.watch(itemRepositoryProvider);
  return repo.getBoxItems(boxId);
});

/// Search results
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<ItemModel>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];
  // userId will need to be passed; handled in the UI
  return [];
});
