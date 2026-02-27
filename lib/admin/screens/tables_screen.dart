import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui' as ui;

// استيراد الخدمات والموديلات
import '../../core/models/table_model.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/qr_services.dart';
import '../../state/auth_brovider.dart';

// للتعامل مع تحميل الصور في الويب
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  final tableController = TextEditingController();

  @override
  void dispose() {
    tableController.dispose();
    super.dispose();
  }

  // --- دالة تحميل الـ QR Code ---
  Future<void> _downloadQR(GlobalKey qrKey, String fileName) async {
    if (!kIsWeb) return;
    try {
      final boundary =
          qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final blob = html.Blob([pngBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Download failed')));
    }
  }

  // --- ديالوج إضافة طاولة بتصميم بريميوم ---
  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add New Table',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: tableController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Table Number',
            hintText: 'e.g. 5',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.table_bar),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              final num = int.tryParse(tableController.text);
              if (num != null) {
                final qrData = QRService.generateQRData(num);
                await FirebaseService.tables.add({
                  'tableNumber': num,
                  'qrUrl': qrData,
                  'createdAt': DateTime.now(),
                });
                tableController.clear();
                if (mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B686),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Create Table',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

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
                  Expanded(
                    child: StreamBuilder<List<TableModel>>(
                      stream: FirebaseService.getTablesStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFF00B686)));
                        }
                        final tables = snapshot.data ?? [];
                        return GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 280,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 25,
                            mainAxisSpacing: 25,
                          ),
                          itemCount: tables.length,
                          itemBuilder: (ctx, i) => _buildTableCard(tables[i]),
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

  // --- تصميم الهيدر ---
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Tables & QR Codes",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Text("Generate and manage QR codes for your tables",
                style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _showAddDialog,
          icon: const Icon(Icons.add),
          label: const Text("Add Table"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00B686),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  // --- كارت الطاولة البريميوم ---
  Widget _buildTableCard(TableModel table) {
    final qrKey = GlobalKey();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Table ${table.tableNumber}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              const Icon(Icons.qr_code_2, color: Color(0xFF00B686)),
            ],
          ),
          const Spacer(),
          RepaintBoundary(
            key: qrKey,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: QrImageView(
                data: table.qrUrl,
                version: QrVersions.auto,
                size: 140.0,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  _downloadQR(qrKey, 'Table_${table.tableNumber}.png'),
              icon: const Icon(Icons.download, size: 18),
              label: const Text("Download"),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00B686),
                side: const BorderSide(color: Color(0xFF00B686)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- الـ Sidebar الموحد ---
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
        _sidebarItem(context, auth, Icons.grid_view_rounded, "Dashboard",
            "/admin/dashboard", location == "/admin/dashboard"),
        _sidebarItem(context, auth, Icons.shopping_cart_outlined, "Orders",
            "/admin/orders", location == "/admin/orders"),
        _sidebarItem(context, auth, Icons.fastfood_outlined, "Products",
            "/admin/products", location == "/admin/products"),
        _sidebarItem(context, auth, Icons.category_outlined, "Categories",
            "/admin/categories", location == "/admin/categories"),
        _sidebarItem(context, auth, Icons.table_restaurant_outlined, "Tables",
            "/admin/tables", location == "/admin/tables"),
        const Spacer(),
        _sidebarItem(context, auth, Icons.logout_rounded, "Logout",
            "/admin/login", false,
            isLogout: true),
      ]),
    );
  }

  Widget _sidebarItem(BuildContext context, AuthProvider auth, IconData icon,
      String label, String route, bool isActive,
      {bool isLogout = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: () async {
          if (isLogout) {
            await auth.logout();
            if (context.mounted) context.go(route);
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
