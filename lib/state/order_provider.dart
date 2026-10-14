import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/order_model.dart';

class OrderProvider extends ChangeNotifier {
  List<Order> _orders = [];

  bool _isLoading = true;

  String? _activeOrderId;
  String? _restaurantId;
  String? _clientSessionId;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ordersSubscription;

  static const String _activeOrderKey = 'active_order_id';
  static const String _orderTimestampKey = 'order_timestamp';
  static const String _clientSessionKey = 'client_session_id';
  static const String _sessionRestaurantKey = 'active_order_restaurant_id';

  // =========================================================
  // Getters
  // =========================================================

  List<Order> get orders => List.unmodifiable(_orders);

  bool get isLoading => _isLoading;

  String? get restaurantId => _restaurantId;

  String? get clientSessionId => _clientSessionId;

  /// الطلب النشط الخاص بجلسة العميل الحالية فقط.
  ///
  /// الأدمن يظل بإمكانه استخدام orders لعرض جميع طلبات المطعم.
  Order? get currentOrder {
    final activeId = _activeOrderId;
    final sessionId = _clientSessionId;

    if (activeId == null || sessionId == null) {
      return null;
    }

    try {
      return _orders.firstWhere((order) {
        return order.id == activeId && _getClientSessionId(order) == sessionId;
      });
    } catch (_) {
      return null;
    }
  }

  // =========================================================
  // Constructor
  // =========================================================

  OrderProvider() {
    _initializeClientSession();
  }

  // =========================================================
  // Client Session
  // =========================================================

  Future<void> _initializeClientSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      String? sessionId = prefs.getString(_clientSessionKey);

      if (sessionId == null || sessionId.trim().isEmpty) {
        sessionId = 'client_${DateTime.now().microsecondsSinceEpoch}';

        await prefs.setString(_clientSessionKey, sessionId);
      }

      _clientSessionId = sessionId;

