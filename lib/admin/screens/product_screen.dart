import 'package:flutter/material.dart';
import 'package:premium_store/app/sidebar.dart';
import 'package:premium_store/state/product_brovider.dart';
import 'package:provider/provider.dart';

// Models & Services
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
  final Color primaryGreen = const Color(0xFF00B686);

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: isMobile ? const Drawer(child: AdminSidebar()) : null,
      body: Row(
        children: [
          if (!isMobile) const AdminSidebar(),
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
                              child: CircularProgressIndicator(
                                  color: primaryGreen))
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
            backgroundColor: primaryGreen,
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
        int crossAxisCount = (width / 220).floor();
        if (crossAxisCount < 2) crossAxisCount = 2;

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.65, // زيادة الطول لاحتواء السويتش
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
    // الحصول على السعر (أصغر سعر في حال وجود أحجام)
   String displayPrice = product.price.toStringAsFixed(2);
    
    // التعديل هنا: استخدام values للوصول للأرقام مباشرة
    if (product.hasSizes && product.sizes.isNotEmpty) {
      double minPrice = product.sizes.values.reduce((a, b) => a < b ? a : b);
      displayPrice = minPrice.toStringAsFixed(2);
    }

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
                Text("\$$displayPrice",
                    style: TextStyle(
                        color: primaryGreen,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text("Available", style: TextStyle(fontSize: 12)),
                    Switch(
                      value: product.isAvailable,
                      activeColor: primaryGreen,
                      onChanged: (val) async {
                        await FirebaseService.products.doc(product.id).update({'isAvailable': val});
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product Updated Successfully")));
                      },
                    ),
                  ],
                ),
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
        color: isAvailable ? primaryGreen : Colors.redAccent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(isAvailable ? "Available" : "Sold Out",
          style: const TextStyle(
              color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  void _navigateToEdit(BuildContext context, Product? product) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AddProductScreen(product: product)),
    ).then((_) {
       // إضافة تنبيه عند العودة من شاشة التعديل
       if (product != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product Updated Successfully")));
       }
    });
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Product"),
        content: Text("Are you sure you want to delete '${product.name}'?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseService.products.doc(product.id).delete();
              if (mounted) Navigator.pop(dialogContext);
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