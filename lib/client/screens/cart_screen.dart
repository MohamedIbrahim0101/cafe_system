import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../state/cart_provider.dart';
import '../../core/models/order_model.dart';
import '../../core/services/firebase_service.dart';
import '../../app/constants.dart';

class CartScreen extends StatelessWidget {
  final int tableNumber;
  const CartScreen({super.key, required this.tableNumber});

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    const Color primaryColor = Color(0xFF00B686);
    const Color noonDark = Color(0xFF2D2D2D);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7), // نفس خلفية المنيو
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "MY BASKET",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 15,
            letterSpacing: 1.1,
          ),
        ),
        actions: [
          if (cartProvider.items.isNotEmpty)
            TextButton(
              onPressed: () => _showClearConfirm(context, cartProvider),
              child: const Text("Clear",
                  style: TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.bold)),
            )
        ],
      ),
      body: cartProvider.items.isEmpty
          ? _buildEmptyState(context)
          : Column(
              children: [
                // إشعار بسيط بخصوص الطاولة
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: primaryColor.withOpacity(0.1),
                  child: Text(
                    "Ordering for Table $tableNumber",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                // قائمة المنتجات
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartProvider.items.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final item = cartProvider.items[i];
                      return _buildNoonCartItem(
                          item, cartProvider, primaryColor);
                    },
                  ),
                ),
                // ملخص الفاتورة وزر التأكيد
                _buildNoonCheckoutPanel(
                    context, cartProvider, primaryColor, noonDark),
              ],
            ),
    );
  }

  Widget _buildNoonCartItem(
      dynamic item, CartProvider provider, Color primary) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // الصورة
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              item.imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          // بيانات المنتج
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'USD ${item.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          // التحكم في الكمية (Noon Style)
          Container(
            height: 35,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => provider.updateQuantity(
                      item.productId, item.quantity - 1),
                  icon: const Icon(Icons.remove, size: 14),
                  constraints: const BoxConstraints(minWidth: 30),
                  padding: EdgeInsets.zero,
                ),
                Text('${item.quantity}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                IconButton(
                  onPressed: () => provider.updateQuantity(
                      item.productId, item.quantity + 1),
                  icon: const Icon(Icons.add, size: 14),
                  constraints: const BoxConstraints(minWidth: 30),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoonCheckoutPanel(
      BuildContext context, CartProvider cart, Color primary, Color dark) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Order Total",
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                Text("USD ${cart.totalPrice.toStringAsFixed(2)}",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: dark,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                onPressed: () => _processOrder(context, cart),
                child: const Text(
                  'CONFIRM ORDER',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _processOrder(BuildContext context, CartProvider cart) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
            child: CircularProgressIndicator(color: Colors.black)));

    try {
      final orderId = DateTime.now().millisecondsSinceEpoch.toString();
      final orderItems = cart.items
          .map((item) => OrderItem(
                productId: item.productId,
                name: item.name,
                quantity: item.quantity,
                price: item.price,
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
      cart.clear();

      if (context.mounted) {
        Navigator.pop(context); // إغلاق اللودنج
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
          Icon(Icons.shopping_basket_outlined,
              size: 100, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("Your basket is empty",
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            child: OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.black)),
              child: const Text("START SHOPPING",
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  void _showClearConfirm(BuildContext context, CartProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text("Clear Basket?"),
        content: const Text("Are you sure you want to remove all items?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text("CANCEL", style: TextStyle(color: Colors.grey))),
          TextButton(
              onPressed: () {
                provider.clear();
                Navigator.pop(ctx);
              },
              child: const Text("CLEAR",
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
