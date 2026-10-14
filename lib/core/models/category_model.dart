import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String? imageUrl;
  final DateTime createdAt;

  CategoryModel({
    required this.id, 
    required this.name, 
    this.imageUrl, 
    required this.createdAt,
  });

  factory CategoryModel.fromSnapshot(DocumentSnapshot snapshot) {
    // 🔥 تحويل آمن للـ data لمنع خطأ Web Type Cast (LegacyJavaScriptObject)
    final rawData = snapshot.data();
    final Map<String, dynamic> data =
        rawData != null ? Map<String, dynamic>.from(rawData as Map) : {};

    return CategoryModel(
      id: snapshot.id,
      name: data['name'] ?? 'Unnamed Category',
      imageUrl: data['imageUrl'] as String?,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name, 
    'imageUrl': imageUrl, 
    'createdAt': Timestamp.fromDate(createdAt),
  };
}