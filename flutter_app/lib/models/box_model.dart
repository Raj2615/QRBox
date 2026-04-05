import 'package:cloud_firestore/cloud_firestore.dart';

class BoxModel {
  final String id;
  final String ownerId;
  final String name;
  final String location;
  final String pinHash;
  final String? description;
  final DateTime createdAt;
  final bool isConfigured;
  final int itemCount;

  BoxModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.location,
    required this.pinHash,
    this.description,
    required this.createdAt,
    this.isConfigured = false,
    this.itemCount = 0,
  });

  factory BoxModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BoxModel(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      name: data['name'] ?? '',
      location: data['location'] ?? '',
      pinHash: data['pinHash'] ?? '',
      description: data['description'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isConfigured: data['isConfigured'] ?? false,
      itemCount: data['itemCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'name': name,
      'location': location,
      'pinHash': pinHash,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'isConfigured': isConfigured,
      'itemCount': itemCount,
    };
  }

  BoxModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? location,
    String? pinHash,
    String? description,
    DateTime? createdAt,
    bool? isConfigured,
    int? itemCount,
  }) {
    return BoxModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      location: location ?? this.location,
      pinHash: pinHash ?? this.pinHash,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      isConfigured: isConfigured ?? this.isConfigured,
      itemCount: itemCount ?? this.itemCount,
    );
  }

  /// Generate a box ID like QRBOX-0001
  static String generateBoxId(int number) {
    return 'QRBOX-${number.toString().padLeft(4, '0')}';
  }

  /// Get the full QR URL for this box
  String get qrUrl => 'https://qrbox-cbcbb.web.app/box/$id';
}
