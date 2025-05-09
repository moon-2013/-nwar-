import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart'; // استيراد ملف main.dart للوصول إلى baseUrl
import '../widgets/main_scaffold.dart'; // استيراد MainScaffold

class MerchantPage extends StatefulWidget {
  final int userId;
  const MerchantPage({required this.userId, Key? key}) : super(key: key);

  @override
  State<MerchantPage> createState() => _MerchantPageState();
}

class _MerchantPageState extends State<MerchantPage> {
  final descriptionController = TextEditingController();
  List orders = [];

  Future<void> fetchOrders() async {
    final res = await http.get(
        Uri.parse('$baseUrl/get_orders?role=تاجر&user_id=${widget.userId}'));
    if (res.statusCode == 200) {
      setState(() {
        orders = json.decode(res.body)['orders'];
      });
    }
  }

  Future<void> addOrder() async {
    final description = descriptionController.text;
    if (description.isEmpty) return;

    final res = await http.post(
      Uri.parse('$baseUrl/add_order'),
      headers: {'Content-Type': 'application/json'},
      body: json
          .encode({'description': description, 'created_by': widget.userId}),
    );

    if (res.statusCode == 200) {
      descriptionController.clear();
      fetchOrders();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم إضافة الطلب بنجاح')));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('فشل في إضافة الطلب')));
    }
  }

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'صفحة التاجر',
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'وصف الطلب'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: addOrder, child: const Text('إضافة طلب')),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return ListTile(
                    title: Text(order['description']),
                    subtitle: Text('الحالة: ${order['status']}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
