import 'package:flutter/material.dart';
import 'package:premium_store/state/product_brovider.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// استيراد الـ Providers والخدمات
import '../../state/restaurant_provider.dart';
import '../../state/category_provider.dart';
import '../../state/cart_provider.dart';
import '../../state/order_provider.dart';

class MenuScreen extends StatefulWidget {
  final int tableNumber;
  const MenuScreen({super.key, required this.tableNumber});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String selectedCategoryId = '';
  final ScrollController _scrollController = ScrollController();
  bool _isAppBarExpanded = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final isExpanded = _scrollController.offset < 160;
        if (isExpanded != _isAppBarExpanded) {
          setState(() => _isAppBarExpanded = isExpanded);
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().tableNumber = widget.tableNumber;
    });
  }

  // دالة لجلب رسالة ترحيبية بناءً على الوقت
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning ☀️";
    if (hour < 17) return "Good Afternoon ☕";
    return "Good Evening ✨";
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = context.watch<RestaurantProvider>().restaurant;
    final categoryProvider = context.watch<CategoryProvider>();
    final productProvider = context.watch<ProductProvider>();
    final cartProvider = context.watch<CartProvider>();
    final orderProvider = context.watch<OrderProvider>();

    final products = selectedCategoryId.isEmpty
        ? productProvider.products.where((p) => p.isAvailable).toList()
        : productProvider
            .getProductsByCategory(selectedCategoryId)
            .where((p) => p.isAvailable)
            .toList();

    const Color primaryColor = Color(0xFF00B686);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // --- Header (SliverAppBar) ---
              SliverAppBar(
                expandedHeight: 250, // تم زيادة الطول لإبراز اسم المطعم
                pinned: true,
                elevation: 0,
                automaticallyImplyLeading: false, // حذف زر الرجوع
                backgroundColor: primaryColor,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding: const EdgeInsets.only(bottom: 16),
                  title: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isAppBarExpanded ? 0.0 : 1.0,
                    child: Text(
                      restaurant?.name ?? "MENU",
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
                      // خلفية الصورة مع Overlay داكن
                      if (restaurant?.coverImageUrl != null &&
                          restaurant!.coverImageUrl.isNotEmpty)
                        Image.network(restaurant.coverImageUrl,
                            fit: BoxFit.cover)
                      else
                        Container(color: primaryColor),

                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black45, Colors.black87],
                          ),
                        ),
                      ),

                      // اسم المطعم ورقم الطاولة والترحيب (في المنتصف)
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
                                  letterSpacing: 1),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              restaurant?.name.toUpperCase() ??
                                  "OUR RESTAURANT",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cinzel(
                                color: Colors.white,
                                fontSize: 28, // اسم كبير وواضح
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "TABLE ${widget.tableNumber}",
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

              // --- Categories ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          "Categories",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildCategoryList(categoryProvider, primaryColor),
                    ],
                  ),
                ),
              ),

              // --- Products Grid ---
              if (productProvider.isLoading)
                const SliverFillRemaining(
                  child: Center(
                      child: CircularProgressIndicator(color: primaryColor)),
                )
              else if (products.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text("No products available")),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 15,
                      crossAxisSpacing: 15,
                      childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildSmallGridProductCard(
                          products[index], primaryColor, orderProvider),
                      childCount: products.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 150)),
            ],
          ),

          // --- Bottom UI (Active Order Bar & Floating Cart) ---
          Positioned(
            bottom: 25,
            left: 15,
            right: 15,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActiveOrderBar(orderProvider),
                const SizedBox(height: 12),
                if (cartProvider.totalItems > 0)
                  _buildFloatingCart(cartProvider, primaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Widgets (UI Components) ---

  Widget _buildActiveOrderBar(OrderProvider orderProvider) {
    final activeOrder = orderProvider.currentOrder;
    if (activeOrder == null) return const SizedBox.shrink();

    final s = activeOrder.status.toLowerCase();
    final bool isFinal = s.contains('deliv') ||
        s.contains('paid') ||
        s.contains('complet') ||
        s.contains('cancel');
    if (isFinal) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => context.push('/order-status/${activeOrder.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF00B686),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: const Offset(0, 5))
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.sync, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Order #${activeOrder.id.substring(activeOrder.id.length - 4)} is ${activeOrder.status}",
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ),
            const Text("TRACK",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12)),
            const Icon(Icons.chevron_right, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallGridProductCard(
      dynamic product, Color primary, OrderProvider orderProvider) {
    final int alreadyOrderedCount = orderProvider.currentOrder?.items
            .where((item) => item.name == product.name)
            .fold(0, (prev, element) => prev! + element.quantity) ??
        0;

    return GestureDetector(
      onTap: () =>
          context.push('/product/${product.id}?table=${widget.tableNumber}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 8))
          ],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Hero(
                      tag: product.id,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(product.imageUrl,
                            width: double.infinity, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  if (alreadyOrderedCount > 0)
                    Positioned(
                      top: 15,
                      right: 15,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(10)),
                        child: Text("Ordered: $alreadyOrderedCount",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(product.name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('EGP ${product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 15)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList(CategoryProvider provider, Color primary) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: provider.categories.length + 1,
        itemBuilder: (ctx, i) {
          bool isAll = i == 0;
          bool isSelected = isAll
              ? selectedCategoryId.isEmpty
              : selectedCategoryId == provider.categories[i - 1].id;
          String name = isAll ? "All" : provider.categories[i - 1].name;
          String? imageUrl = isAll ? null : provider.categories[i - 1].imageUrl;

          return GestureDetector(
            onTap: () => setState(() => selectedCategoryId =
                isAll ? '' : provider.categories[i - 1].id),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? primary : Colors.white,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                  color: primary.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5))
                            ]
                          : [],
                      border: Border.all(
                          color: isSelected ? primary : Colors.grey.shade200,
                          width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(35),
                      child: isAll
                          ? Icon(Icons.restaurant,
                              size: 28,
                              color: isSelected ? Colors.white : Colors.grey)
                          : (imageUrl != null && imageUrl.isNotEmpty)
                              ? Image.network(imageUrl, fit: BoxFit.cover)
                              : Icon(Icons.fastfood,
                                  color:
                                      isSelected ? Colors.white : Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(name,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? primary : Colors.black54)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFloatingCart(CartProvider cart, Color primary) {
    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: InkWell(
        onTap: () => context.push('/cart?table=${widget.tableNumber}'),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Badge(
                label: Text("${cart.totalItems}"),
                backgroundColor: primary,
                child: const Icon(Icons.shopping_basket_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 15),
              const Text("View Basket",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const Spacer(),
              Text("EGP ${cart.totalPrice.toStringAsFixed(2)}",
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              const SizedBox(width: 10),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white54, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