      // استرجاع الطلب النشط بعد تهيئة الجلسة.
      await _loadActiveOrderId();

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error initializing client session: $e');
    }
  }

  /// استخدم هذه الدالة عند الحاجة لبدء جلسة عميل جديدة صراحةً.
  ///
  /// لا تستدعها مع كل فتح للمنيو، وإلا لن يتمكن العميل من
  /// متابعة طلبه السابق.
  Future<void> startNewClientSession() async {
    final prefs = await SharedPreferences.getInstance();

    final newSessionId = 'client_${DateTime.now().microsecondsSinceEpoch}';

    await prefs.setString(_clientSessionKey, newSessionId);

    await prefs.remove(_activeOrderKey);
    await prefs.remove(_orderTimestampKey);
    await prefs.remove(_sessionRestaurantKey);

    _clientSessionId = newSessionId;
    _activeOrderId = null;

    notifyListeners();
  }

  String? _getClientSessionId(Order order) {
    // يتطلب إضافة clientSessionId إلى Order model.
    return order.clientSessionId;
  }

  // =========================================================
  // Restaurant ID
  // =========================================================

  void updateRestaurantId(String? restaurantId) {
    if (_restaurantId == restaurantId) {
      return;
    }

    _restaurantId = restaurantId;

    debugPrint(
      '🏪 OrderProvider restaurantId updated: $_restaurantId',
    );

    _initOrdersStream();
    _restoreOrderForCurrentRestaurant();
  }

  Future<void> _restoreOrderForCurrentRestaurant() async {
    final prefs = await SharedPreferences.getInstance();

    final savedRestaurantId = prefs.getString(_sessionRestaurantKey);

    if (savedRestaurantId != _restaurantId) {
      _activeOrderId = null;
      notifyListeners();
      return;
    }

    _activeOrderId = prefs.getString(_activeOrderKey);

    notifyListeners();
  }

  // =========================================================
  // Add New Order
  // =========================================================

  Future<String> addNewOrder(Order order) async {
    final restaurantId = _restaurantId;
    final sessionId = _clientSessionId;

    if (restaurantId == null || restaurantId.isEmpty) {
      throw Exception('لا يوجد مطعم محدد لإضافة الطلب إليه!');
    }

    if (sessionId == null || sessionId.isEmpty) {
      throw Exception('لم يتم تهيئة جلسة العميل بعد، حاول مرة أخرى.');
    }

    try {
      final ordersRef = FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .collection('orders');

      // حساب رقم الطلب اليومي.
      final now = DateTime.now();

      final startOfDay = DateTime(
        now.year,
        now.month,
        now.day,
      );

      final snapshot = await ordersRef
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      var nextSequence = 1;

      if (snapshot.docs.isNotEmpty) {
        final lastOrderData = snapshot.docs.first.data();

        final lastSequence =
            (lastOrderData['dailySequenceNumber'] as num?)?.toInt() ?? 0;

        nextSequence = lastSequence + 1;
      }

      // ربط الطلب بجلسة العميل الحالية.
      final orderWithSession = order.copyWith(
        dailySequenceNumber: nextSequence,
        clientSessionId: sessionId,
      );

      final orderMap = orderWithSession.toMap();

      orderMap['createdAt'] = FieldValue.serverTimestamp();
      orderMap['clientSessionId'] = sessionId;

      final docRef = await ordersRef.add(orderMap);
      final firestoreOrderId = docRef.id;

      debugPrint('✅ Order added successfully');
      debugPrint('🏪 Restaurant ID: $restaurantId');
      debugPrint('🧾 Order ID: $firestoreOrderId');
      debugPrint('👤 Client session: $sessionId');
      debugPrint('🔢 Daily sequence: $nextSequence');

      await saveOrderLocally(
        firestoreOrderId,
        restaurantId: restaurantId,
      );

      // إضافة الطلب محليًا حتى يصل تحديث Firestore.
      final localOrder = orderWithSession.copyWith(
        id: firestoreOrderId,
      );

      _orders.removeWhere((item) => item.id == firestoreOrderId);
      _orders.insert(0, localOrder);

      _isLoading = false;
      notifyListeners();

      return firestoreOrderId;
    } catch (e) {
      debugPrint('❌ Error adding order: $e');
      rethrow;
    }
  }

  // =========================================================
  // Update Order Status
  // =========================================================

  Future<void> updateOrderStatus(
    String orderId,
    String newStatus,
  ) async {
    final restaurantId = _restaurantId;

    if (restaurantId == null || restaurantId.isEmpty) {
      debugPrint('⚠️ Cannot update order status: restaurantId is empty');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .collection('orders')
          .doc(orderId)
          .update({'status': newStatus});

      debugPrint('✅ Order status updated');
      debugPrint('🧾 Order ID: $orderId');
      debugPrint('📌 New Status: $newStatus');

      final index = _orders.indexWhere((order) => order.id == orderId);

      if (index != -1) {
        _orders[index] = _orders[index].copyWith(status: newStatus);
        notifyListeners();
      }

      await _checkAndClearFinishedSession();
    } catch (e) {
      debugPrint('❌ Error updating order status: $e');
      rethrow;
    }
  }

  // =========================================================
  // Initialize Orders Stream
  // =========================================================

  void _initOrdersStream() {
    _ordersSubscription?.cancel();

    if (_restaurantId == null || _restaurantId!.isEmpty) {
      _orders = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    debugPrint('🔄 Starting orders stream...');
    debugPrint('🏪 Restaurant: $_restaurantId');

    _ordersSubscription = FirebaseFirestore.instance
        .collection('restaurants')
        .doc(_restaurantId)
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        try {
          _orders = snapshot.docs.map((doc) {
            return Order.fromSnapshot(doc);
          }).toList();

          _isLoading = false;

          debugPrint('📦 Orders loaded: ${_orders.length}');

          _checkAndClearFinishedSession();
          notifyListeners();
        } catch (e) {
          debugPrint('❌ Error parsing orders: $e');
          _isLoading = false;
          notifyListeners();
        }
      },
      onError: (error) {
        debugPrint('❌ Error in Orders Stream: $error');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // =========================================================
  // Load Active Order ID
  // =========================================================

  Future<void> _loadActiveOrderId() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final orderId = await getActiveOrderId();
      final savedRestaurantId = prefs.getString(_sessionRestaurantKey);

      if (savedRestaurantId != _restaurantId) {
        _activeOrderId = null;
      } else {
        _activeOrderId = orderId;
      }

      debugPrint('💾 Active Order ID: $_activeOrderId');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading active order ID: $e');
    }
  }

  // =========================================================
  // Save Order Locally
  // =========================================================

  Future<void> saveOrderLocally(
    String orderId, {
    String? restaurantId,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_activeOrderKey, orderId);
    await prefs.setString(
      _orderTimestampKey,
      DateTime.now().toIso8601String(),
    );

    final effectiveRestaurantId = restaurantId ?? _restaurantId;

    if (effectiveRestaurantId != null) {
      await prefs.setString(
        _sessionRestaurantKey,
        effectiveRestaurantId,
      );
    }

    _activeOrderId = orderId;

    debugPrint('💾 Saved active order ID: $orderId');
    notifyListeners();
  }

  // =========================================================
  // Get Active Order ID
  // =========================================================

  Future<String?> getActiveOrderId() async {
    final prefs = await SharedPreferences.getInstance();

    final orderId = prefs.getString(_activeOrderKey);
    final timestampStr = prefs.getString(_orderTimestampKey);

    if (orderId == null || timestampStr == null) {
      return null;
    }

    try {
      final orderTime = DateTime.parse(timestampStr);
      final difference = DateTime.now().difference(orderTime);

      if (difference.isNegative || difference.inHours >= 6) {
        await clearLocalSession();
        return null;
      }

      return orderId;
    } catch (e) {
      debugPrint('❌ Error reading active order: $e');
      await clearLocalSession();
      return null;
    }
  }

  // =========================================================
  // Clear Local Session
  // =========================================================

  Future<void> clearLocalSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_activeOrderKey);
    await prefs.remove(_orderTimestampKey);
    await prefs.remove(_sessionRestaurantKey);

    _activeOrderId = null;

    debugPrint('🗑️ Active order session cleared');
    notifyListeners();
  }

  // =========================================================
  // Check Finished Order
  // =========================================================

  Future<void> _checkAndClearFinishedSession() async {
    final activeId = _activeOrderId;
    final sessionId = _clientSessionId;

    if (activeId == null || sessionId == null) {
      return;
    }

    Order? activeOrder;

    try {
      activeOrder = _orders.firstWhere((order) {
        return order.id == activeId && _getClientSessionId(order) == sessionId;
      });
    } catch (_) {
      // قد لا يكون الطلب وصل من Firestore بعد.
      return;
    }

    final status = activeOrder.status.toLowerCase().trim();

    final isFinished = status.contains('deliv') ||
        status.contains('paid') ||
        status.contains('complete') ||
        status.contains('done') ||
        status.contains('served') ||
        status.contains('cancel');

    if (isFinished) {
      debugPrint('✅ Active order finished: $status');
      await clearLocalSession();
    }
  }

  // =========================================================
  // Get Order By ID
  // =========================================================

  Order? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((order) => order.id == orderId);
    } catch (_) {
      return null;
    }
  }

  // =========================================================
  // Today's Total Sales
  // =========================================================

  double get todayTotalSales {
    final today = DateTime.now();

    return _orders.where((order) {
      final isSameDay = order.createdAt.year == today.year &&
          order.createdAt.month == today.month &&
          order.createdAt.day == today.day;

      final status = order.status.toLowerCase();

      final isFinished = status.contains('deliv') ||
          status.contains('done') ||
          status.contains('served') ||
          status.contains('complete') ||
          status.contains('paid');

      return isSameDay && isFinished;
    }).fold(
      0.0,
      (sum, order) => sum + order.totalPrice,
    );
  }

  // =========================================================
  // Dispose
  // =========================================================

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }
}
