// lib/core/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/restaurant_model.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/table_model.dart';
import '../models/order_model.dart';
import '../../app/constants.dart';

class FirebaseService {
  // Firestore & Auth instances
  static final fs.FirebaseFirestore _firestore = fs.FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
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

  // Get default restaurant
  static Future<Restaurant?> getRestaurant() async {
    try {
      final doc = await restaurants.doc('default').get();
      if (doc.exists) {
        return Restaurant.fromSnapshot(doc);
      }
      return null;
    } catch (e) {
      print('Error fetching restaurant: $e');
      return null;
    }
  }

  // Orders
  static Future<void> createOrder(Order order) async {
    await orders.doc(order.id).set(order.toMap());
  }

  static Future<void> updateOrderStatus(String orderId, String status) async {
    if (_auth.currentUser == null) throw Exception('Admin required');
    await orders.doc(orderId).update({'status': status});
  }

  static Stream<List<Order>> getOrdersStream() {
    return orders.orderBy('createdAt', descending: true).snapshots().map(
        (snapshot) =>
            snapshot.docs.map((doc) => Order.fromSnapshot(doc)).toList());
  }

  static Future<List<Order>> getOrders({String? status}) async {
    fs.Query<Map<String, dynamic>> query =
        orders.orderBy('createdAt', descending: true);
    if (status != null) query = query.where('status', isEqualTo: status);
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Order.fromSnapshot(doc)).toList();
  }

  // Products
  static Stream<List<Product>> getProductsStream() =>
      products.snapshots().map((snapshot) =>
          snapshot.docs.map((doc) => Product.fromSnapshot(doc)).toList());

  // Categories
  static Stream<List<CategoryModel>> getCategoriesStream() =>
      categories.snapshots().map((snapshot) =>
          snapshot.docs.map((doc) => CategoryModel.fromSnapshot(doc)).toList());

  // Tables
  static Stream<List<TableModel>> getTablesStream() =>
      tables.orderBy('tableNumber').snapshots().map((snapshot) =>
          snapshot.docs.map((doc) => TableModel.fromSnapshot(doc)).toList());

  // Optional initialization
  static Future<void> init() async {
    // Add any initialization code here if needed
  }

  // Access Auth outside
  static FirebaseAuth get auth => _auth;
}
