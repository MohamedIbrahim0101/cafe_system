import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:premium_store/super_admin/screens/super_admin_dashboard.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Imports Base ---
import 'package:premium_store/admin/screens/inventory_management_screen.dart';
import 'package:premium_store/admin/screens/stock_control.dart';

// --- Client Screens ---
import '../client/screens/splash_screen.dart';
import '../client/screens/menu_screens.dart';
import '../client/screens/product_detail_screen.dart';
import '../client/screens/cart_screen.dart';
import '../client/screens/order_status_screen.dart';

// --- Admin Screens ---
import '../admin/screens/dashboard_screen.dart';
import '../admin/screens/order_screen.dart';
import '../admin/screens/product_screen.dart';
import '../admin/screens/categoury_screen.dart';
import '../admin/screens/tables_screen.dart';
import '../admin/screens/pos_screen.dart';
import '../admin/screens/add_product_screen.dart';

// --- Super Admin Screens (يتم تعديل المسار حسب مشروعك) ---

// --- State & Models ---
import '../state/auth_brovider.dart';
import '../core/models/product_model.dart';

class AppRouter {
  late final GoRouter router;

  AppRouter(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    router = GoRouter(
      initialLocation: '/splash',
      // ربط التغييرات في AuthProvider فوراً بالراوتر لمنع الـ Lag
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isLoggedIn = authProvider.user != null;
        final isLoggingIn = state.matchedLocation == '/admin/login';
        final isSuperAdmin = authProvider.isSuperAdmin; // افترضنا وجود الخصائص في البروفايدر

        // إذا لم يكن مسجلاً ودخل على مسار محمي للأدمن أو السوبر أدمن
        final isAdminRoute = state.matchedLocation.startsWith('/admin') ||
            state.matchedLocation.startsWith('/super-admin');

        if (!isLoggedIn && isAdminRoute && !isLoggingIn) {
          return '/admin/login';
        }

        // إذا كان مسجلاً ويحاول فتح صفحة تسجيل الدخول
        if (isLoggedIn && isLoggingIn) {
          return isSuperAdmin ? '/super-admin/dashboard' : '/admin/dashboard';
        }

        // حماية مسارات الـ Super Admin من أدمن المطعم العادي
        if (isLoggedIn &&
            state.matchedLocation.startsWith('/super-admin') &&
            !isSuperAdmin) {
          return '/admin/dashboard';
        }

        return null;
      },
      routes: [
        // 1. Splash Screen
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),

        // --------------------------------------------------------
        // --- مسارات العميل (Client Routes) ---
        // --------------------------------------------------------
       GoRoute(
  path: '/menu',
  builder: (context, state) {
    // 1. قراءة الـ restaurantId والـ table من الـ QR
    final restaurantId = state.uri.queryParameters['restaurantId'];
    final tableStr = state.uri.queryParameters['table'];
    final tableNumber = int.tryParse(tableStr ?? '');

    // 2. التحقق من وجود الاثنين
    if (restaurantId == null || tableNumber == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Please scan a valid Table QR Code',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // 3. تمرير الـ restaurantId إلى MenuScreen
    return MenuScreen(
      restaurantId: restaurantId, 
      tableNumber: tableNumber,
    );
  },
),// مسار تفاصيل المنتج
GoRoute(
  path: '/product/:id',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    // 1. استخراج restaurantId و table من الـ queryParameters
    final restaurantId = state.uri.queryParameters['restaurantId'] ?? '';
    final tableNumber = int.tryParse(state.uri.queryParameters['table'] ?? '0') ?? 0;

    return ProductDetailsScreen(
      productId: id,
      restaurantId: restaurantId, // <-- تم تعريفها بالسطر الأعلى
      tableNumber: tableNumber,
    );
  },
),

// مسار السلة
GoRoute(
  path: '/cart',
  builder: (context, state) {
    // 1. استخراج restaurantId و table من الـ queryParameters
    final restaurantId = state.uri.queryParameters['restaurantId'] ?? '';
    final tableNumber = int.tryParse(state.uri.queryParameters['table'] ?? '0') ?? 0;

    return CartScreen(
      restaurantId: restaurantId, // <-- إرسال المتغير المطلوب
      tableNumber: tableNumber,
    );
  },
),
        GoRoute(
          path: '/order-status/:orderId',
          builder: (context, state) => OrderStatusScreen(
            orderId: state.pathParameters['orderId']!,
          ),
        ),

        // --------------------------------------------------------
        // --- تسجيل الدخول (Login) ---
        // --------------------------------------------------------
        GoRoute(
          path: '/admin/login',
          builder: (context, state) => const LoginScreen(),
        ),

        // --------------------------------------------------------
        // --- مسارات الأدمن (Restaurant Admin Routes) ---
        // --------------------------------------------------------
        GoRoute(
          path: '/admin/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/admin/orders',
          builder: (context, state) => const OrdersScreen(),
        ),
        GoRoute(
          path: '/admin/products',
          builder: (context, state) => const ProductsScreen(),
        ),
        GoRoute(
  path: '/admin/add-product',
  builder: (context, state) {
    return const AddProductScreen();
  },
),

GoRoute(
  path: '/admin/edit-product',
  builder: (context, state) {
    final product = state.extra as Product?;

    return AddProductScreen(
      product: product,
    );
  },
),
        GoRoute(
          path: '/admin/categories',
          builder: (context, state) => const CategoriesScreen(),
        ),
        GoRoute(
          path: '/admin/tables',
          builder: (context, state) => const TablesScreen(),
        ),
        GoRoute(
          path: '/admin/pos',
          builder: (context, state) => const POSScreen(),
        ),
        GoRoute(
          path: '/admin/inventory',
          builder: (context, state) => const InventoryManagementScreen(),
        ),
        GoRoute(
          path: '/admin/stock-control',
          builder: (context, state) => const StockControlScreen(),
        ),
        GoRoute(
          path: '/admin/add-product',
          builder: (context, state) => const AddProductScreen(),
        ),
        GoRoute(
          path: '/admin/edit-product',
          builder: (context, state) {
            final product = state.extra as Product?;
            return AddProductScreen(product: product);
          },
          
        ),

        // --------------------------------------------------------
        // --- مسارات السوبر أدمن (Super Admin Routes) ---
        // --------------------------------------------------------
        GoRoute(
          path: '/super-admin/dashboard',
          builder: (context, state) => const SuperAdminDashboardScreen(),
        ),
      ],
    );
  }
}

