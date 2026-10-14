// lib/app/sidebar.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:premium_store/state/auth_brovider.dart';
import 'package:premium_store/state/language_provider.dart';
import 'package:premium_store/localization/app_translations.dart';

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({super.key});

  static const Color primaryGreen = Color(0xFF00B686);

  @override
  Widget build(BuildContext context) {
    // متابعة اللغة الحالية
    final languageProvider = context.watch<LanguageProvider>();

    // الحصول على كود اللغة الحالية
    // ar = عربي
    // de = ألماني
    final languageCode = languageProvider.locale.languageCode;

    String location = '';

    try {
      location = GoRouter.of(context)
          .routerDelegate
          .currentConfiguration
          .last
          .matchedLocation;
    } catch (e) {
      location = '/';
    }

    final authProvider = context.read<AuthProvider>();

    return Container(
      width: 260,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(
            color: Colors.grey.withOpacity(0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          // =========================
          // Logo
          // =========================
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 40,
            ),
            child: const Text(
              'Premium.',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),
          ),

          // =========================
          // Menu
          // =========================
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _sidebarItem(
                    context,
                    icon: Icons.grid_view_rounded,
                    label: AppTranslations.get(
                      languageCode,
                      'dashboard',
                    ),
                    route: '/admin/dashboard',
                    isActive: location == '/admin/dashboard',
                  ),
                  _sidebarItem(
                    context,
                    icon: Icons.shopping_bag_outlined,
                    label: AppTranslations.get(
                      languageCode,
                      'orders',
                    ),
                    route: '/admin/orders',
                    isActive: location == '/admin/orders',
                  ),
                  _sidebarItem(
                    context,
                    icon: Icons.shopping_cart_checkout,
                    label: AppTranslations.get(
                      languageCode,
                      'pos',
                    ),
                    route: '/admin/pos',
                    isActive: location == '/admin/pos',
                  ),
                  _sidebarItem(
                    context,
                    icon: Icons.fastfood_outlined,
                    label: AppTranslations.get(
                      languageCode,
                      'products',
                    ),
                    route: '/admin/products',
                    isActive: location == '/admin/products',
                  ),
                  _sidebarItem(
                    context,
                    icon: Icons.table_restaurant_rounded,
                    label: AppTranslations.get(
                      languageCode,
                      'tables',
                    ),
                    route: '/admin/tables',
                    isActive: location == '/admin/tables',
                  ),
                  _sidebarItem(
                    context,
                    icon: Icons.category_rounded,
                    label: AppTranslations.get(
                      languageCode,
                      'categories',
                    ),
                    route: '/admin/categories',
                    isActive: location == '/admin/categories',
                  ),
                  _sidebarItem(
                    context,
                    icon: Icons.inventory_2_outlined,
                    label: AppTranslations.get(
                      languageCode,
                      'inventory',
                    ),
                    route: '/admin/inventory',
                    isActive: location == '/admin/inventory',
                  ),
                  _sidebarItem(
                    context,
                    icon: Icons.warehouse_outlined,
                    label: AppTranslations.get(
                      languageCode,
                      'stock_control',
                    ),
                    route: '/admin/stock-control',
                    isActive: location == '/admin/stock-control',
                  ),
                ],
              ),
            ),
          ),

          // =========================
          // Language Button
          // =========================
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            child: ListTile(
              onTap: () async {
                await languageProvider.toggleLanguage();
              },
              mouseCursor: SystemMouseCursors.click,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              leading: Icon(
                Icons.language_rounded,
                color: primaryGreen,
                size: 22,
              ),
              title: Text(
                AppTranslations.get(
                  languageCode,
                  'language',
                ),
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.normal,
                  fontSize: 14,
                ),
              ),
              trailing: Text(
                languageProvider.isArabic ? 'Deutsch' : 'العربية',
                style: const TextStyle(
                  color: primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const Divider(),

          // =========================
          // Logout
          // =========================
          _sidebarItem(
            context,
            icon: Icons.logout_rounded,
            label: AppTranslations.get(
              languageCode,
              'logout',
            ),
            route: '/admin/login',
            isActive: false,
            isLogout: true,
            auth: authProvider,
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // =========================
  // Sidebar Item
  // =========================
  Widget _sidebarItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required bool isActive,
    bool isLogout = false,
    AuthProvider? auth,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 2,
      ),
      child: ListTile(
        onTap: () async {
          final scaffoldState = Scaffold.maybeOf(context);

          // إغلاق Drawer إذا كان مفتوحًا
          if (scaffoldState != null && scaffoldState.isDrawerOpen) {
            Navigator.of(context).pop();
          }

          // =========================
          // Logout
          // =========================
          if (isLogout) {
            try {
              await auth?.logout();

              if (!context.mounted) {
                return;
              }

              context.go('/admin/login');
            } catch (e) {
              debugPrint(
                'Logout Error: $e',
              );
            }

            return;
          }

          // =========================
          // Navigation
          // =========================
          if (!context.mounted) {
            return;
          }

          debugPrint(
            'Navigating to: $route',
          );

          context.go(route);
        },
        mouseCursor: SystemMouseCursors.click,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        leading: Icon(
          icon,
          color: isActive ? primaryGreen : Colors.grey[600],
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isActive ? primaryGreen : Colors.black87,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        tileColor:
            isActive ? primaryGreen.withOpacity(0.1) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
