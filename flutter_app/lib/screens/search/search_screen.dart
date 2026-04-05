import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/item_repository.dart';
import '../../models/item_model.dart';
import '../../services/firestore_service.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  List<ItemModel> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  // Cache box names for display
  final Map<String, String> _boxNames = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final repo = ref.read(itemRepositoryProvider);
      final items = await repo.searchItems(user.uid, query);

      // Fetch box names for results
      final firestore = ref.read(firestoreServiceProvider);
      for (final item in items) {
        if (!_boxNames.containsKey(item.boxId)) {
          final box = await firestore.getBox(item.boxId);
          _boxNames[item.boxId] = box?.name ?? item.boxId;
        }
      }

      if (mounted) {
        setState(() => _results = items);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.search),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: AppStrings.searchItems,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _results = [];
                            _hasSearched = false;
                          });
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _search,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Results
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : !_hasSearched
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search,
                                size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'Search items across all boxes',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                      color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : _results.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off,
                                    size: 64,
                                    color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  AppStrings.noResults,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                          color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _results.length,
                            itemBuilder: (context, index) {
                              final item = _results[index];
                              final boxName =
                                  _boxNames[item.boxId] ?? item.boxId;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                        Icons.category_outlined,
                                        color: AppColors.primary),
                                  ),
                                  title: Text(
                                    item.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Row(
                                    children: [
                                      const Icon(Icons.inventory_2,
                                          size: 14,
                                          color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(boxName),
                                    ],
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.accent.withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'x${item.quantity}',
                                      style: const TextStyle(
                                        color: AppColors.accentDark,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  onTap: () =>
                                      context.go('/boxes/${item.boxId}'),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
