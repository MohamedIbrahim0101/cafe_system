import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:premium_store/app/sidebar.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

// Models & Services
import '../../core/models/table_model.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/qr_services.dart';

class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final tableController = TextEditingController();
  final Color primaryGreen = const Color(0xFF00B686);

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
        content: Text(tableNum == 0
            ? "Are you sure you want to delete Takeaway QR?"
            : "Are you sure you want to delete Table $tableNum?"),
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
    bool isTakeaway = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add New QR Point',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isTakeaway)
                TextField(
                  controller: tableController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Table Number',
                    hintText: 'e.g. 5',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.table_bar),
                  ),
                ),
              const SizedBox(height: 10),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Is this for Takeaway?"),
                value: isTakeaway,
                onChanged: (v) => setDialogState(() => isTakeaway = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final num = isTakeaway ? 0 : int.tryParse(tableController.text);
                if (num != null || isTakeaway) {
                  final qrData = QRService.generateQRData(num ?? 0);
                  await FirebaseService.tables.add({
                    'tableNumber': num ?? 0,
                    'qrUrl': qrData,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  tableController.clear();
                  if (mounted) Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
              child:
                  const Text('Create', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: isMobile ? const Drawer(child: AdminSidebar()) : null,
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
                    Expanded(
                      child: StreamBuilder<List<TableModel>>(
                        stream: FirebaseService.getTablesStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                                child: CircularProgressIndicator(
                                    color: primaryGreen));
                          }
                          final tables = snapshot.data ?? [];
                          if (tables.isEmpty) return _buildEmptyState();

                          return GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 280,
                              childAspectRatio: 0.72,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Tables Management",
                  style: TextStyle(
                      fontSize: isMobile ? 20 : 28,
                      fontWeight: FontWeight.w900)),
              if (!isMobile)
                Text("Generate and manage QR codes for your tables & Takeaway",
                    style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: _showAddDialog,
          icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
          label: Text(isMobile ? "Add" : "Add New",
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 20, vertical: 15),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildTableCard(TableModel table) {
    final qrKey = GlobalKey();
    bool isTakeaway = table.tableNumber == 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                        isTakeaway
                            ? Icons.shopping_bag_outlined
                            : Icons.table_bar_outlined,
                        size: 18,
                        color: primaryGreen),
                    const SizedBox(width: 8),
                    Text(isTakeaway ? 'Takeaway' : 'Table ${table.tableNumber}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: RepaintBoundary(
                    key: qrKey,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(12),
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => _downloadQR(qrKey,
                        'Table_${table.tableNumber == 0 ? "Takeaway" : table.tableNumber}.png'),
                    icon: const Icon(Icons.file_download_outlined,
                        size: 18, color: Colors.blue),
                    label: const Text("Download",
                        style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blue.withOpacity(0.05),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 5,
            right: 5,
            child: IconButton(
              icon: Icon(Icons.cancel_rounded,
                  color: Colors.red.withOpacity(0.3), size: 20),
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
          const Text("No tables or Takeaway points added yet",
              style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}
