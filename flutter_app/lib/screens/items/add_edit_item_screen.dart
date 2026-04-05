import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/item_repository.dart';
import '../../services/storage_service.dart';
import '../../services/firestore_service.dart';
import '../../models/item_model.dart';
import '../../widgets/loading_overlay.dart';

class AddEditItemScreen extends ConsumerStatefulWidget {
  final String boxId;
  final String? itemId;

  const AddEditItemScreen({super.key, required this.boxId, this.itemId});

  @override
  ConsumerState<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends ConsumerState<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  bool _isEdit = false;
  ItemModel? _existingItem;
  File? _imageFile;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.itemId != null;
    if (_isEdit) {
      _loadItem();
    }
  }

  Future<void> _loadItem() async {
    setState(() => _isLoading = true);
    final firestore = ref.read(firestoreServiceProvider);
    final items = await firestore.getBoxItems(widget.boxId).first;
    final item = items.where((i) => i.id == widget.itemId).firstOrNull;

    if (item != null && mounted) {
      setState(() {
        _existingItem = item;
        _nameController.text = item.name;
        _quantityController.text = item.quantity.toString();
        _descriptionController.text = item.description ?? '';
        _existingImageUrl = item.imageUrl;
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final storageService = ref.read(storageServiceProvider);
    final file = await storageService.pickImage();
    if (file != null && mounted) {
      setState(() => _imageFile = file);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(itemRepositoryProvider);
      final user = ref.read(currentUserProvider);

      if (_isEdit && _existingItem != null) {
        final updated = _existingItem!.copyWith(
          name: _nameController.text.trim(),
          quantity: int.parse(_quantityController.text),
          description: _descriptionController.text.trim(),
        );
        await repo.updateItem(updated, newImageFile: _imageFile);
      } else {
        await repo.addItem(
          boxId: widget.boxId,
          ownerId: user!.uid,
          name: _nameController.text.trim(),
          quantity: int.parse(_quantityController.text),
          description: _descriptionController.text.trim(),
          imageFile: _imageFile,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Item updated!' : 'Item added!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? AppStrings.editItem : AppStrings.addItem),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image picker
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              _imageFile!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          )
                        : _existingImageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  _existingImageUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined,
                                      size: 48, color: Colors.grey.shade400),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to add photo',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                            color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                  ),
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _nameController,
                  validator: Validators.name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: AppStrings.itemName,
                    prefixIcon: Icon(Icons.category_outlined),
                    hintText: 'e.g., HDMI Cable',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  validator: Validators.quantity,
                  decoration: const InputDecoration(
                    labelText: AppStrings.quantity,
                    prefixIcon: Icon(Icons.numbers),
                    hintText: 'e.g., 2',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: '${AppStrings.description} (Optional)',
                    prefixIcon: Icon(Icons.description_outlined),
                    hintText: 'Any additional details...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    icon: Icon(_isEdit ? Icons.save : Icons.add),
                    label: Text(_isEdit ? 'Save Changes' : 'Add Item'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
