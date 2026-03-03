import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:premium_store/state/auth_brovider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/models/table_model.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/qr_services.dart';

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
  final Color brandGreen = const Color(0xFF00B686);

  @override
  void dispose() {
    tableController.dispose();
    super.dispose();
  }

  // --- دالة تحميل الـ QR Code ---
  Future<void> _downloadQR(GlobalKey qrKey, String fileName) async {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Download is only supported on Web for now')),
      );
      return;
    }
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
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Download failed')));
      }
    }
  }

  // --- دالة حذف الطاولة ---
  Future<void> _deleteTable(String docId, int tableNum) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Delete Table?"),
        content: Text("Are you sure you want to delete Table $tableNum?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseService.tables.doc(docId).delete();
    }
  }

  // --- ديالوج إضافة طاولة ---
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
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Table Number',
            hintText: 'e.g. 5',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.table_bar),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final num = int.tryParse(tableController.text);
              if (num != null) {
                final qrData = QRService.generateQRData(num);
                await FirebaseService.tables.add({
                  'tableNumber': num,
                  'qrUrl': qrData,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                tableController.clear();
                if (mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: brandGreen),
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      // Drawer للموبايل
      drawer:
          isMobile ? Drawer(child: _buildSidebar(context, authProvider)) : null,
      appBar: isMobile
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              iconTheme: const IconThemeData(color: Colors.black),
              title: const Text("Tables Management",
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile) _buildSidebar(context, authProvider),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16.0 : 32.0,
                  vertical: isMobile ? 16.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isMobile),
                  const SizedBox(height: 32),
                  Expanded(
                    child: StreamBuilder<List<TableModel>>(
                      stream: FirebaseService.getTablesStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                              child:
                                  CircularProgressIndicator(color: brandGreen));
                        }
                        final tables = snapshot.data ?? [];
                        if (tables.isEmpty) return _buildEmptyState();

                        return GridView.builder(
                          // توزيع تلقائي بناءً على العرض
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 280,
                            childAspectRatio: 0.72,
                            crossAxisSpacing: 24,
                            mainAxisSpacing: 24,
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

  Widget _buildHeader(bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool wrapMode = constraints.maxWidth < 600;
        return Flex(
          direction: wrapMode ? Axis.vertical : Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment:
              wrapMode ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Tables & QR Codes",
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1C1E))),
                const SizedBox(height: 4),
                Text("Generate and manage QR codes for your tables",
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              ],
            ),
            if (wrapMode) const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text("Add New Table"),
              style: ElevatedButton.styleFrom(
                backgroundColor: brandGreen,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTableCard(TableModel table) {
    final qrKey = GlobalKey();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 6))
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.table_bar_outlined, size: 18, color: brandGreen),
                    const SizedBox(width: 8),
                    Text('Table ${table.tableNumber}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: RepaintBoundary(
                    key: qrKey,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: QrImageView(
                        data: table.qrUrl,
                        version: QrVersions.auto,
                        eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square, color: Colors.black),
                        dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Colors.black),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _downloadQR(qrKey, 'Table_${table.tableNumber}.png'),
                    icon: const Icon(Icons.file_download_outlined, size: 18),
                    label: const Text("Download PNG",
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: brandGreen,
                      side: BorderSide(color: brandGreen.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              tooltip: "Delete Table",
              icon: Icon(Icons.cancel_rounded,
                  color: Colors.red.shade200, size: 22),
              onPressed: () => _deleteTable(table.id, table.tableNumber),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_2_rounded, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 16),
          const Text("No tables added yet",
              style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  // --- Sidebar المتناسق مع بقية التطبيق ---
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
                  color: brandGreen)),
          const SizedBox(height: 40),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _sidebarItem(
                      context,
                      auth,
                      Icons.grid_view_rounded,
                      "Dashboard",
                      "/admin/dashboard",
                      location.contains("dashboard")),
                  _sidebarItem(context, auth, Icons.shopping_bag_outlined,
                      "Orders", "/admin/orders", location.contains("orders")),
                  _sidebarItem(
                      context,
                      auth,
                      Icons.fastfood_outlined,
                      "Products",
                      "/admin/products",
                      location.contains("products")),
                  _sidebarItem(context, auth, Icons.table_bar_outlined,
                      "Tables", "/admin/tables", location.contains("tables")),
                ],
              ),
            ),
          ),
          _sidebarItem(context, auth, Icons.logout_rounded, "Logout",
              "/admin/login", false,
              isLogout: true),
          const SizedBox(height: 24),
        ],
      ),
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
            if (mounted) context.go(route);
          } else {
            context.go(route);
          }
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: isActive ? brandGreen.withOpacity(0.08) : Colors.transparent,
        leading: Icon(icon,
            color: isActive ? brandGreen : Colors.grey[400], size: 22),
        title: Text(label,
            style: TextStyle(
                color: isActive ? brandGreen : Colors.grey[700],
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                fontSize: 15)),
      ),
    );
  }
}
