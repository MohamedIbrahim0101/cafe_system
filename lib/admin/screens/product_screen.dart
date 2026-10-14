// lib/admin/screens/products_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:premium_store/app/sidebar.dart';
import 'package:premium_store/localization/app_translations.dart';
import 'package:premium_store/state/language_provider.dart';
import 'package:premium_store/state/product_brovider.dart';
import 'package:provider/provider.dart';

// Models & Services
import '../../core/models/product_model.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final Color primaryGreen = const Color(0xFF00B686);

  // ============================================================
  // Translation helper
  // ============================================================

  String _tr(BuildContext context, String key) {
    final languageProvider = context.read<LanguageProvider>();

    return AppTranslations.get(
      languageProvider.locale.languageCode,
      key,
    );
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();

    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),

      // Mobile drawer
      drawer: isMobile
          ? const Drawer(
              child: AdminSidebar(),
            )
          : null,

      body: Row(
        children: [
          // Desktop sidebar
          if (!isMobile) const AdminSidebar(),

          Expanded(
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(
                  isMobile ? 16.0 : 30.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, isMobile),

                    const SizedBox(height: 25),

                    Expanded(
                      child: productProvider.isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                color: primaryGreen,
                              ),
                            )
                          : productProvider.products.isEmpty
                              ? _buildEmptyState(context)
                              : _buildProductGrid(
                                  context,
                                  productProvider.products,
                                ),
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

  // ============================================================
  // Header
  // ============================================================

  Widget _buildHeader(
    BuildContext context,
    bool isMobile,
  ) {
    return Row(
      children: [
        // Mobile menu button
        if (isMobile)
          IconButton(
            icon: const Icon(
              Icons.menu_rounded,
              size: 28,
            ),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),

        if (isMobile)
          const SizedBox(width: 8),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _tr(context, 'products_management'),
                style: TextStyle(
                  fontSize: isMobile ? 20 : 28,
                  fontWeight: FontWeight.w900,
                ),
              ),

              if (!isMobile)
                Text(
                  _tr(context, 'manage_restaurant_menu'),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ),

        // Add Product button
        ElevatedButton.icon(
          onPressed: () {
            _navigateToEdit(context, null);
          },

          icon: const Icon(
            Icons.add_rounded,
            size: 20,
            color: Colors.white,
          ),

          label: Text(
            isMobile
                ? _tr(context, 'add')
                : _tr(context, 'add_product'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,

            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 20,
              vertical: 15,
            ),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),

            elevation: 0,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // Product Grid
  // ============================================================

  Widget _buildProductGrid(
    BuildContext context,
    List<Product> products,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;

        int crossAxisCount = (width / 220).floor();

        if (crossAxisCount < 2) {
          crossAxisCount = 2;
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,

            // Keep original design
            childAspectRatio: 0.58,

            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),

          itemCount: products.length,

          itemBuilder: (context, index) {
            return _buildProductCard(
              context,
              products[index],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // Product Card
  // ============================================================

  Widget _buildProductCard(
    BuildContext context,
    Product product,
  ) {
    // Default price
    String displayPrice = product.price.toStringAsFixed(2);

    // If product has sizes,
    // show the minimum price
    if (product.hasSizes && product.sizes.isNotEmpty) {
      final double minPrice = product.sizes.values.reduce(
        (a, b) => a < b ? a : b,
      );

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
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // Product Image
          // ======================================================

          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),

                    child: Image.network(
                      product.imageUrl,

                      fit: BoxFit.cover,

                      errorBuilder: (_, __, ___) {
                        return Container(
                          color: Colors.grey[100],
                          child: const Icon(
                            Icons.fastfood,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Availability tag
                Positioned(
                  top: 10,
                  right: 10,
                  child: _buildAvailabilityTag(
                    context,
                    product.isAvailable,
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // Product Information
          // ======================================================

          Padding(
            padding: const EdgeInsets.all(12.0),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product name
                Text(
                  product.name,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 4),

                // Price
                Text(
                  "\$$displayPrice",

                  style: TextStyle(
                    color: primaryGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 8),

                // ==================================================
                // Availability
                // ==================================================

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    Text(
                      _tr(context, 'available'),
                      style: const TextStyle(
                        fontSize: 12,
                      ),
                    ),

                    Switch(
                      value: product.isAvailable,

                      activeColor: primaryGreen,

                      onChanged: (val) async {
                        try {
                          await context
                              .read<ProductProvider>()
                              .toggleAvailability(
                                product.id,
                                val,
                              );
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "${_tr(context, 'error_prefix')}: $e",
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),

                // ==================================================
                // Edit / Delete
                // ==================================================

                Row(
                  children: [
                    // Edit
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          _navigateToEdit(
                            context,
                            product,
                          );
                        },

                        style: TextButton.styleFrom(
                          backgroundColor:
                              Colors.blue.withOpacity(0.05),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),

                        child: Text(
                          _tr(context, 'edit'),

                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Delete
                    Container(
                      width: 35,

                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.05),

                        borderRadius: BorderRadius.circular(8),
                      ),

                      child: IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                          size: 18,
                        ),

                        onPressed: () {
                          _confirmDelete(
                            context,
                            product,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Availability Tag
  // ============================================================

  Widget _buildAvailabilityTag(
    BuildContext context,
    bool isAvailable,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),

      decoration: BoxDecoration(
        color: isAvailable
            ? primaryGreen
            : Colors.redAccent,

        borderRadius: BorderRadius.circular(8),
      ),

      child: Text(
        isAvailable
            ? _tr(context, 'available')
            : _tr(context, 'sold_out'),

        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // Navigate To Add / Edit Product
  // ============================================================

  void _navigateToEdit(
    BuildContext context,
    Product? product,
  ) {
    if (product == null) {
      context.go('/admin/add-product');
    } else {
      context.go(
        '/admin/edit-product',
        extra: product,
      );
    }
  }

  // ============================================================
  // Delete Confirmation
  // ============================================================

  void _confirmDelete(
    BuildContext context,
    Product product,
  ) {
    showDialog(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          title: Text(
            _tr(context, 'delete_product'),
          ),

          content: Text(
            "${_tr(context, 'are_you_sure_delete_product')} "
            "'${product.name}'?",
          ),

          actions: [
            // Cancel
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },

              child: Text(
                _tr(context, 'cancel'),
              ),
            ),

            // Delete
            ElevatedButton(
              onPressed: () async {
                try {
                  await context
                      .read<ProductProvider>()
                      .deleteProduct(product.id);

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "${_tr(context, 'error_prefix')}: $e",
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              child: Text(
                _tr(context, 'delete'),
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // Empty State
  // ============================================================

  Widget _buildEmptyState(
    BuildContext context,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey[200],
          ),

          const SizedBox(height: 16),

          Text(
            _tr(context, 'no_products_found'),

            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}