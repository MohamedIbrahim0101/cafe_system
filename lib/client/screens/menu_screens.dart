// lib/client/screens/menu_screens.dart

import 'package:flutter/material.dart';
import 'package:premium_store/state/product_brovider.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../state/restaurant_provider.dart';
import '../../state/category_provider.dart';
import '../../state/cart_provider.dart';
import '../../state/order_provider.dart';

class MenuScreen extends StatefulWidget {
  final String restaurantId;
  final int tableNumber;

  const MenuScreen({
    super.key,
    required this.restaurantId,
    required this.tableNumber,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String selectedCategoryId = '';
  String selectedProductType = 'food';
  String _searchQuery = '';

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController =
      TextEditingController();

  bool _isAppBarExpanded = true;
  bool _isInitializing = true;

  static const Color primaryColor = Color(0xFF00B686);

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_handleScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMenu();
    });
  }

  // =========================================================
  // Initialize Menu Using QR Restaurant ID
  // =========================================================

  Future<void> _initializeMenu() async {
    if (!mounted) return;

    debugPrint('========================================');
    debugPrint('🟢 Initializing QR Menu');
    debugPrint('🏪 QR restaurantId: ${widget.restaurantId}');
    debugPrint('🪑 QR tableNumber: ${widget.tableNumber}');
    debugPrint('========================================');

    try {
      // Set the current table for the customer's cart.
      context.read<CartProvider>().tableNumber =
          widget.tableNumber;

      // Get providers.
      final restaurantProvider =
          context.read<RestaurantProvider>();

      final categoryProvider =
          context.read<CategoryProvider>();

      final productProvider =
          context.read<ProductProvider>();

      final orderProvider =
          context.read<OrderProvider>();

      // IMPORTANT:
      // Set the restaurant ID from the QR URL.
      // Do not rely on the customer's login.
      restaurantProvider.updateRestaurantId(
        widget.restaurantId,
      );

      categoryProvider.updateRestaurantId(
        widget.restaurantId,
      );

      productProvider.updateRestaurantId(
        widget.restaurantId,
      );

      orderProvider.updateRestaurantId(
        widget.restaurantId,
      );

      debugPrint(
        '🏪 RestaurantProvider ID: '
        '${restaurantProvider.restaurantId}',
      );

      debugPrint(
        '📂 CategoryProvider ID: '
        '${categoryProvider.restaurantId}',
      );

      debugPrint(
        '📦 ProductProvider ID: '
        '${productProvider.restaurantId}',
      );

      // Fetch fresh data from the server.
      // The providers' snapshots listeners continue
      // to handle real-time updates.
      await Future.wait([
        restaurantProvider.refreshFromServer(),
        categoryProvider.refreshFromServer(),
        productProvider.refreshFromServer(),
      ]);

      if (!mounted) return;

      debugPrint('========================================');
      debugPrint(
        '✅ Menu initialization completed',
      );
      debugPrint(
        '🏪 Restaurant: '
        '${restaurantProvider.restaurant?.name ?? "Not loaded"}',
      );
      debugPrint(
        '📂 Categories: '
        '${categoryProvider.categories.length}',
      );
      debugPrint(
        '📦 Products: '
        '${productProvider.products.length}',
      );
      debugPrint('========================================');
    } catch (error, stackTrace) {
      debugPrint('❌ Menu initialization error: $error');
      debugPrint('📌 StackTrace: $stackTrace');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  // =========================================================
  // Scroll Handler
  // =========================================================

  void _handleScroll() {
    if (!_scrollController.hasClients || !mounted) return;

    final isExpanded = _scrollController.offset < 160;

    if (isExpanded != _isAppBarExpanded) {
      setState(() {
        _isAppBarExpanded = isExpanded;
      });
    }
  }

  // =========================================================
  // Greeting
  // =========================================================

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon ☕';

    return 'Good Evening ✨';
  }

  // =========================================================
  // Build
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final restaurantProvider =
        context.watch<RestaurantProvider>();

    final restaurant = restaurantProvider.restaurant;

    final categoryProvider =
        context.watch<CategoryProvider>();

    final productProvider =
        context.watch<ProductProvider>();

    final cartProvider =
        context.watch<CartProvider>();

    final orderProvider =
        context.watch<OrderProvider>();

    // Show only the order belonging to this restaurant.
    final isCorrectRestaurant =
        orderProvider.restaurantId == widget.restaurantId;

    final activeOrder =
        isCorrectRestaurant ? orderProvider.currentOrder : null;

    // Filter products by Food or Drinks.
    final typedProducts = productProvider.products.where((product) {
      return product.productType.toLowerCase().trim() ==
          selectedProductType;
    }).toList();

    // Filter products by category.
    final categoryProducts = selectedCategoryId.isEmpty
        ? typedProducts
        : typedProducts.where((product) {
            return product.categoryId == selectedCategoryId;
          }).toList();

    // Search and hide unavailable products.
    final products = categoryProducts.where((product) {
      return product.isAvailable &&
          product.name.toLowerCase().contains(
                _searchQuery.trim().toLowerCase(),
              );
    }).toList();

    // Restaurant name and cover image.
    final restaurantName =
        restaurant?.name.trim().isNotEmpty == true
            ? restaurant!.name.trim()
            : 'OUR RESTAURANT';

    final coverImageUrl = restaurant?.coverImageUrl ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // =================================================
              // Restaurant Header
              // =================================================

              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                elevation: 0,
                automaticallyImplyLeading: false,
                backgroundColor: primaryColor,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding:
                      const EdgeInsets.only(bottom: 16),
                  title: AnimatedOpacity(
                    duration:
                        const Duration(milliseconds: 200),
                    opacity: _isAppBarExpanded ? 0.0 : 1.0,
                    child: Text(
                      restaurantName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (coverImageUrl.isNotEmpty)
                        Image.network(
                          coverImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) {
                            return Container(
                              color: primaryColor,
                            );
                          },
                        )
                      else
                        Container(color: primaryColor),

                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black45,
                              Colors.black87,
                            ],
                          ),
                        ),
                      ),

                      Positioned(
                        bottom: 40,
                        left: 0,
                        right: 0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getGreeting(),
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 14,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                restaurantName.toUpperCase(),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cinzel(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.9),
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.tableNumber == 0
                                    ? 'TAKEAWAY'
                                    : 'TABLE ${widget.tableNumber}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // =================================================
              // Search, Product Types and Categories
              // =================================================

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 20,
                    bottom: 10,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search in menu...',
                            prefixIcon: const Icon(
                              Icons.search,
                              color: primaryColor,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding:
                                const EdgeInsets.symmetric(
                              vertical: 0,
                            ),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(15),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Padding(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildProductTypeButton(
                                label: 'Food',
                                icon: Icons.restaurant,
                                type: 'food',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildProductTypeButton(
                                label: 'Drinks',
                                icon: Icons.local_cafe,
                                type: 'drink',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                        child: Text(
                          'Categories',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      _buildCategoryList(
                        categoryProvider,
                        primaryColor,
                      ),
                    ],
                  ),
                ),
              ),

              // =================================================
              // Products
              // =================================================

              if (_isInitializing || productProvider.isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: primaryColor,
                    ),
                  ),
                )
              else if (products.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text('No products found'),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 15,
                      crossAxisSpacing: 15,
                      childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _buildSmallGridProductCard(
                          products[index],
                          primaryColor,
                          activeOrder,
                        );
                      },
                      childCount: products.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 150),
              ),
            ],
          ),

          // =====================================================
          // Active Order and Cart
          // =====================================================

          Positioned(
            bottom: 25,
            left: 15,
            right: 15,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActiveOrderBar(activeOrder),
                const SizedBox(height: 12),
                if (cartProvider.totalItems > 0)
                  _buildFloatingCart(
                    cartProvider,
                    primaryColor,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // Food / Drinks Button
  // =========================================================

  Widget _buildProductTypeButton({
    required String label,
    required IconData icon,
    required String type,
  }) {
    final isSelected = selectedProductType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedProductType = type;
          selectedCategoryId = '';
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 14,
        ),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color:
                  isSelected ? Colors.white : Colors.black54,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // Active Order Bar
  // =========================================================

  Widget _buildActiveOrderBar(dynamic activeOrder) {
    if (activeOrder == null) {
      return const SizedBox.shrink();
    }

    final status =
        activeOrder.status.toLowerCase().trim();

    final isFinal = status.contains('deliv') ||
        status.contains('paid') ||
        status.contains('complet') ||
        status.contains('cancel') ||
        status == 'done' ||
        status == 'served';

    if (isFinal) {
      return const SizedBox.shrink();
    }

    final orderId = activeOrder.id.toString();

    final shortId = orderId.length > 4
        ? orderId.substring(orderId.length - 4)
        : orderId;

    return GestureDetector(
      onTap: () {
        context.push('/order-status/$orderId');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.sync,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Order #$shortId is ${activeOrder.status}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const Text(
              'TRACK',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // Product Card
  // =========================================================

  Widget _buildSmallGridProductCard(
    dynamic product,
    Color primary,
    dynamic activeOrder,
  ) {
    final orderedItems = activeOrder?.items ?? [];

    final int alreadyOrderedCount = orderedItems
        .where((item) => item.productId == product.id)
        .fold<int>(
          0,
          (previous, item) => previous + item.quantity,
        );

    String displayPrice =
        product.price.toStringAsFixed(2);

    if (product.hasSizes && product.sizes.isNotEmpty) {
      final prices = product.sizes.values
          .where((value) => value is num)
          .map((value) => (value as num).toDouble())
          .toList();

      if (prices.isNotEmpty) {
        final minPrice = prices.reduce(
          (a, b) => a < b ? a : b,
        );

        displayPrice = minPrice.toStringAsFixed(2);
      }
    }

    return GestureDetector(
      onTap: () {
        context.push(
          '/product/${product.id}'
          '?restaurantId=${Uri.encodeComponent(widget.restaurantId)}'
          '&table=${widget.tableNumber}',
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Hero(
                      tag: product.id,
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(15),
                        child: Image.network(
                          product.imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  if (alreadyOrderedCount > 0)
                    Positioned(
                      top: 15,
                      right: 15,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Ordered: $alreadyOrderedCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Text(
                      product.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'EGP $displayPrice',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // Category List
  // =========================================================

  Widget _buildCategoryList(
    CategoryProvider provider,
    Color primary,
  ) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: provider.categories.length + 1,
        itemBuilder: (context, index) {
          final isAll = index == 0;

          final category = isAll
              ? null
              : provider.categories[index - 1];

          final isSelected = isAll
              ? selectedCategoryId.isEmpty
              : selectedCategoryId == category!.id;

          final name = isAll ? 'All' : category!.name;

          final imageUrl = isAll ? null : category!.imageUrl;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategoryId =
                    isAll ? '' : category!.id;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
              ),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration:
                        const Duration(milliseconds: 300),
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          isSelected ? primary : Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? primary
                            : Colors.grey.shade200,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(35),
                      child: isAll
                          ? Icon(
                              Icons.restaurant,
                              size: 28,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey,
                            )
                          : (imageUrl != null &&
                                  imageUrl.isNotEmpty)
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.fastfood,
                                      color: Colors.grey,
                                    );
                                  },
                                )
                              : Icon(
                                  Icons.fastfood,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey,
                                ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected
                          ? primary
                          : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // =========================================================
  // Floating Cart
  // =========================================================

  Widget _buildFloatingCart(
    CartProvider cart,
    Color primary,
  ) {
    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          context.push(
            '/cart'
            '?restaurantId=${Uri.encodeComponent(widget.restaurantId)}'
            '&table=${widget.tableNumber}',
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
          ),
          child: Row(
            children: [
              Badge(
                label: Text('${cart.totalItems}'),
                backgroundColor: primary,
                child: const Icon(
                  Icons.shopping_basket_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 15),
              const Text(
                'View Basket',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Text(
                'EGP ${cart.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white54,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // Dispose
  // =========================================================

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
