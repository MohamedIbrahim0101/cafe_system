// lib/core/models/order_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String productId;
  final String name;
  final int quantity;
  final double price; // unit price
  final String? notes; // 🔥 إضافة حقل الملحوظات ليتناسب مع السلة والـ Admin

  OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    this.notes = "", // قيمة افتراضية فارغة
  });

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'quantity': quantity,
        'price': price,
        'notes': notes, // 🔥 حفظ الملحوظات في Firebase
      };

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
        productId: map['productId']?.toString() ?? '',
        name: map['name']?.toString() ?? 'Unknown',
        quantity: (map['quantity'] as num?)?.toInt() ?? 0,
        price: (map['price'] as num?)?.toDouble() ?? 0.0,
        notes: map['notes']?.toString() ?? '', // 🔥 قراءة الملحوظات من Firebase
      );

  // دالة لتسهيل زيادة الكمية في حال تكرار نفس الصنف مع الحفاظ على الملحوظات
  OrderItem copyWith({int? quantity, String? notes}) => OrderItem(
        productId: productId,
        name: name,
        quantity: quantity ?? this.quantity,
        price: price,
        notes: notes ?? this.notes,
      );
}

class Order {
  final String id;
  final int tableNumber;
  final List<OrderItem> items;
  final double totalPrice;
  final String status; // Pending, Preparing, Done, Completed, Cancelled
  final DateTime createdAt;

  Order({
    required this.id,
    required this.tableNumber,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
  });

  // --- دالة copyWith ---
  // مهمة جداً لتحديث حالة الطلب أو إضافة أصناف
  Order copyWith({
    String? id,
    int? tableNumber,
    List<OrderItem>? items,
    double? totalPrice,
    String? status,
    DateTime? createdAt,
  }) {
    return Order(
      id: id ?? this.id,
      tableNumber: tableNumber ?? this.tableNumber,
      items: items ?? this.items,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
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
        } else {
          print("⚠️ Warning: Invalid item format in order ${snapshot.id}");
        }
      }
    }

    return Order(
      id: snapshot.id,
      tableNumber: int.tryParse(data['tableNumber']?.toString() ?? '0') ?? 0,
      items: itemsList,
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
      status: data['status']?.toString() ?? 'Pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'tableNumber': tableNumber,
        'items': items.map((item) => item.toMap()).toList(),
        'totalPrice': totalPrice,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
      };
}