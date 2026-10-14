// lib/app/pos_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:premium_store/app/sidebar.dart';
import 'package:provider/provider.dart';

// Localization
import 'package:premium_store/localization/app_translations.dart';
import 'package:premium_store/state/language_provider.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  final Color primaryGreen = const Color(0xFF00B686);

  List<OrderItem> currentCart = [];

  String searchQuery = "";

  // IMPORTANT:
  // This value is used internally for filtering.
  // Do not translate it.
  String selectedCategoryId = "All";

  // =========================================================
  // CHECKOUT LOADING STATE
  // =========================================================

  bool _isCheckingOut = false;

  // =========================================================
  // TRANSLATION
  // =========================================================

  String _tr(String key) {
    final languageProvider =
        Provider.of<LanguageProvider>(context);

    return AppTranslations.get(
      languageProvider.locale.languageCode,
      key,
    );
  }

  // =========================================================
  // TOTAL AMOUNT
  // =========================================================

  double get totalAmount {
    return currentCart.fold(
      0,
      (sum, item) =>
          sum + (item.price * item.quantity),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final bool isMobile =
        MediaQuery.of(context).size.width < 1100;

    return Scaffold(
      key: _scaffoldKey,

      backgroundColor:
          const Color(0xFFF8F9FA),

      // =====================================================
      // MOBILE SIDEBAR
      // =====================================================

      drawer: isMobile
          ? const Drawer(
              child: AdminSidebar(),
            )
          : null,

      body: Row(
        children: [
          // ===================================================
          // DESKTOP SIDEBAR
          // ===================================================

          if (!isMobile)
            const AdminSidebar(),

          // ===================================================
          // MAIN CONTENT
          // ===================================================

          Expanded(
            child: LayoutBuilder(
              builder: (
                context,
                constraints,
              ) {
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

  // =========================================================
  // HORIZONTAL LAYOUT
  // =========================================================

  Widget _buildHorizontalLayout() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _buildMenuSection(),
        ),

        Container(
          width: 400,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(0.05),
                blurRadius: 15,
              ),
            ],
          ),
          child: _buildRightInvoicePanel(),
        ),
      ],
    );
  }

  // =========================================================
  // VERTICAL LAYOUT
  // =========================================================

  Widget _buildVerticalLayout() {
    return Column(
      children: [
        Expanded(
          child: _buildMenuSection(),
        ),

        _buildSummaryBottomBar(),
      ],
    );
  }

  // =========================================================
  // MENU SECTION
  // =========================================================

  Widget _buildMenuSection() {
    final productProvider =
        context.watch<ProductProvider>();

    final categoryProvider =
        context.watch<CategoryProvider>();

    // Only available products are displayed.
    final filteredProducts =
        productProvider.products.where((p) {
      // Hide sold out products.
      if (!p.isAvailable) {
        return false;
      }

      final bool matchesSearch =
          p.name
              .toLowerCase()
              .contains(
                searchQuery.toLowerCase(),
              );

      final bool matchesCategory =
          selectedCategoryId == "All" ||
          p.categoryId ==
              selectedCategoryId;

      return matchesSearch &&
          matchesCategory;
    }).toList();

    return Column(
      children: [
        // POS Header
        _buildPOSHeader(),

        // Categories
        _buildCategoryBar(
          categoryProvider.categories,
        ),

        // Products
        Expanded(
          child: GridView.builder(
            padding:
                const EdgeInsets.all(20),

            gridDelegate:
                const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              childAspectRatio: 0.8,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),

            itemCount:
                filteredProducts.length,

            itemBuilder: (
              context,
              index,
            ) {
              return _buildProductCard(
                filteredProducts[index],
              );
            },
          ),
        ),
      ],
    );
  }

  // =========================================================
  // POS HEADER
  // =========================================================

  Widget _buildPOSHeader() {
    final bool isMobile =
        MediaQuery.of(context).size.width < 1100;

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        30,
        20,
        10,
      ),

      child: Row(
        children: [
          // ===================================================
          // MOBILE MENU BUTTON
          // ===================================================

          if (isMobile)
            IconButton(
              icon: const Icon(
                Icons.menu_rounded,
                size: 28,
                color: Colors.black,
              ),

              onPressed: () {
                _scaffoldKey
                    .currentState
                    ?.openDrawer();
              },
            ),

          // ===================================================
          // TITLE
          // ===================================================

          Expanded(
            child: Text(
              _tr('point_of_sale'),

              style:
                  const TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ),

          // ===================================================
          // SEARCH
          // ===================================================

          _buildSearchBox(),
        ],
      ),
    );
  }

  // =========================================================
  // SEARCH
  // =========================================================

  Widget _buildSearchBox() {
    return Container(
      width: 250,
      height: 45,

      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(10),
        border: Border.all(
          color:
              Colors.grey.withOpacity(0.2),
        ),
      ),

      child: TextField(
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },

        style:
            const TextStyle(
          color: Colors.black,
        ),

        decoration:
            InputDecoration(
          hintText:
              _tr('search_products'),

          hintStyle:
              const TextStyle(
            color: Colors.grey,
          ),

          prefixIcon:
              const Icon(
            Icons.search,
            size: 20,
            color: Colors.grey,
          ),

          border:
              InputBorder.none,

          contentPadding:
              const EdgeInsets.only(
            top: 10,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // CATEGORY BAR
  // =========================================================

  Widget _buildCategoryBar(
    List<CategoryModel> categories,
  ) {
    return SizedBox(
      height: 60,

      child: ListView.builder(
        scrollDirection:
            Axis.horizontal,

        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 8,
        ),

        itemCount:
            categories.length + 1,

        itemBuilder: (
          context,
          index,
        ) {
          // "All" is display only.
          // Internal ID remains "All".
          final String name =
              index == 0
                  ? _tr('all')
                  : categories[
                      index - 1
                    ].name;

          final String id =
              index == 0
                  ? "All"
                  : categories[
                      index - 1
                    ].id;

          final bool isSelected =
              selectedCategoryId ==
                  id;

          return Padding(
            padding:
                const EdgeInsets.only(
              right: 12,
            ),

            child: ChoiceChip(
              label: Text(name),

              selected:
                  isSelected,

              onSelected: (value) {
                setState(() {
                  selectedCategoryId =
                      id;
                });
              },

              selectedColor:
                  primaryGreen,

              backgroundColor:
                  Colors.white,

              side:
                  BorderSide(
                color: isSelected
                    ? primaryGreen
                    : Colors.grey[300]!,
              ),

              labelStyle:
                  TextStyle(
                color: isSelected
                    ? Colors.white
                    : Colors.black,

                fontWeight:
                    isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
              ),

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // =========================================================
  // PRODUCT TAP
  // =========================================================

  void _handleProductTap(
    Product product,
  ) {
    if (!product.isAvailable) {
      return;
    }

    if (product.hasSizes &&
        product.sizes.isNotEmpty) {
      _showSizeSelectionDialog(product);
    } else {
      _addToCart(product);
    }
  }

  // =========================================================
  // SIZE DIALOG
  // =========================================================

  void _showSizeSelectionDialog(
    Product product,
  ) {
    showDialog(
      context: context,

      builder: (ctx) {
        return AlertDialog(
          title: Text(
            "${_tr('select_size')}: ${product.name}",

            style:
                const TextStyle(
              color: Colors.black,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          backgroundColor:
              Colors.white,

          content: Column(
            mainAxisSize:
                MainAxisSize.min,

            children:
                product.sizes.entries
                    .map(
              (entry) {
                return ListTile(
                  title: Text(
                    entry.key,

                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  trailing: Text(
                    "\$${entry.value.toStringAsFixed(2)}",

                    style:
                        TextStyle(
                      color:
                          primaryGreen,
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),

                  onTap: () {
                    Navigator.pop(ctx);

                    _addToCart(
                      product,
                      size: entry.key,
                      customPrice:
                          entry.value
                              .toDouble(),
                    );
                  },
                );
              },
            ).toList(),
          ),
        );
      },
    );
  }

  // =========================================================
  // ADD TO CART
  // =========================================================

  void _addToCart(
    Product product, {
    String? size,
    double? customPrice,
  }) {
    if (!product.isAvailable) {
      return;
    }

    setState(() {
      final double finalPrice =
          customPrice ?? product.price;

      final String finalName =
          size != null
              ? "${product.name} - $size"
              : product.name;

      final String sizeNote =
          size ?? "";

      final int index =
          currentCart.indexWhere(
        (item) =>
            item.productId ==
                product.id &&
            item.notes ==
                sizeNote,
      );

      if (index != -1) {
        currentCart[index] =
            currentCart[index]
                .copyWith(
          quantity:
              currentCart[index]
                      .quantity +
                  1,
        );
      } else {
        currentCart.add(
          OrderItem(
            productId:
                product.id,
            name: finalName,
            quantity: 1,
            price: finalPrice,
            notes: sizeNote,

            // IMPORTANT:
            // Keep the product type inside the order item.
            // This allows the Orders screen to filter
            // between Food and Drinks later.
            productType:
                product.productType,
          ),
        );
      }
    });
  }

  // =========================================================
  // PRODUCT CARD
  // =========================================================

  Widget _buildProductCard(
    Product product,
  ) {
    return InkWell(
      onTap: () =>
          _handleProductTap(product),

      borderRadius:
          BorderRadius.circular(15),

      child: Container(
        decoration:
            BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(
            15,
          ),

          border: Border.all(
            color:
                Colors.grey.withOpacity(
              0.1,
            ),
          ),
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // =================================================
            // PRODUCT IMAGE
            // =================================================

            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius
                        .vertical(
                  top: Radius.circular(
                    15,
                  ),
                ),

                child:
                    Image.network(
                  product.imageUrl,

                  width:
                      double.infinity,

                  fit:
                      BoxFit.cover,

                  errorBuilder: (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return const Icon(
                      Icons.fastfood,
                      size: 50,
                    );
                  },
                ),
              ),
            ),

            // =================================================
            // PRODUCT INFO
            // =================================================

            Padding(
              padding:
                  const EdgeInsets.all(
                12,
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [
                  Text(
                    product.name,

                    maxLines: 1,

                    overflow:
                        TextOverflow
                            .ellipsis,

                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 14,
                      color:
                          Colors.black,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    product.hasSizes
                        ? _tr(
                            'multiple_sizes',
                          )
                        : "\$${product.price.toStringAsFixed(2)}",

                    style:
                        TextStyle(
                      color:
                          primaryGreen,

                      fontWeight:
                          FontWeight.w900,

                      fontSize:
                          product.hasSizes
                              ? 13
                              : 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // RIGHT INVOICE PANEL
  // =========================================================

  Widget _buildRightInvoicePanel() {
    return Column(
      children: [
        // ===================================================
        // CURRENT ORDER HEADER
        // ===================================================

        Padding(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            40,
            20,
            20,
          ),

          child: Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,

            children: [
              Text(
                _tr('current_order'),

                style:
                    const TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.w900,
                  color:
                      Colors.black,
                ),
              ),

              if (currentCart.isNotEmpty)
                IconButton(
                  icon:
                      const Icon(
                    Icons
                        .delete_sweep_outlined,
                    color:
                        Colors.red,
                  ),

                  onPressed: () {
                    setState(() {
                      currentCart
                          .clear();
                    });
                  },
                ),
            ],
          ),
        ),

        // ===================================================
        // CART
        // ===================================================

        Expanded(
          child:
              currentCart.isEmpty
                  ? Center(
                      child: Text(
                        _tr(
                          'cart_is_empty',
                        ),

                        style:
                            const TextStyle(
                          color:
                              Colors.black,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 15,
                      ),

                      itemCount:
                          currentCart
                              .length,

                      itemBuilder: (
                        context,
                        index,
                      ) {
                        final item =
                            currentCart[
                                index];

                        return Container(
                          margin:
                              const EdgeInsets
                                  .only(
                            bottom: 10,
                          ),

                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                              0xFFFBFBFB,
                            ),

                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),

                            border:
                                Border.all(
                              color: Colors
                                  .black
                                  .withOpacity(
                                0.05,
                              ),
                            ),
                          ),

                          child:
                              ListTile(
                            title: Text(
                              item.name,

                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight
                                        .w900,
                                fontSize:
                                    15,
                                color: Colors
                                    .black,
                              ),
                            ),

                            subtitle:
                                Text(
                              "\$${item.price.toStringAsFixed(2)} x ${item.quantity}",

                              style:
                                  const TextStyle(
                                color: Colors
                                    .black,
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),

                            trailing:
                                Row(
                              mainAxisSize:
                                  MainAxisSize
                                      .min,

                              children: [
                                Text(
                                  "\$${(item.price * item.quantity).toStringAsFixed(2)}",

                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .w900,
                                    color:
                                        Colors
                                            .black,
                                    fontSize:
                                        14,
                                  ),
                                ),

                                const SizedBox(
                                  width: 5,
                                ),

                                IconButton(
                                  icon:
                                      const Icon(
                                    Icons
                                        .remove_circle_outline,
                                    color:
                                        Colors
                                            .redAccent,
                                    size:
                                        22,
                                  ),

                                  onPressed:
                                      () {
                                    setState(
                                      () {
                                        currentCart
                                            .removeAt(
                                          index,
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),

        // ===================================================
        // SUMMARY
        // ===================================================

        _buildSummarySection(),
      ],
    );
  }

  // =========================================================
  // SUMMARY
  // =========================================================

  Widget _buildSummarySection() {
    return Container(
      padding:
          const EdgeInsets.all(25),

      decoration:
          BoxDecoration(
        color: Colors.white,

        border:
            Border(
          top:
              BorderSide(
            color:
                Colors.black.withOpacity(
              0.1,
            ),
          ),
        ),
      ),

      child: Column(
        children: [
          // ===================================================
          // TOTAL
          // ===================================================

          Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,

            children: [
              Text(
                _tr('total_amount'),

                style:
                    const TextStyle(
                  fontSize: 18,
                  color:
                      Colors.black,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              Text(
                "\$${totalAmount.toStringAsFixed(2)}",

                style:
                    TextStyle(
                  fontSize: 26,
                  color:
                      primaryGreen,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 20,
          ),

          // ===================================================
          // CHECKOUT BUTTON
          // ===================================================

          SizedBox(
            width:
                double.infinity,

            height: 60,

            child:
                ElevatedButton(
              onPressed:
                  currentCart.isEmpty ||
                          _isCheckingOut
                      ? null
                      : _handleCheckout,

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.black,

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),

                disabledBackgroundColor:
                    Colors.grey[300],
              ),

              child:
                  _isCheckingOut
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color:
                                Colors.white,
                          ),
                        )
                      : Text(
                          _tr(
                            'process_checkout',
                          ),

                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontWeight:
                                FontWeight
                                    .w900,
                            fontSize:
                                16,
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // CHECKOUT
  // =========================================================

  Future<void> _handleCheckout() async {
    // Prevent double checkout.
    if (_isCheckingOut ||
        currentCart.isEmpty) {
      return;
    }

    final orderProvider =
        context.read<OrderProvider>();

    final List<int> availableTables =
        List.generate(
      15,
      (index) => index + 1,
    );

    // -------------------------------------------------------
    // Select Table / Takeaway
    // -------------------------------------------------------

    final int? selectedTable =
        await showDialog<int>(
      context: context,

      builder: (ctx) {
        return AlertDialog(
          title: Text(
            _tr(
              'select_order_destination',
            ),

            style:
                const TextStyle(
              color: Colors.white,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          backgroundColor:
              Colors.black,

          content: SizedBox(
            width: 300,

            child: Column(
              mainAxisSize:
                  MainAxisSize.min,

              children: [
                // =================================================
                // TAKEAWAY
                // =================================================

                ListTile(
                  leading: Icon(
                    Icons.shopping_bag,
                    color:
                        primaryGreen,
                  ),

                  title: Text(
                    _tr('takeaway'),

                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),

                  onTap: () {
                    Navigator.pop(
                      ctx,
                      0,
                    );
                  },
                ),

                const Divider(),

                // =================================================
                // TABLES
                // =================================================

                SizedBox(
                  height: 200,

                  child:
                      GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          3,
                      childAspectRatio:
                          2,
                    ),

                    itemCount:
                        availableTables
                            .length,

                    itemBuilder:
                        (
                      context,
                      index,
                    ) {
                      return TextButton(
                        onPressed: () {
                          Navigator.pop(
                            ctx,
                            availableTables[
                                index],
                          );
                        },

                        child:
                            Text(
                          "T ${availableTables[index]}",
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // User closed the dialog.
    if (selectedTable == null) {
      return;
    }

    // -------------------------------------------------------
    // Start Loading
    // -------------------------------------------------------

    if (!mounted) {
      return;
    }

    setState(() {
      _isCheckingOut = true;
    });

    try {
      // -----------------------------------------------------
      // Create Order
      // -----------------------------------------------------

      final Order newOrder =
          Order(
        id: "",

        items:
            List<OrderItem>.from(
          currentCart,
        ),

        totalPrice:
            totalAmount,

        tableNumber:
            selectedTable,

        orderType:
            selectedTable == 0
                ? 'Takeaway'
                : 'Dining',

        // IMPORTANT:
        // Stored status must remain English.
        status: "Pending",

        createdAt:
            DateTime.now(),
      );

      // -----------------------------------------------------
      // Send Order to Firestore
      // -----------------------------------------------------

      final String
          firestoreOrderId =
          await orderProvider
              .addNewOrder(
        newOrder,
      );

      debugPrint(
        '✅ Checkout successful',
      );

      debugPrint(
        '🧾 Order ID: $firestoreOrderId',
      );

      // -----------------------------------------------------
      // Clear Cart
      // -----------------------------------------------------

      if (!mounted) {
        return;
      }

      setState(() {
        currentCart.clear();
        _isCheckingOut = false;
      });

      // -----------------------------------------------------
      // Go directly to Orders
      //
      // IMPORTANT:
      // We use GoRouter instead of Navigator.pop().
      // This prevents:
      // !debugLocked
      // popped last page
      // Duplicate GlobalKey
      // -----------------------------------------------------

      if (!mounted) {
        return;
      }

      WidgetsBinding.instance
          .addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        context.go(
          '/admin/orders',
        );
      });
    } catch (e) {
      // -----------------------------------------------------
      // Stop Loading
      // -----------------------------------------------------

      if (mounted) {
        setState(() {
          _isCheckingOut = false;
        });
      }

      debugPrint(
        '❌ Checkout Error: $e',
      );

      // -----------------------------------------------------
      // Error Message
      // -----------------------------------------------------

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              "${_tr('error_processing_order')}: $e",

              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            backgroundColor:
                Colors.red,

            duration:
                const Duration(
              seconds: 4,
            ),
          ),
        );
      }
    }
  }

  // =========================================================
  // MOBILE BOTTOM BAR
  // =========================================================

  Widget _buildSummaryBottomBar() {
    return Container(
      padding:
          const EdgeInsets.all(20),

      decoration:
          const BoxDecoration(
        color: Colors.white,

        boxShadow: [
          BoxShadow(
            color:
                Colors.black12,
            blurRadius: 10,
          ),
        ],
      ),

      child: Row(
        mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,

        children: [
          // ===================================================
          // TOTAL
          // ===================================================

          Text(
            "\$${totalAmount.toStringAsFixed(2)}",

            style:
                const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          // ===================================================
          // VIEW ORDER
          // ===================================================

          ElevatedButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,

                isScrollControlled:
                    true,

                backgroundColor:
                    Colors.white,

                builder: (_) {
                  return SizedBox(
                    height:
                        MediaQuery.of(
                              context,
                            ).size.height *
                            0.8,

                    child:
                        _buildRightInvoicePanel(),
                  );
                },
              );
            },

            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  primaryGreen,
            ),

            child: Text(
              _tr('view_order'),

              style:
                  const TextStyle(
                color:
                    Colors.white,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
