import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/box_provider.dart';
import '../../widgets/box_card.dart';

class BoxListScreen extends ConsumerWidget {
  const BoxListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boxesAsync = ref.watch(userBoxesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.myBoxes),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/add-box'),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.addBox),
      ),
      body: boxesAsync.when(
        data: (boxes) {
          if (boxes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No boxes yet',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Generate QR codes or add a box to get started',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/generate'),
                    icon: const Icon(Icons.qr_code),
                    label: const Text(AppStrings.generateQR),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: boxes.length,
            itemBuilder: (context, index) {
              final box = boxes[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: BoxCard(
                  box: box,
                  onTap: () {
                    if (box.isConfigured) {
                      context.push('/boxes/${box.id}');
                    } else {
                      context.push('/boxes/${box.id}/edit');
                    }
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Error: $e'),
            ],
          ),
        ),
      ),
    );
  }
}
