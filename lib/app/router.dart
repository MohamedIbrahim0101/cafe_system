// lib/app/router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// Screens
import '../client/screens/splash_screen.dart';
import '../client/screens/menu_screens.dart';
import '../client/screens/product_detail_screen.dart';
import '../client/screens/cart_screen.dart';
import '../client/screens/order_status_screen.dart';
import '../admin/screens/dashboard_screen.dart';
import '../admin/screens/order_screen.dart';
import '../admin/screens/product_screen.dart';
import '../admin/screens/categoury_screen.dart';
import '../admin/screens/tables_screen.dart';

// State & Constants
import '../state/auth_brovider.dart';
import '../app/constants.dart';

class AppRouter {
  late final GoRouter router;

  AppRouter() {
    router = GoRouter(
      initialLocation: '/splash',
      routes: [
        // --- 1. Splash Screen ---
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),

        // --- 2. Client: Menu Screen ---
        GoRoute(
          path: '/menu',
          builder: (context, state) {
            final tableStr = state.uri.queryParameters['table'];
            final tableNumber = int.tryParse(tableStr ?? '');
            
            if (tableNumber == null) {
              return const Scaffold(
                body: Center(child: Text('Please scan the QR code on your table')),
              );
            }
            return MenuScreen(tableNumber: tableNumber);
          },
        ),

        // --- 3. Client: Product Details ---
        GoRoute(
          path: '/product/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            final tableStr = state.uri.queryParameters['table'];
            final tableNumber = int.tryParse(tableStr ?? '0');
            return ProductDetailsScreen(productId: id, tableNumber: tableNumber!);
          },
        ),

        // --- 4. Client: Cart Screen (المكان الذي حدث فيه الخطأ) ---
        // سنقوم بتعريف المسار ليدعم الطريقتين لضمان عدم حدوث Crash
        GoRoute(
          path: '/cart',
          builder: (context, state) {
            final tableStr = state.uri.queryParameters['table'];
            final tableNumber = int.tryParse(tableStr ?? '0');
            return CartScreen(tableNumber: tableNumber!);
          },
        ),

        // --- 5. Client: Order Status ---
        GoRoute(
          path: '/order-status/:orderId',
          builder: (context, state) {
            final orderId = state.pathParameters['orderId']!;
            return OrderStatusScreen(orderId: orderId);
          },
        ),

        // --- 6. Admin: Login Screen ---
        GoRoute(
          path: '/admin/login',
          builder: (context, state) => const LoginScreen(),
        ),

        // --- 7. Admin: Dashboard & Sections (With Auth Guard) ---
        _adminRoute('/admin/dashboard', (state) => const DashboardScreen()),
        _adminRoute('/admin/orders', (state) => const OrdersScreen()),
        _adminRoute('/admin/products', (state) => const ProductsScreen()),
        _adminRoute('/admin/categories', (state) => const CategoriesScreen()),
        _adminRoute('/admin/tables', (state) => const TablesScreen()),
      ],
    );
  }

  // دالة مساعدة لتقليل تكرار كود الحماية (Auth Guard) للـ Admin
  GoRoute _adminRoute(String path, Widget Function(GoRouterState state) builder) {
    return GoRoute(
      path: path,
      builder: (context, state) => builder(state),
      redirect: (context, state) {
        final auth = context.read<AuthProvider>();
        if (auth.user == null) return '/admin/login';
        return null;
      },
    );
  }
}

// --- Login Screen (تحسين التصميم ليكون Premium) ---
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final emailController = TextEditingController();
    final passController = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(kPadding * 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_person_rounded, size: 80, color: kPrimaryColor),
              ),
              const SizedBox(height: 32),
              Text(
                'Admin Portal',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text('Please sign in to continue', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 48),
              
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.password_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D2D2D), // لون نون الأسود
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: authProvider.loading
                      ? null
                      : () async {
                          await authProvider.login(emailController.text, passController.text);
                          if (authProvider.user != null) {
                            if (context.mounted) context.go('/admin/dashboard');
                          }
                        },
                  child: authProvider.loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('SIGN IN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}