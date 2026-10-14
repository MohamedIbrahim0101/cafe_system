import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'package:provider/provider.dart';

// Firebase
import 'package:premium_store/core/services/firebase_service.dart';
import 'package:premium_store/firebase_options.dart';

// Providers
import 'package:premium_store/state/auth_brovider.dart';
import 'package:premium_store/state/inventory_provider.dart';
import 'package:premium_store/state/product_brovider.dart';
import 'package:premium_store/state/super_admin_provider.dart';
import 'package:premium_store/state/restaurant_provider.dart';
import 'package:premium_store/state/category_provider.dart';
import 'package:premium_store/state/order_provider.dart';
import 'package:premium_store/state/cart_provider.dart';
import 'package:premium_store/state/language_provider.dart';

// App
import 'app/router.dart';
import 'app/theme.dart';

void main() async {
  // 1. التأكد من تهيئة Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // 2. تهيئة Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. تفعيل Offline Persistence للـ Firestore
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // 4. تهيئة Firebase Service
  await FirebaseService.init();

  // 5. تشغيل التطبيق
  runApp(
    MultiProvider(
      providers: [
        // =====================================================
        // Language Provider
        // =====================================================
        ChangeNotifierProvider<LanguageProvider>(
          create: (_) => LanguageProvider(),
        ),

        // =====================================================
        // Auth Provider
        // =====================================================
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),

        // =====================================================
        // Super Admin Provider
        // =====================================================
        ChangeNotifierProvider<SuperAdminProvider>(
          create: (_) => SuperAdminProvider(),
        ),

        // =====================================================
        // Restaurant Provider
        //
        // لا نمسح restaurantId عندما تكون قيمة AuthProvider
        // تساوي null، لأن MenuScreen قد يحدد المطعم من QR.
        // =====================================================
        ChangeNotifierProxyProvider<
            AuthProvider,
            RestaurantProvider>(
          create: (_) => RestaurantProvider(),
          update: (
            context,
            auth,
            restaurantProvider,
          ) {
            final provider =
                restaurantProvider ?? RestaurantProvider();

            if (auth.restaurantId != null &&
                auth.restaurantId!.isNotEmpty) {
              provider.updateRestaurantId(
                auth.restaurantId,
              );
            }

            return provider;
          },
        ),

        // =====================================================
        // Product Provider
        //
        // يدعم:
        // 1. المطعم المسجل دخوله.
        // 2. العميل الذي يفتح المنيو من QR.
        //
        // لا نمسح restaurantId الخاص بالـ QR إذا كان
        // AuthProvider لا يحتوي على restaurantId.
        // =====================================================
        ChangeNotifierProxyProvider<
            AuthProvider,
            ProductProvider>(
          create: (_) => ProductProvider(),
          update: (
            context,
            auth,
            productProvider,
          ) {
            final provider =
                productProvider ?? ProductProvider();

            if (auth.restaurantId != null &&
                auth.restaurantId!.isNotEmpty) {
              provider.updateRestaurantId(
                auth.restaurantId,
              );
            }

            return provider;
          },
        ),

        // =====================================================
        // Order Provider
        // =====================================================
        ChangeNotifierProxyProvider<
            AuthProvider,
            OrderProvider>(
          create: (_) => OrderProvider(),
          update: (
            context,
            auth,
            orderProvider,
          ) {
            final provider =
                orderProvider ?? OrderProvider();

            if (auth.isRestaurantAdmin &&
                auth.restaurantId != null &&
                auth.restaurantId!.isNotEmpty) {
              provider.updateRestaurantId(
                auth.restaurantId,
              );
            }

            return provider;
          },
        ),

        // =====================================================
        // Inventory Provider
        // =====================================================
        ChangeNotifierProxyProvider<
            AuthProvider,
            InventoryProvider>(
          create: (_) => InventoryProvider(),
          update: (
            context,
            auth,
            inventoryProvider,
          ) {
            final provider =
                inventoryProvider ?? InventoryProvider();

            if (auth.restaurantId != null &&
                auth.restaurantId!.isNotEmpty) {
              provider.updateRestaurantId(
                auth.restaurantId,
              );
            }

            return provider;
          },
        ),

        // =====================================================
        // Category Provider
        //
        // لا نمسح restaurantId الخاص بالـ QR بسبب null.
        // =====================================================
        ChangeNotifierProxyProvider<
            AuthProvider,
            CategoryProvider>(
          create: (_) => CategoryProvider(),
          update: (
            context,
            auth,
            categoryProvider,
          ) {
            final provider =
                categoryProvider ?? CategoryProvider();

            if (auth.restaurantId != null &&
                auth.restaurantId!.isNotEmpty) {
              provider.updateRestaurantId(
                auth.restaurantId,
              );
            }

            return provider;
          },
        ),

        // =====================================================
        // Cart Provider
        // =====================================================
        ChangeNotifierProvider<CartProvider>(
          create: (_) => CartProvider(),
        ),
      ],

      // التطبيق الرئيسي
      child: const MyApp(),
    ),
  );
}

// ===============================================================
// MyApp
// ===============================================================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Language Provider
    final languageProvider =
        context.watch<LanguageProvider>();

    // Router
    final appRouter = AppRouter(context);

    return MaterialApp.router(
      title: 'Restaurant Management System',
      theme: AppTheme.theme,
      routerConfig: appRouter.router,
      locale: languageProvider.locale,

      builder: (context, child) {
        return Directionality(
          textDirection: languageProvider.isArabic
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        );
      },

      debugShowCheckedModeBanner: false,
    );
  }
}
