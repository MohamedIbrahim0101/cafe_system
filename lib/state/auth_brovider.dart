// lib/state/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  // استخدام الـ Instance من FirebaseService الخاص بك
  final FirebaseAuth _auth = FirebaseService.auth;
  User? _user;
  bool _loading = false;

  // --- Getters ---
  User? get user => _user;
  bool get loading => _loading;
  bool get authenticated => _user != null;

  AuthProvider() {
    // البدء بمراقبة حالة المستخدم فور إنشاء الـ Provider
    _init();
  }

  /// مراقبة تغيرات حالة تسجيل الدخول (Sign in / Sign out)
  void _init() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  /// تسجيل الدخول باستخدام البريد الإلكتروني وكلمة المرور
  Future<void> login(String email, String password) async {
    _loading = true;
    notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(), 
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      // يمكنك هنا تخصيص رسائل الخطأ بناءً على e.code إذا أردت
      rethrow; 
    } catch (e) {
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// تسجيل الخروج
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint("❌ Logout Error: $e");
    }
  }

  @override
  void dispose() {
    // ملاحظة: لا حاجة لعمل شيء خاص هنا لـ authStateChanges 
    // لأنها تغلق تلقائياً مع انتهاء الـ Lifecycle الخاص بالتطبيق في معظم الحالات
    super.dispose();
  }
}