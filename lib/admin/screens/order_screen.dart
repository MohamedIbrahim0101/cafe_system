// lib/screens/admin/orders_screen.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:premium_store/app/sidebar.dart';
import 'package:premium_store/localization/app_translations.dart';
import 'package:premium_store/state/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../state/order_provider.dart';
import '../../core/models/order_model.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  // ==============================================================
  // FILTER
  // ==============================================================

  String selectedFilter = 'All';

  // ==============================================================
  // PRODUCT TYPE FILTER
  // ==============================================================

  // All = كل المنتجات
  // Food = الطعام فقط
  // Drinks = المشروبات فقط
  String selectedProductType = 'All';

  // IMPORTANT:
  // These values are stored/used internally.
  // Do NOT translate them because OrderProvider/Firebase
  // uses these exact values.
  final List<String> statusOptions = const [
    'Pending',
    'Preparing',
    'Done',
    'Cancelled',
    'Delivered',
  ];

  // ==============================================================
  // SCAFFOLD
  // ==============================================================

  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  // ==============================================================
  // BRAND COLOR
  // ==============================================================

  final Color brandGreen = const Color(0xFF00B686);

  // ==============================================================
  // TRANSLATION
  // ==============================================================

  String _tr(String key) {
    final languageProvider =
        Provider.of<LanguageProvider>(context);

    return AppTranslations.get(
      languageProvider.locale.languageCode,
      key,
    );
  }

  // ==============================================================
  // STATUS TRANSLATION
  // ==============================================================

  String _translateStatus(String status) {
    switch (status) {
      case 'Pending':
        return _tr('status_pending');

      case 'Preparing':
        return _tr('status_preparing');

      case 'Done':
        return _tr('status_done');

      case 'Cancelled':
        return _tr('status_cancelled');

      case 'Delivered':
        return _tr('status_delivered');

      case 'All':
        return _tr('all');

      default:
        return status;
    }
  }

  // ==============================================================
  // PRODUCT TYPE TRANSLATION
  // ==============================================================

  String _translateProductType(String type) {
    switch (type) {
      case 'Food':
        return _tr('food');

      case 'Drinks':
        return _tr('drinks');

      case 'All':
        return _tr('all');

      default:
        return type;
    }
  }

  // ==============================================================
  // PRINT RECEIPT
  // ==============================================================

  Future<void> _printReceipt(Order order) async {
    final doc = pw.Document();

    final languageProvider =
        Provider.of<LanguageProvider>(
      context,
      listen: false,
    );

    final String languageCode =
        languageProvider.locale.languageCode;

    String trPrint(String key) {
      return AppTranslations.get(
        languageCode,
        key,
      );
    }

    String translatePrintStatus(String status) {
      switch (status) {
        case 'Pending':
          return trPrint('status_pending');

        case 'Preparing':
          return trPrint('status_preparing');

        case 'Done':
          return trPrint('status_done');

        case 'Cancelled':
          return trPrint('status_cancelled');

        case 'Delivered':
          return trPrint('status_delivered');

        default:
          return status;
      }
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(8),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment:
                pw.CrossAxisAlignment.center,
            children: [
              // ==================================================
              // RESTAURANT NAME
              // ==================================================

              pw.Text(
                "RESTAURANT",
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 5),

              pw.Divider(),

              // ==================================================
              // ORDER NUMBER
              // ==================================================

              pw.Text(
                "${trPrint('order_number')} #${order.dailySequenceNumber}",
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 5),

              // ==================================================
              // TABLE
              // ==================================================

              pw.Text(
                "${trPrint('table')} ${order.tableNumber}",
                style: const pw.TextStyle(
                  fontSize: 12,
                ),
              ),

              pw.SizedBox(height: 4),

              // ==================================================
              // STATUS
              // ==================================================

              pw.Text(
                "${trPrint('status_label')}: "
                "${translatePrintStatus(order.status)}",
                style: const pw.TextStyle(
                  fontSize: 10,
                ),
              ),

              pw.Divider(),

              // ==================================================
              // ORDER ITEMS
              // ==================================================

              ...order.items.map(
                (item) {
                  return pw.Container(
                    margin: const pw.EdgeInsets.only(
                      bottom: 8,
                    ),
                    child: pw.Column(
                      crossAxisAlignment:
                          pw.CrossAxisAlignment.start,
                      children: [
                        // ========================================
                        // PRODUCT ROW
                        // ========================================

                        pw.Row(
                          mainAxisAlignment:
                              pw.MainAxisAlignment
                                  .spaceBetween,
                          children: [
                            pw.Expanded(
                              child: pw.Text(
                                "${item.quantity}x ${item.name}",
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight:
                                      pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Text(
                              item.price
                                  .toStringAsFixed(2),
                              style:
                                  const pw.TextStyle(
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),

                        // ========================================
                        // SIZE
                        // ========================================

                        if (item.size != null &&
                            item.size!
                                .trim()
                                .isNotEmpty)
                          pw.Padding(
                            padding:
                                const pw.EdgeInsets.only(
                              left: 12,
                              top: 2,
                            ),
                            child: pw.Text(
                              "${trPrint('size')}: "
                              "${item.size}",
                              style:
                                  const pw.TextStyle(
                                fontSize: 9,
                              ),
                            ),
                          ),

                        // ========================================
                        // NOTES / SIDE DISHES
                        // ========================================

                        if (item.notes != null &&
                            item.notes!
                                .trim()
                                .isNotEmpty)
                          pw.Padding(
                            padding:
                                const pw.EdgeInsets.only(
                              left: 12,
                              top: 2,
                            ),
                            child: pw.Text(
                              item.notes!,
                              style:
                                  const pw.TextStyle(
                                fontSize: 9,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),

              pw.Divider(),

              // ==================================================
              // TOTAL
              // ==================================================

              pw.Row(
                mainAxisAlignment:
                    pw.MainAxisAlignment
                        .spaceBetween,
                children: [
                  pw.Text(
                    "${trPrint('total')}:",
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight:
                          pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    order.totalPrice
                        .toStringAsFixed(2),
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight:
                          pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 10),

              pw.Text(
                trPrint('thank_you'),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight:
                      pw.FontWeight.bold,
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        return doc.save();
      },
    );
  }

  // ==============================================================
  // BUILD
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    final orders =
        context.select<OrderProvider, List<Order>>(
      (p) => p.orders,
    );

    final isLoading =
        context.select<OrderProvider, bool>(
      (p) => p.isLoading,
    );

    final languageProvider =
        context.watch<LanguageProvider>();

    final bool isMobile =
        MediaQuery.of(context).size.width < 1100;

    // ============================================================
    // FILTER ORDERS BY STATUS
    // ============================================================

    List<Order> filteredOrders;

    if (selectedFilter == 'All') {
      filteredOrders = List<Order>.from(orders);
    } else {
      filteredOrders = orders
          .where(
            (o) => o.status == selectedFilter,
          )
          .toList();
    }

    // ============================================================
    // FILTER ORDERS BY PRODUCT TYPE
    // ============================================================

    if (selectedProductType != 'All') {
      final String requiredType =
          selectedProductType == 'Food'
              ? 'food'
              : 'drink';

      filteredOrders = filteredOrders
          .map(
            (order) {
              final filteredItems = order.items
                  .where(
                    (item) =>
                        item.productType ==
                        requiredType,
                  )
                  .toList();

              // If the order doesn't contain any item
              // matching the selected type, remove it.
              if (filteredItems.isEmpty) {
                return null;
              }

              // Keep the original order data,
              // especially tableNumber.
              return order.copyWith(
                items: filteredItems,
              );
            },
          )
          .whereType<Order>()
          .toList();
    }

    return Directionality(
      textDirection: languageProvider.isArabic
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor:
            const Color(0xFFF8F9FA),

        // ========================================================
        // MOBILE SIDEBAR
        // ========================================================

        drawer: isMobile
            ? const Drawer(
                child: AdminSidebar(),
              )
            : null,

        body: Row(
          children: [
            // ====================================================
            // DESKTOP SIDEBAR
            // ====================================================

            if (!isMobile)
              const AdminSidebar(),

            // ====================================================
            // MAIN CONTENT
            // ====================================================

            Expanded(
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(
                    isMobile ? 16.0 : 30.0,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      // ==========================================
                      // HEADER
                      // ==========================================

                      _buildHeader(isMobile),

                      const SizedBox(
                        height: 25,
                      ),

                      // ==========================================
                      // STATUS FILTERS
                      // ==========================================

                      _buildFilterChips(),

                      const SizedBox(
                        height: 15,
                      ),

                      // ==========================================
                      // FOOD / DRINK FILTERS
                      // ==========================================

                      _buildProductTypeFilterChips(),

                      const SizedBox(
                        height: 25,
                      ),

                      // ==========================================
                      // ORDERS TABLE
                      // ==========================================

                      Expanded(
                        child: Container(
                          decoration:
                              BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(
                              15,
                            ),
                          ),
                          child: isLoading
                              ? Center(
                                  child:
                                      CircularProgressIndicator(
                                    color:
                                        brandGreen,
                                  ),
                                )
                              : filteredOrders
                                      .isEmpty
                                  ? Center(
                                      child: Text(
                                        _tr(
                                          'no_orders_found',
                                        ),
                                      ),
                                    )
                                  : _buildOptimizedTable(
                                      filteredOrders,
                                      isMobile,
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
      ),
    );
  }

  // ==============================================================
  // ORDER ROW
  // ==============================================================

  Widget _buildOrderRow(Order order) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 12,
      ),
      child: Row(
        children: [
          // ======================================================
          // ORDER ID
          // ======================================================

          Expanded(
            flex: 2,
            child: Text(
              "#${order.dailySequenceNumber}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // ======================================================
          // TABLE
          // ======================================================

          Expanded(
            flex: 2,
            child: Text(
              "T-${order.tableNumber}",
            ),
          ),

          // ======================================================
          // ITEMS
          // ======================================================

          Expanded(
            flex: 2,
            child: Text(
              "${order.items.length} "
              "${_tr('items')}",
            ),
          ),

          // ======================================================
          // TOTAL
          // ======================================================

          Expanded(
            flex: 2,
            child: Text(
              order.totalPrice
                  .toStringAsFixed(2),
            ),
          ),

          // ======================================================
          // STATUS
          // ======================================================

          Expanded(
            flex: 3,
            child: _buildStatusDropdown(
              order.status,
              order.id,
            ),
          ),

          // ======================================================
          // TIME
          // ======================================================

          Expanded(
            flex: 2,
            child: Text(
              _formatOrderTime(order),
            ),
          ),

          // ======================================================
          // PRINT
          // ======================================================

          Expanded(
            flex: 1,
            child: IconButton(
              tooltip: _tr('print'),
              icon: const Icon(
                Icons.print,
                size: 20,
              ),
              onPressed: () {
                _printReceipt(order);
              },
            ),
          ),

          // ======================================================
          // VIEW
          // ======================================================

          Expanded(
            flex: 1,
            child: IconButton(
              tooltip: _tr('view'),
              icon: const Icon(
                Icons.visibility,
              ),
              onPressed: () {
                _showGlassDetails(
                  context,
                  order,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // FORMAT ORDER TIME
  // ==============================================================

  String _formatOrderTime(Order order) {
    final date = order.createdAt;

    final hour =
        date.hour.toString().padLeft(2, '0');

    final minute =
        date.minute.toString().padLeft(2, '0');

    return "$hour:$minute";
  }

  // ==============================================================
  // HEADER
  // ==============================================================

  Widget _buildHeader(bool isMobile) {
    return Row(
      children: [
        // ========================================================
        // MOBILE MENU
        // ========================================================

        if (isMobile)
          IconButton(
            icon: const Icon(
              Icons.menu_rounded,
              size: 28,
              color: Colors.black,
            ),
            onPressed: () {
              _scaffoldKey.currentState
                  ?.openDrawer();
            },
          ),

        if (isMobile)
          const SizedBox(width: 8),

        // ========================================================
        // TITLE
        // ========================================================

        Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              _tr('orders_control'),
              style: TextStyle(
                fontSize:
                    isMobile ? 22 : 28,
                fontWeight:
                    FontWeight.w900,
                color: Colors.black,
              ),
            ),
            if (!isMobile)
              Text(
                _tr('track_manage_orders'),
                style: const TextStyle(
                  color: Colors.black,
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ==============================================================
  // ORDERS TABLE
  // ==============================================================

  Widget _buildOptimizedTable(
    List<Order> orders,
    bool isMobile,
  ) {
    return Column(
      children: [
        // ========================================================
        // TABLE HEADER
        // ========================================================

        Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
          decoration:
              const BoxDecoration(
            color: Color(0xFFF1F3F5),
            borderRadius:
                BorderRadius.vertical(
              top: Radius.circular(15),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  _tr('id'),
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),

              Expanded(
                flex: 2,
                child: Text(
                  _tr('table'),
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),

              Expanded(
                flex: 2,
                child: Text(
                  _tr('items'),
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),

              Expanded(
                flex: 2,
                child: Text(
                  _tr('total'),
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),

              Expanded(
                flex: 3,
                child: Text(
                  _tr('status'),
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),

              Expanded(
                flex: 2,
                child: Text(
                  _tr('time'),
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),

              Expanded(
                flex: 2,
                child: Text(
                  _tr('action'),
                  textAlign:
                      TextAlign.center,
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ========================================================
        // ORDERS LIST
        // ========================================================

        Expanded(
          child: ListView.separated(
            itemCount: orders.length,
            physics:
                const BouncingScrollPhysics(),
            separatorBuilder:
                (context, index) =>
                    const Divider(
              height: 1,
              color: Color(0xFFF1F3F5),
            ),
            itemBuilder:
                (context, index) {
              final order =
                  orders[index];

              return _buildOrderRow(
                order,
              );
            },
          ),
        ),
      ],
    );
  }

  // ==============================================================
  // STATUS DROPDOWN
  // ==============================================================

  Widget _buildStatusDropdown(
    String status,
    String orderId,
  ) {
    Color color =
        (status == 'Done' ||
                status == 'Delivered')
            ? brandGreen
            : (status == 'Cancelled'
                ? Colors.red
                : Colors.orange);

    final String currentValue =
        statusOptions.contains(status)
            ? status
            : 'Pending';

    return Align(
      alignment:
          Alignment.centerLeft,
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 8,
        ),
        height: 32,
        decoration: BoxDecoration(
          color:
              color.withOpacity(0.1),
          borderRadius:
              BorderRadius.circular(8),
          border: Border.all(
            color:
                color.withOpacity(0.2),
          ),
        ),
        child:
            DropdownButtonHideUnderline(
          child:
              DropdownButton<String>(
            value: currentValue,
            icon: Icon(
              Icons
                  .keyboard_arrow_down_rounded,
              color: color,
              size: 16,
            ),
            dropdownColor:
                Colors.white,
            style: TextStyle(
              color: color,
              fontWeight:
                  FontWeight.bold,
              fontSize: 11,
            ),
            onChanged:
                (newStatus) async {
              if (newStatus != null &&
                  newStatus != status) {
                await context
                    .read<OrderProvider>()
                    .updateOrderStatus(
                      orderId,
                      newStatus,
                    );
              }
            },
            items:
                statusOptions
                    .map(
                      (s) =>
                          DropdownMenuItem<
                              String>(
                        value: s,
                        child: Text(
                          _translateStatus(
                            s,
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // STATUS FILTER CHIPS
  // ==============================================================

  Widget _buildFilterChips() {
    final filters = [
      'All',
      ...statusOptions,
    ];

    return SingleChildScrollView(
      scrollDirection:
          Axis.horizontal,
      child: Row(
        children: filters.map(
          (status) {
            final bool isSelected =
                selectedFilter == status;

            return Padding(
              padding:
                  const EdgeInsets.only(
                right: 10,
              ),
              child: ChoiceChip(
                label: Text(
                  _translateStatus(
                    status,
                  ),
                ),
                selected:
                    isSelected,
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      selectedFilter =
                          status;
                    });
                  }
                },
                selectedColor:
                    brandGreen,
                backgroundColor:
                    Colors.white,
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
                    10,
                  ),
                ),
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  // ==============================================================
  // FOOD / DRINK FILTER CHIPS
  // ==============================================================

  Widget _buildProductTypeFilterChips() {
    final filters = [
      'All',
      'Food',
      'Drinks',
    ];

    return SingleChildScrollView(
      scrollDirection:
          Axis.horizontal,
      child: Row(
        children: filters.map(
          (type) {
            final bool isSelected =
                selectedProductType ==
                    type;

            return Padding(
              padding:
                  const EdgeInsets.only(
                right: 10,
              ),
              child: ChoiceChip(
                label: Text(
                  _translateProductType(
                    type,
                  ),
                ),
                selected:
                    isSelected,
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      selectedProductType =
                          type;
                    });
                  }
                },
                selectedColor:
                    brandGreen,
                backgroundColor:
                    Colors.white,
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
                    10,
                  ),
                ),
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  // ==============================================================
  // ORDER DETAILS
  // ==============================================================

  void _showGlassDetails(
    BuildContext context,
    Order order,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor:
          Colors.black54,
      transitionDuration:
          const Duration(
        milliseconds: 200,
      ),
      pageBuilder:
          (ctx, anim1, anim2) {
        return Center(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 8,
              sigmaY: 8,
            ),
            child: Container(
              width:
                  MediaQuery.of(context)
                              .size
                              .width >
                          500
                      ? 450
                      : MediaQuery.of(
                              context)
                          .size
                          .width *
                          0.9,
              padding:
                  const EdgeInsets.all(
                25,
              ),
              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  25,
                ),
              ),
              child: Material(
                color:
                    Colors.transparent,
                child: Directionality(
                  textDirection:
                      context
                              .read<
                                  LanguageProvider>()
                              .isArabic
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      // ==========================================
                      // ORDER NUMBER
                      // ==========================================

                      Text(
                        "${_tr('order_number')} "
                        "#${order.dailySequenceNumber}",
                        style:
                            const TextStyle(
                          fontSize: 22,
                          fontWeight:
                              FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      // ==========================================
                      // TABLE
                      // ==========================================

                      Text(
                        "${_tr('table')} "
                        "${order.tableNumber}",
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              Colors.grey.shade600,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      // ==========================================
                      // STATUS
                      // ==========================================

                      Text(
                        "${_tr('status_label')}: "
                        "${_translateStatus(order.status)}",
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              Colors.grey.shade600,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      const Divider(
                        height: 30,
                        color:
                            Color(0xFFEEEEEE),
                      ),

                      // ==========================================
                      // ITEMS
                      // ==========================================

                      Flexible(
                        child:
                            SingleChildScrollView(
                          child: Column(
                            children:
                                order.items
                                    .map(
                              (item) {
                                return Container(
                                  margin:
                                      const EdgeInsets
                                          .only(
                                    bottom: 10,
                                  ),
                                  padding:
                                      const EdgeInsets
                                          .all(
                                    10,
                                  ),
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        const Color(
                                      0xFFF9F9F9,
                                    ),
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      10,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      // ==================
                                      // PRODUCT
                                      // ==================

                                      Row(
                                        children: [
                                          Expanded(
                                            child:
                                                Text(
                                              item.name,
                                              style:
                                                  const TextStyle(
                                                fontWeight:
                                                    FontWeight
                                                        .bold,
                                                color:
                                                    Colors
                                                        .black,
                                                fontSize:
                                                    16,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            "x${item.quantity}",
                                            style:
                                                const TextStyle(
                                              fontWeight:
                                                  FontWeight
                                                      .w900,
                                              color:
                                                  Colors
                                                      .black,
                                              fontSize:
                                                  16,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(
                                        height: 5,
                                      ),

                                      // ==================
                                      // PRICE
                                      // ==================

                                      Text(
                                        item.price
                                            .toStringAsFixed(
                                          2,
                                        ),
                                        style:
                                            TextStyle(
                                          color:
                                              brandGreen,
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                          fontSize:
                                              13,
                                        ),
                                      ),

                                      // ==================
                                      // SIZE
                                      // ==================

                                      if (item.size !=
                                              null &&
                                          item.size!
                                              .trim()
                                              .isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets
                                                  .only(
                                            top: 6,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .start,
                                            children: [
                                              const Icon(
                                                Icons
                                                    .straighten,
                                                size:
                                                    16,
                                                color:
                                                    Colors
                                                        .black54,
                                              ),
                                              const SizedBox(
                                                width:
                                                    6,
                                              ),
                                              Expanded(
                                                child:
                                                    Text(
                                                  "${_tr('size')}: "
                                                  "${item.size}",
                                                  style:
                                                      TextStyle(
                                                    color:
                                                        Colors.grey.shade800,
                                                    fontSize:
                                                        13,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                      // ==================
                                      // NOTES / SIDE DISHES
                                      // ==================

                                      if (item.notes !=
                                              null &&
                                          item.notes!
                                              .trim()
                                              .isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets
                                                  .only(
                                            top: 6,
                                          ),
                                          child:
                                              Container(
                                            width:
                                                double.infinity,
                                            padding:
                                                const EdgeInsets
                                                    .all(
                                              8,
                                            ),
                                            decoration:
                                                BoxDecoration(
                                              color:
                                                  brandGreen
                                                      .withOpacity(
                                                0.08,
                                              ),
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                8,
                                              ),
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                              children: [
                                                Icon(
                                                  Icons
                                                      .restaurant_menu,
                                                  size:
                                                      16,
                                                  color:
                                                      brandGreen,
                                                ),
                                                const SizedBox(
                                                  width:
                                                      6,
                                                ),
                                                Expanded(
                                                  child:
                                                      Text(
                                                    item.notes!,
                                                    style:
                                                        TextStyle(
                                                      color:
                                                          Colors.grey.shade800,
                                                      fontSize:
                                                          12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      height:
                                                          1.4,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ).toList(),
                          ),
                        ),
                      ),

                      const Divider(
                        height: 30,
                        color:
                            Color(0xFFEEEEEE),
                      ),

                      // ==========================================
                      // TOTAL
                      // ==========================================

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,
                        children: [
                          Text(
                            _tr(
                              'total_amount',
                            ),
                            style:
                                const TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  Colors.black,
                            ),
                          ),
                          Text(
                            order.totalPrice
                                .toStringAsFixed(
                              2,
                            ),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight:
                                  FontWeight.w900,
                              color:
                                  brandGreen,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 25,
                      ),

                      // ==========================================
                      // CLOSE
                      // ==========================================

                      ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(
                          ctx,
                        ),
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              Colors.black,
                          minimumSize:
                              const Size(
                            double.infinity,
                            55,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              15,
                            ),
                          ),
                        ),
                        child: Text(
                          _tr('close'),
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
