import 'package:flutter/material.dart';
import 'package:premium_store/app/sidebar.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:printing/printing.dart'; // للطباعة
import 'package:pdf/pdf.dart'; // لتصميم الفاتورة
import 'package:pdf/widgets.dart' as pw;

import '../../state/order_provider.dart';
import '../../core/services/firebase_service.dart';
import '../../core/models/order_model.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String selectedFilter = 'All';
  final List<String> statusOptions = const [
    'Pending',
    'Preparing',
    'Done',
    'Cancelled',
    'Delivered'
  ];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Color brandGreen = const Color(0xFF00B686);

  // --- دالة طباعة الفاتورة ---
  Future<void> _printReceipt(Order order) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // مقاس طابعة الكاشير الحرارية
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text("REStAURANT",
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.Text(
                  "Order #${order.dailySequenceNumber}"), // الرقم المسلسل الجديد
              pw.ListView(
                  children: order.items
                      .map((item) => pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text("${item.quantity}x ${item.name}"),
                              pw.Text("\$${item.price}")
                            ],
                          ))
                      .toList()),
              pw.Divider(),
              pw.Text("Total: \$${order.totalPrice.toStringAsFixed(2)}",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save());
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.select<OrderProvider, List<Order>>((p) => p.orders);
    final isLoading = context.select<OrderProvider, bool>((p) => p.isLoading);
    final bool isMobile = MediaQuery.of(context).size.width < 1100;

    // فلترة الطلبات
    final filteredOrders = selectedFilter == 'All'
        ? orders
        : orders.where((o) => o.status == selectedFilter).toList();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: isMobile ? const AdminSidebar() : null,
      body: Row(
        children: [
          if (!isMobile) const AdminSidebar(),
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 16.0 : 30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isMobile),
                    const SizedBox(height: 25),
                    _buildFilterChips(),
                    const SizedBox(height: 25),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15)),
                        child: isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                    color: brandGreen))
                            : filteredOrders.isEmpty
                                ? const Center(child: Text("No orders found."))
                                : _buildOptimizedTable(
                                    filteredOrders, isMobile),
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
  }

  // --- تم تعديل الـ Row ليظهر الـ Sequence Number ---
  Widget _buildOrderRow(Order order) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text("#${order.dailySequenceNumber}",
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text("T-${order.tableNumber}")),
          Expanded(flex: 2, child: Text("${order.items.length} Items")),
          Expanded(
              flex: 2, child: Text("\$${order.totalPrice.toStringAsFixed(2)}")),
          Expanded(
              flex: 3, child: _buildStatusDropdown(order.status, order.id)),
          Expanded(
              flex: 1,
              child: IconButton(
                  icon: const Icon(Icons.print, size: 20),
                  onPressed: () => _printReceipt(order))),
          Expanded(
              flex: 1,
              child: IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: () => _showGlassDetails(context, order))),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Row(
      children: [
        if (isMobile)
          IconButton(
            icon: const Icon(Icons.menu_rounded, size: 28, color: Colors.black),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        if (isMobile) const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Orders Control",
                style: TextStyle(
                    fontSize: isMobile ? 22 : 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.black)),
            if (!isMobile)
              const Text("Track and manage your restaurant flow",
                  style: TextStyle(color: Colors.black)),
          ],
        ),
      ],
    );
  }

  // استخدام نظام الـ List المحسن بدلاً من DataTable لمنع الـ Lag تماماً
  Widget _buildOptimizedTable(List<Order> orders, bool isMobile) {
    return Column(
      children: [
        // Header ثابت للجدول
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: const BoxDecoration(
            color: Color(0xFFF1F3F5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
          ),
          child: const Row(
            children: [
              Expanded(
                  flex: 2,
                  child: Text('ID',
                      style: TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 13))),
              Expanded(
                  flex: 2,
                  child: Text('TABLE',
                      style: TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 13))),
              Expanded(
                  flex: 2,
                  child: Text('ITEMS',
                      style: TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 13))),
              Expanded(
                  flex: 2,
                  child: Text('TOTAL',
                      style: TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 13))),
              Expanded(
                  flex: 3,
                  child: Text('STATUS',
                      style: TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 13))),
              Expanded(
                  flex: 2,
                  child: Text('TIME',
                      style: TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 13))),
              Expanded(
                  flex: 1,
                  child: Text('ACTION',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 13))),
            ],
          ),
        ),
        // قائمة الطلبات (تحمل فقط ما يظهر على الشاشة)
        Expanded(
          child: ListView.separated(
            itemCount: orders.length,
            physics: const BouncingScrollPhysics(),
            separatorBuilder: (context, index) =>
                const Divider(height: 1, color: Color(0xFFF1F3F5)),
            itemBuilder: (context, index) {
              final order = orders[index];
              return _buildOrderRow(order);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown(String status, String orderId) {
    Color color = (status == 'Done' || status == 'Delivered')
        ? brandGreen
        : (status == 'Cancelled' ? Colors.red : Colors.orange);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        height: 32,
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.2))),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: statusOptions.contains(status) ? status : 'Pending',
            icon:
                Icon(Icons.keyboard_arrow_down_rounded, color: color, size: 16),
            dropdownColor: Colors.white,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 11),
            onChanged: (newStatus) async {
              if (newStatus != null && newStatus != status) {
                await FirebaseService.updateOrderStatus(orderId, newStatus);
              }
            },
            items: statusOptions
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ['All', ...statusOptions].map((status) {
          bool isSelected = selectedFilter == status;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(status),
              selected: isSelected,
              onSelected: (val) {
                if (val) setState(() => selectedFilter = status);
              },
              selectedColor: brandGreen,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showGlassDetails(BuildContext context, Order order) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) {
        return Center(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              width: MediaQuery.of(context).size.width > 500
                  ? 450
                  : MediaQuery.of(context).size.width * 0.9,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Order #${order.id.substring(order.id.length.clamp(0, 5)).toUpperCase()}",
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.black),
                    ),
                    const Divider(height: 30, color: Color(0xFFEEEEEE)),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: order.items
                              .map((item) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(item.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                            fontSize: 16)),
                                    trailing: Text("x${item.quantity}",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            color: Colors.black,
                                            fontSize: 16)),
                                    // تم إضافة الحجم هنا مع الملاحظات
                                    subtitle: (item.size != null ||
                                            (item.notes != null &&
                                                item.notes!.isNotEmpty))
                                        ? Text(
                                            "${item.size != null ? 'Size: ${item.size}' : ''}${item.size != null && item.notes != null && item.notes!.isNotEmpty ? ' | ' : ''}${item.notes ?? ''}",
                                            style: TextStyle(
                                                color: Colors.grey.shade800),
                                          )
                                        : null,
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                    const Divider(height: 30, color: Color(0xFFEEEEEE)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total Amount",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                        Text("\$${order.totalPrice.toStringAsFixed(2)}",
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: brandGreen)),
                      ],
                    ),
                    const SizedBox(height: 25),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text("Close",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
