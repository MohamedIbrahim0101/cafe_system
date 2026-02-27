// lib/state/cart_provider.dart
import 'package:flutter/material.dart';
import '../core/models/product_model.dart';

class CartItem {
  final String productId;
  final String name;
  final String imageUrl;
  final double price;
  int quantity;

  CartItem({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.quantity = 1,
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
    notifyListeners();
  }
}
