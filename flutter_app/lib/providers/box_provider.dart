import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/box_model.dart';
import '../repositories/box_repository.dart';
import 'auth_provider.dart';

/// Stream of all user boxes
final userBoxesProvider = StreamProvider<List<BoxModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  final repo = ref.watch(boxRepositoryProvider);
  return repo.getUserBoxes(user.uid);
});

/// Stream of recent boxes for dashboard
final recentBoxesProvider = StreamProvider<List<BoxModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  final repo = ref.watch(boxRepositoryProvider);
  return repo.getRecentBoxes(user.uid);
});

/// User stats (total boxes, total items)
final userStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return {'totalBoxes': 0, 'totalItems': 0};
  final repo = ref.watch(boxRepositoryProvider);
  return repo.getUserStats(user.uid);
});

/// Single box by ID
final boxByIdProvider =
    FutureProvider.family<BoxModel?, String>((ref, boxId) async {
  final repo = ref.watch(boxRepositoryProvider);
  return repo.getBox(boxId);
});
