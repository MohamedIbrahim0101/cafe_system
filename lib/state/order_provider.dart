import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order; 
import '../../core/services/firebase_service.dart';
import '../../core/models/order_model.dart';

class OrderProvider extends ChangeNotifier {
  List<Order> _orders = [];
  bool _isLoading = true;
  String? _activeOrderId; 
  StreamSubscription<List<Order>>? _ordersSubscription;

  // --- Getters ---
  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;

  Order? get currentOrder {
    if (_activeOrderId == null || _orders.isEmpty) return null;
    try {
      return _orders.firstWhere((o) => o.id == _activeOrderId);
    } catch (e) {
      return null;
    }
  }

  OrderProvider() {
    _initProvider();
  }

  // --- 🔥 الجزء الخاص بالـ POS (تم تعديل دالة الإضافة لحساب الترقيم) ---
  
  Future<void> addNewOrder(Order order) async {
    try {
      // 1. تحديد بداية اليوم الحالي لحساب الطلبات
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      // 2. جلب آخر طلب تم تسجيله اليوم لمعرفة الرقم التسلسلي الأخير
      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      int nextSequence = 1; 
      if (snapshot.docs.isNotEmpty) {
        final lastOrderData = snapshot.docs.first.data();
        final lastSequence = (lastOrderData['dailySequenceNumber'] as num?)?.toInt() ?? 0;
        nextSequence = lastSequence + 1;
      }

      // 3. إنشاء نسخة محدثة من الطلب بالرقم التسلسلي الجديد
      final Order orderWithSequence = order.copyWith(dailySequenceNumber: nextSequence);

      // 4. رفع الطلب إلى Firestore
      final docRef = await FirebaseFirestore.instance
          .collection('orders')
          .add(orderWithSequence.toMap());

      // 5. حفظ المعرف محلياً
      await saveOrderLocally(docRef.id);
      
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error adding POS order: $e");
      rethrow;
    }
  }

  // ------------------------------------------

  Future<void> _initProvider() async {
    await _loadActiveOrderId();
    _initOrdersStream();
  }

  Future<void> _loadActiveOrderId() async {
    _activeOrderId = await getActiveOrderId();
    notifyListeners();
  }

  void _initOrdersStream() {
    _isLoading = true;
    _ordersSubscription?.cancel();

    _ordersSubscription = FirebaseService.getOrdersStream().listen(
      (ordersData) {
        ordersData.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _orders = ordersData;
        _isLoading = false;
        _checkAndClearExpiredSession();
        notifyListeners();
      },
      onError: (error) {
        debugPrint("❌ Error in Orders Stream: $error");
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // --- إدارة الجلسة (Session Management) ---

  Future<void> saveOrderLocally(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_order_id', orderId);
    await prefs.setString('order_timestamp', DateTime.now().toIso8601String());
    
    _activeOrderId = orderId; 
    notifyListeners();
  }

  Future<String?> getActiveOrderId() async {
    final prefs = await SharedPreferences.getInstance();
    final String? orderId = prefs.getString('active_order_id');
    final String? timestampStr = prefs.getString('order_timestamp');

    if (orderId == null || timestampStr == null) return null;

    final orderTime = DateTime.parse(timestampStr);
    if (DateTime.now().difference(orderTime).inHours >= 6) {
      await clearLocalSession();
      return null;
    }

    return orderId;
  }

  Future<void> clearLocalSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_order_id');
    await prefs.remove('order_timestamp');
    
    _activeOrderId = null; 
    notifyListeners();
  }

  void _checkAndClearExpiredSession() async {
    if (_activeOrderId != null && _orders.isNotEmpty) {
      try {
        final currentOrderFromList = _orders.firstWhere((o) => o.id == _activeOrderId);
        final status = currentOrderFromList.status.toLowerCase();

        bool isFinished = status.contains('deliv') ||
                          status.contains('paid') ||
                          status.contains('complete') ||
                          status.contains('cancel');

        if (isFinished) {
          await clearLocalSession();
        }
      } catch (e) {
        await clearLocalSession();
      }
    }
  }

  // --- دوال المساعدة والإحصائيات ---

  Order? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  double get todayTotalSales {
    final today = DateTime.now();
    return _orders.where((o) {
      final isSameDay = o.createdAt.year == today.year &&
          o.createdAt.month == today.month &&
          o.createdAt.day == today.day;
          
      final s = o.status.toLowerCase();
      final isFinished = s.contains('deliv') ||
          s.contains('done') ||
          s.contains('served') ||
          s.contains('complete') ||
          s.contains('paid');
          
      return isSameDay && isFinished;
    }).fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }
}