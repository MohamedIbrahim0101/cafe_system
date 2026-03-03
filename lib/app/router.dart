import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

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
        GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),

        // --- Client Routes ---
        GoRoute(
          path: '/menu',
          builder: (context, state) {
            final tableStr = state.uri.queryParameters['table'];
            final tableNumber = int.tryParse(tableStr ?? '');
            if (tableNumber == null) {
              return const Scaffold(body: Center(child: Text('Scan Table QR Code', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))));
            }
            return MenuScreen(tableNumber: tableNumber);
          },
        ),
        GoRoute(
          path: '/product/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            final tableNumber = int.tryParse(state.uri.queryParameters['table'] ?? '0');
            return ProductDetailsScreen(productId: id, tableNumber: tableNumber!);
          },
        ),
        GoRoute(
          path: '/cart',
          builder: (context, state) {
            final tableNumber = int.tryParse(state.uri.queryParameters['table'] ?? '0');
            return CartScreen(tableNumber: tableNumber!);
          },
        ),
        GoRoute(
          path: '/order-status/:orderId',
          builder: (context, state) => OrderStatusScreen(orderId: state.pathParameters['orderId']!),
        ),

        // --- Admin Routes ---
        GoRoute(path: '/admin/login', builder: (context, state) => const LoginScreen()),
        _adminRoute('/admin/dashboard', (state) => const DashboardScreen()),
        _adminRoute('/admin/orders', (state) => const OrdersScreen()),
        _adminRoute('/admin/products', (state) => const ProductsScreen()),
        _adminRoute('/admin/categories', (state) => const CategoriesScreen()),
        _adminRoute('/admin/tables', (state) => const TablesScreen()),
      ],
    );
  }

  GoRoute _adminRoute(String path, Widget Function(GoRouterState state) builder) {
    return GoRoute(
      path: path,
      builder: (context, state) => builder(state),
      redirect: (context, state) {
        final auth = context.read<AuthProvider>();
        return auth.user == null ? '/admin/login' : null;
      },
    );
  }
}

// --- Login Screen (Admin Style - High Clarity) ---
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final emailController = TextEditingController();
    final passController = TextEditingController();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // خلفية رمادية فاتحة جداً
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // لوجو أو أيقونة الأدمن
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.admin_panel_settings_rounded, size: 80, color: Colors.black),
              ),
              const SizedBox(height: 24),
              Text(
                "ADMIN LOGIN",
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 1.5),
              ),
              const SizedBox(height: 40),
              
              // حاوية المدخلات (بيضاء صريحة)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _inputLabel("EMAIL ADDRESS"),
                    _buildTextField(emailController, Icons.email_outlined, false),
                    const SizedBox(height: 20),
                    _inputLabel("PASSWORD"),
                    _buildTextField(passController, Icons.lock_outline, true),
                    const SizedBox(height: 30),
                    
                    // زر تسجيل الدخول
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: authProvider.loading 
                          ? null 
                          : () async {
                              if (emailController.text.isEmpty || passController.text.isEmpty) {
                                _showStatus(context, "Please enter all fields", isError: true);
                                return;
                              }
                              
                              try {
                                await authProvider.login(emailController.text, passController.text);
                                if (authProvider.user != null) {
                                  if (context.mounted) {
                                    _showStatus(context, "Welcome Back!", isError: false);
                                    context.go('/admin/dashboard');
                                  }
                                } else {
                                  if (context.mounted) _showStatus(context, "Invalid Email or Password", isError: true);
                                }
                              } catch (e) {
                                if (context.mounted) _showStatus(context, "Connection Error. Try again.", isError: true);
                              }
                            },
                        child: authProvider.loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("LOGIN TO DASHBOARD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12)),
    );
  }

  Widget _buildTextField(TextEditingController controller, IconData icon, bool isPass) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold), // نص أسود عريض
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.black, size: 20),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        hintText: isPass ? "••••••••" : "admin@restaurant.com",
        hintStyle: const TextStyle(color: Colors.black26, fontSize: 14),
      ),
    );
  }

  void _showStatus(BuildContext context, String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}