// lib/core/models/order_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String productId;
  final String name;
  final int quantity;
  final double price; // unit price

  OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'quantity': quantity,
        'price': price,
      };

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
        productId: map['productId'] ?? '',
        name: map['name'] ?? '',
        quantity: map['quantity'] ?? 0,
        price: (map['price'] as num?)?.toDouble() ?? 0.0,
      );
}

class Order {
  final String id;
  final int tableNumber;
  final List<OrderItem> items;
  final double totalPrice;
  final String status; // Pending, Preparing, Done
  final DateTime createdAt;

  Order({
    required this.id,
    required this.tableNumber,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
  });

  factory Order.fromSnapshot(DocumentSnapshot snapshot) {
  final data = snapshot.data() as Map<String, dynamic>?;

  if (data == null) {
    throw Exception('Order document data is null');
  }

  final List<dynamic> itemsData = data['items'] ?? [];

  final itemsList = itemsData
      .map<OrderItem>(
          (item) => OrderItem.fromMap(item as Map<String, dynamic>))
      .toList();

  return Order(
    id: snapshot.id,
    tableNumber: data['tableNumber'] ?? 0,
    items: itemsList,
    totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
    status: data['status'] ?? 'Pending',

    // 🔥 الجزء المهم
    createdAt: (data['createdAt'] as Timestamp?)
            ?.toDate() ??
        DateTime.now(),
  );
}

  Map<String, dynamic> toMap() => {
        'tableNumber': tableNumber,
        'items': items.map((item) => item.toMap()).toList(),
        'totalPrice': totalPrice,
        'status': status,
        'createdAt': createdAt,
      };
}
