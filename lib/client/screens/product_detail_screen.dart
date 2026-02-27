import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../state/product_brovider.dart';
import '../../state/cart_provider.dart';
import '../../app/constants.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;
  final int tableNumber;

  const ProductDetailsScreen(
      {super.key, required this.productId, required this.tableNumber});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int qty = 1; // نقلناها للـ State عشان الـ UI يتحدث فوراً

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF00B686);

    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        final product = productProvider.products.firstWhere(
          (p) => p.id == widget.productId,
          orElse: () => throw Exception('Product not found'),
        );
        final cartProvider = Provider.of<CartProvider>(context);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.black, size: 20),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined,
                    color: Colors.black, size: 20),
                onPressed: () {},
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    // --- Product Image Box ---
                    Container(
                      height: MediaQuery.of(context).size.height * 0.4,
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF9F9F9),
                      ),
                      child: Hero(
                        tag: product.id,
                        child: Image.network(product.imageUrl,
                            fit: BoxFit.contain),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Brand / Category Tag ---
                          Text(
                            "FRESH SELECTION",
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // --- Product Name ---
                          Text(
                            product.name,
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2D2D2D),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // --- Price ---
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              const Text("USD ",
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
                              Text(
                                product.price.toStringAsFixed(2),
                                style: const TextStyle(
                                    fontSize: 28, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "(Inclusive of VAT)",
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                          const Divider(height: 40),
                          // --- Description ---
                          const Text("Overview",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Text(
                            product.description,
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                height: 1.6),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // --- Bottom Action Bar (Noon Style) ---
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5))
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      // --- Quantity Selector ---
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: primaryColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed:
                                  qty > 1 ? () => setState(() => qty--) : null,
                              icon: const Icon(Icons.remove, size: 18),
                            ),
                            Text('$qty',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            IconButton(
                              onPressed: () => setState(() => qty++),
                              icon: const Icon(Icons.add, size: 18),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      // --- Add to Cart Button ---
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              for (int i = 0; i < qty; i++) {
                                cartProvider.add(product);
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: primaryColor,
                                  content: Text(
                                      'Added $qty ${product.name} to your basket'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              context.pop();
                            },
                            child: const Text(
                              'ADD TO CART',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1),
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
