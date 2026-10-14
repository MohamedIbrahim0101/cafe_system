
// lib/state/restaurant_provider.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:premium_store/core/services/firebase_service.dart';
import '../core/models/restaurant_model.dart';

class RestaurantProvider extends ChangeNotifier {
  Restaurant? _restaurant;
  bool _loading = true;
  String? _restaurantId;

  StreamSubscription<DocumentSnapshot>? _restaurantSubscription;

  // ============================================================
  // Getters
  // ============================================================

  Restaurant? get restaurant => _restaurant;

  bool get loading => _loading;

  String? get restaurantId => _restaurantId;

  RestaurantProvider();

  // ============================================================
  // Update Restaurant ID
  // ============================================================

  /// يتم استدعاؤها من AuthProvider عن طريق ProxyProvider.
  ///
  /// عندما يتغير restaurantId:
  /// 1. نلغي الـ listener القديم.
  /// 2. نربط الـ provider بالمطعم الجديد.
  /// 3. نبدأ الاستماع لبيانات المطعم الجديد.
  void updateRestaurantId(String? restaurantId) {
    // لا نعيد التحميل إذا كان نفس الـ ID
    if (_restaurantId == restaurantId) {
      return;
    }

    // إلغاء الـ listener القديم أولاً
    _restaurantSubscription?.cancel();
    _restaurantSubscription = null;

    // تحديث restaurantId
    _restaurantId = restaurantId;

    // ============================================================
    // لا يوجد restaurantId
    // ============================================================

    if (_restaurantId == null || _restaurantId!.isEmpty) {
      _restaurant = null;
      _loading = false;

      notifyListeners();
      return;
    }

    // ============================================================
    // يوجد restaurantId
    // ============================================================

    _listenToRestaurant();
  }

  // ============================================================
  // Listen To Restaurant
  // ============================================================

  /// الاستماع المباشر لبيانات المطعم من Firestore.
  ///
  /// snapshots() تعطي:
  /// - بيانات من cache إذا كانت موجودة.
  /// - ثم بيانات server عند توفرها.
  /// - وتستمر في استقبال التحديثات Realtime.
  void _listenToRestaurant() {
    final currentRestaurantId = _restaurantId;

    if (currentRestaurantId == null ||
        currentRestaurantId.isEmpty) {
      _restaurant = null;
      _loading = false;

      notifyListeners();
      return;
    }

    _loading = true;
    notifyListeners();

    _restaurantSubscription = FirebaseService.restaurants
        .doc(currentRestaurantId)
        .snapshots()
        .listen(
      (snapshot) {
        // ========================================================
        // حماية من وصول Snapshot قديم
        // ========================================================
        //
        // لو المستخدم غير المطعم أثناء وجود listener قديم،
        // لا نسمح للـ snapshot القديم بتغيير البيانات الحالية.
        if (_restaurantId != currentRestaurantId) {
          return;
        }

        if (snapshot.exists) {
          _restaurant = Restaurant.fromSnapshot(snapshot);
        } else {
          _restaurant = null;
        }

        _loading = false;

        notifyListeners();
      },
      onError: (error) {
        // لا نمسح البيانات الحالية في حالة الخطأ.
        // خصوصًا مع Offline Persistence.
        debugPrint(
          '❌ Error fetching restaurant details: $error',
        );

        if (_restaurantId != currentRestaurantId) {
          return;
        }

        _loading = false;

        notifyListeners();
      },
    );
  }

  // ============================================================
  // Refresh Restaurant From Firebase Server
  // ============================================================

  /// إجبار Firestore على قراءة بيانات المطعم من Server.
  ///
  /// نستخدمها عندما نحتاج أحدث نسخة من بيانات المطعم،
  /// مثل QR Menu.
  ///
  /// Offline Persistence تظل مفعلة في التطبيق بالكامل.
  Future<void> refreshFromServer() async {
    final currentRestaurantId = _restaurantId;

    if (currentRestaurantId == null ||
        currentRestaurantId.isEmpty) {
      return;
    }

    try {
      final snapshot = await FirebaseService.restaurants
          .doc(currentRestaurantId)
          .get(
            const GetOptions(
              source: Source.server,
            ),
          );

      // ==========================================================
      // التأكد أن المستخدم ما زال على نفس المطعم
      // ==========================================================

      if (_restaurantId != currentRestaurantId) {
        return;
      }

      if (snapshot.exists) {
        _restaurant = Restaurant.fromSnapshot(snapshot);
      } else {
        _restaurant = null;
      }

      _loading = false;

      notifyListeners();

      debugPrint(
        '✅ Restaurant refreshed from Firebase Server',
      );
    } catch (e) {
      debugPrint(
        '❌ Error refreshing restaurant from server: $e',
      );

      // ==========================================================
      // مهم:
      // لا نمسح البيانات الحالية إذا فشل الاتصال بالـ Server.
      //
      // Firestore Cache ما زالت متاحة.
      // ==========================================================
    }
  }

  // ============================================================
  // Load Restaurant
  // ============================================================

  /// تحميل مطعم بشكل مباشر.
  ///
  /// يمكن استخدامها إذا أردت تحميل مطعم معين باستخدام customId.
  ///
  /// في الاستخدام العادي داخل التطبيق:
  /// updateRestaurantId() + snapshots()
  /// هما المسؤولان عن تحميل المطعم.
  Future<void> load({
    String? customId,
  }) async {
    final targetId = customId ?? _restaurantId;

    if (targetId == null || targetId.isEmpty) {
      _loading = false;

      notifyListeners();
      return;
    }

    _loading = true;

    notifyListeners();

    try {
      final doc = await FirebaseService.restaurants
          .doc(targetId)
          .get();

      // ==========================================================
      // إذا كان هذا تحميل المطعم الحالي
      // ==========================================================

      if (customId == null &&
          _restaurantId != targetId) {
        return;
      }

      if (doc.exists) {
        _restaurant = Restaurant.fromSnapshot(doc);
      } else {
        _restaurant = null;
      }
    } catch (e) {
      debugPrint(
        '❌ Error loading restaurant: $e',
      );
    } finally {
      if (customId == null &&
          _restaurantId != targetId) {
        return;
      }

      _loading = false;

      notifyListeners();
    }
  }

  // ============================================================
  // Update Restaurant Details
  // ============================================================

  /// تحديث بيانات المطعم.
  Future<void> updateRestaurantDetails({
    required String name,
    String? logoUrl,
    String? coverImageUrl,
  }) async {
    final currentRestaurantId = _restaurantId;

    if (currentRestaurantId == null ||
        currentRestaurantId.isEmpty) {
      return;
    }

    try {
      final Map<String, dynamic> updateData = {
        'name': name.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (logoUrl != null && logoUrl.isNotEmpty) {
        updateData['logoUrl'] = logoUrl;
      }

      if (coverImageUrl != null &&
          coverImageUrl.isNotEmpty) {
        updateData['coverImageUrl'] = coverImageUrl;
      }

      await FirebaseService.restaurants
          .doc(currentRestaurantId)
          .update(updateData);

      debugPrint(
        '✅ Restaurant details updated successfully',
      );
    } catch (e) {
      debugPrint(
        '❌ Error updating restaurant details: $e',
      );

      rethrow;
    }
  }

  // ============================================================
  // Dispose
  // ============================================================

  @override
  void dispose() {
    _restaurantSubscription?.cancel();
    _restaurantSubscription = null;

    super.dispose();
  }
}
