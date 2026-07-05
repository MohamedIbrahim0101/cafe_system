import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../state/product_brovider.dart'; // تأكد من اسم الملف عندك
import '../../state/cart_provider.dart';
import '../../app/constants.dart';
import '../../core/models/product_model.dart'; // ضفنا الـ import للمودل عشان ننسخ منه

class ProductDetailsScreen extends StatefulWidget {
  final String productId;
  final int tableNumber;

  const ProductDetailsScreen({
    super.key,
    required this.productId,
    required this.tableNumber,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int qty = 1;
  String? selectedSize; // متغير عشان نحفظ فيه الحجم اللي الزبون اختاره

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF00B686);

    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        final product = productProvider.products.firstWhere(
          (p) => p.id == widget.productId,
          orElse: () => throw Exception('Product not found'),
        );
        final cartProvider = Provider.of<CartProvider>(context, listen: false);

        // لو المنتج ليه أحجام ولسه الزبون مختارش، نختار أول حجم كافتراضي
        if (product.hasSizes && product.sizes.isNotEmpty && selectedSize == null) {
          selectedSize = product.sizes.keys.first;
        }

        // تحديد السعر اللي هيتعرض (لو ليه أحجام نعرض سعر الحجم المختار، لو لأ نعرض السعر الأساسي)
        final displayPrice = (product.hasSizes && selectedSize != null)
            ? product.sizes[selectedSize]!
            : product.price;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
              onPressed: () => context.pop(),
            ),
           
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
                        child: Image.network(product.imageUrl, fit: BoxFit.contain),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Brand / Category Tag ---
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
                              const Text("EGP ",
                                  style: TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w500)),
                              Text(
                                displayPrice.toStringAsFixed(2),
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
                          const Divider(height: 30),

                          // --- Sizes Selection (يظهر فقط لو المنتج ليه أحجام) ---
                          if (product.hasSizes && product.sizes.isNotEmpty) ...[
                            const Text(
                              "Select Size",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              children: product.sizes.keys.map((sizeName) {
                                final isSelected = selectedSize == sizeName;
                                return ChoiceChip(
                                  label: Text(
                                    sizeName.toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedColor: primaryColor,
                                  backgroundColor: Colors.grey.shade100,
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
                              onPressed: qty > 1 ? () => setState(() => qty--) : null,
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
                              // الحركة الذكية: نجهز منتج جديد بمعلومات الحجم عشان السلة
                              Product productToCart = product;
                              
                              if (product.hasSizes && selectedSize != null) {
                                productToCart = Product(
                                  id: '${product.id}_$selectedSize', // بنميز الـ ID عشان ميتلخبطش في السلة
                                  name: '${product.name} ($selectedSize)', // بنكتب الحجم جنب الاسم
                                  description: product.description,
                                  price: displayPrice, // السعر المخصص للحجم
                                  imageUrl: product.imageUrl,
                                  categoryId: product.categoryId,
                                  isAvailable: product.isAvailable,
                                  createdAt: product.createdAt,
                                  // مبنبعتش الأحجام للسلة عشان هي مش محتاجاها خلاص
                                  hasSizes: false, 
                                );
                              }

                              // الإضافة للسلة
                              for (int i = 0; i < qty; i++) {
                                cartProvider.add(productToCart);
                              }
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: primaryColor,
                                  content: Text(
                                      'Added $qty ${productToCart.name} to your basket'),
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