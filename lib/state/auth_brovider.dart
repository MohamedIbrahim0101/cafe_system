// lib/state/auth_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseService.auth;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  String? _role;
  String? _restaurantId;
  bool _loading = false;
  StreamSubscription<User?>? _authStateSubscription;

  // --- Getters ---
  User? get user => _user;
  bool get loading => _loading;
  bool get authenticated => _user != null;

  /// تحقق ممتاذ ومباشر للتفريق بين الأدوار (Roles)
  bool get isSuperAdmin => _role == 'super_admin';
  bool get isRestaurantAdmin => _role == 'restaurant_admin' || _role == 'admin';
  
  /// معرف المطعم التابع لـ Admin المطعم الحالي
  String? get restaurantId => _restaurantId;
  String? get role => _role;

  AuthProvider() {
    _init();
  }

  /// مراقبة تغيرات حالة تسجيل الدخول وجلب بيانات المستخدم من Firestore
  void _init() {
    _authStateSubscription = _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        try {
          await _fetchUserData(user.uid);
        } catch (e) {
          // إذا كان الحساب موقوفاً، سيقوم _fetchUserData بتسجيل الخروج ورمي الخطأ
          debugPrint("⚠️ Auth check warning: $e");
        }
      } else {
        _clearUserData();
      }
      notifyListeners();
    });
  }

  /// جلب دور المستخدم وحالة نشاطه ومطعم المستخدم من Firestore
  Future<void> _fetchUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        
        // التحقق الأساسي من حالة الحساب (isActive)
        final bool isActive = data['isActive'] ?? true;
        if (!isActive && _role != 'super_admin') {
          // إذا كان الحساب موقوفاً وليس سوبر أدمن، نقوم بتسجيل الخروج الإلزامي
          await _auth.signOut();
          _clearUserData();
          throw Exception("تم إيقاف حسابك لعدم دفع الاشتراك. يرجى التواصل مع الإدارة للتفعيل.");
        }

        _role = data['role'] as String?;
        _restaurantId = data['restaurantId'] as String?;
      } else {
        _role = 'user';
        _restaurantId = null;
      }
    } catch (e) {
      debugPrint("❌ Error fetching user data: $e");
      _clearUserData();
      rethrow;
    }
  }

  /// مسح بيانات الجلسة عند تسجيل الخروج
  void _clearUserData() {
    _user = null;
    _role = null;
    _restaurantId = null;
  }

  /// تسجيل الدخول مع تحديث فوري للـ state وجلب البيانات والتحقق من التفعيل
  Future<void> login(String email, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      
      if (credential.user != null) {
        _user = credential.user;
        // سيقوم بجلب البيانات والتحقق من الـ isActive وفي حال كان معطلاً سيطرد ويطبع الخطأ
        await _fetchUserData(credential.user!.uid);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ FirebaseAuthException: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("❌ Auth Error: $e");
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// إعادة جلب بيانات المستخدم يدوياً والتحقق من حالة الاشتراك
  Future<void> refreshUserData() async {
    if (_user != null) {
      await _fetchUserData(_user!.uid);
      notifyListeners();
    }
  }

  /// تسجيل الخروج
  Future<void> logout() async {
    _loading = true;
    notifyListeners();
    try {
      await _auth.signOut();
      _clearUserData();
    } catch (e) {
      debugPrint("❌ Logout Error: $e");
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}