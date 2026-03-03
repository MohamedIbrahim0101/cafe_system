import 'package:flutter/material.dart';
import 'package:premium_store/state/auth_brovider.dart';
import 'package:premium_store/state/product_brovider.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../state/order_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String selectedPeriod = "This Week";
  final Color primaryGreen = const Color(0xFF00B686); // اللون الخاص بك

  // دالة لحساب أرباح يوم محدد في الأسبوع الحالي
  double _getRevenueForDay(List<dynamic> orders, int weekdayIndex) {
    final now = DateTime.now();
    // الحصول على تاريخ يوم الاثنين من هذا الأسبوع كمبدأ
    final firstDayOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final targetDate = firstDayOfWeek.add(Duration(days: weekdayIndex));

    return orders.where((o) {
      final isSuccess = ['Completed', 'Served', 'Delivered'].contains(o.status);
      final isSameDay = o.createdAt.year == targetDate.year &&
          o.createdAt.month == targetDate.month &&
          o.createdAt.day == targetDate.day;
      return isSuccess && isSameDay;
    }).fold(0.0, (sum, o) => sum + o.totalPrice);
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final productProvider = context.watch<ProductProvider>();
    final authProvider = context.watch<AuthProvider>();

    final totalRevenue = orderProvider.orders
        .where((o) => ['Completed', 'Served', 'Delivered'].contains(o.status))
        .fold<double>(0.0, (sum, o) => sum + o.totalPrice);

    final activeOrders = orderProvider.orders
        .where(
            (o) => !['Completed', 'Cancelled', 'Delivered'].contains(o.status))
        .length;

    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 950;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      drawer:
          isMobile ? Drawer(child: _buildSidebar(context, authProvider)) : null,
      appBar: isMobile
          ? AppBar(
              title: const Text("Admin Dashboard",
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black))
          : null,
      body: Row(
        children: [
          if (!isMobile) _buildSidebar(context, authProvider),
          Expanded(
            child: SelectionArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(authProvider),
                    const SizedBox(height: 32),
                    _buildStatGrid(
                        orderProvider.orders.length,
                        totalRevenue,
                        activeOrders,
                        productProvider.products.length,
                        isMobile),
                    const SizedBox(height: 32),
                    LayoutBuilder(builder: (context, constraints) {
                      if (constraints.maxWidth > 1150) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                flex: 3,
                                child:
                                    _buildDetailedChart(orderProvider.orders)),
                            const SizedBox(width: 24),
                            Expanded(
                                flex: 2,
                                child: _buildRecentOrdersSection(context,
                                    orderProvider, isMobile, screenWidth)),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            _buildDetailedChart(orderProvider.orders),
                            const SizedBox(height: 24),
                            _buildRecentOrdersSection(
                                context, orderProvider, isMobile, screenWidth),
                          ],
                        );
                      }
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AuthProvider auth) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 20,
      runSpacing: 15,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Dashboard Overview",
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.black)),
            Text("Welcome back, ${auth.user?.email?.split('@')[0] ?? 'Admin'}!",
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primaryGreen.withOpacity(0.5)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedPeriod,
              icon: Icon(Icons.keyboard_arrow_down, color: primaryGreen),
              style:
                  TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
              items: ["Today", "This Week", "This Month"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => selectedPeriod = v!),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildDetailedChart(List<dynamic> orders) {
    // إنشاء النقاط بناءً على أرباح الأسبوع الفعلي
    List<FlSpot> weekSpots = List.generate(7, (index) {
      double dailyRevenue = _getRevenueForDay(orders, index);
      return FlSpot(index.toDouble(), dailyRevenue);
    });

    return Container(
      height: 400,
      padding: const EdgeInsets.fromLTRB(10, 24, 24, 24),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 14),
            child: Text("Revenue Analytics",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black)),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) =>
                        Colors.black.withOpacity(0.8),
                    getTooltipItems: (spots) => spots
                        .map((s) => LineTooltipItem(
                            '\$${s.y.toStringAsFixed(2)}',
                            const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)))
                        .toList(),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        const days = [
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun'
                        ];
                        if (val >= 0 && val < 7) {
                          return Text(days[val.toInt()],
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 10));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (val, meta) => Text('\$${val.toInt()}',
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 10)),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: weekSpots, // هنا البيانات التلقائية
                    isCurved: true,
                    color: primaryGreen,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                              radius: 4,
                              color: Colors.white,
                              strokeWidth: 2,
                              strokeColor: primaryGreen),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          primaryGreen.withOpacity(0.2),
                          primaryGreen.withOpacity(0.0)
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
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
  }

  Widget _buildStatGrid(
      int total, double revenue, int active, int products, bool isMobile) {
    return LayoutBuilder(builder: (context, constraints) {
      int crossAxisCount = constraints.maxWidth < 600
          ? 1
          : (constraints.maxWidth < 1100 ? 2 : 4);
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: isMobile ? 3.2 : 1.7,
        children: [
          _buildStatCard("Total Orders", total.toString(),
              Icons.shopping_basket_outlined, Colors.blue),
          _buildStatCard("Revenue", "\$${revenue.toStringAsFixed(0)}",
              Icons.monetization_on_outlined, Colors.orange),
          _buildStatCard("Active Orders", active.toString(),
              Icons.pending_actions, primaryGreen),
          _buildStatCard("Total Products", products.toString(),
              Icons.restaurant_menu, Colors.purple),
        ],
      );
    });
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)
          ]),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(value,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black))),
                Text(title,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersSection(BuildContext context, OrderProvider provider,
      bool isMobile, double screenWidth) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Recent Orders",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
              TextButton(
                  onPressed: () => context.go('/admin/orders'),
                  child:
                      Text("View All", style: TextStyle(color: primaryGreen))),
            ],
          ),
          const SizedBox(height: 20),
          if (provider.orders.isEmpty)
            const Center(
                child: Text("No orders yet",
                    style: TextStyle(color: Colors.black)))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount:
                  provider.orders.length > 5 ? 5 : provider.orders.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final order = provider.orders[index];
                return Row(
                  children: [
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxRadius(
                          color: Colors.grey[100] ?? Colors.grey,
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.receipt_long_outlined,
                          color: Colors.black54),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              "#${order.id.substring(order.id.length - 4).toUpperCase()}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black)),
                          Text("Table ${order.tableNumber}",
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("\$${order.totalPrice.toStringAsFixed(2)}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                        _statusChip(order.status),
                      ],
                    )
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color =
        (status == 'Completed' || status == 'Served' || status == 'Delivered')
            ? primaryGreen
            : (status == 'Cancelled' ? Colors.red : Colors.orange);
    return Text(status,
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold));
  }

  Widget _buildSidebar(BuildContext context, AuthProvider auth) {
    final String location = GoRouterState.of(context).uri.toString();
    return Container(
      width: 260,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 40),
          Text("Romdol.",
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen)),
          const SizedBox(height: 40),
          _sidebarItem(context, Icons.grid_view_rounded, "Dashboard",
              "/admin/dashboard", location == "/admin/dashboard"),
          _sidebarItem(context, Icons.shopping_cart_outlined, "Orders",
              "/admin/orders", location == "/admin/orders"),
          _sidebarItem(context, Icons.fastfood_outlined, "Products",
              "/admin/products", location == "/admin/products"),
          _sidebarItem(context, Icons.table_restaurant_outlined, "Tables",
              "/admin/tables", location == "/admin/tables"),
          const Spacer(),
          const Divider(),
          _sidebarItem(
              context, Icons.logout_rounded, "Logout", "/admin/login", false,
              isLogout: true),
          const SizedBox(height: 20),
        ],
      ),
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
            if (context.mounted) context.go('/admin/login');
          } else {
            context.go(route);
          }
        },
        leading: Icon(icon, color: isActive ? primaryGreen : Colors.grey[400]),
        title: Text(label,
            style: TextStyle(
                color: isActive ? Colors.black : Colors.grey[600],
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        tileColor:
            isActive ? primaryGreen.withOpacity(0.08) : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// تعديل بسيط في BoxRadius ليصبح BoxDecoration
BoxDecoration BoxRadius(
    {required Color color, required BorderRadius borderRadius}) {
  return BoxDecoration(color: color, borderRadius: borderRadius);
}
