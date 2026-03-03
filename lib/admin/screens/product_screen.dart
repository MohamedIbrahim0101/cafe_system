import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../state/auth_brovider.dart';
import '../../state/product_brovider.dart';
import '../../core/models/product_model.dart';
import '../../core/services/firebase_service.dart';
import 'add_product_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Color brandGreen = const Color(0xFF00B686);

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final authProvider = context.watch<AuthProvider>();

    // فحص حجم الشاشة
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      // الدرور للموبايل فقط
      drawer:
          isMobile ? Drawer(child: _buildSidebar(context, authProvider)) : null,
      body: Row(
        children: [
          // السايد بار الثابت للكمبيوتر فقط
          if (!isMobile) _buildSidebar(context, authProvider),

          Expanded(
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 16.0 : 30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, isMobile),
                    const SizedBox(height: 25),
                    Expanded(
                      child: productProvider.isLoading
                          ? Center(
                              child:
                                  CircularProgressIndicator(color: brandGreen))
                          : productProvider.products.isEmpty
                              ? _buildEmptyState()
                              : _buildProductGrid(productProvider.products),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Row(
      children: [
        if (isMobile)
          IconButton(
            icon: const Icon(Icons.menu_rounded, size: 28),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        if (isMobile) const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Products Management",
                  style: TextStyle(
                      fontSize: isMobile ? 20 : 28,
                      fontWeight: FontWeight.w900)),
              if (!isMobile)
                Text("Manage and track your restaurant menu",
                    style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _navigateToEdit(context, null),
          icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
          label: Text(isMobile ? "Add" : "Add Product",
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: brandGreen,
            padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 20, vertical: 15),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildProductGrid(List<Product> products) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;
        int crossAxisCount = (width / 220).floor(); // حساب تلقائي لعدد الأعمدة
        if (crossAxisCount < 2) crossAxisCount = 2;

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.75,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) => _buildProductCard(products[index]),
        );
      },
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[100],
                          child:
                              const Icon(Icons.fastfood, color: Colors.grey)),
                    ),
                  ),
                ),
                Positioned(
                    top: 10,
                    right: 10,
                    child: _buildAvailabilityTag(product.isAvailable)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text("\$${product.price.toStringAsFixed(2)}",
                    style: TextStyle(
                        color: brandGreen,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => _navigateToEdit(context, product),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.blue.withOpacity(0.05),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Edit",
                            style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 35,
                      decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8)),
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: Colors.red, size: 18),
                        onPressed: () => _confirmDelete(context, product),
                      ),
                    )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAvailabilityTag(bool isAvailable) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable ? brandGreen : Colors.redAccent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(isAvailable ? "Available" : "Sold Out",
          style: const TextStyle(
              color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSidebar(BuildContext context, AuthProvider authProvider) {
    final String location = GoRouterState.of(context).uri.toString();
    return Container(
      width: 260,
      height: double.infinity,
      color: Colors.white,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Text("Romdol.",
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00B686))),
          ),
          Expanded(
            child: Column(
              children: [
                _sidebarItem(
                    context,
                    authProvider,
                    Icons.grid_view_rounded,
                    "Dashboard",
                    "/admin/dashboard",
                    location.contains("dashboard")),
                _sidebarItem(context, authProvider, Icons.shopping_bag_outlined,
                    "Orders", "/admin/orders", location.contains("orders")),
                _sidebarItem(
                    context,
                    authProvider,
                    Icons.fastfood_outlined,
                    "Products",
                    "/admin/products",
                    location.contains("products")),
                _sidebarItem(
                    context,
                    authProvider,
                    Icons.category_rounded,
                    "Categories",
                    "/admin/categories",
                    location.contains("categories")),
                _sidebarItem(context, authProvider, Icons.table_bar_outlined,
                    "Tables", "/admin/tables", location.contains("tables")),
              ],
            ),
          ),
          const Divider(indent: 20, endIndent: 20),
          _sidebarItem(context, authProvider, Icons.logout_rounded, "Logout",
              "/admin/login", false,
              isLogout: true),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sidebarItem(BuildContext context, AuthProvider authProvider,
      IconData icon, String label, String route, bool isActive,
      {bool isLogout = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: () async {
          if (isLogout) {
            await authProvider.logout();
            if (mounted) context.go(route);
          } else {
            if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
              Navigator.pop(context);
            }
            context.go(route);
          }
        },
        leading: Icon(icon,
            color: isActive ? brandGreen : Colors.grey[400], size: 22),
        title: Text(label,
            style: TextStyle(
                color: isActive ? brandGreen : Colors.grey[700],
                fontSize: 15,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500)),
        tileColor: isActive ? brandGreen.withOpacity(0.08) : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        dense: true,
      ),
    );
  }

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Product"),
        content: Text("Are you sure you want to delete '${product.name}'?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseService.products.doc(product.id).delete();
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
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
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 16),
          const Text("No products found",
              style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}
