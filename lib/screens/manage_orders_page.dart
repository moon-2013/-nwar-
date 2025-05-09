import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../widgets/order_card.dart';
import 'order_details_page.dart';
import '../widgets/main_scaffold.dart';

class ManageOrdersPage extends StatefulWidget {
  const ManageOrdersPage({super.key});

  @override
  State<ManageOrdersPage> createState() => _ManageOrdersPageState();
}

class _ManageOrdersPageState extends State<ManageOrdersPage> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{
    'order_name': TextEditingController(),
    'order_code': TextEditingController(),
    'tracking_code': TextEditingController(),
    'order_price': TextEditingController(),
    'delivery_price': TextEditingController(),
    'customer_phone': TextEditingController(),
    'notes': TextEditingController(),
    'product_type': TextEditingController(),
    'quantity': TextEditingController(),
    'customer_city': TextEditingController(),
    'customer_district': TextEditingController(),
    'page_name': TextEditingController(),
  };

  String _selectedStatus = 'قيد المراجعة';
  String _selectedFinancialStatus = 'آجل';
  final List<String> _statuses = [
    'قيد المراجعة',
    'قيد الاستلام',
    'تم الاستلام',
    'قيد التجهيز',
    'جار التوصيل',
    'تم التسليم',
    'تم القبض',
    'تم المحاسبة',
  ];

  final List<String> _financialStatuses = [
    'آجل',
    'كاش',
    'سلفة',
  ];

  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 1;
    final res = await http.get(Uri.parse('$baseUrl/orders?user_id=$userId'));
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() {
        orders = List<Map<String, dynamic>>.from(data['orders']);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> saveOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 1;
    final username = prefs.getString('username') ?? 'غير معروف';

    final Map<String, dynamic> body = {
      'order_name': _controllers['order_name']!.text,
      'order_code': _controllers['order_code']!.text,
      'tracking_code': _controllers['tracking_code']!.text,
      'order_price': double.tryParse(_controllers['order_price']!.text) ?? 0,
      'delivery_price':
          double.tryParse(_controllers['delivery_price']!.text) ?? 0,
      'customer_phone': _controllers['customer_phone']!.text,
      'notes': _controllers['notes']!.text,
      'product_type': _controllers['product_type']!.text,
      'quantity': int.tryParse(_controllers['quantity']!.text) ?? 1,
      'status': _selectedStatus,
      'financial_status': _selectedFinancialStatus,
      'created_by': userId,
      'customer_city': _controllers['customer_city']!.text,
      'customer_district': _controllers['customer_district']!.text,
      'page_name': _controllers['page_name']!.text,
    };

    final res = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (res.statusCode == 200) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ManageOrdersPage()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إضافة الطلب بنجاح')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في إضافة الطلب: ${res.body}')),
      );
    }
  }

  void _openOrderDetails(Map<String, dynamic> order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailsPage(),
        settings: RouteSettings(arguments: order),
      ),
    ).then((result) {
      if (result == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ManageOrdersPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'إدارة الطلبات',
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        for (var field in [
                          ['page_name', 'اسم البيج'],
                          ['product_type', 'نوع المنتج'],
                          ['quantity', 'الكمية'],
                          ['order_code', 'رقم الطلب'],
                          ['tracking_code', 'رقم الكود'],
                          ['order_name', 'اسم الطلب'],
                          ['customer_city', 'المحافظة'],
                          ['customer_district', 'القضاء أو المنطقة'],
                          ['customer_phone', 'رقم هاتف الزبون'],
                          ['order_price', 'سعر الطلب'],
                          ['delivery_price', 'سعر التوصيل'],
                          ['notes', 'ملاحظات'],
                        ])
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextFormField(
                              controller: _controllers[field[0]]!,
                              decoration: InputDecoration(labelText: field[1]),
                              keyboardType: (field[0].contains('price') ||
                                      field[0] == 'quantity')
                                  ? TextInputType.number
                                  : TextInputType.text,
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'مطلوب' : null,
                            ),
                          ),
                        DropdownButtonFormField(
                          value: _selectedFinancialStatus,
                          items: _financialStatuses
                              .map((s) =>
                                  DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (val) => setState(
                              () => _selectedFinancialStatus = val as String),
                          decoration:
                              const InputDecoration(labelText: 'الوضع المالي'),
                        ),
                        DropdownButtonFormField(
                          value: _selectedStatus,
                          items: _statuses
                              .map((s) =>
                                  DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedStatus = val as String),
                          decoration:
                              const InputDecoration(labelText: 'الحالة'),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: saveOrder,
                          child: const Text('إضافة الطلب'),
                        )
                      ],
                    ),
                  ),
                  const Divider(height: 32),
                  if (orders.isEmpty)
                    const Center(child: Text('لا توجد طلبات'))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return GestureDetector(
                          onTap: () => _openOrderDetails(order),
                          child: OrderCard(order: order),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
