import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel { // غيرنا الاسم هنا ليتطابق مع الـ Provider والـ Screen
  final String id;
  final String name;
  final String? imageUrl; // أضفنا هذا الحقل لعرض الصور
  final DateTime createdAt;

  CategoryModel({
    required this.id, 
    required this.name, 
    this.imageUrl, 
    required this.createdAt
  });

  factory CategoryModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return CategoryModel(
      id: snapshot.id,
      name: data['name'] ?? 'Unnamed Category',
      imageUrl: data['imageUrl'], // استقبال رابط الصورة من فيربيز
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name, 
    'imageUrl': imageUrl, 
    'createdAt': createdAt
  };
}