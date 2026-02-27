import 'package:flutter/material.dart';
import 'package:premium_store/admin/screens/add_product_screen.dart';
import 'package:premium_store/core/models/product_model.dart';
import 'package:premium_store/core/services/firebase_service.dart';
import 'package:premium_store/state/product_brovider.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../state/auth_brovider.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Row(
        children: [
          // Sidebar ثابت العرض مع إمكانية التمرير داخلياً
          _buildSidebar(context, authProvider),

          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.all(24.0), // تقليل البادينج قليلاً للمساحة
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 24),

                  // منطقة المنتجات مع التعامل مع أحجام الشاشة المختلفة
                  Expanded(
                    child: productProvider.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF00B686)))
                        : productProvider.products.isEmpty
                            ? _buildEmptyState()
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  // تغيير عدد الأعمدة ديناميكياً بناءً على المساحة المتاحة
                                  int crossAxisCount =
                                      constraints.maxWidth > 1200
                                          ? 4
                                          : constraints.maxWidth > 800
                                              ? 3
                                              : 2;

                                  return GridView.builder(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      childAspectRatio:
                                          0.75, // نسبة العرض للارتفاع لمنع التكدس
                                      crossAxisSpacing: 20,
                                      mainAxisSpacing: 20,
                                    ),
                                    itemCount: productProvider.products.length,
                                    itemBuilder: (context, index) {
                                      return _buildProductCard(
                                          productProvider.products[index]);
                                    },
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Wrap(
      // استخدام Wrap بدلاً من Row لمنع الـ Overflow عند صغر العرض
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Products Management",
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1C1E))),
            Text("Manage your menu items",
                style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _navigateToEdit(context, null),
          icon: const Icon(Icons.add, size: 20),
          label: const Text("Add Product"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00B686),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // جزء الصورة
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[100],
                          child: const Icon(Icons.broken_image,
                              color: Colors.grey)),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildAvailabilityTag(product.isAvailable),
                ),
              ],
            ),
          ),
          // جزء البيانات
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(product.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  FittedBox(
                    // يضمن أن السعر لن يخرج عن الحاوية أبداً
                    fit: BoxFit.scaleDown,
                    child: Text("\$${product.price.toStringAsFixed(2)}",
                        style: const TextStyle(
                            color: Color(0xFF00B686),
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: OutlinedButton(
                            onPressed: () => _navigateToEdit(context, product),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              side: BorderSide(color: Colors.grey.shade200),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("Edit",
                                style: TextStyle(
                                    fontSize: 12, color: Colors.blueGrey)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8)),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _confirmDelete(context, product),
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent, size: 18),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityTag(bool isAvailable) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isAvailable
            ? Colors.green.withOpacity(0.9)
            : Colors.red.withOpacity(0.9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isAvailable ? "Available" : "Sold Out",
        style: const TextStyle(
            color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  // الميثودات المساعدة (تأكد من وجودها في الكلاس)
  void _navigateToEdit(BuildContext context, Product? product) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => AddProductScreen(product: product)));
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Product"),
        content: Text("Delete '${product.name}'?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseService.products.doc(product.id).delete();
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
          const Text("No products found", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, AuthProvider auth) {
    final String location = GoRouterState.of(context).uri.toString();
    return Container(
      width: 260,
      color: Colors.white,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Text("Romdol.",
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00B686))),
          ),
          Expanded(
            // التمرير في حال كانت الشاشة قصيرة
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _sidebarItem(context, Icons.grid_view_rounded, "Dashboard",
                      "/admin/dashboard", location == "/admin/dashboard"),
                  _sidebarItem(context, Icons.shopping_cart_outlined, "Orders",
                      "/admin/orders", location == "/admin/orders"),
                  _sidebarItem(context, Icons.fastfood_outlined, "Products",
                      "/admin/products", location == "/admin/products"),
                  _sidebarItem(context, Icons.category_outlined, "Categories",
                      "/admin/categories", location == "/admin/categories"),
                  _sidebarItem(context, Icons.table_restaurant_outlined,
                      "Tables", "/admin/tables", location == "/admin/tables"),
                ],
              ),
            ),
          ),
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
            final authProvider = context.read<AuthProvider>();
            await authProvider.logout();
            if (context.mounted) context.go(route);
          } else {
            context.go(route);
          }
        },
        leading: Icon(icon,
            color: isActive ? const Color(0xFF00B686) : Colors.grey[400],
            size: 22),
        title: Text(label,
            style: TextStyle(
                color: isActive ? Colors.black : Colors.grey[600],
                fontSize: 14,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        tileColor: isActive
            ? const Color(0xFF00B686).withOpacity(0.08)
            : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        dense: true, // تصغير حجم الـ ListTile قليلاً لمنع التكدس
      ),
    );
  }
}
