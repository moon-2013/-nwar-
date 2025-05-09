import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart';

class OrderDetailsPage extends StatefulWidget {
  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  late Map<String, dynamic> order;
  late Map<String, dynamic> originalOrder;
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};

  final List<String> statusList = [
    'قيد المراجعة',
    'قيد الاستلام',
    'تم الاستلام',
    'قيد التجهيز',
    'جار التوصيل',
    'تم التسليم',
    'تم المحاسبة (مندوب)',
    'تم المحاسبة (تاجر)'
  ];
  final List<String> financialStatusList = ['آجل', 'كاش', 'سلفة'];
  final List<String> deliveryStatusList = ['قيد التوصيل', 'واصل', 'راجع'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    order = Map<String, dynamic>.from(
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>);
    originalOrder = Map<String, dynamic>.from(order);
    print('✅ البيانات المستلمة للصفحة: $order');
    order.forEach((key, value) {
      _controllers[key] = TextEditingController(text: value?.toString() ?? '');
    });
  }

  Future<void> deleteOrder() async {
    print('🗑️ حذف الطلب id: ${order['id']}');
    final response = await http.delete(
      Uri.parse('$baseUrl/delete_order/${order['id']}'),
    );
    if (response.statusCode == 200) {
      print('✅ تم الحذف بنجاح');
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تم حذف الطلب بنجاح'), backgroundColor: Colors.green),
      );
    } else {
      print('❌ فشل في الحذف: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('فشل في حذف الطلب'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> updateOrder() async {
    final Map<String, dynamic> updatedOrder = {};

    _controllers.forEach((key, controller) {
      String newValue = controller.text.trim();
      String oldValue = (originalOrder[key]?.toString() ?? '').trim();
      if (newValue != oldValue) {
        updatedOrder[key] = newValue;
        print('✏️ تعديل حقل [$key]: $oldValue ➔ $newValue');
      }
    });

    if (updatedOrder.isEmpty) {
      print('ℹ️ لا توجد تغييرات لإرسالها.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('لم يتم تعديل أي بيانات'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    updatedOrder['id'] = order['id'];

    print('📝 البيانات المعدلة للإرسال: $updatedOrder');

    final response = await http.put(
      Uri.parse('$baseUrl/orders/${order['id']}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updatedOrder),
    );

    if (response.statusCode == 200) {
      print('✅ تم تعديل الطلب بنجاح');
      setState(() {
        updatedOrder.forEach((key, value) {
          order[key] = value;
          originalOrder[key] = value;
        });
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تم تعديل الطلب بنجاح'),
            backgroundColor: Colors.green),
      );
    } else {
      print('❌ فشل تعديل الطلب: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('فشل في تعديل الطلب'), backgroundColor: Colors.red),
      );
    }
  }

  Widget buildEditableField(String key, String label) {
    if (key == 'status') {
      return dropdownField(key, label, statusList);
    } else if (key == 'financial_status') {
      return dropdownField(key, label, financialStatusList);
    } else if (key == 'delivery_status') {
      return dropdownField(key, label, deliveryStatusList);
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextFormField(
          controller: _controllers[key],
          decoration: InputDecoration(labelText: label),
        ),
      );
    }
  }

  Widget dropdownField(String key, String label, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<String>(
        value: _controllers[key]?.text.isEmpty == true
            ? null
            : _controllers[key]?.text,
        decoration: InputDecoration(labelText: label),
        items: items
            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
            .toList(),
        onChanged: (val) {
          print('🔄 تغيير $key إلى $val');
          setState(() {
            _controllers[key]?.text = val!;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalPrice =
        (double.tryParse(order['order_price']?.toString() ?? '0') ?? 0) +
            (double.tryParse(order['delivery_price']?.toString() ?? '0') ?? 0);

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الطلب')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                buildEditableField('page_name', 'اسم البيج'),
                buildEditableField('created_by_name', 'اسم التاجر'),
                buildEditableField('customer_city', 'عنوان البيج'),
                buildEditableField('created_by_phone', 'هاتف البيج'),
                buildEditableField('created_at', 'وقت الإضافة'),
                buildEditableField('product_type', 'نوع البضاعة'),
                buildEditableField('quantity', 'عدد القطع'),
                buildEditableField('order_code', 'رقم الطلب'),
                buildEditableField('tracking_code', 'رقم الكود'),
                buildEditableField('order_name', 'اسم الطلب'),
                buildEditableField('customer_city', 'المحافظة'),
                buildEditableField('customer_district', 'القضاء'),
                buildEditableField('customer_phone', 'هاتف الزبون'),
                buildEditableField('order_price', 'سعر الطلب'),
                buildEditableField('delivery_price', 'سعر التوصيل'),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('السعر الكلي: $totalPrice',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                buildEditableField('status', 'حالة الطلب'),
                buildEditableField('financial_status', 'الوضع المالي'),
                buildEditableField('delivery_status', 'حالة التوصيل'),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: updateOrder,
                        icon: const Icon(Icons.save),
                        label: const Text('حفظ التعديلات'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: deleteOrder,
                        icon: const Icon(Icons.delete),
                        label: const Text('حذف الطلب'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
