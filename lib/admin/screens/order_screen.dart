import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../../state/auth_brovider.dart';
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
  final List<String> statusOptions = [
    'Pending',
    'Preparing',
    'Done',
    'Cancelled',
    'Delivered'
  ];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Color brandGreen = const Color(0xFF00B686);

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final authProvider = context.watch<AuthProvider>();

    // فحص حجم الشاشة
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    final filteredOrders = selectedFilter == 'All'
        ? orderProvider.orders
        : orderProvider.orders
            .where((o) => o.status == selectedFilter)
            .toList();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      // الدرور للموبايل فقط
      drawer:
          isMobile ? Drawer(child: _buildSidebar(context, authProvider)) : null,
      body: Row(
        children: [
          // السايد بار الثابت للكمبيوتر فقط
          if (!isMobile) _buildSidebar(context, authProvider),

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
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: orderProvider.isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                    color: brandGreen))
                            : filteredOrders.isEmpty
                                ? const Center(child: Text("No orders found."))
                                : _buildResponsiveTable(filteredOrders),
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

  Widget _buildHeader(bool isMobile) {
    return Row(
      children: [
        if (isMobile)
          IconButton(
            icon: const Icon(Icons.menu_rounded, size: 28),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        if (isMobile) const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Orders Control",
                style: TextStyle(
                    fontSize: isMobile ? 22 : 28, fontWeight: FontWeight.w900)),
            if (!isMobile)
              Text("Track and manage your restaurant flow",
                  style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ],
    );
  }

  Widget _buildResponsiveTable(List<Order> orders) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  // لون خلفية الهيدر فاتح عشان يبرز النص الأسود فوقه
                  headingRowColor:
                      MaterialStateProperty.all(const Color(0xFFF1F3F5)),
                  dataRowHeight: 75,
                  headingRowHeight: 55,
                  horizontalMargin: 20,
                  columnSpacing: 40,

                  // --- هذا هو التعديل المطلوب لبروز العناوين ---
                  headingTextStyle: const TextStyle(
                    color: Colors.black, // لون أسود صريح
                    fontWeight: FontWeight.w900, // أقصى درجات العرض (Bold)
                    fontSize: 14, // مقاس الخط
                    letterSpacing: 1.1, // مسافة بسيطة بين الحروف لزيادة الوضوح
                  ),
                  // -------------------------------------------

                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('TABLE')),
                    DataColumn(label: Text('ITEMS')),
                    DataColumn(label: Text('TOTAL')),
                    DataColumn(label: Text('STATUS')),
                    DataColumn(label: Text('TIME')),
                    DataColumn(label: Text('ACTION')),
                  ],
                  rows: orders.map((order) => _buildOrderRow(order)).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  DataRow _buildOrderRow(Order order) {
    return DataRow(cells: [
      DataCell(Text("#${order.id.substring(order.id.length - 5).toUpperCase()}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
      DataCell(Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Text("T-${order.tableNumber}",
            style: const TextStyle(
                color: Colors.blue, fontWeight: FontWeight.bold)),
      )),
      DataCell(Text("${order.items.length} Items")),
      DataCell(Text("\$${order.totalPrice.toStringAsFixed(2)}",
          style: const TextStyle(fontWeight: FontWeight.bold))),
      DataCell(_buildStatusDropdown(order.status, order.id)),
      DataCell(Text(order.createdAt.toString().substring(11, 16))),
      DataCell(IconButton(
        icon: Icon(Icons.visibility_rounded, color: brandGreen),
        onPressed: () => _showGlassDetails(context, order),
      )),
    ]);
  }

  Widget _buildStatusDropdown(String status, String orderId) {
    Color color = status == 'Done' || status == 'Delivered'
        ? brandGreen
        : (status == 'Cancelled' ? Colors.red : Colors.orange);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      height: 35,
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: statusOptions.contains(status) ? status : 'Pending',
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: color, size: 16),
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 12),
          onChanged: (newStatus) async {
            if (newStatus != null) {
              await FirebaseService.updateOrderStatus(orderId, newStatus);
            }
          },
          items: statusOptions
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
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
              onSelected: (val) => setState(() => selectedFilter = status),
              selectedColor: brandGreen,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
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
                    // رقم الطلب بالأسود العريض
                    Text(
                      "Order #${order.id.substring(order.id.length - 5).toUpperCase()}",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900, // أسود عريض جداً
                        color: Colors.black,
                      ),
                    ),
                    const Divider(height: 30, color: Color(0xFFEEEEEE)),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: order.items
                              .map((item) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black, // اسم الصنف أسود
                                        fontSize: 16,
                                      ),
                                    ),
                                    trailing: Text(
                                      "x${item.quantity}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color:
                                            Colors.black, // الكمية سوداء وواضحة
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: item.notes != null &&
                                            item.notes!.isNotEmpty
                                        ? Text(
                                            item.notes!,
                                            style: TextStyle(
                                                color: Colors.grey
                                                    .shade800), // ملاحظات غامقة
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
                        const Text(
                          "Total Amount",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black, // النص أسود
                          ),
                        ),
                        Text(
                          "\$${order.totalPrice.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: brandGreen, // السعر بالأخضر الخاص بك للتميز
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black, // الزر أسود صريح
                        minimumSize: const Size(double.infinity, 55),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        "Close",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  // ميثود السايد بار الموحدة
  Widget _buildSidebar(BuildContext context, AuthProvider authProvider) {
    final String location = GoRouterState.of(context).uri.toString();
    return Container(
      width: 260,
      height: double.infinity,
      color: Colors.white,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Text("Romdol.",
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00B686))),
          ),
          Expanded(
            child: Column(
              children: [
                _sidebarItem(
                    context,
                    authProvider,
                    Icons.grid_view_rounded,
                    "Dashboard",
                    "/admin/dashboard",
                    location.contains("dashboard")),
                _sidebarItem(context, authProvider, Icons.shopping_bag_outlined,
                    "Orders", "/admin/orders", location.contains("orders")),
                _sidebarItem(
                    context,
                    authProvider,
                    Icons.fastfood_outlined,
                    "Products",
                    "/admin/products",
                    location.contains("products")),
                _sidebarItem(
                    context,
                    authProvider,
                    Icons.category_rounded,
                    "Categories",
                    "/admin/categories",
                    location.contains("categories")),
              ],
            ),
          ),
          const Divider(indent: 20, endIndent: 20),
          _sidebarItem(context, authProvider, Icons.logout_rounded, "Logout",
              "/admin/login", false,
              isLogout: true),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sidebarItem(BuildContext context, AuthProvider authProvider,
      IconData icon, String label, String route, bool isActive,
      {bool isLogout = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: () async {
          if (isLogout) {
            await authProvider.logout();
            if (mounted) context.go(route);
          } else {
            if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
              Navigator.pop(context);
            }
            context.go(route);
          }
        },
        leading: Icon(icon,
            color: isActive ? brandGreen : Colors.grey[400], size: 22),
        title: Text(label,
            style: TextStyle(
                color: isActive ? brandGreen : Colors.grey[700],
                fontSize: 15,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500)),
        tileColor: isActive ? brandGreen.withOpacity(0.08) : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        dense: true,
      ),
    );
  }
}
