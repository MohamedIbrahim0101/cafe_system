// lib/admin/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:premium_store/state/product_brovider.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../state/order_provider.dart';
import '../../state/auth_brovider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // جلب البيانات
    final orderProvider = context.watch<OrderProvider>();
    final productProvider = context.watch<ProductProvider>();
    final authProvider = context.watch<AuthProvider>();

    // حساب الإحصائيات
    final totalOrders = orderProvider.orders.length;
    final totalRevenue = orderProvider.orders
        .where((o) => o.status == 'Completed' || o.status == 'Served')
        .fold<double>(0.0, (sum, o) => sum + o.totalPrice);

    final activeOrders = orderProvider.orders
        .where((o) => o.status != 'Completed' && o.status != 'Cancelled')
        .length;

    final totalProducts = productProvider.products.length;

    // الحصول على عرض الشاشة للتعامل مع Responsive
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      // إضافة Drawer في حالة الموبايل لمنع الـ Overflow الجانبي
      drawer:
          isMobile ? Drawer(child: _buildSidebar(context, authProvider)) : null,
      appBar: isMobile
          ? AppBar(
              title: const Text("Admin Dashboard"),
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black))
          : null,
      body: Row(
        children: [
          // إخفاء الـ Sidebar في الشاشات الصغيرة واستبداله بـ Drawer
          if (!isMobile) _buildSidebar(context, authProvider),

          Expanded(
            child: SelectionArea(
              // يسمح بنسخ النصوص في الـ Web
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(authProvider),
                    const SizedBox(height: 32),

                    // استخدام LayoutBuilder للتحكم في عدد الأعمدة
                    LayoutBuilder(builder: (context, constraints) {
                      int crossAxisCount = 4;
                      if (constraints.maxWidth < 600)
                        crossAxisCount = 1;
                      else if (constraints.maxWidth < 1100) crossAxisCount = 2;

                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: isMobile ? 2.5 : 1.5,
                        children: [
                          _buildStatCard("Total Orders", totalOrders.toString(),
                              Icons.shopping_basket_outlined, Colors.blue),
                          _buildStatCard(
                              "Revenue",
                              "\$${totalRevenue.toStringAsFixed(0)}",
                              Icons.monetization_on_outlined,
                              Colors.orange),
                          _buildStatCard(
                              "Active Orders",
                              activeOrders.toString(),
                              Icons.pending_actions,
                              Colors.green),
                          _buildStatCard(
                              "Total Products",
                              totalProducts.toString(),
                              Icons.restaurant_menu,
                              Colors.purple),
                        ],
                      );
                    }),

                    const SizedBox(height: 40),
                    _buildRecentOrdersSection(context, orderProvider, isMobile),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Header
  Widget _buildHeader(AuthProvider auth) {
    return Wrap(
      // لمنع الـ overflow عند صغر الشاشة عرضياً
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 20,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Dashboard Overview",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1C1E))),
            Text("Welcome back, ${auth.user?.email?.split('@')[0] ?? 'Admin'}!",
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_rounded)),
            const SizedBox(width: 12),
            CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: const Icon(Icons.person, color: Colors.green),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)
        ],
      ),
      child: Row(
        // تغيير لـ Row ليكون أفضل في المساحات الصغيرة
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                    child: Text(value,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold))),
                Text(title,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    maxLines: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, AuthProvider auth) {
    final String location = GoRouterState.of(context).uri.toString();

    return Container(
      width: 260,
      height: double.infinity,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Text("Romdol.",
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green)),
          const SizedBox(height: 40),
          Expanded(
            child: ListView(
              // تحويل القائمة لـ ListView لمنع الـ overflow الطولي
              children: [
                _sidebarItem(context, Icons.grid_view_rounded, "Dashboard",
                    "/admin/dashboard", location == "/admin/dashboard"),
                _sidebarItem(context, Icons.shopping_cart_outlined, "Orders",
                    "/admin/orders", location == "/admin/orders"),
                _sidebarItem(context, Icons.fastfood_outlined, "Products",
                    "/admin/products", location == "/admin/products"),
                _sidebarItem(context, Icons.category_outlined, "Categories",
                    "/admin/categories", location == "/admin/categories"),
                _sidebarItem(context, Icons.table_restaurant_outlined, "Tables",
                    "/admin/tables", location == "/admin/tables"),
              ],
            ),
          ),
          const Divider(),
          _sidebarItem(
              context, Icons.logout_rounded, "Logout", "/admin/login", false,
              isLogout: true),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sidebarItem(BuildContext context, IconData icon, String label,
      String route, bool isActive,
      {bool isLogout = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: () async {
          if (isLogout) {
            await context.read<AuthProvider>().logout();
            if (context.mounted) context.go('/admin/login');
          } else {
            context.go(route);
          }
        },
        leading: Icon(icon, color: isActive ? Colors.green : Colors.grey[400]),
        title: Text(label,
            style: TextStyle(
                color: isActive ? Colors.black : Colors.grey[600],
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        tileColor:
            isActive ? Colors.green.withOpacity(0.08) : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildRecentOrdersSection(
      BuildContext context, OrderProvider provider, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Recent Orders",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              TextButton(
                  onPressed: () => context.go('/admin/orders'),
                  child: const Text("See All")),
            ],
          ),
          const SizedBox(height: 20),
          if (provider.orders.isEmpty)
            const Center(child: Text("No orders found."))
          else
            SingleChildScrollView(
              // حماية الجدول من الـ Overflow العرضي
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: isMobile
                    ? 600
                    : null, // إجبار الجدول على عرض كافٍ عند الحاجة
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text("Order ID")),
                    DataColumn(label: Text("Table")),
                    DataColumn(label: Text("Total")),
                    DataColumn(label: Text("Status")),
                  ],
                  rows: provider.orders
                      .take(5)
                      .map((order) => DataRow(cells: [
                            DataCell(Text("#${order.id.substring(0, 6)}")),
                            DataCell(Text("${order.tableNumber}")),
                            DataCell(Text("\$${order.totalPrice}")),
                            DataCell(_statusChip(order.status)),
                          ]))
                      .toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color = Colors.orange;
    if (status == 'Completed' || status == 'Served') color = Colors.green;
    if (status == 'Cancelled') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20)),
      child: Text(status,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
