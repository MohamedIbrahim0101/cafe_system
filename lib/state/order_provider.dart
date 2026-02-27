import 'dart:async'; // نحتاجه للتحكم في الـ StreamSubscription
import 'package:flutter/material.dart';
import '../../core/services/firebase_service.dart'; // تأكد من صحة المسار
import '../../core/models/order_model.dart';

class OrderProvider extends ChangeNotifier {
  List<Order> _orders = [];
  bool _isLoading = true;
  
  // لحفظ الاشتراك في الـ Stream وإغلاقه لاحقاً لمنع تسريب الذاكرة (Memory Leak)
  StreamSubscription<List<Order>>? _ordersSubscription;

  // Getters
  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;

  OrderProvider() {
    _initOrdersStream();
  }

  void _initOrdersStream() {
    _isLoading = true;
    
    // إلغاء أي اشتراك سابق لتجنب التكرار
    _ordersSubscription?.cancel();

    _ordersSubscription = FirebaseService.getOrdersStream().listen(
      (ordersData) {
        // ترتيب الطلبات بحيث يظهر الأحدث في الأعلى (اختياري)
        ordersData.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        _orders = ordersData;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint("❌ Error fetching orders: $error");
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // دالة لجلب الطلبات يدوياً في حال انقطع الـ Stream أو حدث خطأ
  void refreshOrders() {
    _initOrdersStream();
  }

  // البحث عن طلب معين
  Order? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  // إحصائيات المبيعات (Dashboard)
  double get todayTotalSales {
    final today = DateTime.now();
    return _orders
        .where((o) =>
            o.createdAt.year == today.year &&
            o.createdAt.month == today.month &&
            o.createdAt.day == today.day &&
            o.status == 'Done')
        .fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  // إحصائيات عدد الطلبات النشطة (Pending + Preparing)
  int get activeOrdersCount {
    return _orders.where((o) => o.status == 'Pending' || o.status == 'Preparing').length;
  }

  @override
  void dispose() {
    // إغلاق الاشتراك عند تدمير الـ Provider لتحرير الموارد
    _ordersSubscription?.cancel();
    super.dispose();
  }
}