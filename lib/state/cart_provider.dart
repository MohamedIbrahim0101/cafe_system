// lib/state/cart_provider.dart
import 'package:flutter/material.dart';
import '../core/models/product_model.dart';

class CartItem {
  final String productId;
  final String name;
  final String imageUrl;
  final double price;
  int quantity;
  String notes; // 🔥 إضافة حقل الملحوظات

  CartItem({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.quantity = 1,
    this.notes = "", // قيمة افتراضية فارغة
  });

  double get total => price * quantity;
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  int? _tableNumber;

  List<CartItem> get items => _items;
  int get itemCount => _items.length;
  
  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);
  
  double get totalPrice => _items.fold(0.0, (sum, item) => sum + item.total);

  set tableNumber(int? table) {
    _tableNumber = table;
    notifyListeners();
  }

  int? get tableNumber => _tableNumber;

  // --- العمليات على السلة ---

  void add(Product product) {
    final existingIndex = _items.indexWhere((item) => item.productId == product.id);
    
    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(CartItem(
        productId: product.id,
        name: product.name,
        imageUrl: product.imageUrl,
        price: product.price,
      ));
    }
    notifyListeners();
  }

  // 🔥 الدالة السحرية لتحديث الملحوظات من الـ CartScreen
  void updateItemNote(String productId, String newNote) {
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      _items[index].notes = newNote;
      // لا نحتاج دائماً لـ notifyListeners هنا إذا كان الـ TextField 
      // يتم التحكم به محلياً، لكن يفضل وضعها لضمان تحديث الـ UI
      notifyListeners(); 
    }
  }

  void updateQuantity(String productId, int qty) {
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      if (qty <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = qty;
      }
      notifyListeners();
    }
  }

  void remove(String productId) {
    _items.removeWhere((item) => item.productId == productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _tableNumber = null; // اختياري: تصغير رقم الطاولة عند مسح السلة
    notifyListeners();
  }
}