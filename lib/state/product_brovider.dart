// lib/state/product_provider.dart
import 'package:flutter/material.dart';
import 'package:premium_store/core/services/firebase_service.dart';
import '../core/models/product_model.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false; // المتغير الذي كان ينقصك
  Map<String, List<Product>> _productsByCategory = {};

  List<Product> get products => _products;
  bool get isLoading => _isLoading; // الـ Getter المطلوب في شاشة ProductsScreen

  ProductProvider() {
    _initProducts();
  }

  void _initProducts() {
    _setLoading(true);
    FirebaseService.products.snapshots().listen((snapshot) {
      _products =
          snapshot.docs.map((doc) => Product.fromSnapshot(doc)).toList();

      _productsByCategory = {};
      for (var product in _products) {
        _productsByCategory
            .putIfAbsent(product.categoryId, () => [])
            .add(product);
      }

      _setLoading(false);
      notifyListeners();
    }, onError: (error) {
      _setLoading(false);
      debugPrint("Error fetching products: $error");
    });
  }

  // دالة لتغيير حالة التحميل وتنبيه الواجهة
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  List<Product> getProductsByCategory(String categoryId) =>
      _productsByCategory[categoryId] ?? [];

  // دالة حذف منتج (نحتاجها في الأزرار التي برمجناها)
  Future<void> deleteProduct(String id) async {
    try {
      await FirebaseService.products.doc(id).delete();
    } catch (e) {
      debugPrint("Delete error: $e");
    }
  }

  // دالة تحديث توفر المنتج (Toggle Availability)
  Future<void> toggleAvailability(String id, bool status) async {
    try {
      await FirebaseService.products.doc(id).update({'isAvailable': status});
    } catch (e) {
      debugPrint("Update error: $e");
    }
  }
}
