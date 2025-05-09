import 'package:flutter/material.dart';

class OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback? onEdit; // استدعاء عند الضغط على زر التعديل
  final VoidCallback? onDelete; // استدعاء عند الضغط على زر الحذف

  const OrderCard({
    Key? key,
    required this.order,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // التنقل إلى صفحة تفاصيل الطلب عند الضغط على الويدجت
        Navigator.pushNamed(
          context,
          '/order_details',
          arguments: order,
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(
            vertical: 4, horizontal: 8), // تقليل الحواف
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              vertical: 8, horizontal: 12), // تقليل الحشو
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // الجهة اليسرى: اسم الطلب والحالة
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order['order_name'] ?? 'اسم غير متوفر',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'الحالة: ${order['status'] ?? 'غير معروف'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              // الجهة اليمنى: رقم الطلب ورقم الكود
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'رقم الطلب: ${order['order_code'] ?? 'غير متوفر'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'رقم الكود: ${order['tracking_code'] ?? 'غير متوفر'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
