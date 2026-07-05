// lib/app/pos_screen.dart
import 'package:flutter/material.dart';
import 'package:premium_store/app/sidebar.dart';
import 'package:provider/provider.dart';

// Models & Providers
import 'package:premium_store/core/models/category_model.dart';
import 'package:premium_store/core/models/product_model.dart';
import 'package:premium_store/core/models/order_model.dart';
import 'package:premium_store/state/product_brovider.dart';
import 'package:premium_store/state/category_provider.dart';
import 'package:premium_store/state/order_provider.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Color primaryGreen = const Color(0xFF00B686);

  List<OrderItem> currentCart = [];
  String searchQuery = "";
  String selectedCategoryId = "All";

  double get totalAmount =>
      currentCart.fold(0, (sum, item) => sum + (item.price * item.quantity));

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 1100;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: isMobile ? const Drawer(child: AdminSidebar()) : null,
      body: Row(
        children: [
          if (!isMobile) const AdminSidebar(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 850) {
                  return _buildVerticalLayout();
                } else {
                  return _buildHorizontalLayout();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalLayout() {
    return Row(
      children: [
        Expanded(flex: 3, child: _buildMenuSection()),
        Container(
          width: 400,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)
            ],
          ),
          child: _buildRightInvoicePanel(),
        ),
      ],
    );
  }

  Widget _buildVerticalLayout() {
    return Column(
      children: [
        Expanded(child: _buildMenuSection()),
        _buildSummaryBottomBar(),
      ],
    );
  }

  Widget _buildMenuSection() {
    final productProvider = context.watch<ProductProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    final filteredProducts = productProvider.products.where((p) {
      bool matchesSearch =
          p.name.toLowerCase().contains(searchQuery.toLowerCase());
      bool matchesCategory =
          selectedCategoryId == "All" || p.categoryId == selectedCategoryId;
      return matchesSearch && matchesCategory;
    }).toList();

    return Column(
      children: [
        _buildPOSHeader(),
        _buildCategoryBar(categoryProvider.categories),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              childAspectRatio: 0.8,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) =>
                _buildProductCard(filteredProducts[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildPOSHeader() {
    bool isMobile = MediaQuery.of(context).size.width < 1100;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              icon:
                  const Icon(Icons.menu_rounded, size: 28, color: Colors.black),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          const Expanded(
            child: Text("Point of Sale",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.black)),
          ),
          _buildSearchBox(),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      width: 250,
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: TextField(
        onChanged: (v) => setState(() => searchQuery = v),
        style: const TextStyle(color: Colors.black),
        decoration: const InputDecoration(
          hintText: "Search products...",
          hintStyle: TextStyle(color: Colors.grey),
          prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.only(top: 10),
        ),
      ),
    );
  }

  Widget _buildCategoryBar(List<CategoryModel> categories) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          String name = index == 0 ? "All" : categories[index - 1].name;
          String id = index == 0 ? "All" : categories[index - 1].id;
          bool isSelected = selectedCategoryId == id;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(name),
              selected: isSelected,
              onSelected: (v) => setState(() => selectedCategoryId = id),
              selectedColor: primaryGreen,
              backgroundColor: Colors.white,
              side: BorderSide(
                  color: isSelected ? primaryGreen : Colors.grey[300]!),
              labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      ),
    );
  }

  void _handleProductTap(Product product) {
    if (product.hasSizes &&
        product.sizes != null &&
        product.sizes!.isNotEmpty) {
      _showSizeSelectionDialog(product);
    } else {
      _addToCart(product);
    }
  }

  void _showSizeSelectionDialog(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Select Size: ${product.name}",
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: product.sizes!.entries.map((entry) {
            return ListTile(
              title: Text(entry.key,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text("\$${entry.value}",
                  style: TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              onTap: () {
                Navigator.pop(ctx);
                _addToCart(product,
                    size: entry.key, customPrice: entry.value.toDouble());
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _addToCart(Product product, {String? size, double? customPrice}) {
    setState(() {
      double finalPrice = customPrice ?? product.price;
      String finalName =
          size != null ? "${product.name} - $size" : product.name;
      String sizeNote = size ?? "";

      int index = currentCart.indexWhere(
          (item) => item.productId == product.id && item.notes == sizeNote);

      if (index != -1) {
        currentCart[index] = currentCart[index]
            .copyWith(quantity: currentCart[index].quantity + 1);
      } else {
        currentCart.add(OrderItem(
          productId: product.id,
          name: finalName,
          quantity: 1,
          price: finalPrice,
          notes: sizeNote,
        ));
      }
    });
  }

  Widget _buildProductCard(Product product) {
    return InkWell(
      onTap: () => _handleProductTap(product),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(15)),
                child: Image.network(
                  product.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.fastfood, size: 50),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black)),
                  const SizedBox(height: 4),
                  Text(
                    product.hasSizes
                        ? "Multiple Sizes"
                        : "\$${product.price.toStringAsFixed(2)}",
                    style: TextStyle(
                        color: primaryGreen,
                        fontWeight: FontWeight.w900,
                        fontSize: product.hasSizes ? 13 : 14),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRightInvoicePanel() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Current Order",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.black)),
              if (currentCart.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined,
                      color: Colors.red),
                  onPressed: () => setState(() => currentCart.clear()),
                )
            ],
          ),
        ),
        Expanded(
          child: currentCart.isEmpty
              ? const Center(
                  child: Text("Cart is empty",
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  itemCount: currentCart.length,
                  itemBuilder: (context, index) {
                    final item = currentCart[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBFBFB),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.black.withOpacity(0.05)),
                      ),
                      child: ListTile(
                        title: Text(item.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: Colors.black)),
                        subtitle: Text("\$${item.price} x ${item.quantity}",
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                                "\$${(item.price * item.quantity).toStringAsFixed(2)}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                    fontSize: 14)),
                            const SizedBox(width: 5),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: Colors.redAccent, size: 22),
                              onPressed: () =>
                                  setState(() => currentCart.removeAt(index)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        _buildSummarySection(),
      ],
    );
  }

  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.1))),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Amount",
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                      fontWeight: FontWeight.bold)),
              Text("\$${totalAmount.toStringAsFixed(2)}",
                  style: TextStyle(
                      fontSize: 26,
                      color: primaryGreen,
                      fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: currentCart.isEmpty ? null : _handleCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: const Text("PROCESS CHECKOUT",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16)),
            ),
          )
        ],
      ),
    );
  }

  void _handleCheckout() async {
    final orderProvider = context.read<OrderProvider>();
    final List<int> availableTables = List.generate(15, (i) => i + 1);

    int? selectedTable = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Select Order Destination",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.shopping_bag, color: primaryGreen),
                title: const Text("Takeaway",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () => Navigator.pop(ctx, 0),
              ),
              const Divider(),
              SizedBox(
                height: 200,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2,
                  ),
                  itemCount: availableTables.length,
                  itemBuilder: (context, index) {
                    return TextButton(
                      onPressed: () =>
                          Navigator.pop(ctx, availableTables[index]),
                      child: Text("T ${availableTables[index]}"),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selectedTable == null) return;

    try {
      final newOrder = Order(
        id: "",
        items: List.from(currentCart),
        totalPrice: totalAmount,
        tableNumber: selectedTable,
        orderType: selectedTable == 0 ? 'Takeaway' : 'Dining', // 🔥 إضافة النوع
        status: "Pending", // عادة نبدأ بـ Pending
        createdAt: DateTime.now(),
      );

      await orderProvider.addNewOrder(newOrder);

      setState(() => currentCart.clear());
      if (mounted) {
        String msg = selectedTable == 0
            ? "Order set as Takeaway"
            : "Order Sent to Table $selectedTable";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(msg,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: primaryGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Error processing order"),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildSummaryBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("\$${totalAmount.toStringAsFixed(2)}",
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
          ElevatedButton(
            onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.white,
                builder: (_) => SizedBox(
                    height: MediaQuery.of(context).size.height * 0.8,
                    child: _buildRightInvoicePanel())),
            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
            child: const Text("View Order",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}
