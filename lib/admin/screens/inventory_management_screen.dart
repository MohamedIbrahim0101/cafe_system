// lib/screens/admin/inventory_management_screen.dart

import 'package:flutter/material.dart';
import 'package:premium_store/app/sidebar.dart';
import 'package:premium_store/state/inventory_provider.dart';
import 'package:premium_store/state/order_provider.dart';
import 'package:premium_store/localization/app_translations.dart';
import 'package:premium_store/state/language_provider.dart';
import 'package:provider/provider.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() =>
      _InventoryManagementScreenState();
}

class _InventoryManagementScreenState
    extends State<InventoryManagementScreen> {
  final Color primaryGreen = const Color(0xFF00B686);
  final Color backgroundColor = const Color(0xFFF8F9FA);

  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  final _formKey = GlobalKey<FormState>();

  final _supplierNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _productNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  String _selectedUnit = 'kg';

  final List<Map<String, String>> _availableUnits = [
    {
      'value': 'kg',
      'label': 'كيلو جرام (kg)',
    },
    {
      'value': 'g',
      'label': 'جرام (g)',
    },
    {
      'value': 'L',
      'label': 'لتر (L)',
    },
    {
      'value': 'ml',
      'label': 'ملي لتر (ml)',
    },
    {
      'value': 'pcs',
      'label': 'قطعة (pcs)',
    },
    {
      'value': 'box',
      'label': 'كرتونة (box)',
    },
  ];

  // ============================================================
  // Translation
  // ============================================================

  String _tr(String key) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return AppTranslations.get(
      languageProvider.locale.languageCode,
      key,
    );
  }

  // ============================================================
  // Dispose
  // ============================================================

  @override
  void dispose() {
    _supplierNameController.dispose();
    _phoneController.dispose();
    _productNameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();

    super.dispose();
  }

  // ============================================================
  // Add Invoice Dialog
  // ============================================================

  void _showAddInvoiceDialog(
      InventoryProvider inventoryProvider) {
    _supplierNameController.clear();
    _phoneController.clear();
    _productNameController.clear();
    _quantityController.clear();
    _priceController.clear();

    setState(() {
      _selectedUnit = 'kg';
    });

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.add_shopping_cart_rounded,
                    color: primaryGreen,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _tr('add_purchase_invoice'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTextField(
                          _supplierNameController,
                          _tr('supplier_name'),
                          Icons.person_outline,
                        ),

                        const SizedBox(height: 12),

                        _buildTextField(
                          _phoneController,
                          _tr('phone_number'),
                          Icons.phone_android_outlined,
                          isTextInput: false,
                        ),

                        const SizedBox(height: 12),

                        _buildTextField(
                          _productNameController,
                          _tr('purchased_product'),
                          Icons.fastfood_outlined,
                        ),

                        const SizedBox(height: 12),

                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildTextField(
                                _quantityController,
                                _tr('quantity'),
                                Icons
                                    .production_quantity_limits_rounded,
                                isTextInput: false,
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              flex: 2,
                              child:
                                  DropdownButtonFormField<String>(
                                value: _selectedUnit,
                                decoration: InputDecoration(
                                  labelText: _tr('quantity_unit'),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 14,
                                  ),
                                ),
                                items:
                                    _availableUnits.map((unit) {
                                  return DropdownMenuItem<String>(
                                    value: unit['value'],
                                    child: Text(
                                      _translateUnit(
                                          unit['value']!),
                                      style: const TextStyle(
                                        fontSize: 13,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setDialogState(() {
                                      _selectedUnit = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        _buildTextField(
                          _priceController,
                          _tr('unit_price'),
                          Icons.price_change_outlined,
                          isTextInput: false,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext),
                  child: Text(
                    _tr('cancel'),
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );

                      try {
                        await inventoryProvider.addNewInvoice(
                          supplierName:
                              _supplierNameController.text.trim(),
                          phoneNumber:
                              _phoneController.text.trim(),
                          productName:
                              _productNameController.text.trim(),
                          quantity: double.parse(
                            _quantityController.text.trim(),
                          ),
                          unit: _selectedUnit,
                          price: double.parse(
                            _priceController.text.trim(),
                          ),
                        );

                        if (mounted) {
                          Navigator.pop(context);
                          Navigator.pop(dialogContext);

                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            SnackBar(
                              content: Text(
                                _tr(
                                    'invoice_saved_successfully'),
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            SnackBar(
                              content: Text(
                                '${_tr('error_saving')}: $e',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: Text(
                    _tr('save_to_firestore'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // Translate Units
  // ============================================================

  String _translateUnit(String unit) {
    switch (unit) {
      case 'kg':
        return _tr('kilogram_unit');

      case 'g':
        return _tr('gram_unit');

      case 'L':
        return _tr('liter_unit');

      case 'ml':
        return _tr('milliliter_unit');

      case 'pcs':
        return _tr('piece_unit');

      case 'box':
        return _tr('box_unit');

      default:
        return unit;
    }
  }

  // ============================================================
  // Invoice Details Dialog
  // ============================================================

  void _showInvoiceDetailsDialog(
      SupplierInvoice invoice) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _tr('current_supply_details'),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  Icons.receipt_long_rounded,
                  color: primaryGreen,
                ),
              ],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                _tr('supplier_name_colon'),
                invoice.supplierName,
              ),

              _buildDetailRow(
                _tr('phone_number_colon'),
                invoice.phoneNumber,
              ),

              _buildDetailRow(
                _tr('purchased_product_colon'),
                invoice.productName,
              ),

              _buildDetailRow(
                _tr('quantity_and_unit'),
                "${invoice.quantity} ${_translateUnit(invoice.unit)}",
              ),

              _buildDetailRow(
                _tr('unit_price_colon'),
                invoice.price.toStringAsFixed(2),
              ),

              const Divider(height: 24),

              _buildDetailRow(
                _tr('total_cost'),
                invoice.totalCost.toStringAsFixed(2),
                isTotal: true,
              ),

              _buildDetailRow(
                _tr('operation_date'),
                "${invoice.createdAt.day}/"
                "${invoice.createdAt.month}/"
                "${invoice.createdAt.year} - "
                "${invoice.createdAt.hour}:"
                "${invoice.createdAt.minute}",
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: Text(
                _tr('close'),
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final screenWidth =
        MediaQuery.of(context).size.width;

    final bool isMobile = screenWidth < 1000;

    return Consumer2<OrderProvider, InventoryProvider>(
      builder: (
        context,
        orderProvider,
        inventoryProvider,
        child,
      ) {
        // إجمالي الإيرادات من الطلبات المكتملة
        final double totalRevenue =
            orderProvider.orders
                .where(
                  (o) => [
                    'Completed',
                    'Served',
                    'Delivered',
                  ].contains(o.status),
                )
                .fold<double>(
                  0.0,
                  (sum, o) => sum + o.totalPrice,
                );

        // إجمالي المشتريات
        final double totalPurchases =
            inventoryProvider.totalPurchases;

        // صافي الربح
        final double netProfit =
            totalRevenue - totalPurchases;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: backgroundColor,

          // ====================================================
          // Sidebar
          // ====================================================

          drawer: isMobile
              ? const Drawer(
                  child: AdminSidebar(),
                )
              : null,

          body: Row(
            children: [
              // Sidebar على الشاشات الكبيرة
              if (!isMobile) const AdminSidebar(),

              // ==================================================
              // Main Content
              // ==================================================

              Expanded(
                child: Directionality(
                  textDirection: context
                      .watch<LanguageProvider>()
                      .isArabic
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  child: SafeArea(
                    child: Column(
                      children: [
                        // Mobile Header
                        if (isMobile)
                          Container(
                            height: 70,
                            width: double.infinity,
                            color: Colors.white,
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.menu_rounded,
                                    color: Colors.black,
                                    size: 28,
                                  ),
                                  onPressed: () {
                                    _scaffoldKey
                                        .currentState
                                        ?.openDrawer();
                                  },
                                ),

                                Expanded(
                                  child: Text(
                                    _tr(
                                        'inventory_management_title'),
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight:
                                          FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // ==================================================
                        // Content
                        // ==================================================

                        Expanded(
                          child: (orderProvider.isLoading ||
                                  inventoryProvider.isLoading)
                              ? const Center(
                                  child:
                                      CircularProgressIndicator(),
                                )
                              : SingleChildScrollView(
                                  padding: EdgeInsets.all(
                                    isMobile ? 16.0 : 32.0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // ========================================
                                      // Desktop Title
                                      // ========================================

                                      if (!isMobile)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(
                                            bottom: 28,
                                          ),
                                          child: Text(
                                            _tr(
                                                'inventory_management_title'),
                                            style:
                                                const TextStyle(
                                              color: Colors.black,
                                              fontWeight:
                                                  FontWeight.bold,
                                              fontSize: 24,
                                            ),
                                          ),
                                        ),

                                      // ========================================
                                      // Summary
                                      // ========================================

                                      _buildTopSummaryGrid(
                                        isMobile,
                                        totalRevenue,
                                        totalPurchases,
                                        netProfit,
                                      ),

                                      const SizedBox(height: 32),

                                      // ========================================
                                      // Invoice Header
                                      // ========================================

                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment
                                                .spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .center,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                              children: [
                                                Text(
                                                  _tr(
                                                      'supplier_invoice_records'),
                                                  style:
                                                      const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight
                                                            .bold,
                                                    color:
                                                        Colors.black,
                                                  ),
                                                ),

                                                const SizedBox(
                                                    height: 4),

                                                Text(
                                                  _tr(
                                                      'click_invoice_details'),
                                                  style:
                                                      const TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          const SizedBox(width: 15),

                                          // Add Invoice Button
                                          InkWell(
                                            onTap: () =>
                                                _showAddInvoiceDialog(
                                              inventoryProvider,
                                            ),
                                            borderRadius:
                                                BorderRadius
                                                    .circular(12),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                horizontal: 16,
                                                vertical: 10,
                                              ),
                                              decoration:
                                                  BoxDecoration(
                                                color:
                                                    primaryGreen,
                                                borderRadius:
                                                    BorderRadius
                                                        .circular(
                                                            12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color:
                                                        primaryGreen
                                                            .withOpacity(
                                                                0.3),
                                                    blurRadius: 10,
                                                    offset:
                                                        const Offset(
                                                      0,
                                                      4,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisSize:
                                                    MainAxisSize
                                                        .min,
                                                children: [
                                                  const Icon(
                                                    Icons
                                                        .add_box_rounded,
                                                    color:
                                                        Colors.white,
                                                  ),

                                                  const SizedBox(
                                                      width: 8),

                                                  Text(
                                                    _tr(
                                                        'add_supply'),
                                                    style:
                                                        const TextStyle(
                                                      color:
                                                          Colors.white,
                                                      fontWeight:
                                                          FontWeight
                                                              .bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 20),

                                      // ========================================
                                      // Empty Invoices
                                      // ========================================

                                      inventoryProvider
                                              .invoices
                                              .isEmpty
                                          ? Center(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets
                                                        .all(
                                                  40.0,
                                                ),
                                                child: Text(
                                                  _tr(
                                                      'no_purchase_invoices'),
                                                  textAlign:
                                                      TextAlign
                                                          .center,
                                                ),
                                              ),
                                            )
                                          : ListView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              itemCount:
                                                  inventoryProvider
                                                      .invoices
                                                      .length,
                                              itemBuilder:
                                                  (context, index) {
                                                final invoice =
                                                    inventoryProvider
                                                        .invoices[index];

                                                return Card(
                                                  margin:
                                                      const EdgeInsets
                                                          .only(
                                                    bottom: 14,
                                                  ),
                                                  elevation: 0,
                                                  shape:
                                                      RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(
                                                                16),
                                                    side:
                                                        BorderSide(
                                                      color: Colors
                                                          .grey
                                                          .withOpacity(
                                                              0.15),
                                                    ),
                                                  ),
                                                  child: InkWell(
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(
                                                                16),
                                                    onTap: () =>
                                                        _showInvoiceDetailsDialog(
                                                      invoice,
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets
                                                              .all(
                                                        18.0,
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(
                                                              12,
                                                            ),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: primaryGreen
                                                                  .withOpacity(
                                                                      0.1),
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                            child:
                                                                Icon(
                                                              Icons
                                                                  .local_shipping_outlined,
                                                              color:
                                                                  primaryGreen,
                                                            ),
                                                          ),

                                                          const SizedBox(
                                                              width:
                                                                  16),

                                                          Expanded(
                                                            child:
                                                                LayoutBuilder(
                                                              builder:
                                                                  (
                                                                context,
                                                                constraints,
                                                              ) {
                                                                return Wrap(
                                                                  alignment:
                                                                      WrapAlignment.spaceBetween,
                                                                  crossAxisAlignment:
                                                                      WrapCrossAlignment.center,
                                                                  spacing:
                                                                      16,
                                                                  runSpacing:
                                                                      8,
                                                                  children: [
                                                                    // Supplier
                                                                    Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment.start,
                                                                      children: [
                                                                        Text(
                                                                          invoice.supplierName,
                                                                          style:
                                                                              const TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            fontSize:
                                                                                15,
                                                                          ),
                                                                        ),

                                                                        const SizedBox(
                                                                            height:
                                                                                4),

                                                                        Row(
                                                                          children: [
                                                                            Icon(
                                                                              Icons.phone,
                                                                              size:
                                                                                  14,
                                                                              color:
                                                                                  Colors.grey[500],
                                                                            ),

                                                                            const SizedBox(
                                                                                width:
                                                                                    4),

                                                                            Text(
                                                                              invoice.phoneNumber,
                                                                              style:
                                                                                  TextStyle(
                                                                                color:
                                                                                    Colors.grey[600],
                                                                                fontSize:
                                                                                    13,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ],
                                                                    ),

                                                                    // Product
                                                                    Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment.start,
                                                                      children: [
                                                                        Text(
                                                                          "${_tr('product_label')}: ${invoice.productName}",
                                                                          style:
                                                                              const TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.w500,
                                                                          ),
                                                                        ),

                                                                        const SizedBox(
                                                                            height:
                                                                                4),

                                                                        Text(
                                                                          "${_tr('quantity_label')}: ${invoice.quantity} ${_translateUnit(invoice.unit)}",
                                                                          style:
                                                                              TextStyle(
                                                                            color:
                                                                                Colors.grey[600],
                                                                            fontSize:
                                                                                13,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),

                                                                    // Price
                                                                    Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment.end,
                                                                      children: [
                                                                        Text(
                                                                          invoice.totalCost.toStringAsFixed(2),
                                                                          style:
                                                                              TextStyle(
                                                                            color:
                                                                                primaryGreen,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            fontSize:
                                                                                16,
                                                                          ),
                                                                        ),

                                                                        Text(
                                                                          "${_tr('unit_price_label')}: ${invoice.price.toStringAsFixed(2)}",
                                                                          style:
                                                                              TextStyle(
                                                                            color:
                                                                                Colors.grey[500],
                                                                            fontSize:
                                                                                11,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ],
                                                                );
                                                              },
                                                            ),
                                                          ),

                                                          const SizedBox(
                                                              width: 8),

                                                          Icon(
                                                            Icons
                                                                .arrow_forward_ios_rounded,
                                                            size: 16,
                                                            color: Colors
                                                                .grey[400],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // Summary Grid
  // ============================================================

  Widget _buildTopSummaryGrid(
    bool isMobile,
    double sales,
    double purchases,
    double netProfit,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount =
            constraints.maxWidth < 600 ? 1 : 3;

        return GridView.count(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio:
              isMobile ? 3.5 : 2.0,
          children: [
            _buildSummaryBox(
              _tr('total_cafe_sales'),
              sales.toStringAsFixed(2),
              Icons.trending_up_rounded,
              Colors.blue,
            ),

            _buildSummaryBox(
              _tr('total_inventory_costs'),
              purchases.toStringAsFixed(2),
              Icons.shopping_bag_outlined,
              Colors.orange,
            ),

            _buildSummaryBox(
              _tr('total_net_profit'),
              netProfit.toStringAsFixed(2),
              Icons.account_balance_wallet_outlined,
              primaryGreen,
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // Summary Box
  // ============================================================

  Widget _buildSummaryBox(
    String title,
    String value,
    IconData icon,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: 30,
            ),
          ),

          const SizedBox(width: 18),

          Flexible(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w500,
                  ),
                  overflow:
                      TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Text Field
  // ============================================================

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isTextInput = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isTextInput
          ? TextInputType.text
          : const TextInputType.numberWithOptions(
              decimal: true,
            ),
      textAlign: TextAlign.right,
      validator: (value) {
        if (value == null ||
            value.trim().isEmpty) {
          return _tr('field_required');
        }

        if (!isTextInput &&
            double.tryParse(value) == null) {
          return _tr('numbers_only');
        }

        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: Colors.grey[500],
          size: 20,
        ),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide: BorderSide(
            color: primaryGreen,
            width: 2,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  // ============================================================
  // Detail Row
  // ============================================================

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isTotal = false,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 6.0,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isTotal
                    ? Colors.black
                    : Colors.grey[700],
                fontWeight: isTotal
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Text(
            value,
            style: TextStyle(
              color: isTotal
                  ? primaryGreen
                  : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}