import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SupplierInvoice {
  final String id;
  final String supplierName;
  final String phoneNumber;
  final String productName;
  final double quantity;
  final double consumedQuantity; // الحقل الجديد لمتابعة النقص المستهلك
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

  factory SupplierInvoice.fromMap(Map<String, dynamic> map, String docId) {
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
  StreamSubscription<QuerySnapshot>? _invoicesSubscription;

  List<SupplierInvoice> get invoices => _invoices;
  bool get isLoading => _isLoading;

  double get totalPurchases {
    return _invoices.fold(0.0, (sum, item) => sum + item.totalCost);
  }

  InventoryProvider() {
    _initInvoicesStream();
  }

  void _initInvoicesStream() {
    _isLoading = true;
    _invoicesSubscription?.cancel();

    _invoicesSubscription = FirebaseFirestore.instance
        .collection('supplier_invoices')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        _invoices = snapshot.docs.map((doc) {
          return SupplierInvoice.fromMap(doc.data(), doc.id);
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

  Future<void> addNewInvoice({
    required String supplierName,
    required String phoneNumber,
    required String productName,
    required double quantity,
    required String unit,
    required double price,
  }) async {
    try {
      final newInvoice = SupplierInvoice(
        id: '', 
        supplierName: supplierName,
        phoneNumber: phoneNumber,
        productName: productName,
        quantity: quantity,
        consumedQuantity: 0.0, // يبدأ الاستهلاك من صفر عند الشراء الجديد
        unit: unit,
        price: price,
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('supplier_invoices')
          .add(newInvoice.toMap());
    } catch (e) {
      debugPrint("❌ Error adding supplier invoice: $e");
      rethrow;
    }
  }

  // 🔥 الدالة الحركية الجديدة لتحديث الكمية المنقوصة يدوياً في Firestore
  Future<void> reduceStockQuantity(String docId, double amountToReduce) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('supplier_invoices').doc(docId);
      
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) throw Exception("الفاتورة غير موجودة!");

        final currentConsumed = (snapshot.data()?['consumedQuantity'] as num?)?.toDouble() ?? 0.0;
        final totalQty = (snapshot.data()?['quantity'] as num?)?.toDouble() ?? 0.0;
        
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