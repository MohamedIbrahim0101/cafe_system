import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../state/cart_provider.dart';
import '../../state/order_provider.dart';
import '../../core/models/order_model.dart';
import '../../core/services/firebase_service.dart';

class CartScreen extends StatelessWidget {
  final int tableNumber;
  const CartScreen({super.key, required this.tableNumber});

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    const Color primaryColor = Color(0xFF00B686);

    return Scaffold(
      // خلفية التطبيق رمادي فاتح جداً لتبرز البطاقات البيضاء
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "MY BASKET",
          style: GoogleFonts.poppins(
            color: Colors.black, // أسود صريح
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          if (cartProvider.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton(
                onPressed: () => _showClearConfirm(context, cartProvider),
                child: const Text("Clear",
                    style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
            )
        ],
      ),
      body: cartProvider.items.isEmpty
          ? _buildEmptyState(context)
          : Column(
              children: [
                // ترويسة رقم الطاولة (حاوية بيضاء وكلام أسود)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border:
                        Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.table_restaurant,
                          size: 16, color: Colors.black),
                      const SizedBox(width: 8),
                      Text(
                        "TABLE: $tableNumber",
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // قائمة المنتجات
                      ...cartProvider.items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 15.0),
                            child: _buildNoonCartItem(item, cartProvider),
                          )),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
                _buildNoonCheckoutPanel(context, cartProvider, primaryColor),
              ],
            ),
    );
  }

  Widget _buildNoonCartItem(dynamic item, CartProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // الحاوية بيضاء
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(item.imageUrl,
                      width: 75, height: 75, fit: BoxFit.cover),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black // أسود صريح
                            ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'EGP ${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 14),
                      ),
                    ],
                  ),
                ),
                // تحكم الكمية
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove,
                            size: 16, color: Colors.black),
                        onPressed: () => provider.updateQuantity(
                            item.productId, item.quantity - 1),
                      ),
                      Text('${item.quantity}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black)),
                      IconButton(
                        icon: const Icon(Icons.add,
                            size: 16, color: Colors.black),
                        onPressed: () => provider.updateQuantity(
                            item.productId, item.quantity + 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // خانة ملحوظة الصنف (Item Specific Note)
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9), // خلفية المربع فاتحة جداً
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: TextField(
              onChanged: (val) => provider.updateItemNote(item.productId, val),
              // الكلام أسود صريح وعريض
              style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
              cursorColor: Colors.black,
              decoration: const InputDecoration(
                hintText: "Special request (no onion, extra sauce...)",
                hintStyle: TextStyle(fontSize: 12, color: Colors.white),
                border: InputBorder.none,
                icon: Icon(Icons.edit_note, size: 18, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoonCheckoutPanel(
      BuildContext context, CartProvider cart, Color primary) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 35),
      decoration: BoxDecoration(
        color: Colors.white, // الحاوية بيضاء
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("TOTAL AMOUNT",
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              Text("EGP ${cart.totalPrice.toStringAsFixed(2)}",
                  style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.black)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary, // لون الزر الرئيسي
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              onPressed: () => _processOrder(context, cart),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('CONFIRM ORDER',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2)),
                  SizedBox(width: 10),
                  Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _processOrder(BuildContext context, CartProvider cart) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
            child: CircularProgressIndicator(color: Color(0xFF00B686))));

    try {
      final orderId =
          "ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";

      final orderItems = cart.items
          .map((item) => OrderItem(
                productId: item.productId,
                name: item.name,
                quantity: item.quantity,
                price: item.price,
                notes: item.notes,
              ))
          .toList();

      final order = Order(
        id: orderId,
        tableNumber: tableNumber,
        items: orderItems,
        totalPrice: cart.totalPrice,
        status: 'Pending',
        createdAt: DateTime.now(),
      );

      await FirebaseService.createOrder(order);

      if (context.mounted) {
        await context.read<OrderProvider>().saveOrderLocally(orderId);
        cart.clear();
        Navigator.pop(context);
        context.push('/order-status/$orderId');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_basket_outlined,
              size: 80, color: Colors.black26),
          const SizedBox(height: 20),
          Text("Your basket is empty",
              style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("BROWSE MENU",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _showClearConfirm(BuildContext context, CartProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Clear Basket?",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        content: const Text("Remove all items from your basket?",
            style: TextStyle(color: Colors.black87)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("CANCEL",
                  style: TextStyle(color: Colors.black54))),
          TextButton(
              onPressed: () {
                provider.clear();
                Navigator.pop(ctx);
              },
              child: const Text("YES, CLEAR",
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
