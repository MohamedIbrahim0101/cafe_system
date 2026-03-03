import 'package:flutter/material.dart';
import 'package:premium_store/core/services/firebase_service.dart';
import '../core/models/category_model.dart';

class CategoryProvider extends ChangeNotifier {
  List<CategoryModel> _categories = [];
  bool _isLoading = true; // متغير لمتابعة حالة التحميل

  // Getters
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;

  CategoryProvider() {
    _listenToCategories();
  }

  void _listenToCategories() {
    FirebaseService.categories.snapshots().listen(
      (snapshot) {
        _categories = snapshot.docs
            .map((doc) => CategoryModel.fromSnapshot(doc))
            .toList();

        // بمجرد وصول أول نسخة من البيانات، نوقف حالة التحميل
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint("Error in CategoryProvider: $error");
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // دالة مساعدة للحصول على اسم القسم من الـ ID (مفيدة في شاشة المنتجات)
  String getCategoryName(String id) {
    try {
      return _categories.firstWhere((cat) => cat!.id == id).name;
    } catch (e) {
      return "Unknown";
    }
  }
}
