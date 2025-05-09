import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart'; // استيراد ملف main.dart للوصول إلى baseUrl
import '../widgets/main_scaffold.dart'; // استيراد MainScaffold

class PreparerPage extends StatefulWidget {
  const PreparerPage({Key? key}) : super(key: key);

  @override
  State<PreparerPage> createState() => _PreparerPageState();
}

class _PreparerPageState extends State<PreparerPage> {
  List orders = [];

  Future<void> fetchOrders() async {
    final res =
        await http.get(Uri.parse('$baseUrl/get_orders?role=مندوب تجهيز'));
    if (res.statusCode == 200) {
      setState(() {
        orders = json.decode(res.body)['orders'];
      });
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
      title: 'صفحة مندوب التجهيز',
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
    );
  }
}
