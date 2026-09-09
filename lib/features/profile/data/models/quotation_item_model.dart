class QuotationItemModel {
  final String id;
  final String name;
  final String category;
  final double unitPrice;
  final int quantity;

  const QuotationItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.unitPrice,
    this.quantity = 1,
  });

  double get totalPrice => unitPrice * quantity;

  QuotationItemModel copyWith({
    String? id,
    String? name,
    String? category,
    double? unitPrice,
    int? quantity,
  }) {
    return QuotationItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'unitPrice': unitPrice,
        'quantity': quantity,
        'totalPrice': totalPrice,
      };

  factory QuotationItemModel.fromJson(Map<String, dynamic> json) {
    return QuotationItemModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] ?? 1,
    );
  }
}
