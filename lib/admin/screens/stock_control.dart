// lib/admin/screens/stock_control_screen.dart

import 'package:flutter/material.dart';
import 'package:premium_store/app/sidebar.dart';
import 'package:premium_store/localization/app_translations.dart';
import 'package:premium_store/state/inventory_provider.dart';
import 'package:premium_store/state/language_provider.dart';
import 'package:provider/provider.dart';

class StockControlScreen extends StatefulWidget {
  const StockControlScreen({super.key});

  @override
  State<StockControlScreen> createState() => _StockControlScreenState();
}

class _StockControlScreenState extends State<StockControlScreen> {
  // ============================================================
  // Colors
  // ============================================================

  final Color primaryGreen = const Color(0xFF00B686);
  final Color warningOrange = const Color(0xFFFF9800);
  final Color dangerRed = const Color(0xFFE53935);
  final Color backgroundColor = const Color(0xFFF8F9FA);

  // ============================================================
  // Scaffold
  // ============================================================

  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  // ============================================================
  // Form
  // ============================================================

  final _reduceFormKey = GlobalKey<FormState>();

  final _reduceAmountController = TextEditingController();

  // ============================================================
  // Translation Helper
  // ============================================================

  String _tr(BuildContext context, String key) {
    final languageProvider = context.read<LanguageProvider>();

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
    _reduceAmountController.dispose();
    super.dispose();
  }

  // ============================================================
  // Reduce Stock Dialog
  // ============================================================

