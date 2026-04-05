import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/box_provider.dart';
import '../../providers/item_provider.dart';
import '../../repositories/box_repository.dart';
import '../../widgets/item_tile.dart';
import '../../repositories/item_repository.dart';

class BoxDetailScreen extends ConsumerWidget {
  final String boxId;

  const BoxDetailScreen({super.key, required this.boxId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boxAsync = ref.watch(boxByIdProvider(boxId));
    final itemsAsync = ref.watch(boxItemsProvider(boxId));

    return boxAsync.when(
      data: (box) {
        if (box == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Box not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(box.name.isEmpty ? box.id : box.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push('/boxes/${box.id}/edit'),
                tooltip: AppStrings.editBox,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: () => _showDeleteDialog(context, ref),
                tooltip: AppStrings.deleteBox,
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/boxes/${box.id}/add-item'),
            icon: const Icon(Icons.add),
            label: const Text(AppStrings.addItem),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Box info card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.inventory_2,
                                color: AppColors.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    box.name.isEmpty ? 'Unnamed Box' : box.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                            fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    box.id,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                          fontFamily: 'monospace',
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        _InfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Location',
                          value: box.location.isEmpty
                              ? 'Not set'
                              : box.location,
                        ),
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.inventory_outlined,
                          label: 'Items',
                          value: '${box.itemCount}',
                        ),
                        if (box.description != null &&
                            box.description!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _InfoRow(
                            icon: Icons.description_outlined,
                            label: 'Description',
                            value: box.description!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // QR Code Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          'QR Code',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: QrImageView(
                            data: box.qrUrl,
                            version: QrVersions.auto,
                            size: 180,
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          box.qrUrl,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontFamily: 'monospace',
                                fontSize: 10,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _shareQR(context, box.id, box.qrUrl),
                            icon: const Icon(Icons.share, size: 18),
                            label: const Text('Share QR Code'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Items header
                Text(
                  'Items',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),

                // Items list
                itemsAsync.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.category_outlined,
                                  size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text(
                                'No items in this box',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                        color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap the + button to add items',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: items
                          .map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: ItemTile(
                                  item: item,
                                  onTap: () => context.push(
                                      '/boxes/$boxId/items/${item.id}/edit'),
                                  onDelete: () =>
                                      _showDeleteItemDialog(
                                          context, ref, item.id),
                                ),
                              ))
                          .toList(),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                ),

                const SizedBox(height: 80), // space for FAB
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.deleteBox),
        content: const Text(
            'Are you sure you want to delete this box and all its items? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(boxRepositoryProvider).deleteBox(boxId);
              context.go('/boxes');
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeleteItemDialog(
      BuildContext context, WidgetRef ref, String itemId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.deleteItem),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(itemRepositoryProvider).deleteItem(itemId, boxId);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareQR(BuildContext context, String boxId, String qrUrl) async {
    try {
      // Render QR code to PNG
      final qrPainter = QrPainter(
        data: qrUrl,
        version: QrVersions.auto,
        gapless: true,
      );
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      // Paint white background first (transparent PNG looks blank in most apps)
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 400, 400),
        Paint()..color = const Color(0xFFFFFFFF),
      );
      qrPainter.paint(canvas, const Size(400, 400));
      final picture = recorder.endRecording();
      final img = await picture.toImage(400, 400);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to generate QR image')),
          );
        }
        return;
      }

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/QRBox_$boxId.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      // Share
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'QRBox: $boxId\nScan to view contents: $qrUrl',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Share error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}
