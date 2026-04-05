import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/app_constants.dart';

final storageServiceProvider =
    Provider<StorageService>((ref) => StorageService());

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Pick an image from gallery or camera
  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: AppConstants.maxImageWidth,
      maxHeight: AppConstants.maxImageHeight,
      imageQuality: AppConstants.imageQuality,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  /// Upload an image for an item
  Future<String> uploadItemImage(String itemId, File file) async {
    final ref = _storage
        .ref()
        .child(AppConstants.itemImagesPath)
        .child(itemId)
        .child('photo.jpg');

    final uploadTask = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await uploadTask.ref.getDownloadURL();
  }

  /// Delete an item's image
  Future<void> deleteItemImage(String itemId) async {
    try {
      final ref = _storage
          .ref()
          .child(AppConstants.itemImagesPath)
          .child(itemId)
          .child('photo.jpg');
      await ref.delete();
    } catch (_) {
      // Image might not exist, ignore
    }
  }
}
