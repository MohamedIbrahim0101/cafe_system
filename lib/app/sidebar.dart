import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:premium_store/state/auth_brovider.dart';

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({super.key});

  final Color primaryGreen = const Color(0xFF00B686);

  @override
  Widget build(BuildContext context) {
    // حل مشكلة الـ GoRouterState: نستخدم try/catch أو نعتمد على GoRouter للوصول للـ location
    String location = "";
    try {
      location = GoRouter.of(context)
          .routerDelegate
          .currentConfiguration
          .last
          .matchedLocation;
    } catch (e) {
      location = "/"; // Fallback لو حصل مشكلة في الـ context
    }

    final authProvider = context.read<AuthProvider>();

    return Container(
      width: 260,
      height: double.infinity, // لضمان أخذ كامل الارتفاع ومنع الـ Overflow
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
      ),
      child: Column(
        children: [
          // Logo Section
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Text(
              "Premium.",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),
          ),

          // Sidebar Items - الأفضل نضعهم في ScrollView عشان لو الشاشة صغيرة
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _sidebarItem(
                    context,
                    icon: Icons.grid_view_rounded,
                    label: "Dashboard",
                    route: "/admin/dashboard",
                    isActive: location.contains("dashboard"),
                  ),
                  _sidebarItem(
                    context,
                    icon: Icons.shopping_bag_outlined,
                    label: "Orders",
                    route: "/admin/orders",
                    isActive: location.contains("orders"),
                  ),
                  _sidebarItem(
                    context,
                    icon: Icons.shopping_cart_checkout,
                    label: "Cashier (POS)",
                    route: "/admin/pos",
                    isActive: location.contains("pos"),
                  ),
                  _sidebarItem(
                    context,
                    icon: Icons.fastfood_outlined,
                    label: "Products",
                    route: "/admin/products",
                    isActive: location.contains("products"),
                  ),
                  _sidebarItem(
                    context,
                    icon: Icons.table_restaurant_rounded,
                    label: "Tables",
                    route: "/admin/tables",
                    isActive: location.contains("tables"),
                  ),
                  _sidebarItem(
                    context,
                    icon: Icons.category_rounded,
                    label: "Categories",
                    route: "/admin/categories",
                    isActive: location.contains("categories"),
                  ),
                   _sidebarItem(
                    context,
                    icon: Icons.category_rounded,
                    label: "inventory",
                    route: "/admin/inventory",
                    isActive: location.contains("InventoryManagementScreen"),
                  ),
                   _sidebarItem(
                    context,
                    icon: Icons.category_rounded,
                    label: "stock control",
                    route: "/admin/stock-control",
                    isActive: location.contains("StockControlScreen"),
                  ),
                ],
              ),
            ),
          ),

          const Divider(),

          // Logout Button
          _sidebarItem(
            context,
            icon: Icons.logout_rounded,
            label: "Logout",
            route: "/login",
            isActive: false,
            isLogout: true,
            auth: authProvider,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sidebarItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required bool isActive,
    bool isLogout = false,
    AuthProvider? auth,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        onTap: () async {
          // إغلاق الـ Drawer فوراً إذا كان مفتوحاً (مهم جداً للويب والموبايل)
          if (Scaffold.of(context).isDrawerOpen) {
            Navigator.pop(context);
          }

          if (isLogout) {
            await auth?.logout();
            if (context.mounted) context.go('/login');
          } else {
            context.go(route);
          }
        },
        mouseCursor: SystemMouseCursors.click,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        leading: Icon(
          icon,
          color: isActive ? primaryGreen : Colors.grey[600],
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isActive ? primaryGreen : Colors.black87,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        tileColor:
            isActive ? primaryGreen.withOpacity(0.1) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
