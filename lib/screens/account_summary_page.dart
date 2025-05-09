import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart';

class AccountSummaryPage extends StatefulWidget {
  final int userId;

  const AccountSummaryPage({super.key, required this.userId});

  @override
  State<AccountSummaryPage> createState() => _AccountSummaryPageState();
}

class _AccountSummaryPageState extends State<AccountSummaryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> summary = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchSummary();
  }

  Future<void> fetchSummary() async {
    setState(() => isLoading = true);
    final res =
        await http.get(Uri.parse('$baseUrl/account_summary/${widget.userId}'));
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() {
        summary = data;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في تحميل كشف الحساب')),
      );
    }
  }

  Widget buildSummaryTab(String status) {
    final count =
        int.tryParse(summary[status]?['count'].toString() ?? '0') ?? 0;
    final totalOrderPrice = double.tryParse(
            summary[status]?['total_order_price'].toString() ?? '0') ??
        0.0;
    final totalDeliveryPrice = double.tryParse(
            summary[status]?['total_delivery_price'].toString() ?? '0') ??
        0.0;
    final total = (totalOrderPrice + totalDeliveryPrice).toInt();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('عدد الطلبات: $count'),
          SizedBox(height: 8),
          Text('مجموع سعر الطلب: ${totalOrderPrice.toStringAsFixed(0)} دينار'),
          SizedBox(height: 8),
          Text(
              'مجموع سعر التوصيل: ${totalDeliveryPrice.toStringAsFixed(0)} دينار'),
          SizedBox(height: 8),
          Text('المجموع الكلي: $total دينار'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('كشف الحساب')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(text: 'واصل'),
                    Tab(text: 'راجع'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      buildSummaryTab('واصل'),
                      buildSummaryTab('راجع'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
