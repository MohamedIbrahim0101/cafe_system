// lib/state/category_provider.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:premium_store/core/services/firebase_service.dart';
import '../core/models/category_model.dart';

class CategoryProvider extends ChangeNotifier {
  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  String? _restaurantId;
  StreamSubscription? _subscription;

  // ============================================================
  // Getters
  // ============================================================

  List<CategoryModel> get categories => _categories;

  bool get isLoading => _isLoading;

  String? get restaurantId => _restaurantId;

  CategoryProvider();

  // ============================================================
  // Update Restaurant ID
  // ============================================================

  void updateRestaurantId(String? restaurantId) {
    if (_restaurantId != restaurantId) {
      _restaurantId = restaurantId;

      // إعادة الاستماع لأقسام المطعم الجديد
      _listenToCategories();
    }
  }

  // ============================================================
  // Listen To Categories
  // ============================================================

  void _listenToCategories() {
    // إلغاء الاشتراك القديم
    // لمنع تداخل البيانات أو memory leaks
    _subscription?.cancel();

    if (_restaurantId == null || _restaurantId!.isEmpty) {
      _categories = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    // الاستماع إلى categories الخاصة بالمطعم الحالي
    //
    // snapshots() ستظل مسؤولة عن الـ realtime updates
    _subscription = FirebaseService.restaurants
        .doc(_restaurantId)
        .collection('categories')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        _categories = snapshot.docs
            .map(
              (doc) => CategoryModel.fromSnapshot(doc),
            )
            .toList();

        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint(
          "❌ Error in CategoryProvider stream: $error",
        );

        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // ============================================================
  // 🔥 Refresh Categories From Firebase Server
  // ============================================================
  //
  // هذه الدالة مختلفة عن snapshots().
  //
  // snapshots() ممكن تبدأ بالبيانات الموجودة في الـ cache.
  //
  // أما هنا فنطلب صراحةً البيانات من Firebase Server.
  //
  // الهدف:
  // عند فتح QR Menu على iPhone أو أي جهاز،
  // نقدر نطلب أحدث categories مباشرة من السيرفر.
  //
  // مهم:
  // لا نقوم بإلغاء Offline Persistence من التطبيق كله.
  // ============================================================

  Future<void> refreshFromServer() async {
    if (_restaurantId == null || _restaurantId!.isEmpty) {
      return;
    }

    try {
      final snapshot = await FirebaseService.restaurants
          .doc(_restaurantId)
          .collection('categories')
          .orderBy('createdAt', descending: true)
          .get(
            const GetOptions(
              source: Source.server,
            ),
          );

      _categories = snapshot.docs
          .map(
            (doc) => CategoryModel.fromSnapshot(doc),
          )
          .toList();

      _isLoading = false;

      notifyListeners();

      debugPrint(
        "✅ Categories refreshed from Firebase Server",
      );
    } catch (e) {
      debugPrint(
        "❌ Error refreshing categories from server: $e",
      );

      // لا نمسح البيانات الموجودة.
      //
      // لو الإنترنت فيه مشكلة، نخلي البيانات الموجودة
      // سواء كانت من cache أو من آخر snapshot.
    }
  }

  // ============================================================
  // Add Category
  // ============================================================

  Future<void> addCategory(
    String categoryName, {
    String? imageUrl,
  }) async {
    if (_restaurantId == null || _restaurantId!.isEmpty) {
      throw Exception(
        "لا يوجد مطعم محدد لإضافة القسم إليه!",
      );
    }

    final trimmedName = categoryName.trim();

    if (trimmedName.isEmpty) {
      return;
    }

    try {
      await FirebaseService.restaurants
          .doc(_restaurantId)
          .collection('categories')
          .add({
        'name': trimmedName,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint(
        "❌ Error adding category: $e",
      );

      rethrow;
    }
  }

  // ============================================================
  // Update Category
  // ============================================================

  Future<void> updateCategory(
    String categoryId,
    String newName, {
    String? imageUrl,
  }) async {
    if (_restaurantId == null || _restaurantId!.isEmpty) {
      return;
    }

    final trimmedName = newName.trim();

    if (trimmedName.isEmpty) {
      return;
    }

    try {
      final Map<String, dynamic> updateData = {
        'name': trimmedName,
      };

      // تحديث الصورة فقط إذا تم إرسال صورة جديدة
      if (imageUrl != null) {
        updateData['imageUrl'] = imageUrl;
      }

      await FirebaseService.restaurants
          .doc(_restaurantId)
          .collection('categories')
          .doc(categoryId)
          .update(updateData);
    } catch (e) {
      debugPrint(
        "❌ Error updating category: $e",
      );

      rethrow;
    }
  }

  // ============================================================
  // Delete Category
  // ============================================================

  Future<void> deleteCategory(String categoryId) async {
    if (_restaurantId == null || _restaurantId!.isEmpty) {
      return;
    }

    try {
      await FirebaseService.restaurants
          .doc(_restaurantId)
          .collection('categories')
          .doc(categoryId)
          .delete();
    } catch (e) {
      debugPrint(
        "❌ Error deleting category: $e",
      );

      rethrow;
    }
  }

  // ============================================================
  // Get Category Name
  // ============================================================

  String getCategoryName(String id) {
    try {
      return _categories
          .firstWhere(
            (category) => category.id == id,
          )
          .name;
    } catch (e) {
      return "Unknown";
    }
  }

  // ============================================================
  // Dispose
  // ============================================================

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}