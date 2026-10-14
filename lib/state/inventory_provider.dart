// lib/state/inventory_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SupplierInvoice {
  final String id;
  final String supplierName;
  final String phoneNumber;
  final String productName;
  final double quantity;
  final double consumedQuantity; // الحقل لمتابعة النقص المستهلك
  final String unit; 
  final double price;
  final DateTime createdAt;

  SupplierInvoice({
    required this.id,
    required this.supplierName,
    required this.phoneNumber,
    required this.productName,
    required this.quantity,
    required this.consumedQuantity,
    required this.unit,
    required this.price,
    required this.createdAt,
  });

  // حساب الكمية المتبقية في المخزن حالياً
  double get remainingQuantity => quantity - consumedQuantity;

  // تنبيه إذا اقترب المخزون من الصفر (أقل من أو يساوي 5 وحدات)
  bool get isRunningOut => remainingQuantity <= 5 && remainingQuantity > 0;
  
  // تنبيه إذا نفد تماماً
  bool get isOutOffStock => remainingQuantity <= 0;

  double get totalCost => quantity * price;

  factory SupplierInvoice.fromMap(Map<String, dynamic> rawMap, String docId) {
    // 🔥 تحويل آمن لمنع خطأ Web Type Casting
    final map = Map<String, dynamic>.from(rawMap);

    return SupplierInvoice(
      id: docId,
      supplierName: map['supplierName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      productName: map['productName'] ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      consumedQuantity: (map['consumedQuantity'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? 'kg', 
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'supplierName': supplierName,
      'phoneNumber': phoneNumber,
      'productName': productName,
      'quantity': quantity,
      'consumedQuantity': consumedQuantity,
      'unit': unit,
      'price': price,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class InventoryProvider extends ChangeNotifier {
  List<SupplierInvoice> _invoices = [];
  bool _isLoading = true;
  String? _restaurantId;
  StreamSubscription<QuerySnapshot>? _invoicesSubscription;

  List<SupplierInvoice> get invoices => _invoices;
  bool get isLoading => _isLoading;
  String? get restaurantId => _restaurantId;

  double get totalPurchases {
    return _invoices.fold(0.0, (sum, item) => sum + item.totalCost);
  }

  InventoryProvider();

  // 🔥 دالة تحديث معرف المطعم المربوطة مع AuthProvider عبر ProxyProvider
  void updateRestaurantId(String? restaurantId) {
    if (_restaurantId != restaurantId) {
      _restaurantId = restaurantId;
      _initInvoicesStream(); // إعادة جلب فواتير المخزون للمطعم الجديد
    }
  }

  void _initInvoicesStream() {
    _invoicesSubscription?.cancel();

    if (_restaurantId == null || _restaurantId!.isEmpty) {
      _invoices = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    // الاستماع لفواتير مطعم محدد فقط لمنع التداخل
    _invoicesSubscription = FirebaseFirestore.instance
        .collection('restaurants')
        .doc(_restaurantId)
        .collection('supplier_invoices')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        _invoices = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          return SupplierInvoice.fromMap(data, doc.id);
        }).toList();
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint("❌ Error in Invoices Stream: $error");
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // 🔥 إضافة فاتورة جديدة
  Future<void> addNewInvoice({
    required String supplierName,
    required String phoneNumber,
    required String productName,
    required double quantity,
    required String unit,
    required double price,
  }) async {
    if (_restaurantId == null || _restaurantId!.isEmpty) {
      throw Exception("لا يوجد مطعم محدد لإضافة الفاتورة إليه!");
    }

    try {
      final newInvoice = SupplierInvoice(
        id: '', 
        supplierName: supplierName,
        phoneNumber: phoneNumber,
        productName: productName,
        quantity: quantity,
        consumedQuantity: 0.0,
        unit: unit,
        price: price,
        createdAt: DateTime.now(),
      );

      final map = newInvoice.toMap();
      map['createdAt'] = FieldValue.serverTimestamp();

      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(_restaurantId)
          .collection('supplier_invoices')
          .add(map);
    } catch (e) {
      debugPrint("❌ Error adding supplier invoice: $e");
      rethrow;
    }
  }

  // 🔥 تعديل فاتورة توريد موجودة
  Future<void> updateInvoice(SupplierInvoice invoice) async {
    if (_restaurantId == null || _restaurantId!.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(_restaurantId)
          .collection('supplier_invoices')
          .doc(invoice.id)
          .update(invoice.toMap());
    } catch (e) {
      debugPrint("❌ Error updating invoice: $e");
      rethrow;
    }
  }

  // 🔥 حذف فاتورة توريد
  Future<void> deleteInvoice(String docId) async {
    if (_restaurantId == null || _restaurantId!.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(_restaurantId)
          .collection('supplier_invoices')
          .doc(docId)
          .delete();
    } catch (e) {
      debugPrint("❌ Error deleting invoice: $e");
      rethrow;
    }
  }

  // 🔥 تحديث الكمية المنقوصة يدوياً داخل Firestore للمطعم المحدد
  Future<void> reduceStockQuantity(String docId, double amountToReduce) async {
    if (_restaurantId == null || _restaurantId!.isEmpty) {
      throw Exception("لا يوجد مطعم محدد الخصم من مخزونه!");
    }

    try {
      final docRef = FirebaseFirestore.instance
          .collection('restaurants')
          .doc(_restaurantId)
          .collection('supplier_invoices')
          .doc(docId);
      
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) throw Exception("الفاتورة غير موجودة!");

        final rawData = snapshot.data();
        final map = rawData != null ? Map<String, dynamic>.from(rawData) : {};

        final currentConsumed = (map['consumedQuantity'] as num?)?.toDouble() ?? 0.0;
        final totalQty = (map['quantity'] as num?)?.toDouble() ?? 0.0;
        
        final newConsumed = currentConsumed + amountToReduce;

        if (newConsumed > totalQty) {
          throw Exception("الكمية المراد خصمها أكبر من المتاح بالمخزن!");
        }

        transaction.update(docRef, {'consumedQuantity': newConsumed});
      });
    } catch (e) {
      debugPrint("❌ Error reducing stock: $e");
      rethrow;
    }
  }

  @override
  void dispose() {
    _invoicesSubscription?.cancel();
    super.dispose();
  }
}