import 'package:flutter/material.dart';

import '../common/catalunya_card.dart';

class PaymentProductSummaryCard extends StatelessWidget {
  const PaymentProductSummaryCard({
    required this.courseTitle,
    required this.packageName,
    required this.price,
    super.key,
  });

  final String courseTitle;
  final String packageName;
  final String price;

  @override
  Widget build(BuildContext context) {
    if (courseTitle.isEmpty && packageName.isEmpty) {
      return const SizedBox.shrink();
    }

    final title = courseTitle.isNotEmpty ? courseTitle : packageName;
    final subtitle = price.isNotEmpty ? 'GiÃ¡: $price' : 'Sáº£n pháº©m thanh toÃ¡n';

    return CatalunyaCard(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE6F7FF),
          child: Icon(Icons.shopping_bag_outlined, color: Color(0xFF0284C7)),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

