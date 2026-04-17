class PaymentLinkModel {
  const PaymentLinkModel({required this.paymentId, required this.checkoutUrl});

  final String paymentId;
  final String checkoutUrl;
}

class PaymentHistoryItemModel {
  const PaymentHistoryItemModel({
    required this.paymentId,
    required this.productId,
    required this.orderCode,
    required this.amount,
    required this.status,
    required this.productType,
    required this.createdAt,
  });

  final String paymentId;
  final String productId;
  final String orderCode;
  final String amount;
  final String status;
  final String productType;
  final String createdAt;

  factory PaymentHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryItemModel(
      paymentId: (json['paymentId'] ?? json['PaymentId'] ?? '').toString(),
      productId: (json['productId'] ?? json['ProductId'] ?? '').toString(),
      orderCode: (json['orderCode'] ?? json['OrderCode'] ?? '').toString(),
      amount: (json['amount'] ?? json['Amount'] ?? '').toString(),
      status: (json['status'] ?? json['Status'] ?? '').toString(),
      productType: (json['productType'] ?? json['ProductType'] ?? '')
          .toString(),
      createdAt: (json['createdAt'] ?? json['CreatedAt'] ?? '').toString(),
    );
  }
}
