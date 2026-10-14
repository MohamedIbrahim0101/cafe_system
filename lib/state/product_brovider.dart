// lib/state/product_provider.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:premium_store/core/services/firebase_service.dart';
import '../core/models/product_model.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;
  String? _restaurantId;

  Map<String, List<Product>> _productsByCategory = {};

  StreamSubscription<QuerySnapshot>? _productsSubscription;

  // ============================================================
  // Getters
  // ============================================================

  List<Product> get products => _products;

  bool get isLoading => _isLoading;

  String? get restaurantId => _restaurantId;

  ProductProvider();

  // ============================================================
  // Update Restaurant ID
  // ============================================================

  // يتم استدعاؤها من ProxyProvider
  // عندما يتغير restaurantId في AuthProvider
  void updateRestaurantId(String? restaurantId) {
    debugPrint(
      '🏪 ProductProvider received restaurantId: $restaurantId',
    );

    if (_restaurantId != restaurantId) {
      _restaurantId = restaurantId;

      debugPrint(
        '📍 Products Firestore path: '
        'restaurants/$_restaurantId/products',
      );

      // إعادة الاستماع لمنتجات المطعم الجديد
      _initProducts();
    }
  }

  // ============================================================
  // Initialize Products / Realtime Listener
  // ============================================================

  void _initProducts() {
    // إلغاء الاشتراك القديم
    _productsSubscription?.cancel();

    debugPrint(
      '📦 Starting products listener for restaurant: $_restaurantId',
    );

    // لو مفيش restaurantId
    if (_restaurantId == null || _restaurantId!.isEmpty) {
      debugPrint(
        '⚠️ ProductProvider has no restaurantId',
      );

      _products = [];
      _productsByCategory = {};

      _setLoading(false);

      return;
    }

    _setLoading(true);

    final productsReference = FirebaseService.restaurants
        .doc(_restaurantId)
        .collection('products');

    debugPrint(
      '🔥 Listening to Firestore collection: '
      '${productsReference.path}',
    );

    // الاستماع لمنتجات المطعم المحدد فقط
    _productsSubscription = productsReference.snapshots().listen(
      (snapshot) {
        debugPrint(
          '📦 Firestore returned '
          '${snapshot.docs.length} products '
          'for restaurant $_restaurantId',
        );

        try {
          _products = snapshot.docs
              .map(
                (doc) {
                  debugPrint(
                    '📄 Product document: ${doc.id}',
                  );

                  return Product.fromSnapshot(doc);
                },
              )
              .toList();

          // ترتيب المنتجات حسب التاريخ محلياً
          // لتجنب الحاجة إلى Firestore Index
          _products.sort(
            (a, b) => b.createdAt.compareTo(a.createdAt),
          );

          _rebuildProductsByCategory();

          debugPrint(
            '✅ Products loaded successfully: '
            '${_products.length}',
          );

          _setLoading(false);
        } catch (e, stackTrace) {
          debugPrint(
            '❌ Error parsing products: $e',
          );

          debugPrint(
            '📌 StackTrace: $stackTrace',
          );

          _setLoading(false);
        }
      },
      onError: (error, stackTrace) {
        _setLoading(false);

        debugPrint(
          '❌ Error fetching products from Firestore: $error',
        );

        debugPrint(
          '📌 Products path: '
          'restaurants/$_restaurantId/products',
        );

        debugPrint(
          '📌 StackTrace: $stackTrace',
        );
      },
    );
  }

  // ============================================================
  // Rebuild Products By Category
  // ============================================================

  void _rebuildProductsByCategory() {
    _productsByCategory = {};

    for (final product in _products) {
      _productsByCategory
          .putIfAbsent(
            product.categoryId,
            () => [],
          )
          .add(product);
    }
  }

  // ============================================================
  // Loading State
  // ============================================================

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ============================================================
  // Refresh Products Directly From Firebase Server
  // ============================================================

  Future<void> refreshFromServer() async {
    if (_restaurantId == null || _restaurantId!.isEmpty) {
      debugPrint(
        '⚠️ Cannot refresh products: restaurantId is empty',
      );

      return;
    }

    try {
      debugPrint(
        '🌐 Refreshing products from Firebase Server...',
      );

      debugPrint(
        '📍 Server path: '
        'restaurants/$_restaurantId/products',
      );

      final snapshot = await FirebaseService.restaurants
          .doc(_restaurantId)
          .collection('products')
          .get(
            const GetOptions(
              source: Source.server,
            ),
          );

      debugPrint(
        '🌐 Server returned '
        '${snapshot.docs.length} products',
      );

      try {
        _products = snapshot.docs
            .map(
              (doc) => Product.fromSnapshot(doc),
            )
            .toList();

        // ترتيب المنتجات حسب التاريخ
        _products.sort(
          (a, b) => b.createdAt.compareTo(a.createdAt),
        );

        // إعادة بناء المنتجات حسب الـ category
        _rebuildProductsByCategory();

        _isLoading = false;

        notifyListeners();

        debugPrint(
          '✅ Products refreshed successfully from Firebase Server',
        );
      } catch (e, stackTrace) {
        debugPrint(
          '❌ Error parsing server products: $e',
        );

        debugPrint(
          '📌 StackTrace: $stackTrace',
        );
      }
    } catch (e, stackTrace) {
      debugPrint(
        '❌ Error refreshing products from server: $e',
      );

      debugPrint(
        '📌 StackTrace: $stackTrace',
      );

      // لا نمسح البيانات الحالية في حالة فشل الاتصال.
      //
      // لو الإنترنت غير متاح، نترك البيانات الموجودة
      // سواء كانت من cache أو من آخر snapshot.
    }
  }

  // ============================================================
  // Get Products By Category
  // ============================================================

  List<Product> getProductsByCategory(String categoryId) {
    return _productsByCategory[categoryId] ?? [];
  }

  // ============================================================
  // Get Product By ID
  // ============================================================

  Product? getProductById(String id) {
    try {
      return _products.firstWhere(
        (product) => product.id == id,
      );
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // Add Product
  // ============================================================

  Future<void> addProduct(Product product) async {
    if (_restaurantId == null || _restaurantId!.isEmpty) {
      throw Exception(
        "لا يوجد مطعم محدد لإضافة المنتج إليه!",
      );
    }

    try {
      debugPrint(
        '➕ Adding product to restaurant: $_restaurantId',
      );

      debugPrint(
        '📍 Add path: '
        'restaurants/$_restaurantId/products',
      );

      final productMap = product.toMap();

      productMap['createdAt'] =
          FieldValue.serverTimestamp();

      final documentReference = await FirebaseService.restaurants
          .doc(_restaurantId)
          .collection('products')
          .add(productMap);

      debugPrint(
        '✅ Product added successfully',
      );

      debugPrint(
        '🆔 New product ID: ${documentReference.id}',
      );

      debugPrint(
        '📍 Full document path: '
        '${documentReference.path}',
      );
    } catch (e, stackTrace) {
      debugPrint(
        '❌ Error adding product: $e',
      );

      debugPrint(
        '📌 StackTrace: $stackTrace',
      );

      rethrow;
    }
  }

  // ============================================================
  // Update Product
  // ============================================================

  Future<void> updateProduct(Product product) async {
    if (_restaurantId == null || _restaurantId!.isEmpty) {
      debugPrint(
        '⚠️ Cannot update product: restaurantId is empty',
      );

      return;
    }

    try {
      debugPrint(
        '✏️ Updating product: ${product.id}',
      );

      debugPrint(
        '📍 Update path: '
        'restaurants/$_restaurantId/products/${product.id}',
      );

      final productMap = product.toMap();

      productMap['updatedAt'] =
          FieldValue.serverTimestamp();

      await FirebaseService.restaurants
          .doc(_restaurantId)
          .collection('products')
          .doc(product.id)
          .update(productMap);

      debugPrint(
        '✅ Product updated successfully',
      );
    } catch (e, stackTrace) {
      debugPrint(
        '❌ Error updating product: $e',
      );

      debugPrint(
        '📌 StackTrace: $stackTrace',
      );

      rethrow;
    }
  }

  // ============================================================
  // Delete Product
  // ============================================================

  Future<void> deleteProduct(String id) async {
    if (_restaurantId == null || _restaurantId!.isEmpty) {
      debugPrint(
        '⚠️ Cannot delete product: restaurantId is empty',
      );

      return;
    }

    try {
      debugPrint(
        '🗑️ Deleting product: $id',
      );

      debugPrint(
        '📍 Delete path: '
        'restaurants/$_restaurantId/products/$id',
      );

      await FirebaseService.restaurants
          .doc(_restaurantId)
          .collection('products')
          .doc(id)
          .delete();

      debugPrint(
        '✅ Product deleted successfully',
      );
    } catch (e, stackTrace) {
      debugPrint(
        '❌ Delete error: $e',
      );

      debugPrint(
        '📌 StackTrace: $stackTrace',
      );

      rethrow;
    }
  }

  // ============================================================
  // Toggle Product Availability
  // ============================================================

  Future<void> toggleAvailability(
    String id,
    bool status,
  ) async {
    if (_restaurantId == null || _restaurantId!.isEmpty) {
      debugPrint(
        '⚠️ Cannot toggle product: restaurantId is empty',
      );

      return;
    }

    try {
      // ========================================================
      // 1. تحديث الحالة محلياً فوراً
      // ========================================================

      final index = _products.indexWhere(
        (product) => product.id == id,
      );

      if (index != -1) {
        _products[index] = _products[index].copyWith(
          isAvailable: status,
        );

        _rebuildProductsByCategory();

        notifyListeners();
      }

      // ========================================================
      // 2. تحديث Firestore
      // ========================================================

      debugPrint(
        '🔄 Updating availability for product: $id',
      );

      debugPrint(
        '📍 Availability path: '
        'restaurants/$_restaurantId/products/$id',
      );

      await FirebaseService.restaurants
          .doc(_restaurantId)
          .collection('products')
          .doc(id)
          .update({
        'isAvailable': status,
      });

      debugPrint(
        '✅ Product availability updated: $status',
      );
    } catch (e, stackTrace) {
      debugPrint(
        '❌ Update error: $e',
      );

      debugPrint(
        '📌 StackTrace: $stackTrace',
      );

      // في حالة حدوث خطأ نعيد الاستماع
      // إلى البيانات من Firestore
      _initProducts();

      rethrow;
    }
  }

  // ============================================================
  // Dispose
  // ============================================================

  @override
  void dispose() {
    _productsSubscription?.cancel();

    debugPrint(
      '🧹 ProductProvider disposed',
    );

    super.dispose();
  }
}
