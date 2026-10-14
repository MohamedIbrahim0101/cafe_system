
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

// موديل بيانات المطعم
class Restaurant {
  final String id;
  final String name;
  final String adminEmail;
  final String adminPassword;
  final String adminUid;
  final String phoneNumber;
  final String location;
  final bool isActive;
  final DateTime createdAt;

  Restaurant({
    required this.id,
    required this.name,
    required this.adminEmail,
    required this.adminPassword,
    required this.adminUid,
    required this.phoneNumber,
    required this.location,
    required this.isActive,
    required this.createdAt,
  });

  factory Restaurant.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return Restaurant(
      id: documentId,
      name: map['name'] ?? '',
      adminEmail: map['adminEmail'] ?? '',
      adminPassword: map['adminPassword'] ?? '******',
      adminUid: map['adminUid'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      location: map['location'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'adminEmail': adminEmail,
      'adminPassword': adminPassword,
      'adminUid': adminUid,
      'phoneNumber': phoneNumber,
      'location': location,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class SuperAdminProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Restaurant> _restaurants = [];
  bool _isLoading = false;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _restaurantsSubscription;

  List<Restaurant> get restaurants => _restaurants;
  bool get isLoading => _isLoading;

  SuperAdminProvider() {
    _initRestaurantsStream();
  }

  // الاستماع إلى المطاعم وتحديث القائمة تلقائياً
  void _initRestaurantsStream() {
    _isLoading = true;
    notifyListeners();

    _restaurantsSubscription?.cancel();

    _restaurantsSubscription = _firestore
        .collection('restaurants')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        _restaurants = snapshot.docs.map((doc) {
          return Restaurant.fromMap(doc.data(), doc.id);
        }).toList();

        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error fetching restaurants: $error');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // إضافة مطعم جديد وإنشاء حساب المدير
  Future<void> createRestaurantAndAdmin({
    required String restaurantName,
    required String location,
    required String phoneNumber,
    required String adminEmail,
    required String adminPassword,
  }) async {
    _isLoading = true;
    notifyListeners();

    FirebaseApp? tempApp;

    try {
      final appName =
          'TempFactory_${DateTime.now().millisecondsSinceEpoch}';

      tempApp = await Firebase.initializeApp(
        name: appName,
        options: Firebase.app().options,
      );

      final userCredential =
          await FirebaseAuth.instanceFor(app: tempApp)
              .createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );

      final adminUid = userCredential.user!.uid;

      final restaurantDocRef =
          _firestore.collection('restaurants').doc();

      final newRestaurant = Restaurant(
        id: restaurantDocRef.id,
        name: restaurantName.trim(),
        adminEmail: adminEmail.trim(),
        adminPassword: adminPassword,
        adminUid: adminUid,
        phoneNumber: phoneNumber.trim(),
        location: location.trim(),
        isActive: true,
        createdAt: DateTime.now(),
      );

      // إنشاء مستند المطعم
      await restaurantDocRef.set(newRestaurant.toMap());

      // إنشاء مستند المدير
      await _firestore.collection('users').doc(adminUid).set({
        'uid': adminUid,
        'email': adminEmail.trim(),
        'role': 'restaurant_admin',
        'restaurantId': restaurantDocRef.id,
        'isActive': true,
        'createdAt': Timestamp.now(),
      });

      // إنشاء بيانات المنيو الافتراضية
      await _seedDefaultMenuData(restaurantDocRef.id);
    } catch (e) {
      debugPrint('Error creating restaurant: $e');
      rethrow;
    } finally {
      if (tempApp != null) {
        try {
          await tempApp.delete();
        } catch (e) {
          debugPrint('Error deleting temporary Firebase app: $e');
        }
      }

      _isLoading = false;
      notifyListeners();
    }
  }

  // إنشاء أقسام ومنتجات افتراضية
  Future<void> _seedDefaultMenuData(String restaurantId) async {
    final batch = _firestore.batch();

    final restaurantRef =
        _firestore.collection('restaurants').doc(restaurantId);

    final categoryRef =
        restaurantRef.collection('categories').doc();

    batch.set(categoryRef, {
      'name': 'الرئيسية',
      'createdAt': Timestamp.now(),
    });

    final productRef =
        restaurantRef.collection('products').doc();

    batch.set(productRef, {
      'name': 'وجبة تجريبية',
      'price': 50.0,
      'description': 'وجبة افتراضية مضافة تلقائياً',
      'categoryId': categoryRef.id,
      'isAvailable': true,
      'imageUrl': '',
      'createdAt': Timestamp.now(),
    });

    await batch.commit();
  }

  // تعديل اسم المطعم وعنوانه
  Future<void> updateRestaurantDetails({
    required String restaurantId,
    required String name,
    required String location,
  }) async {
    final cleanName = name.trim();
    final cleanLocation = location.trim();

    if (cleanName.isEmpty) {
      throw ArgumentError('اسم المطعم مطلوب');
    }

    if (cleanLocation.isEmpty) {
      throw ArgumentError('عنوان المطعم مطلوب');
    }

    try {
      // تحديث البيانات في Firestore
      await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .update({
        'name': cleanName,
        'location': cleanLocation,
      });

      // تحديث القائمة المحلية فوراً
      final index = _restaurants.indexWhere(
        (restaurant) => restaurant.id == restaurantId,
      );

      if (index != -1) {
        final oldRestaurant = _restaurants[index];

        _restaurants[index] = Restaurant(
          id: oldRestaurant.id,
          name: cleanName,
          adminEmail: oldRestaurant.adminEmail,
          adminPassword: oldRestaurant.adminPassword,
          adminUid: oldRestaurant.adminUid,
          phoneNumber: oldRestaurant.phoneNumber,
          location: cleanLocation,
          isActive: oldRestaurant.isActive,
          createdAt: oldRestaurant.createdAt,
        );

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating restaurant details: $e');
      rethrow;
    }
  }

  // تفعيل أو إيقاف اشتراك المطعم وحساب المدير
  Future<void> toggleRestaurantStatus(
    String restaurantId,
    String adminUid,
    bool currentStatus,
  ) async {
    try {
      final newStatus = !currentStatus;

      // تحديث حالة المطعم
      await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .update({
        'isActive': newStatus,
      });

      // تحديث حالة حساب المدير
      if (adminUid.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(adminUid)
            .update({
          'isActive': newStatus,
        });
      }

      // تحديث الحالة محلياً
      final index = _restaurants.indexWhere(
        (restaurant) => restaurant.id == restaurantId,
      );

      if (index != -1) {
        final oldRestaurant = _restaurants[index];

        _restaurants[index] = Restaurant(
          id: oldRestaurant.id,
          name: oldRestaurant.name,
          adminEmail: oldRestaurant.adminEmail,
          adminPassword: oldRestaurant.adminPassword,
          adminUid: oldRestaurant.adminUid,
          phoneNumber: oldRestaurant.phoneNumber,
          location: oldRestaurant.location,
          isActive: newStatus,
          createdAt: oldRestaurant.createdAt,
        );

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error toggling restaurant status: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _restaurantsSubscription?.cancel();
    super.dispose();
  }
}
