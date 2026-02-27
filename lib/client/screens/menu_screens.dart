import 'package:flutter/material.dart';
import 'package:premium_store/state/product_brovider.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// استيراد الـ Providers والخدمات
import '../../state/restaurant_provider.dart';
import '../../state/category_provider.dart';
import '../../state/cart_provider.dart';

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
        final isExpanded = _scrollController.offset < 180;
        if (isExpanded != _isAppBarExpanded) {
          setState(() => _isAppBarExpanded = isExpanded);
        }
      }
    });

    // تحديث رقم الطاولة في السلة عند الدخول
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().tableNumber = widget.tableNumber;
    });
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

    // تصفية المنتجات بناءً على التصنيف المختار
    final products = selectedCategoryId.isEmpty
        ? productProvider.products.where((p) => p.isAvailable).toList()
        : productProvider
            .getProductsByCategory(selectedCategoryId)
            .where((p) => p.isAvailable)
            .toList();

    const Color primaryColor = Color(0xFF00B686);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // --- Header (SliverAppBar) ---
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                elevation: 0,
                backgroundColor: primaryColor,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.black, size: 18),
                    onPressed: () => context.pop(),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 55, bottom: 14),
                  title: _isAppBarExpanded
                      ? null
                      : Text(restaurant?.name ?? "Menu",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
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
                            colors: [Colors.transparent, Colors.black87],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              restaurant?.name.toUpperCase() ?? "RESTO",
                              style: GoogleFonts.cinzel(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.table_restaurant,
                                    color: Colors.white70, size: 12),
                                const SizedBox(width: 4),
                                Text("Table ${widget.tableNumber} • Menu",
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 11)),
                              ],
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
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: _buildCategoryList(categoryProvider, primaryColor),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildSmallGridProductCard(
                          products[index], primaryColor),
                      childCount: products.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),

          // --- Floating Cart ---
          if (cartProvider.totalItems > 0)
            Positioned(
              bottom: 20,
              left: 15,
              right: 15,
              child: _buildFloatingCart(cartProvider, primaryColor),
            ),
        ],
      ),
    );
  }

  Widget _buildSmallGridProductCard(dynamic product, Color primary) {
    return GestureDetector(
      // التعديل هنا ليتوافق مع الراوتر (إرسال الـ table كـ query parameter)
      onTap: () =>
          context.push('/product/${product.id}?table=${widget.tableNumber}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 10,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Hero(
                  tag: product.id,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      product.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 7,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 14),
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

  Widget _buildCategoryList(CategoryProvider provider, Color primary) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
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
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? primary : Colors.white,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                  color: primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4))
                            ]
                          : [],
                      border: Border.all(
                        color: isSelected ? primary : Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: isAll
                          ? Icon(Icons.grid_view_rounded,
                              size: 24,
                              color: isSelected ? Colors.white : Colors.grey)
                          : (imageUrl != null && imageUrl.isNotEmpty)
                              ? Image.network(imageUrl, fit: BoxFit.cover)
                              : Icon(Icons.fastfood,
                                  color:
                                      isSelected ? Colors.white : Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? primary : Colors.black54,
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

  Widget _buildFloatingCart(CartProvider cart, Color primary) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        // التعديل الجوهري هنا: استخدام الـ Query Parameter كما هو معرّف في الراوتر
        onTap: () => context.push('/cart?table=${widget.tableNumber}'),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8))
            ],
          ),
          child: Row(
            children: [
              Badge(
                label: Text("${cart.totalItems}"),
                backgroundColor: primary,
                child: const Icon(Icons.shopping_bag_outlined,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 15),
              const Text("View Basket",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              const Spacer(),
              Text("\$${cart.totalPrice.toStringAsFixed(2)}",
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(width: 5),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white54, size: 12),
            ],
          ),
        ),
      ),
    );
  }
}
