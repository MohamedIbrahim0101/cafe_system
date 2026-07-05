// lib/main.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'package:premium_store/core/services/firebase_service.dart';
import 'package:premium_store/firebase_options.dart';
import 'package:premium_store/state/auth_brovider.dart';
import 'package:premium_store/state/inventory_provider.dart';
import 'package:premium_store/state/product_brovider.dart';
import 'package:provider/provider.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'state/restaurant_provider.dart';
import 'state/category_provider.dart';
import 'state/order_provider.dart';
import 'state/cart_provider.dart';

void main() async {
  // 1. التأكد من تهيئة الـ Binding أولاً
  WidgetsFlutterBinding.ensureInitialized();

  // 2. تهيئة Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. تفعيل الـ Offline Persistence للـ Firestore
  // هذا سيجعل التطبيق يحتفظ بالبيانات محلياً ويعمل أوفلاين
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // 4. باقي خدماتك
  await FirebaseService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RestaurantProvider()..load()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()), // البروفايدر الجديد المرفق بالأعلى 🚀
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final _router = AppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Restaurant Management System',
      theme: AppTheme.theme,
      routerConfig: _router.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
