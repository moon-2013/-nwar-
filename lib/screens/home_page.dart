import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/main_scaffold.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = true;
  String errorMessage = '';
  Map<String, dynamic> stats = {};

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      final res = await http.get(Uri.parse('$baseUrl/orders'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final orders = data['orders'] as List;

        int mandoubCount = 0;
        double mandoubAmount = 0, mandoubDelivery = 0;

        int tajerCount = 0;
        double tajerAmount = 0, tajerDelivery = 0;

        for (var order in orders) {
          if (order['created_by'] == userId) {
            if (order['status'] == 'تم المحاسبة (مندوب)') {
              mandoubCount++;
              mandoubAmount += (order['order_price'] ?? 0);
              mandoubDelivery += (order['delivery_price'] ?? 0);
            }
            if (order['status'] == 'تم المحاسبة (تاجر)' ||
                (order['financial_status'] == 'كاش' ||
                    order['financial_status'] == 'سلفة')) {
              tajerCount++;
              tajerAmount += (order['order_price'] ?? 0);
              tajerDelivery += (order['delivery_price'] ?? 0);
            }
          }
        }

        setState(() {
          stats = {
            'mandoub_orders': {
              'total_orders': mandoubCount,
              'total_amount': mandoubAmount,
              'delivery_fee': mandoubDelivery,
              'net_amount': mandoubAmount - mandoubDelivery,
            },
            'tajer_orders': {
              'total_orders': tajerCount,
              'total_amount': tajerAmount,
              'delivery_fee': tajerDelivery,
              'net_amount': tajerAmount - tajerDelivery,
            },
          };
          isLoading = false;
          errorMessage = '';
        });
      } else {
        throw Exception('فشل في جلب البيانات من السيرفر');
      }
    } catch (e) {
      print('Error fetching stats: $e');
      setState(() {
        errorMessage = 'فشل الاتصال بالسيرفر';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'الرئيسية',
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildCard(
                          'طلبات تم المحاسبة (مندوب)', stats['mandoub_orders']),
                      const SizedBox(height: 16),
                      _buildCard('طلبات تم المحاسبة (تاجر - كاش/سلفة)',
                          stats['tajer_orders']),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCard(String title, Map<String, dynamic>? data) {
    data ??= {
      'total_orders': 0,
      'total_amount': 0.0,
      'delivery_fee': 0.0,
      'net_amount': 0.0
    };
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue)),
              const SizedBox(height: 4),
              Text('عدد الوصلات : ${data['total_orders']}',
                  style: const TextStyle(fontSize: 16, color: Colors.blue)),
              const Divider(height: 24, thickness: 1),
              _statRow('المبلغ الكلي', '${data['total_amount']}',
                  Icons.account_balance_wallet, Colors.deepPurple.shade50),
              _statRow('أجرة التوصيل', '${data['delivery_fee']}',
                  Icons.compare_arrows, Colors.red.shade50),
              _statRow('المبلغ الصافي', '${data['net_amount']}',
                  Icons.account_balance, Colors.cyan.shade50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statRow(String title, String value, IconData icon, Color bg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          Row(
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 16, color: Colors.blueGrey)),
              const SizedBox(width: 12),
              CircleAvatar(
                  radius: 20,
                  backgroundColor: bg,
                  child: Icon(icon, size: 20, color: Colors.blue)),
            ],
          ),
        ],
      ),
    );
  }
}
