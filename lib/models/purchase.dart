/// Represents a recorded marketplace purchase transaction
class Purchase {
  final String id;
  final String productId;
  final String userId;
  final DateTime purchaseDate;
  final int pricePaid;
  final String status;

  const Purchase({
    required this.id,
    required this.productId,
    required this.userId,
    required this.purchaseDate,
    required this.pricePaid,
    this.status = 'completed',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'userId': userId,
      'purchaseDate': purchaseDate.toIso8601String(),
      'pricePaid': pricePaid,
      'status': status,
    };
  }

  factory Purchase.fromMap(Map<String, dynamic> map) {
    return Purchase(
      id: map['id'] as String,
      productId: map['productId'] as String,
      userId: map['userId'] as String,
      purchaseDate: DateTime.tryParse(map['purchaseDate'] as String? ?? '') ??
          DateTime.now(),
      pricePaid: (map['pricePaid'] as num).toInt(),
      status: map['status'] as String? ?? 'completed',
    );
  }
}
