/// An item owned by a user in their StepQuest inventory
class InventoryItem {
  final String id;
  final String productId;
  final String userId;
  final DateTime purchaseDate;
  final bool isEquipped;
  final int quantity;

  const InventoryItem({
    required this.id,
    required this.productId,
    required this.userId,
    required this.purchaseDate,
    this.isEquipped = false,
    this.quantity = 1,
  });

  InventoryItem copyWith({
    String? id,
    String? productId,
    String? userId,
    DateTime? purchaseDate,
    bool? isEquipped,
    int? quantity,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      userId: userId ?? this.userId,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      isEquipped: isEquipped ?? this.isEquipped,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'userId': userId,
      'purchaseDate': purchaseDate.toIso8601String(),
      'isEquipped': isEquipped,
      'quantity': quantity,
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'] as String,
      productId: map['productId'] as String,
      userId: map['userId'] as String,
      purchaseDate: DateTime.tryParse(map['purchaseDate'] as String? ?? '') ??
          DateTime.now(),
      isEquipped: map['isEquipped'] as bool? ?? false,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}
