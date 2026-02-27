import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../state/order_provider.dart';
import '../../state/auth_brovider.dart';
import '../../core/services/firebase_service.dart';
import '../../core/models/order_model.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    // الاستماع للمزود (Provider)
    // بفضل الـ Stream في الـ Provider، ستتحدث الواجهة تلقائياً عند أي تغيير في Firebase
    final orderProvider = context.watch<OrderProvider>();
    final authProvider = context.watch<AuthProvider>();

    final filteredOrders = selectedFilter == 'All'
        ? orderProvider.orders
        : orderProvider.orders
            .where((o) => o.status == selectedFilter)
            .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Row(
        children: [
          _buildSidebar(context, authProvider),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildFilterChips()),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 20)
                        ],
                      ),
                      child: orderProvider.isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFF00B686)))
                          : filteredOrders.isEmpty
                              ? _buildEmptyState()
                              : _buildResponsiveTable(filteredOrders),
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

  // --- بناء الجدول المستجيب ---
  Widget _buildResponsiveTable(List<Order> orders) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Scrollbar(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor:
                  MaterialStateProperty.all(const Color(0xFFF8F9FA)),
              dataRowHeight: 75,
              columns: const [
                DataColumn(
                    label: Text('ORDER ID',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('TABLE',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('ITEMS',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('TOTAL',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('STATUS',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('TIME',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('DETAILS',
                        style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: orders.map((order) => _buildOrderRow(order)).toList(),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildOrderRow(Order order) {
    return DataRow(cells: [
      DataCell(Text(
          "#${order.id.substring(order.id.length.clamp(0, 5)).toUpperCase()}",
          style: const TextStyle(fontWeight: FontWeight.bold))),
      DataCell(CircleAvatar(
        radius: 16,
        backgroundColor: Colors.orange.shade50,
        child: Text("${order.tableNumber}",
            style: const TextStyle(
                fontSize: 13,
                color: Colors.orange,
                fontWeight: FontWeight.bold)),
      )),
      DataCell(Text("${order.items.length} Items")),
      DataCell(Text("\$${order.totalPrice.toStringAsFixed(2)}",
          style: const TextStyle(fontWeight: FontWeight.bold))),
      DataCell(_buildStatusBadge(order.status, order.id)),
      DataCell(Text(order.createdAt.toString().length > 16
          ? order.createdAt.toString().substring(11, 16)
          : "00:00")),
      DataCell(IconButton(
        icon: const Icon(Icons.visibility_outlined, color: Color(0xFF00B686)),
        onPressed: () => _showOrderDetails(context, order),
      )),
    ]);
  }

  // --- ديالوج التفاصيل ---
  void _showOrderDetails(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
                child: Text(
                    "Order Details #${order.id.substring(order.id.length.clamp(0, 5)).toUpperCase()}")),
            IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close)),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _buildInfoTile(
                      Icons.table_restaurant, "Table", "${order.tableNumber}"),
                  const SizedBox(width: 30),
                  _buildInfoTile(
                      Icons.access_time,
                      "Order Time",
                      order.createdAt.toString().length > 16
                          ? order.createdAt.toString().substring(11, 16)
                          : "00:00"),
                ],
              ),
              const Divider(height: 30),
              const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Items",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16))),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: order.items.length,
                  itemBuilder: (context, index) {
                    final item = order.items[index];
                    return ListTile(
                      leading: CircleAvatar(
                          backgroundColor: const Color(0xFF00B686),
                          radius: 12,
                          child: Text("${item.quantity}",
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10))),
                      title: Text(item.name),
                      trailing: Text(
                          "\$${(item.price * item.quantity).toStringAsFixed(2)}",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    );
                  },
                ),
              ),
              const Divider(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("\$${order.totalPrice.toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00B686))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- الأجزاء المساعدة (Header, Sidebar, Status) ---
  Widget _buildStatusBadge(String status, String orderId) {
    Color color = status == 'Pending'
        ? Colors.orange
        : status == 'Preparing'
            ? Colors.blue
            : status == 'Done'
                ? Colors.green
                : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)),
      child: DropdownButton<String>(
        value: status,
        underline: const SizedBox(),
        icon: Icon(Icons.arrow_drop_down, color: color),
        style:
            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
        items: ['Pending', 'Preparing', 'Done', 'Cancelled']
            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
            .toList(),
        onChanged: (newStatus) async {
          if (newStatus != null) {
            // تحديث في Firebase. الـ Stream سيتكفل بتحديث الشاشة تلقائياً
            await FirebaseService.updateOrderStatus(orderId, newStatus);
          }
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return Row(
      children:
          ['All', 'Pending', 'Preparing', 'Done', 'Cancelled'].map((status) {
        bool isSelected = selectedFilter == status;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            showCheckmark: false,
            label: Text(status),
            selected: isSelected,
            onSelected: (val) => setState(() => selectedFilter = status),
            selectedColor: const Color(0xFF00B686),
            backgroundColor: Colors.white,
            labelStyle:
                TextStyle(color: isSelected ? Colors.white : Colors.grey[600]),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                    color: isSelected
                        ? Colors.transparent
                        : Colors.grey.shade200)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHeader() {
    return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Orders Management",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          Text("Real-time order tracking system",
              style: TextStyle(color: Colors.grey, fontSize: 16)),
        ]);
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, color: Colors.grey, size: 18),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ]),
    ]);
  }

  Widget _buildEmptyState() => const Center(
      child: Text("No orders found", style: TextStyle(color: Colors.grey)));

  Widget _buildSidebar(BuildContext context, AuthProvider auth) {
    final String location = GoRouterState.of(context).uri.toString();
    return Container(
      width: 260,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(children: [
        const Text("Romdol.",
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00B686))),
        const SizedBox(height: 40),
        _sidebarItem(context, Icons.grid_view_rounded, "Dashboard",
            "/admin/dashboard", location == "/admin/dashboard"),
        _sidebarItem(context, Icons.shopping_cart_outlined, "Orders",
            "/admin/orders", location == "/admin/orders"),
        _sidebarItem(context, Icons.fastfood_outlined, "Products",
            "/admin/products", location == "/admin/products"),
        _sidebarItem(context, Icons.category_outlined, "Categories",
            "/admin/categories", location == "/admin/categories"),
        const Spacer(),
        _sidebarItem(
            context, Icons.logout_rounded, "Logout", "/admin/login", false,
            isLogout: true),
      ]),
    );
  }

  Widget _sidebarItem(BuildContext context, IconData icon, String label,
      String route, bool isActive,
      {bool isLogout = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: () async {
          if (isLogout) {
            await context.read<AuthProvider>().logout();
            context.go('/admin/login');
          } else {
            context.go(route);
          }
        },
        leading: Icon(icon,
            color: isActive ? const Color(0xFF00B686) : Colors.grey[400]),
        title: Text(label,
            style: TextStyle(
                color: isActive ? Colors.black : Colors.grey[600],
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        tileColor: isActive
            ? const Color(0xFF00B686).withOpacity(0.08)
            : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
