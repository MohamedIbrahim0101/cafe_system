import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../state/product_brovider.dart';
import '../../state/cart_provider.dart';
import '../../app/constants.dart';
import '../../core/models/product_model.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String restaurantId;
  final String productId;
  final int tableNumber;

  const ProductDetailsScreen({
    super.key,
    required this.restaurantId,
    required this.productId,
    required this.tableNumber,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int qty = 1;

  // الحجم المختار
  String? selectedSize;

  // الـ Side Dishes المختارة
  final Set<int> selectedSideDishes = {};

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF00B686);

    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        final product = productProvider.products.firstWhere(
          (p) => p.id == widget.productId,
          orElse: () => throw Exception('Product not found'),
        );

        final cartProvider =
            Provider.of<CartProvider>(context, listen: false);

        // ============================================================
        // Default Size
        // ============================================================

        if (product.hasSizes &&
            product.sizes.isNotEmpty &&
            selectedSize == null) {
          selectedSize = product.sizes.keys.first;
        }

        // ============================================================
        // Product Base Price
        // ============================================================

        final double displayPrice =
            (product.hasSizes && selectedSize != null)
                ? product.sizes[selectedSize]!
                : product.price;

        // ============================================================
        // Side Dishes Total
        // ============================================================

        double sideDishesTotal = 0.0;

        for (final index in selectedSideDishes) {
          if (index >= 0 && index < product.sideDishes.length) {
            sideDishesTotal += product.sideDishes[index].price;
          }
        }

        // ============================================================
        // Final Price
        // ============================================================

        final double finalUnitPrice = displayPrice + sideDishesTotal;

        return Scaffold(
          backgroundColor: Colors.white,

          // ==========================================================
          // APP BAR
          // ==========================================================

          appBar: AppBar(
            backgroundColor: const Color.fromARGB(255, 81, 143, 83),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.black,
                size: 20,
              ),
              onPressed: () => context.pop(),
            ),
          ),

          // ==========================================================
          // BODY
          // ==========================================================

          body: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    // ==================================================
                    // PRODUCT IMAGE
                    // ==================================================

                    Container(
                      height: MediaQuery.of(context).size.height * 0.4,
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF9F9F9),
                      ),
                      child: Hero(
                        tag: product.id,
                        child: Image.network(
                          product.imageUrl,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    // ==================================================
                    // PRODUCT INFORMATION
                    // ==================================================

                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ============================================
                          // CATEGORY TAG
                          // ============================================

                          const Text(
                            "FRESH SELECTION",
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // ============================================
                          // PRODUCT NAME
                          // ============================================

                          Text(
                            product.name,
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2D2D2D),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ============================================
                          // PRICE
                          // ============================================

                          Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              const Text(
                                "EGP ",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),

                              Text(
                                finalUnitPrice.toStringAsFixed(2),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black87,
                                ),
                              ),

                              const SizedBox(width: 10),

                              Text(
                                "(Inclusive of VAT)",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),

                          const Divider(height: 30),

                          // =================================================
                          // SIZE SELECTION
                          // =================================================

                          if (product.hasSizes &&
                              product.sizes.isNotEmpty) ...[
                            const Text(
                              "Select Size",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 12),

                            Wrap(
                              spacing: 12,
                              children:
                                  product.sizes.keys.map((sizeName) {
                                final isSelected =
                                    selectedSize == sizeName;

                                return ChoiceChip(
                                  label: Text(
                                    sizeName.toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedColor: primaryColor,
                                  backgroundColor:
                                      Colors.grey.shade100,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        selectedSize = sizeName;
                                      });
                                    }
                                  },
                                );
                              }).toList(),
                            ),

                            const Divider(height: 30),
                          ],

                          // =================================================
                          // SIDE DISHES
                          // =================================================

                          if (product.sideDishes.isNotEmpty) ...[
                            const Text(
                              "Add Side Dishes",
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              "Choose your favorite side dishes",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),

                            const SizedBox(height: 12),

                            Column(
                              children: List.generate(
                                product.sideDishes.length,
                                (index) {
                                  final sideDish =
                                      product.sideDishes[index];

                                  final isSelected =
                                      selectedSideDishes.contains(index);

                                  return Container(
                                    margin: const EdgeInsets.only(
                                      bottom: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? primaryColor.withOpacity(0.06)
                                          : Colors.grey.shade50,
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected
                                            ? primaryColor
                                            : Colors.grey.shade200,
                                      ),
                                    ),
                                    child: CheckboxListTile(
                                      value: isSelected,
                                      activeColor: primaryColor,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 2,
                                      ),
                                      title: Text(
                                        sideDish.name,
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        sideDish.price > 0
                                            ? '+ EGP ${sideDish.price.toStringAsFixed(2)}'
                                            : 'Free',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: sideDish.price > 0
                                              ? primaryColor
                                              : Colors.grey.shade600,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          if (value == true) {
                                            selectedSideDishes.add(index);
                                          } else {
                                            selectedSideDishes.remove(index);
                                          }
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),

                            // ==============================================
                            // SELECTED SIDE DISHES TOTAL
                            // ==============================================

                            if (selectedSideDishes.isNotEmpty)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(
                                  top: 5,
                                  bottom: 10,
                                ),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.08),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Side Dishes Total",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      "EGP ${sideDishesTotal.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const Divider(height: 30),
                          ],

                          // =================================================
                          // DESCRIPTION
                          // =================================================

                          const Text(
                            "Overview",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            product.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.6,
                            ),
                          ),

                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ==========================================================
              // BOTTOM ACTION BAR
              // ==========================================================

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      // ==================================================
                      // QUANTITY SELECTOR
                      // ==================================================

                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: primaryColor,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: qty > 1
                                  ? () {
                                      setState(() {
                                        qty--;
                                      });
                                    }
                                  : null,
                              icon: const Icon(
                                Icons.remove,
                                size: 18,
                              ),
                            ),

                            Text(
                              '$qty',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            IconButton(
                              onPressed: () {
                                setState(() {
                                  qty++;
                                });
                              },
                              icon: const Icon(
                                Icons.add,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 15),

                      // ==================================================
                      // ADD TO CART
                      // ==================================================

                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),

                            onPressed: () {
                              // ==========================================
                              // SIDE DISH NAMES
                              // ==========================================

                              final List<String> selectedSideDishNames =
                                  [];

                              for (final index
                                  in selectedSideDishes) {
                                if (index >= 0 &&
                                    index <
                                        product.sideDishes.length) {
                                  selectedSideDishNames.add(
                                    product.sideDishes[index].name,
                                  );
                                }
                              }

                              // ==========================================
                              // NOTES
                              // ==========================================

                              String notes = "";

                              if (selectedSideDishNames.isNotEmpty) {
                                notes =
                                    "Side Dishes: ${selectedSideDishNames.join(', ')}";
                              }

                              // ==========================================
                              // CREATE UNIQUE ID
                              //
                              // This prevents:
                              //
                              // Burger + Fries
                              //
                              // from being merged with:
                              //
                              // Burger + Salad
                              // ==========================================

                              final String sideDishIds =
                                  selectedSideDishes.isEmpty
                                      ? "no_side"
                                      : selectedSideDishes
                                          .toList()
                                          .toList()
                                          .join("_");

                              final String sizeId =
                                  selectedSize ?? "default";

                              final String uniqueProductId =
                                  '${product.id}_${sizeId}_$sideDishIds';

                              // ==========================================
                              // PRODUCT FOR CART
                              // ==========================================

                              final Product productToCart = Product(
                                id: uniqueProductId,

                                name: selectedSize != null &&
                                        product.hasSizes
                                    ? '${product.name} ($selectedSize)'
                                    : product.name,

                                description: product.description,

                                price: finalUnitPrice,

                                imageUrl: product.imageUrl,

                                categoryId: product.categoryId,

                                isAvailable:
                                    product.isAvailable,

                                createdAt: product.createdAt,

                                hasSizes: false,

                                sizes: const {},

                                // No need to send the original
                                // side dishes to cart.
                                sideDishes: const [],
                              );

                              // ==========================================
                              // ADD TO CART
                              // ==========================================

                              for (int i = 0; i < qty; i++) {
                                cartProvider.add(
                                  productToCart,

                                  targetRestaurantId:
                                      widget.restaurantId,

                                  customPrice:
                                      finalUnitPrice,

                                  notes: notes,
                                );
                              }

                              // ==========================================
                              // SUCCESS MESSAGE
                              // ==========================================

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                SnackBar(
                                  backgroundColor: primaryColor,
                                  content: Text(
                                    'Added $qty ${productToCart.name} to your basket',
                                  ),
                                  behavior:
                                      SnackBarBehavior.floating,
                                ),
                              );

                              // ==========================================
                              // BACK
                              // ==========================================

                              context.pop();
                            },

                            child: const Text(
                              'ADD TO CART',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}