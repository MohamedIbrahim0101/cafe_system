// lib/core/models/product_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app/constants.dart';

// ============================================================
// SIDE DISH MODEL
// ============================================================

class SideDish {
  final String name;
  final double price;

  SideDish({
    required this.name,
    required this.price,
  });

  factory SideDish.fromMap(Map<String, dynamic> map) {
    return SideDish(
      name: map['name'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
    };
  }
}

// ============================================================
// PRODUCT MODEL
// ============================================================

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;

  // ==========================================================
  // CATEGORY
  // ==========================================================

  final String categoryId;

  // ==========================================================
  // PRODUCT TYPE
  // food = طعام
  // drink = مشروب
  // ==========================================================

  final String productType;

  final bool isAvailable;
  final DateTime createdAt;

  // ==========================================================
  // SIZES
  // ==========================================================

  final bool hasSizes;
  final Map<String, double> sizes;

  // ==========================================================
  // SIDE DISHES
  // ==========================================================

  final List<SideDish> sideDishes;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.categoryId,
    this.productType = 'food',
    required this.isAvailable,
    required this.createdAt,
    this.hasSizes = false,
    this.sizes = const {},
    this.sideDishes = const [],
  });

  // ==========================================================
  // FROM FIRESTORE
  // ==========================================================

  factory Product.fromSnapshot(DocumentSnapshot snapshot) {
    final rawData = snapshot.data();

    final Map<String, dynamic> data =
        rawData != null
            ? Map<String, dynamic>.from(rawData as Map)
            : {};

    // ========================================================
    // SIZES
    // ========================================================

    Map<String, double> parsedSizes = {};

    if (data['sizes'] != null && data['sizes'] is Map) {
      final sizesData =
          Map<String, dynamic>.from(data['sizes'] as Map);

      sizesData.forEach((key, value) {
        if (value is num) {
          parsedSizes[key] = value.toDouble();
        }
      });
    }

    // ========================================================
    // SIDE DISHES
    // ========================================================

    List<SideDish> parsedSideDishes = [];

    if (data['sideDishes'] != null &&
        data['sideDishes'] is List) {
      final List<dynamic> sideDishesData =
          data['sideDishes'];

      parsedSideDishes = sideDishesData
          .whereType<Map>()
          .map(
            (item) => SideDish.fromMap(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    }

    // ========================================================
    // PRODUCT TYPE
    // ========================================================
    //
    // لو المنتج القديم مفيهوش productType
    // هنعتبره food بشكل افتراضي.
    //
    // القيم المستخدمة:
    // food  -> طعام
    // drink -> مشروب
    //
    // ========================================================

    final String productType =
        data['productType']?.toString() ?? 'food';

    // ========================================================
    // RETURN PRODUCT
    // ========================================================

    return Product(
      id: snapshot.id,

      name: data['name'] ?? '',

      description: data['description'] ?? '',

      price: (data['price'] as num?)?.toDouble() ?? 0.0,

      imageUrl: imageUrlResize(
        data['imageUrl'] ?? '',
      ),

      categoryId: data['categoryId'] ?? '',

      productType: productType,

      isAvailable: data['isAvailable'] ?? true,

      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ??
              DateTime.now(),

      hasSizes:
          data['hasSizes'] ?? false,

      sizes: parsedSizes,

      sideDishes: parsedSideDishes,
    );
  }

  // ==========================================================
  // TO FIRESTORE
  // ==========================================================

  Map<String, dynamic> toMap() => {
        'name': name,

        'description': description,

        'price': price,

        'imageUrl': imageUrl,

        'categoryId': categoryId,

        // ====================================================
        // PRODUCT TYPE
        // ====================================================

        'productType': productType,

        'isAvailable': isAvailable,

        'createdAt': Timestamp.fromDate(createdAt),

        'hasSizes': hasSizes,

        'sizes': sizes,

        // ====================================================
        // SIDE DISHES
        // ====================================================

        'sideDishes':
            sideDishes.map((side) => side.toMap()).toList(),
      };

  // ==========================================================
  // COPY WITH
  // ==========================================================

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? categoryId,
    String? productType,
    bool? isAvailable,
    DateTime? createdAt,
    bool? hasSizes,
    Map<String, double>? sizes,
    List<SideDish>? sideDishes,
  }) {
    return Product(
      id: id ?? this.id,

      name: name ?? this.name,

      description:
          description ?? this.description,

      price: price ?? this.price,

      imageUrl:
          imageUrl ?? this.imageUrl,

      categoryId:
          categoryId ?? this.categoryId,

      productType:
          productType ?? this.productType,

      isAvailable:
          isAvailable ?? this.isAvailable,

      createdAt:
          createdAt ?? this.createdAt,

      hasSizes:
          hasSizes ?? this.hasSizes,

      sizes:
          sizes ?? this.sizes,

      sideDishes:
          sideDishes ?? this.sideDishes,
    );
  }
}
