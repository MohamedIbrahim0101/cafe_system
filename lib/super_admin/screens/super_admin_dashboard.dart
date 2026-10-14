import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:premium_store/state/auth_brovider.dart';
import 'package:premium_store/state/super_admin_provider.dart';

// استدعاء شاشة قائمة المطاعم الخاصة بك (تأكد من مطابق المسار)
import 'restaurants_list_screen.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  State<SuperAdminDashboardScreen> createState() =>
      _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // التحقق من حجم الشاشة للتكيف بين الموبايل والويب
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    // الشاشات الخاصة بالـ Super Admin
    final List<Widget> pages = [
      const _SuperAdminOverviewTab(),
      const RestaurantsListScreen(), // شاشة قائمة المطاعم
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black,
        title: Text(
          'SUPER ADMIN DASHBOARD',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: isDesktop
          ? Row(
              children: [
                // القائمة الجانبية للشاشات الكبيرة
                NavigationRail(
                  backgroundColor: Colors.white,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  labelType: NavigationRailLabelType.all,
                  selectedIconTheme: const IconThemeData(color: Colors.black),
                  selectedLabelTextStyle: GoogleFonts.poppins(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedIconTheme:
                      const IconThemeData(color: Colors.grey),
                  unselectedLabelTextStyle: GoogleFonts.poppins(
                    color: Colors.grey,
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Overview'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.storefront_outlined),
                      selectedIcon: Icon(Icons.storefront),
                      label: Text('Restaurants'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                // المحتوى الرئيسي
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: pages,
                  ),
                ),
              ],
            )
          : IndexedStack(
              index: _selectedIndex,
              children: pages,
            ),
      // القائمة السفلية للموبايل
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.grey,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard),
                  label: 'Overview',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.storefront_outlined),
                  activeIcon: Icon(Icons.storefront),
                  label: 'Restaurants',
                ),
              ],
            ),
    );
  }
}

// --------------------------------------------------------
// Tab 1: نظرة عامة وإحصائيات الـ Super Admin
// --------------------------------------------------------
class _SuperAdminOverviewTab extends StatelessWidget {
  const _SuperAdminOverviewTab();

  @override
  Widget build(BuildContext context) {
    final superAdminProvider = Provider.of<SuperAdminProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "System Summary",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),

          // كروت الإحصائيات السريعة
          LayoutBuilder(
            builder: (context, constraints) {
              final double cardWidth = constraints.maxWidth > 600
                  ? (constraints.maxWidth - 40) / 3
                  : constraints.maxWidth;

              return Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  _buildStatCard(
                    title: "Total Restaurants",
                    value: "${superAdminProvider.restaurants.length}",
                    icon: Icons.store_rounded,
                    color: Colors.blueAccent,
                    width: cardWidth,
                  ),
                  _buildStatCard(
                    title: "Active Stores",
                    value:
                        "${superAdminProvider.restaurants.where((r) => r.isActive).length}",
                    icon: Icons.check_circle_rounded,
                    color: Colors.green,
                    width: cardWidth,
                  ),
                  _buildStatCard(
                    title: "Inactive Stores",
                    value:
                        "${superAdminProvider.restaurants.where((r) => !r.isActive).length}",
                    icon: Icons.pause_circle_filled_rounded,
                    color: Colors.orangeAccent,
                    width: cardWidth,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 40),

          // قسم آخر النشاطات أو النظرة العامة
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Platform Management",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "From here you can monitor all operations across restaurants, add new sub-admins, and manage subscriptions.",
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}