// --------------------------------------------------------
// --- شاشة تسجيل الدخول (Login Screen) ---
// --------------------------------------------------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  size: 80,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "SYSTEM LOGIN",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                constraints: const BoxConstraints(maxWidth: 450),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _inputLabel("EMAIL ADDRESS"),
                    _buildTextField(_emailController, Icons.email_outlined, false),
                    const SizedBox(height: 20),
                    _inputLabel("PASSWORD"),
                    _buildTextField(_passController, Icons.lock_outline, true),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: authProvider.loading
                            ? null
                            : () async {
                                final email = _emailController.text.trim();
                                final password = _passController.text;

                                if (email.isEmpty || password.isEmpty) {
                                  _showStatus(
                                    context,
                                    "Please enter all fields",
                                    isError: true,
                                  );
                                  return;
                                }

                                try {
                                  await authProvider.login(email, password);

                                  if (!context.mounted) return;

                                  if (authProvider.user != null) {
                                    _showStatus(
                                      context,
                                      "Welcome Back!",
                                      isError: false,
                                    );

                                    // التوجيه التلقائي بناءً على الصلاحية لمنع الـ Lag
                                    if (authProvider.isSuperAdmin) {
                                      context.go('/super-admin/dashboard');
                                    } else {
                                      context.go('/admin/dashboard');
                                    }
                                  } else {
                                    _showStatus(
                                      context,
                                      "Invalid Login Credentials",
                                      isError: true,
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    _showStatus(
                                      context,
                                      "Error: $e",
                                      isError: true,
                                    );
                                  }
                                }
                              },
                        child: authProvider.loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                "LOGIN TO DASHBOARD",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, IconData icon, bool isPass) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.black, size: 20),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintText: isPass ? "••••••••" : "user@domain.com",
        hintStyle: const TextStyle(color: Colors.black26, fontSize: 14),
      ),
    );
  }

  void _showStatus(BuildContext context, String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}