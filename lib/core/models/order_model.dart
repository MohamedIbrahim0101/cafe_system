// lib/core/models/order_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String productId;
  final String name;
  final int quantity;
  final double price; // unit price
  final String? notes;
  final String? size;

  OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    this.notes = "",
    this.size,
  });

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'quantity': quantity,
        'price': price,
        'notes': notes,
        'size': size,
      };

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
        productId: map['productId']?.toString() ?? '',
        name: map['name']?.toString() ?? 'Unknown',
        quantity: (map['quantity'] as num?)?.toInt() ?? 0,
        price: (map['price'] as num?)?.toDouble() ?? 0.0,
        notes: map['notes']?.toString() ?? '',
        size: map['size']?.toString(),
      );

  OrderItem copyWith({int? quantity, String? notes, String? size}) => OrderItem(
        productId: productId,
        name: name,
        quantity: quantity ?? this.quantity,
        price: price,
        notes: notes ?? this.notes,
        size: size ?? this.size,
      );
}

class Order {
  final String id;
  final int tableNumber; // إذا كان 0 فهذا يعني Takeaway
  final List<OrderItem> items;
  final double totalPrice;
  final String status; // Pending, Preparing, Done, Completed, Cancelled
  final DateTime createdAt;
  final String orderType;
  final int dailySequenceNumber; // حقل الترقيم التسلسلي الجديد

  Order({
    required this.id,
    required this.tableNumber,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    this.orderType = 'Dining',
    this.dailySequenceNumber = 0, // القيمة الافتراضية 0
  });

  // --- دالة copyWith المحدثة ---
  Order copyWith({
    String? id,
    int? tableNumber,
    List<OrderItem>? items,
    double? totalPrice,
    String? status,
    DateTime? createdAt,
    String? orderType,
    int? dailySequenceNumber,
  }) {
    return Order(
      id: id ?? this.id,
      tableNumber: tableNumber ?? this.tableNumber,
      items: items ?? this.items,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      orderType: orderType ?? this.orderType,
      dailySequenceNumber: dailySequenceNumber ?? this.dailySequenceNumber,
    );
  }

  factory Order.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('Order document data is null');
    }

    List<OrderItem> itemsList = [];
    if (data['items'] != null && data['items'] is List) {
      for (var item in data['items']) {
        if (item is Map<String, dynamic>) {
          itemsList.add(OrderItem.fromMap(item));
        }
      }
    }

    final tableNum = int.tryParse(data['tableNumber']?.toString() ?? '0') ?? 0;
    final type = data['orderType'] ?? (tableNum == 0 ? 'Takeaway' : 'Dining');

    return Order(
      id: snapshot.id,
      tableNumber: tableNum,
      items: itemsList,
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
      status: data['status']?.toString() ?? 'Pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      orderType: type,
      dailySequenceNumber:
          (data['dailySequenceNumber'] as num?)?.toInt() ?? 0, // قراءة الترقيم
    );
  }

  Map<String, dynamic> toMap() => {
        'tableNumber': tableNumber,
        'items': items.map((item) => item.toMap()).toList(),
        'totalPrice': totalPrice,
        'status': status,
        'orderType': orderType,
        'createdAt': FieldValue.serverTimestamp(),
        'dailySequenceNumber': dailySequenceNumber, // حفظ الترقيم
      };
}
