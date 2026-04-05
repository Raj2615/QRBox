import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/box_repository.dart';
import '../../models/box_model.dart';
import '../../widgets/loading_overlay.dart';

class AddEditBoxScreen extends ConsumerStatefulWidget {
  final String? boxId;

  const AddEditBoxScreen({super.key, this.boxId});

  @override
  ConsumerState<AddEditBoxScreen> createState() => _AddEditBoxScreenState();
}

class _AddEditBoxScreenState extends ConsumerState<AddEditBoxScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _pinController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  bool _isEdit = false;
  BoxModel? _existingBox;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.boxId != null;
    if (_isEdit) {
      _loadBox();
    }
  }

  Future<void> _loadBox() async {
    setState(() => _isLoading = true);
    final repo = ref.read(boxRepositoryProvider);
    final box = await repo.getBox(widget.boxId!);
    if (box != null && mounted) {
      setState(() {
        _existingBox = box;
        _nameController.text = box.name;
        _locationController.text = box.location;
        _descriptionController.text = box.description ?? '';
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _pinController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(boxRepositoryProvider);
      final user = ref.read(currentUserProvider);

      if (_isEdit && _existingBox != null) {
        // Update existing box
        final updated = _existingBox!.copyWith(
          name: _nameController.text.trim(),
          location: _locationController.text.trim(),
          description: _descriptionController.text.trim(),
          isConfigured: true,
        );
        await repo.updateBox(
          updated,
          newPin:
              _pinController.text.isNotEmpty ? _pinController.text : null,
        );
      } else {
        // Create new box - generate a new ID
        final nextNum = await repo.getNextBoxNumber(user!.uid);
        final boxId = BoxModel.generateBoxId(nextNum);

        await repo.createBox(
          boxId: boxId,
          ownerId: user.uid,
          name: _nameController.text.trim(),
          location: _locationController.text.trim(),
          pin: _pinController.text,
          description: _descriptionController.text.trim(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Box updated!' : 'Box created!'),
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
        title: Text(_isEdit ? AppStrings.editBox : AppStrings.addBox),
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
                TextFormField(
                  controller: _nameController,
                  validator: Validators.name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: AppStrings.boxName,
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                    hintText: 'e.g., Electronics Box',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  validator: (v) => Validators.required(v, 'Location'),
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: AppStrings.boxLocation,
                    prefixIcon: Icon(Icons.location_on_outlined),
                    hintText: 'e.g., Garage Shelf 3',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  validator: _isEdit ? null : Validators.pin,
                  decoration: InputDecoration(
                    labelText: _isEdit
                        ? '${AppStrings.boxPin} (leave empty to keep current)'
                        : AppStrings.boxPin,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    hintText: 'e.g., 1234',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: '${AppStrings.boxDescription} (Optional)',
                    prefixIcon: Icon(Icons.description_outlined),
                    hintText: 'What does this box contain?',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    icon: Icon(_isEdit ? Icons.save : Icons.add),
                    label: Text(_isEdit ? 'Save Changes' : 'Create Box'),
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
