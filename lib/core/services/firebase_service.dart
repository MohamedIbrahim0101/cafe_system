// lib/core/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // نحتاجها لـ debugPrint
import '../models/restaurant_model.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/table_model.dart';
import '../models/order_model.dart';

class FirebaseService {
  // Firestore & Auth instances
  static final fs.FirebaseFirestore _firestore = fs.FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- Collections ---
  static fs.CollectionReference<Map<String, dynamic>> get restaurants =>
      _firestore.collection('restaurants');

  static fs.CollectionReference<Map<String, dynamic>> get categories =>
      _firestore.collection('categories');

  static fs.CollectionReference<Map<String, dynamic>> get products =>
      _firestore.collection('products');

  static fs.CollectionReference<Map<String, dynamic>> get tables =>
      _firestore.collection('tables');

  static fs.CollectionReference<Map<String, dynamic>> get orders =>
      _firestore.collection('orders');

  // --- Restaurant Methods ---
  static Future<Restaurant?> getRestaurant() async {
    try {
      final doc = await restaurants.doc('default').get();
      if (doc.exists) {
        return Restaurant.fromSnapshot(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching restaurant: $e');
      return null;
    }
  }

  // --- Orders Methods ---
  static Future<void> createOrder(Order order) async {
    await orders.doc(order.id).set(order.toMap());
  }

  static Future<void> updateOrderStatus(String orderId, String status) async {
    // التأكد من صلاحية المستخدم (الأدمن) قبل التحديث
    if (_auth.currentUser == null)
      throw Exception('Admin authentication required');
    await orders.doc(orderId).update({'status': status});
  }

  /// جلب الطلبات بشكل لحظي مع معالجة الأخطاء لكل مستند على حدة
  static Stream<List<Order>> getOrdersStream() {
    return orders
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return Order.fromSnapshot(doc);
            } catch (e) {
              // في حال فشل تحويل طلب واحد، لا يتوقف التطبيق بل يطبع الخطأ ويتجاهل الطلب التالف
              debugPrint("❌ Error parsing order ${doc.id}: $e");
              return null;
            }
          })
          .whereType<Order>() // استبعاد العناصر التي أرجعت null
          .toList();
    });
  }

  static Future<List<Order>> getOrders({String? status}) async {
    fs.Query<Map<String, dynamic>> query =
        orders.orderBy('createdAt', descending: true);
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Order.fromSnapshot(doc)).toList();
  }

  // --- Products Methods ---
  static Stream<List<Product>> getProductsStream() =>
      products.snapshots().map((snapshot) =>
          snapshot.docs.map((doc) => Product.fromSnapshot(doc)).toList());

  // --- Categories Methods ---
  static Stream<List<CategoryModel>> getCategoriesStream() =>
      categories.snapshots().map((snapshot) =>
          snapshot.docs.map((doc) => CategoryModel.fromSnapshot(doc)).toList());

  // --- Tables Methods ---
  static Stream<List<TableModel>> getTablesStream() =>
      tables.orderBy('tableNumber').snapshots().map((snapshot) =>
          snapshot.docs.map((doc) => TableModel.fromSnapshot(doc)).toList());

  // --- Utility ---
  static Future<void> init() async {
    // أي عمليات تهيئة إضافية عند تشغيل الخدمة
  }

  static FirebaseAuth get auth => _auth;
}
