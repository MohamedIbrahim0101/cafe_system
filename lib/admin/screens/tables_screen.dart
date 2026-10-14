// lib/admin/screens/tables_screen.dart

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:premium_store/app/sidebar.dart';
import 'package:premium_store/localization/app_translations.dart';
import 'package:premium_store/state/auth_brovider.dart';
import 'package:premium_store/state/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

// Models & Services
import '../../core/models/table_model.dart';
import '../../core/services/qr_services.dart';

class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  // ============================================================
  // Scaffold
  // ============================================================

  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  // ============================================================
  // Controllers
  // ============================================================

  final tableController = TextEditingController();

  // ============================================================
  // Colors
  // ============================================================

  final Color primaryGreen = const Color(0xFF00B686);

  // ============================================================
  // Translation Helper
  // ============================================================

  String _tr(BuildContext context, String key) {
    final languageProvider = context.read<LanguageProvider>();

    return AppTranslations.get(
      languageProvider.locale.languageCode,
      key,
    );
  }

  // ============================================================
  // Dispose
  // ============================================================

  @override
  void dispose() {
    tableController.dispose();
    super.dispose();
  }

  // ============================================================
  // Download QR Code
  // ============================================================

  Future<void> _downloadQR(
    GlobalKey qrKey,
    String fileName,
  ) async {
    // Download is currently supported only on Web.
    if (!kIsWeb) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              context,
              'download_web_only',
            ),
          ),
        ),
      );

      return;
    }

    try {
      final boundary = qrKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      final image = await boundary.toImage(
        pixelRatio: 3.0,
      );

      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      final pngBytes = byteData!.buffer.asUint8List();

      final blob = html.Blob([pngBytes]);

      final url = html.Url.createObjectUrlFromBlob(
        blob,
      );

      final anchor = html.AnchorElement(
        href: url,
      )
        ..setAttribute(
          'download',
          fileName,
        )
        ..click();

      html.Url.revokeObjectUrl(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _tr(
                context,
                'download_failed',
              ),
            ),
          ),
        );
      }
    }
  }

  // ============================================================
  // Delete Table
  // ============================================================

  Future<void> _deleteTable(
    String docId,
    int tableNum,
    String restaurantId,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,

      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),

          // Title
          title: Text(
            _tr(
              context,
              'delete_table',
            ),
          ),

          // Content
          content: Text(
            tableNum == 0
                ? _tr(
                    context,
                    'delete_takeaway_qr_confirmation',
                  )
                : "${_tr(context, 'delete_table_confirmation')} "
                  "$tableNum?",
          ),

          // Actions
          actions: [
            // Cancel
            TextButton(
              onPressed: () {
                Navigator.pop(
                  ctx,
                  false,
                );
              },

              child: Text(
                _tr(
                  context,
                  'cancel',
                ),
              ),
            ),

            // Delete
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  ctx,
                  true,
                );
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),

              child: Text(
                _tr(
                  context,
                  'delete',
                ),

                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );

    // Only delete when confirmed
    if (confirmed == true && restaurantId.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .collection('tables')
          .doc(docId)
          .delete();
    }
  }

  // ============================================================
  // Add Table Dialog
  // ============================================================

  void _showAddDialog(
    String restaurantId,
  ) {
    // Make sure restaurant exists
    if (restaurantId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${_tr(context, 'error_prefix')}: "
            "${_tr(context, 'no_active_restaurant')}",
          ),
        ),
      );

      return;
    }

    bool isTakeaway = false;

    // Clear old input
    tableController.clear();

    showDialog(
      context: context,

      builder: (ctx) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),

              // ==================================================
              // Title
              // ==================================================

              title: Text(
                _tr(
                  context,
                  'add_new_qr_point',
                ),

                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              // ==================================================
              // Content
              // ==================================================

              content: Column(
                mainAxisSize: MainAxisSize.min,

                children: [
                  // Table number
                  if (!isTakeaway)
                    TextField(
                      controller: tableController,

                      keyboardType: TextInputType.number,

                      autofocus: true,

                      decoration: InputDecoration(
                        labelText: _tr(
                          context,
                          'table_number',
                        ),

                        hintText: _tr(
                          context,
                          'table_number_hint',
                        ),

                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),

                        prefixIcon: const Icon(
                          Icons.table_bar,
                        ),
                      ),
                    ),

                  const SizedBox(height: 10),

                  // Takeaway
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,

                    title: Text(
                      _tr(
                        context,
                        'is_takeaway',
                      ),
                    ),

                    value: isTakeaway,

                    onChanged: (value) {
                      if (value == null) return;

                      setDialogState(() {
                        isTakeaway = value;
                      });
                    },
                  ),
                ],
              ),

              // ==================================================
              // Actions
              // ==================================================

              actions: [
                // Cancel
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                  },

                  child: Text(
                    _tr(
                      context,
                      'cancel',
                    ),
                  ),
                ),

                // Create
                ElevatedButton(
                  onPressed: () async {
                    final int? tableNumber = isTakeaway
                        ? 0
                        : int.tryParse(
                            tableController.text.trim(),
                          );

                    // Validate table number
                    if (tableNumber != null ||
                        isTakeaway) {
                      // Generate QR data
                      // restaurantId is included in the QR.
                      final qrData =
                          QRService.generateQRData(
                        tableNumber ?? 0,
                        restaurantId,
                      );

                      // Create model
                      final newTable = TableModel(
                        id: '',
                        tableNumber:
                            tableNumber ?? 0,
                        restaurantId:
                            restaurantId,
                        qrUrl: qrData,
                        createdAt:
                            DateTime.now(),
                      );

                      // Save inside restaurant subcollection
                      await FirebaseFirestore
                          .instance
                          .collection(
                            'restaurants',
                          )
                          .doc(restaurantId)
                          .collection(
                            'tables',
                          )
                          .add(
                            newTable.toMap(),
                          );

                      tableController.clear();

                      if (mounted) {
                        Navigator.pop(ctx);

                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          SnackBar(
                            content: Text(
                              _tr(
                                context,
                                'qr_point_created',
                              ),
                            ),
                            backgroundColor:
                                primaryGreen,
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            _tr(
                              context,
                              'please_enter_table_number',
                            ),
                          ),
                        ),
                      );
                    }
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                  ),

                  child: Text(
                    _tr(
                      context,
                      'create',
                    ),

                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // Main Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bool isMobile =
        MediaQuery.of(context).size.width < 900;

    final authProvider =
        Provider.of<AuthProvider>(context);

    final String? restaurantId =
        authProvider.restaurantId;

    return Scaffold(
      key: _scaffoldKey,

      backgroundColor:
          const Color(0xFFF8F9FA),

      // ========================================================
      // Mobile Drawer
      // ========================================================

      drawer: isMobile
          ? const Drawer(
              child: AdminSidebar(),
            )
          : null,

      // ========================================================
      // Body
      // ========================================================

      body: Row(
        children: [
          // Desktop Sidebar
          if (!isMobile)
            const AdminSidebar(),

          // Main Content
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
                    // Header
                    _buildHeader(
                      isMobile,
                      restaurantId ?? '',
                    ),

                    const SizedBox(height: 25),

                    // Tables
                    Expanded(
                      child: restaurantId == null ||
                              restaurantId.isEmpty
                          ? _buildNoRestaurantState(
                              context,
                            )
                          : StreamBuilder<
                              QuerySnapshot>(
                              stream:
                                  FirebaseFirestore
                                      .instance
                                      .collection(
                                        'restaurants',
                                      )
                                      .doc(
                                        restaurantId,
                                      )
                                      .collection(
                                        'tables',
                                      )
                                      .orderBy(
                                        'tableNumber',
                                      )
                                      .snapshots(),

                              builder:
                                  (
                                context,
                                snapshot,
                              ) {
                                // Loading
                                if (snapshot
                                        .connectionState ==
                                    ConnectionState
                                        .waiting) {
                                  return Center(
                                    child:
                                        CircularProgressIndicator(
                                      color:
                                          primaryGreen,
                                    ),
                                  );
                                }

                                // Firestore error
                                if (snapshot.hasError) {
                                  return Center(
                                    child: Text(
                                      "${_tr(context, 'error_prefix')}: "
                                      "${snapshot.error}",
                                    ),
                                  );
                                }

                                // Documents
                                final docs =
                                    snapshot.data
                                            ?.docs ??
                                        [];

                                final tables = docs
                                    .map(
                                      (doc) =>
                                          TableModel
                                              .fromSnapshot(
                                        doc,
                                      ),
                                    )
                                    .toList();

                                // Empty
                                if (tables.isEmpty) {
                                  return _buildEmptyState(
                                    context,
                                  );
                                }

                                // Grid
                                return GridView.builder(
                                  gridDelegate:
                                      const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 280,

                                    childAspectRatio:
                                        0.72,

                                    crossAxisSpacing: 20,

                                    mainAxisSpacing: 20,
                                  ),

                                  itemCount:
                                      tables.length,

                                  itemBuilder:
                                      (ctx, i) {
                                    return _buildTableCard(
                                      context,
                                      tables[i],
                                      restaurantId,
                                    );
                                  },
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

  // ============================================================
  // Header
  // ============================================================

  Widget _buildHeader(
    bool isMobile,
    String restaurantId,
  ) {
    return Row(
      children: [
        // Mobile menu
        if (isMobile)
          IconButton(
            icon: const Icon(
              Icons.menu_rounded,
              size: 28,
            ),

            onPressed: () {
              _scaffoldKey.currentState
                  ?.openDrawer();
            },
          ),

        if (isMobile)
          const SizedBox(width: 8),

        // Title
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Text(
                _tr(
                  context,
                  'tables_management',
                ),

                style: TextStyle(
                  fontSize:
                      isMobile ? 20 : 28,

                  fontWeight:
                      FontWeight.w900,
                ),
              ),

              if (!isMobile)
                Text(
                  _tr(
                    context,
                    'manage_table_qr_codes',
                  ),

                  style: TextStyle(
                    color:
                        Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ),

        // Add button
        ElevatedButton.icon(
          onPressed: () {
            _showAddDialog(
              restaurantId,
            );
          },

          icon: const Icon(
            Icons.add_rounded,
            size: 20,
            color: Colors.white,
          ),

          label: Text(
            isMobile
                ? _tr(context, 'add')
                : _tr(context, 'add_new'),

            style: const TextStyle(
              color: Colors.white,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          style: ElevatedButton.styleFrom(
            backgroundColor:
                primaryGreen,

            padding:
                EdgeInsets.symmetric(
              horizontal:
                  isMobile ? 12 : 20,
              vertical: 15,
            ),

            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(12),
            ),

            elevation: 0,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // Table Card
  // ============================================================

  Widget _buildTableCard(
    BuildContext context,
    TableModel table,
    String restaurantId,
  ) {
    final qrKey = GlobalKey();

    // IMPORTANT:
    // 0 is the internal value for Takeaway.
    final bool isTakeaway =
        table.tableNumber == 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.03),

            blurRadius: 10,

            offset:
                const Offset(0, 4),
          ),
        ],
      ),

      child: Stack(
        children: [
          Padding(
            padding:
                const EdgeInsets.all(15.0),

            child: Column(
              children: [
                // ==================================================
                // Table Name
                // ==================================================

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,

                  children: [
                    Icon(
                      isTakeaway
                          ? Icons
                              .shopping_bag_outlined
                          : Icons
                              .table_bar_outlined,

                      size: 18,

                      color:
                          primaryGreen,
                    ),

                    const SizedBox(width: 8),

                    Text(
                      isTakeaway
                          ? _tr(
                              context,
                              'takeaway',
                            )
                          : "${_tr(context, 'table')} "
                            "${table.tableNumber}",

                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,

                        fontSize: 16,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ==================================================
                // QR Code
                // ==================================================

                Expanded(
                  child: RepaintBoundary(
                    key: qrKey,

                    child: Container(
                      padding:
                          const EdgeInsets.all(8),

                      decoration:
                          BoxDecoration(
                        color:
                            Colors.white,

                        border:
                            Border.all(
                          color:
                              Colors.grey
                                  .shade100,
                        ),

                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                      ),

                      child: QrImageView(
                        data:
                            table.qrUrl,

                        version:
                            QrVersions.auto,

                        eyeStyle:
                            const QrEyeStyle(
                          eyeShape:
                              QrEyeShape.square,

                          color:
                              Colors.black,
                        ),

                        dataModuleStyle:
                            const QrDataModuleStyle(
                          dataModuleShape:
                              QrDataModuleShape
                                  .square,

                          color:
                              Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ==================================================
                // Download Button
                // ==================================================

                SizedBox(
                  width:
                      double.infinity,

                  child:
                      TextButton.icon(
                    onPressed: () {
                      _downloadQR(
                        qrKey,

                        'Table_${table.tableNumber == 0 ? "Takeaway" : table.tableNumber}.png',
                      );
                    },

                    icon:
                        const Icon(
                      Icons
                          .file_download_outlined,

                      size: 18,

                      color:
                          Colors.blue,
                    ),

                    label:
                        Text(
                      _tr(
                        context,
                        'download',
                      ),

                      style:
                          const TextStyle(
                        color:
                            Colors.blue,

                        fontWeight:
                            FontWeight.bold,

                        fontSize: 12,
                      ),
                    ),

                    style:
                        TextButton.styleFrom(
                      backgroundColor:
                          Colors.blue
                              .withOpacity(
                        0.05,
                      ),

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          8,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ========================================================
          // Delete Button
          // ========================================================

          Positioned(
            top: 5,
            right: 5,

            child: IconButton(
              icon: Icon(
                Icons.cancel_rounded,

                color:
                    Colors.red.withOpacity(
                  0.3,
                ),

                size: 20,
              ),

              onPressed: () {
                _deleteTable(
                  table.id,
                  table.tableNumber,
                  restaurantId,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // No Restaurant State
  // ============================================================

  Widget _buildNoRestaurantState(
    BuildContext context,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [
          Icon(
            Icons.restaurant_outlined,
            size: 70,
            color: Colors.grey[200],
          ),

          const SizedBox(height: 16),

          Text(
            _tr(
              context,
              'no_restaurant_selected',
            ),

            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Empty State
  // ============================================================

  Widget _buildEmptyState(
    BuildContext context,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [
          Icon(
            Icons.qr_code_2_rounded,
            size: 80,
            color: Colors.grey[200],
          ),

          const SizedBox(height: 16),

          Text(
            _tr(
              context,
              'no_tables_or_takeaway',
            ),

            textAlign:
                TextAlign.center,

            style:
                const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}