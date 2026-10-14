
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../state/cart_provider.dart';
import '../../state/order_provider.dart';
import '../../core/models/order_model.dart';

class CartScreen extends StatelessWidget {
  final int tableNumber;
  final String restaurantId;

  const CartScreen({
    super.key,
    required this.tableNumber,
    required this.restaurantId,
  });

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();

    const Color primaryColor = Color(0xFF00B686);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'MY BASKET',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          if (cartProvider.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: () {
                  _showClearConfirm(context, cartProvider);
                },
                child: const Text(
                  'Clear',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: cartProvider.items.isEmpty
          ? _buildEmptyState(context)
          : Column(
              children: [
                // TABLE HEADER
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: Color(0xFFEEEEEE),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.table_restaurant,
                        size: 16,
                        color: Colors.black,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tableNumber == 0
                            ? 'TAKEAWAY'
                            : 'TABLE: $tableNumber',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),

                // CART ITEMS
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ...cartProvider.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: _buildNoonCartItem(
                            item,
                            cartProvider,
                          ),
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),

                // CHECKOUT PANEL
                _buildNoonCheckoutPanel(
                  context,
                  cartProvider,
                  primaryColor,
                ),
              ],
            ),
    );
  }

  // =========================================================
  // CART ITEM
  // =========================================================

  Widget _buildNoonCartItem(
    dynamic item,
    CartProvider provider,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // PRODUCT IMAGE
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    item.imageUrl,
                    width: 75,
                    height: 75,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 75,
                        height: 75,
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 15),

                // NAME + PRICE
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'EGP ${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      if (item.selectedSize != null &&
                          item.selectedSize.toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Size: ${item.selectedSize}',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // QUANTITY CONTROL
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.remove,
                          size: 16,
                          color: Colors.black,
                        ),
                        onPressed: () {
                          provider.updateQuantity(
                            item.cartItemId,
                            item.quantity - 1,
                          );
                        },
                      ),
                      Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add,
                          size: 16,
                          color: Colors.black,
                        ),
                        onPressed: () {
                          provider.updateQuantity(
                            item.cartItemId,
                            item.quantity + 1,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // SIDE DISH / NOTE
          if (item.notes.toString().trim().isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFE0E0E0),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.restaurant_menu,
                    size: 18,
                    color: Color(0xFF00B686),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.notes,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ITEM NOTE
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFE0E0E0),
              ),
            ),
            child: TextField(
              onChanged: (value) {
                provider.updateItemNote(
                  item.cartItemId,
                  value,
                );
              },
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              cursorColor: Colors.black,
              decoration: const InputDecoration(
                hintText: 'Special request (no onion, extra sauce...)',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
                border: InputBorder.none,
                icon: Icon(
                  Icons.edit_note,
                  size: 18,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // CHECKOUT PANEL
  // =========================================================

  Widget _buildNoonCheckoutPanel(
    BuildContext context,
    CartProvider cart,
    Color primary,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 35),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // TOTAL
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL AMOUNT',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'EGP ${cart.totalPrice.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // CONFIRM BUTTON
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              onPressed: () => _processOrder(context, cart),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'CONFIRM ORDER',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(width: 10),
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // PROCESS ORDER
  // =========================================================

  Future<void> _processOrder(
    BuildContext context,
    CartProvider cart,
  ) async {
    if (restaurantId.trim().isEmpty) {
      _showMessage(
        context,
        'Restaurant ID is missing',
        isError: true,
      );
      return;
    }

    if (cart.items.isEmpty) {
      _showMessage(
        context,
        'Your basket is empty',
        isError: true,
      );
      return;
    }

    final orderProvider = context.read<OrderProvider>();

    // Make sure the provider uses the restaurant for this menu.
    orderProvider.updateRestaurantId(restaurantId);

    // Ensure client session initialization has finished.
    var sessionId = orderProvider.clientSessionId;

    if (sessionId == null || sessionId.isEmpty) {
      await Future<void>.delayed(
        const Duration(milliseconds: 150),
      );
      sessionId = orderProvider.clientSessionId;
    }

    if (sessionId == null || sessionId.isEmpty) {
      _showMessage(
        context,
        'Could not initialize your session. Please try again.',
        isError: true,
      );
      return;
    }

    debugPrint('========================================');
    debugPrint('Creating new order...');
    debugPrint('Restaurant ID: "$restaurantId"');
    debugPrint('Client Session ID: "$sessionId"');
    debugPrint('Table Number: "$tableNumber"');
    debugPrint('Cart Items: ${cart.items.length}');
    debugPrint('Cart Total: ${cart.totalPrice}');
    debugPrint('========================================');

    var loadingDialogOpen = false;

    try {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF00B686),
          ),
        ),
      );

      loadingDialogOpen = true;

      final orderItems = cart.items.map((item) {
        return OrderItem(
          productId: item.productId,
          name: item.name,
          quantity: item.quantity,
          price: item.price,
          notes: item.notes,
          size: item.selectedSize,
          productType: item.productType,
        );
      }).toList();

      final order = Order(
        id: 'TEMP-${DateTime.now().microsecondsSinceEpoch}',
        tableNumber: tableNumber,
        items: orderItems,
        totalPrice: cart.totalPrice,
        status: 'Pending',
        createdAt: DateTime.now(),
        orderType: tableNumber == 0 ? 'Takeaway' : 'Dining',
        clientSessionId: sessionId,
      );

      // addNewOrder saves the Firestore ID and local active order.
      final firestoreOrderId =
          await orderProvider.addNewOrder(order);

      debugPrint('✅ Order saved successfully');
      debugPrint('Firestore Order ID: $firestoreOrderId');

      cart.clear();

      if (!context.mounted) return;

      if (loadingDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        loadingDialogOpen = false;
      }

      context.push('/order-status/$firestoreOrderId');
    } catch (e, stackTrace) {
      debugPrint('❌ Error creating order: $e');
      debugPrint('StackTrace: $stackTrace');

      if (!context.mounted) return;

      if (loadingDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      _showMessage(
        context,
        'Error creating order: $e',
        isError: true,
      );
    }
  }

  // =========================================================
  // EMPTY CART
  // =========================================================

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_basket_outlined,
            size: 80,
            color: Colors.black26,
          ),
          const SizedBox(height: 20),
          Text(
            'Your basket is empty',
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'BROWSE MENU',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // CLEAR CART CONFIRMATION
  // =========================================================

  void _showClearConfirm(
    BuildContext context,
    CartProvider provider,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Clear Basket?',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Remove all items from your basket?',
            style: TextStyle(color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'CANCEL',
                style: TextStyle(color: Colors.black54),
              ),
            ),
            TextButton(
              onPressed: () {
                provider.clear();
                Navigator.pop(ctx);
              },
              child: const Text(
                'YES, CLEAR',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF00B686),
      ),
    );
  }
}
