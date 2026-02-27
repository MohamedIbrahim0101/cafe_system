// lib/main.dart
import 'package:flutter/material.dart';
import 'package:premium_store/core/services/firebase_service.dart';
import 'package:premium_store/firebase_options.dart';
import 'package:premium_store/state/auth_brovider.dart';
import 'package:premium_store/state/product_brovider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'state/restaurant_provider.dart';
import 'state/category_provider.dart';
import 'state/order_provider.dart';
import 'state/cart_provider.dart';

void main() async {
   await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseService.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => RestaurantProvider()..load()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
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
      title: 'Premium Restaurant',
      theme: AppTheme.theme,
      routerConfig: _router.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
