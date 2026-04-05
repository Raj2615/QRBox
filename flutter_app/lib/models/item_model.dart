import 'package:cloud_firestore/cloud_firestore.dart';

class ItemModel {
  final String id;
  final String boxId;
  final String ownerId;
  final String name;
  final int quantity;
  final String? description;
  final String? imageUrl;

  ItemModel({
    required this.id,
    required this.boxId,
    required this.ownerId,
    required this.name,
    required this.quantity,
    this.description,
    this.imageUrl,
  });

  factory ItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ItemModel(
      id: doc.id,
      boxId: data['boxId'] ?? '',
      ownerId: data['ownerId'] ?? '',
      name: data['name'] ?? '',
      quantity: data['quantity'] ?? 0,
      description: data['description'],
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'boxId': boxId,
      'ownerId': ownerId,
      'name': name,
      'quantity': quantity,
      'description': description,
      'imageUrl': imageUrl,
    };
  }

  ItemModel copyWith({
    String? id,
    String? boxId,
    String? ownerId,
    String? name,
    int? quantity,
    String? description,
    String? imageUrl,
  }) {
    return ItemModel(
      id: id ?? this.id,
      boxId: boxId ?? this.boxId,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
