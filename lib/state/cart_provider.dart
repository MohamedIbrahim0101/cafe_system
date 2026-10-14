// lib/state/cart_provider.dart

import 'package:flutter/material.dart';
import '../core/models/product_model.dart';

class CartItem {
  final String productId;
  final String name;
  final String imageUrl;
  final double price;
  final String? selectedSize;
  final String productType;

  int quantity;
  String notes;

  CartItem({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.selectedSize,
    this.quantity = 1,
    this.notes = "",
    this.productType = 'food',
  });

  String get cartItemId =>
      '${productId}_${selectedSize ?? "default"}';

  double get total => price * quantity;

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'imageUrl': imageUrl,
        'price': price,
        'selectedSize': selectedSize,
        'quantity': quantity,
        'notes': notes,
        'productType': productType,
        'total': total,
      };
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  int? _tableNumber;
  String? _restaurantId;

  List<CartItem> get items => _items;

  int get itemCount => _items.length;

  int get totalItems =>
      _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice =>
      _items.fold(0.0, (sum, item) => sum + item.total);

  String? get restaurantId => _restaurantId;

  int? get tableNumber => _tableNumber;

  void setRestaurantId(String? resId) {
    if (_restaurantId != resId) {
      _restaurantId = resId;
      _items.clear();
      notifyListeners();
    }
  }

  set tableNumber(int? table) {
    _tableNumber = table;
    notifyListeners();
  }

  void add(
    Product product, {
    String? targetRestaurantId,
    String? selectedSize,
    double? customPrice,
    String notes = "",
  }) {
    if (targetRestaurantId != null &&
        targetRestaurantId != _restaurantId) {
      _restaurantId = targetRestaurantId;
      _items.clear();
    }

    final double effectivePrice = customPrice ??
        (selectedSize != null &&
                product.sizes.containsKey(selectedSize)
            ? product.sizes[selectedSize]!
            : product.price);

    final String targetCartItemId =
        '${product.id}_${selectedSize ?? "default"}';

    final existingIndex = _items.indexWhere(
      (item) => item.cartItemId == targetCartItemId,
    );

    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;

      if (notes.isNotEmpty) {
        _items[existingIndex].notes = notes;
      }
    } else {
      _items.add(
        CartItem(
          productId: product.id,
          name: product.name,
          imageUrl: product.imageUrl,
          price: effectivePrice,
          selectedSize: selectedSize,
          notes: notes,
          productType: product.productType
              .toLowerCase()
              .trim(),
        ),
      );
    }

    notifyListeners();
  }

  void updateItemNote(String cartItemId, String newNote) {
    final index = _items.indexWhere(
      (item) => item.cartItemId == cartItemId,
    );

    if (index >= 0) {
      _items[index].notes = newNote;
      notifyListeners();
    }
  }

  void updateQuantity(String cartItemId, int qty) {
    final index = _items.indexWhere(
      (item) => item.cartItemId == cartItemId,
    );

    if (index >= 0) {
      if (qty <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = qty;
      }

      notifyListeners();
    }
  }

  void remove(String cartItemId) {
    _items.removeWhere(
      (item) => item.cartItemId == cartItemId,
    );

    notifyListeners();
  }

  void clear() {
    _items.clear();
    _tableNumber = null;
    notifyListeners();
  }
}
