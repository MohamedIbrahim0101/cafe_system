
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String productId;
  final String name;
  final int quantity;
  final double price;
  final String? notes;
  final String? size;

  // food = طعام
  // drink = مشروب
  final String productType;

  OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    this.notes = '',
    this.size,
    this.productType = 'food',
  });

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'quantity': quantity,
        'price': price,
        'notes': notes,
        'size': size,
        'productType': productType,
      };

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unknown',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes']?.toString() ?? '',
      size: map['size']?.toString(),
      // الطلبات القديمة التي لا تحتوي على productType تعتبر طعامًا.
      productType: map['productType']?.toString() ?? 'food',
    );
  }

  OrderItem copyWith({
    int? quantity,
    String? notes,
    String? size,
    String? productType,
  }) {
    return OrderItem(
      productId: productId,
      name: name,
      quantity: quantity ?? this.quantity,
      price: price,
      notes: notes ?? this.notes,
      size: size ?? this.size,
      productType: productType ?? this.productType,
    );
  }
}

class Order {
  final String id;

  /// رقم الطاولة، والقيمة 0 تعني Takeaway.
  final int tableNumber;

  final List<OrderItem> items;
  final double totalPrice;

  /// Pending, Preparing, Done, Completed, Cancelled
  final String status;

  final DateTime createdAt;
  final String orderType;
  final int dailySequenceNumber;

  /// معرّف جلسة العميل الذي أنشأ الطلب.
  ///
  /// الطلبات القديمة قد لا تحتوي على هذا الحقل، لذلك هو اختياري.
  final String? clientSessionId;

  Order({
    required this.id,
    required this.tableNumber,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    this.orderType = 'Dining',
    this.dailySequenceNumber = 0,
    this.clientSessionId,
  });

  // =========================================================
  // Copy With
  // =========================================================

  Order copyWith({
    String? id,
    int? tableNumber,
    List<OrderItem>? items,
    double? totalPrice,
    String? status,
    DateTime? createdAt,
    String? orderType,
    int? dailySequenceNumber,
    String? clientSessionId,
  }) {
    return Order(
      id: id ?? this.id,
      tableNumber: tableNumber ?? this.tableNumber,
      items: items ?? this.items,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      orderType: orderType ?? this.orderType,
      dailySequenceNumber:
          dailySequenceNumber ?? this.dailySequenceNumber,
      clientSessionId: clientSessionId ?? this.clientSessionId,
    );
  }

  // =========================================================
  // From Firestore
  // =========================================================

  factory Order.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('Order document data is null');
    }

    final List<OrderItem> itemsList = [];

    final rawItems = data['items'];

    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          itemsList.add(
            OrderItem.fromMap(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final tableNum = int.tryParse(
          data['tableNumber']?.toString() ?? '0',
        ) ??
        0;

    final orderType =
        data['orderType']?.toString() ??
        (tableNum == 0 ? 'Takeaway' : 'Dining');

    return Order(
      id: snapshot.id,
      tableNumber: tableNum,
      items: itemsList,
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
      status: data['status']?.toString() ?? 'Pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      orderType: orderType,
      dailySequenceNumber:
          (data['dailySequenceNumber'] as num?)?.toInt() ?? 0,
      clientSessionId: data['clientSessionId']?.toString(),
    );
  }

  // =========================================================
  // To Firestore
  // =========================================================

  Map<String, dynamic> toMap() => {
        'tableNumber': tableNumber,
        'items': items.map((item) => item.toMap()).toList(),
        'totalPrice': totalPrice,
        'status': status,
        'orderType': orderType,
        'createdAt': FieldValue.serverTimestamp(),
        'dailySequenceNumber': dailySequenceNumber,
        'clientSessionId': clientSessionId,
      };
}
