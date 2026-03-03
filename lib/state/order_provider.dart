import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/firebase_service.dart';
import '../../core/models/order_model.dart';

class OrderProvider extends ChangeNotifier {
  List<Order> _orders = [];
  bool _isLoading = true;
  String? _activeOrderId; // لتخزين المعرف النشط في الذاكرة لسرعة الوصول
  StreamSubscription<List<Order>>? _ordersSubscription;

  // --- Getters ---
  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;

  /// 🔥 الـ Getter الذي تحتاجه شاشة المنيو لمعرفة إذا كان للعميل طلب مفتوح حالياً
  Order? get currentOrder {
    if (_activeOrderId == null || _orders.isEmpty) return null;
    try {
      // البحث عن الطلب النشط داخل قائمة الطلبات القادمة من السيرفر
      return _orders.firstWhere((o) => o.id == _activeOrderId);
    } catch (e) {
      // في حال لم يجد الطلب (ربما تم حذفه من Firebase)
      return null;
    }
  }

  OrderProvider() {
    _initProvider();
  }

  /// تهيئة المزود: تحميل المعرف المحلي وفتح اتصال مع Firebase
  Future<void> _initProvider() async {
    await _loadActiveOrderId();
    _initOrdersStream();
  }

  /// تحميل المعرف من التخزين المحلي عند بدء التطبيق
  Future<void> _loadActiveOrderId() async {
    _activeOrderId = await getActiveOrderId();
    notifyListeners();
  }

  /// فتح تدفق البيانات (Stream) لمراقبة الطلبات بشكل حي
  void _initOrdersStream() {
    _isLoading = true;
    _ordersSubscription?.cancel();

    _ordersSubscription = FirebaseService.getOrdersStream().listen(
      (ordersData) {
        // ترتيب الطلبات من الأحدث إلى الأقدم
        ordersData.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _orders = ordersData;
        _isLoading = false;

        // فحص الجلسة المحلية: هل انتهى الطلب في الواقع؟ إذاً نمسحه من الهاتف
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

  /// 1. حفظ معرف الطلب محلياً (عندما يطلب العميل لأول مرة)
  Future<void> saveOrderLocally(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_order_id', orderId);
    await prefs.setString('order_timestamp', DateTime.now().toIso8601String());
    
    _activeOrderId = orderId; 
    notifyListeners();
  }

  /// 2. الحصول على المعرف النشط (مع التحقق من صلاحية الوقت - 6 ساعات)
  Future<String?> getActiveOrderId() async {
    final prefs = await SharedPreferences.getInstance();
    final String? orderId = prefs.getString('active_order_id');
    final String? timestampStr = prefs.getString('order_timestamp');

    if (orderId == null || timestampStr == null) return null;

    final orderTime = DateTime.parse(timestampStr);
    // إذا مر أكثر من 6 ساعات على الطلب، نعتبر الجلسة منتهية
    if (DateTime.now().difference(orderTime).inHours >= 6) {
      await clearLocalSession();
      return null;
    }

    return orderId;
  }

  /// 3. مسح الجلسة (عند الخروج أو انتهاء الطلب)
  Future<void> clearLocalSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_order_id');
    await prefs.remove('order_timestamp');
    
    _activeOrderId = null; 
    notifyListeners();
  }

  /// 4. فحص حالة الطلب في قاعدة البيانات لمسح الجلسة تلقائياً إذا انتهى
  void _checkAndClearExpiredSession() async {
    if (_activeOrderId != null && _orders.isNotEmpty) {
      try {
        final currentOrderFromList = _orders.firstWhere((o) => o.id == _activeOrderId);
        final status = currentOrderFromList.status.toLowerCase();

        // الحالات التي تعني أن الزبون "أنهى" زيارته للمطعم
        bool isFinished = status.contains('deliv') ||
                          status.contains('paid') ||
                          status.contains('complete') ||
                          status.contains('cancel');

        if (isFinished) {
          await clearLocalSession();
        }
      } catch (e) {
        // الطلب ربما تم حذفه من Firebase، نمسح الجلسة المحلية أيضاً للتنظيف
        await clearLocalSession();
      }
    }
  }

  // --- دوال المساعدة والإحصائيات ---

  /// البحث عن طلب معين بواسطة المعرف
  Order? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  /// حساب إجمالي مبيعات اليوم (للطلبات المكتملة فقط)
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