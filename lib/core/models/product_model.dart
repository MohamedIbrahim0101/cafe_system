// lib/core/models/product_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app/constants.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price; // السعر الأساسي في حالة عدم وجود أحجام
  final String imageUrl;
  final String categoryId;
  final bool isAvailable;
  final DateTime createdAt;
  
  // --- الإضافات الجديدة الخاصة بالأحجام ---
  final bool hasSizes;
  final Map<String, double> sizes;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.categoryId,
    required this.isAvailable,
    required this.createdAt,
    // قيم افتراضية عشان الكود القديم ميبُظش ويطلبهم بالإجبار
    this.hasSizes = false, 
    this.sizes = const {}, 
  });

  factory Product.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;

    // معالجة آمنة لخريطة الأسعار (الأحجام) الجاية من الفايربيز
    Map<String, double> parsedSizes = {};
    if (data['sizes'] != null) {
      final sizesData = data['sizes'] as Map<String, dynamic>;
      sizesData.forEach((key, value) {
        // بنحول القيمة لـ double بأمان عشان الفايربيز أحياناً بيرجع الأرقام int
        parsedSizes[key] = (value as num).toDouble();
      });
    }

    return Product(
      id: snapshot.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: imageUrlResize(data['imageUrl']),
      categoryId: data['categoryId'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      // قراءة البيانات الجديدة
      hasSizes: data['hasSizes'] ?? false,
      sizes: parsedSizes,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'price': price,
        'imageUrl': imageUrl,
        'categoryId': categoryId,
        'isAvailable': isAvailable,
        'createdAt': createdAt,
        // حفظ البيانات الجديدة
        'hasSizes': hasSizes,
        'sizes': sizes,
      };
}