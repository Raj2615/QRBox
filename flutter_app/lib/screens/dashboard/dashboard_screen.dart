import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/box_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/box_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final stats = ref.watch(userStatsProvider);
    final recentBoxes = ref.watch(recentBoxesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${user?.displayName?.split(' ').first ?? 'User'} 👋',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              AppStrings.appTagline,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () => ref.read(authServiceProvider).signOut(),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userStatsProvider);
          ref.invalidate(recentBoxesProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats
              stats.when(
                data: (data) => Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: AppStrings.totalBoxes,
                        value: '${data['totalBoxes'] ?? 0}',
                        icon: Icons.inventory_2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: AppStrings.totalItems,
                        value: '${data['totalItems'] ?? 0}',
                        icon: Icons.category,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
                loading: () => const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('Error: $e'),
              ),

              const SizedBox(height: 28),

              // Quick Actions
              Text(
                AppStrings.quickActions,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.qr_code_scanner,
                      label: AppStrings.scanQR,
                      color: AppColors.primary,
                      onTap: () => context.go('/scan'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.qr_code,
                      label: AppStrings.generateQR,
                      color: AppColors.accent,
                      onTap: () => context.go('/generate'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.add_box_outlined,
                      label: AppStrings.addBox,
                      color: AppColors.warning,
                      onTap: () => context.go('/add-box'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.search,
                      label: AppStrings.search,
                      color: AppColors.primaryDark,
                      onTap: () => context.go('/search'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Recent Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.recentBoxes,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/boxes'),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              recentBoxes.when(
                data: (boxes) {
                  if (boxes.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 48,
                                color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              'No boxes yet',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () => context.go('/generate'),
                              icon: const Icon(Icons.qr_code, size: 18),
                              label: const Text('Generate QR Codes'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: boxes
                        .map((box) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: BoxCard(
                                box: box,
                                onTap: () => context.push('/boxes/${box.id}'),
                              ),
                            ))
                        .toList(),
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