  void _showReduceStockDialog(
    SupplierInvoice invoice,
    InventoryProvider provider,
  ) {
    _reduceAmountController.clear();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          // ======================================================
          // Dialog Title
          // ======================================================

          title: Row(
            children: [
              Icon(
                Icons.remove_circle_outline_rounded,
                color: dangerRed,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  _tr(context, 'record_stock_consumption'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),

          // ======================================================
          // Dialog Content
          // ======================================================

          content: Form(
            key: _reduceFormKey,

            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // Product
                Text(
                  "${_tr(context, 'product')}: ${invoice.productName}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                // Current available quantity
                Text(
                  "${_tr(context, 'current_available')}: "
                  "${invoice.remainingQuantity} ${invoice.unit}",

                  style: TextStyle(
                    color: primaryGreen,
                  ),
                ),

                const Divider(height: 20),

                // Quantity input
                TextFormField(
                  controller: _reduceAmountController,

                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),

                  textAlign: TextAlign.right,

                  autofocus: true,

                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return _tr(
                        context,
                        'please_enter_reduction_quantity',
                      );
                    }

                    final numValue = double.tryParse(
                      value,
                    );

                    if (numValue == null || numValue <= 0) {
                      return _tr(
                        context,
                        'enter_valid_positive_number',
                      );
                    }

                    if (numValue >
                        invoice.remainingQuantity) {
                      return _tr(
                        context,
                        'quantity_greater_than_available',
                      );
                    }

                    return null;
                  },

                  decoration: InputDecoration(
                    labelText: _tr(
                      context,
                      'consumed_quantity',
                    ),

                    suffixText: invoice.unit,

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),

                      borderSide: BorderSide(
                        color: dangerRed,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // Dialog Actions
          // ======================================================

          actions: [
            // Cancel
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },

              child: Text(
                _tr(context, 'cancel'),
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),

            // Confirm
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: dangerRed,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              onPressed: () async {
                if (!_reduceFormKey.currentState!.validate()) {
                  return;
                }

                // Loading dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (loadingContext) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                );

                try {
                  final double amount = double.parse(
                    _reduceAmountController.text.trim(),
                  );

                  // Update stock quantity
                  await provider.reduceStockQuantity(
                    invoice.id,
                    amount,
                  );

                  if (mounted) {
                    // Close loading dialog
                    Navigator.pop(context);

                    // Close reduce dialog
                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _tr(
                            context,
                            'stock_updated_successfully',
                          ),
                        ),
                        backgroundColor: Colors.black,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    // Close loading dialog
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "${_tr(context, 'error_prefix')}: $e",
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },

              child: Text(
                _tr(context, 'confirm_reduction'),
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
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final double screenWidth =
        MediaQuery.of(context).size.width;

    final bool isMobile = screenWidth < 900;

    return Scaffold(
      key: _scaffoldKey,

      backgroundColor: backgroundColor,

      // ========================================================
      // Mobile Drawer
      // ========================================================

      drawer: isMobile
          ? const Drawer(
              child: AdminSidebar(),
            )
          : null,

      // ========================================================
      // Body
      // ========================================================

      body: Row(
        children: [
          // Desktop Sidebar
          if (!isMobile) const AdminSidebar(),

          // Main Content
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  // ==================================================
                  // App Bar
                  // ==================================================

                  Container(
                    width: double.infinity,

                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 30,
                      vertical: 14,
                    ),

                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),

                    child: Row(
                      children: [
                        // Mobile menu button
                        if (isMobile)
                          IconButton(
                            icon: const Icon(
                              Icons.menu_rounded,
                              size: 28,
                            ),

                            onPressed: () {
                              _scaffoldKey.currentState
                                  ?.openDrawer();
                            },
                          ),

                        if (isMobile)
                          const SizedBox(width: 8),

                        // Title
                        Expanded(
                          child: Text(
                            _tr(
                              context,
                              'stock_control_title',
                            ),

                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 17 : 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Small divider
                  Container(
                    height: 1,
                    color: Colors.grey.withOpacity(0.12),
                  ),

                  // ==================================================
                  // Inventory Content
                  // ==================================================

                  Expanded(
                    child: Consumer<InventoryProvider>(
                      builder: (
                        context,
                        inventoryProvider,
                        child,
                      ) {
                        // Loading
                        if (inventoryProvider.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        // Empty
                        if (inventoryProvider.invoices.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                _tr(
                                  context,
                                  'no_purchased_goods',
                                ),

                                textAlign: TextAlign.center,

                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          );
                        }

                        // List
                        return ListView.builder(
                          padding: EdgeInsets.all(
                            isMobile ? 16 : 30,
                          ),

                          itemCount:
                              inventoryProvider.invoices.length,

                          itemBuilder: (context, index) {
                            final item =
                                inventoryProvider.invoices[index];

                            return _buildStockCard(
                              context,
                              item,
                              inventoryProvider,
                              isMobile,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Stock Card
  // ============================================================

  Widget _buildStockCard(
    BuildContext context,
    SupplierInvoice item,
    InventoryProvider inventoryProvider,
    bool isMobile,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),

      elevation: 0,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),

        side: BorderSide(
          color: item.isOutOffStock
              ? dangerRed.withOpacity(0.4)
              : item.isRunningOut
                  ? warningOrange.withOpacity(0.4)
                  : Colors.grey.withOpacity(0.15),

          width:
              (item.isRunningOut || item.isOutOffStock)
                  ? 2
                  : 1,
        ),
      ),

      child: Padding(
        padding: EdgeInsets.all(
          isMobile ? 14 : 16,
        ),

        child: Column(
          children: [
            // ======================================================
            // Warning Alert
            // ======================================================

            if (item.isOutOffStock)
              _buildStatusAlert(
                context,

                Icons.dangerous_rounded,

                _tr(
                  context,
                  'stock_out_message',
                ),

                dangerRed,
              )
            else if (item.isRunningOut)
              _buildStatusAlert(
                context,

                Icons.warning_amber_rounded,

                _tr(
                  context,
                  'stock_running_out_message',
                ),

                warningOrange,
              ),

            const SizedBox(height: 8),

            // ======================================================
            // Product Information
            // ======================================================

            if (isMobile)
              _buildMobileProductInfo(
                context,
                item,
              )
            else
              _buildDesktopProductInfo(
                context,
                item,
              ),

            const Divider(height: 24),

            // ======================================================
            // Progress Bar
            // ======================================================

            ClipRRect(
              borderRadius: BorderRadius.circular(10),

              child: LinearProgressIndicator(
                value: item.quantity > 0
                    ? (item.remainingQuantity /
                        item.quantity)
                    : 0,

                backgroundColor: Colors.grey[200],

                color: item.isOutOffStock
                    ? dangerRed
                    : item.isRunningOut
                        ? warningOrange
                        : primaryGreen,

                minHeight: 8,
              ),
            ),

            const SizedBox(height: 14),

            // ======================================================
            // Consumption + Manual Reduction
            // ======================================================

            if (isMobile)
              _buildMobileControlRow(
                context,
                item,
                inventoryProvider,
              )
            else
              _buildDesktopControlRow(
                context,
                item,
                inventoryProvider,
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Desktop Product Information
  // ============================================================

  Widget _buildDesktopProductInfo(
    BuildContext context,
    SupplierInvoice item,
  ) {
    return Row(
      children: [
        // Product icon
        Container(
          padding: const EdgeInsets.all(12),

          decoration: BoxDecoration(
            color: item.isOutOffStock
                ? dangerRed.withOpacity(0.1)
                : primaryGreen.withOpacity(0.1),

            shape: BoxShape.circle,
          ),

          child: Icon(
            Icons.inventory_2_outlined,

            color: item.isOutOffStock
                ? dangerRed
                : primaryGreen,
          ),
        ),

        const SizedBox(width: 14),

        // Product / Supplier
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Text(
                item.productName,

                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                "${_tr(context, 'supplier')}: "
                "${item.supplierName}",

                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // Quantity
        Column(
          crossAxisAlignment:
              CrossAxisAlignment.end,

          children: [
            Text(
              "${item.remainingQuantity} / "
              "${item.quantity} "
              "${item.unit}",

              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,

                color: item.isOutOffStock
                    ? dangerRed
                    : item.isRunningOut
                        ? warningOrange
                        : Colors.black,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              _tr(
                context,
                'actual_remaining_stock',
              ),

              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // Mobile Product Information
  // ============================================================

  Widget _buildMobileProductInfo(
    BuildContext context,
    SupplierInvoice item,
  ) {
    return Column(
      children: [
        Row(
          children: [
            // Product icon
            Container(
              padding: const EdgeInsets.all(10),

              decoration: BoxDecoration(
                color: item.isOutOffStock
                    ? dangerRed.withOpacity(0.1)
                    : primaryGreen.withOpacity(0.1),

                shape: BoxShape.circle,
              ),

              child: Icon(
                Icons.inventory_2_outlined,

                color: item.isOutOffStock
                    ? dangerRed
                    : primaryGreen,

                size: 22,
              ),
            ),

            const SizedBox(width: 12),

            // Product name
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    item.productName,

                    maxLines: 2,

                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    "${_tr(context, 'supplier')}: "
                    "${item.supplierName}",

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,

                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Quantity information
        Container(
          width: double.infinity,

          padding: const EdgeInsets.all(10),

          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.05),

            borderRadius: BorderRadius.circular(10),
          ),

          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,

            children: [
              Text(
                _tr(
                  context,
                  'actual_remaining_stock',
                ),

                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),

              Text(
                "${item.remainingQuantity} / "
                "${item.quantity} "
                "${item.unit}",

                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,

                  color: item.isOutOffStock
                      ? dangerRed
                      : item.isRunningOut
                          ? warningOrange
                          : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // Desktop Control Row
  // ============================================================

  Widget _buildDesktopControlRow(
    BuildContext context,
    SupplierInvoice item,
    InventoryProvider inventoryProvider,
  ) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,

      children: [
        // Consumed quantity
        Text(
          "${_tr(context, 'consumed')}: "
          "${item.consumedQuantity} "
          "${item.unit}",

          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),

        // Reduce button
        _buildReduceButton(
          context,
          item,
          inventoryProvider,
        ),
      ],
    );
  }

  // ============================================================
  // Mobile Control Row
  // ============================================================

  Widget _buildMobileControlRow(
    BuildContext context,
    SupplierInvoice item,
    InventoryProvider inventoryProvider,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,

      children: [
        Text(
          "${_tr(context, 'consumed')}: "
          "${item.consumedQuantity} "
          "${item.unit}",

          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),

        const SizedBox(height: 10),

        _buildReduceButton(
          context,
          item,
          inventoryProvider,
        ),
      ],
    );
  }

  // ============================================================
  // Reduce Button
  // ============================================================

  Widget _buildReduceButton(
    BuildContext context,
    SupplierInvoice item,
    InventoryProvider inventoryProvider,
  ) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: item.isOutOffStock
            ? Colors.grey
            : dangerRed.withOpacity(0.9),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),

        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      ),

      onPressed: item.isOutOffStock
          ? null
          : () {
              _showReduceStockDialog(
                item,
                inventoryProvider,
              );
            },

      icon: const Icon(
        Icons.trending_down_rounded,
        color: Colors.white,
        size: 18,
      ),

      label: Text(
        _tr(context, 'record_manual_consumption'),

        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // Status Alert
  // ============================================================

  Widget _buildStatusAlert(
    BuildContext context,
    IconData icon,
    String message,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),

      decoration: BoxDecoration(
        color: color.withOpacity(0.1),

        borderRadius: BorderRadius.circular(8),
      ),

      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 18,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              message,

              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}