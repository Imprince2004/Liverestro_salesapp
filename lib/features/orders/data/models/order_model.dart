class OrderItemModel {
  final String productId;
  final String title;
  final double price;
  final int quantity;

  const OrderItemModel({
    required this.productId,
    required this.title,
    required this.price,
    required this.quantity,
  });

  double get total => price * quantity;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productId: json['productId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'title': title,
      'price': price,
      'quantity': quantity,
    };
  }
}

class OrderModel {
  final String id;
  final String restaurantName;
  final List<OrderItemModel> items;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final String paymentTerms;
  final String status; // Placed, Confirmed, Delivered, Cancelled
  final String createdAt;
  final bool isSynced;

  const OrderModel({
    required this.id,
    required this.restaurantName,
    required this.items,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.paymentTerms,
    required this.status,
    required this.createdAt,
    required this.isSynced,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final parsedItems = rawItems.map((item) {
      return OrderItemModel.fromJson(item as Map<String, dynamic>);
    }).toList();

    return OrderModel(
      id: json['id'] as String? ?? '',
      restaurantName: json['restaurantName'] as String? ?? '',
      items: parsedItems,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentTerms: json['paymentTerms'] as String? ?? 'Net 30 Days',
      status: json['status'] as String? ?? 'Placed',
      createdAt: json['createdAt'] as String? ?? '',
      isSynced: json['isSynced'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurantName': restaurantName,
      'items': items.map((i) => i.toJson()).toList(),
      'subtotal': subtotal,
      'discountAmount': discountAmount,
      'taxAmount': taxAmount,
      'totalAmount': totalAmount,
      'paymentTerms': paymentTerms,
      'status': status,
      'createdAt': createdAt,
      'isSynced': isSynced,
    };
  }
}
