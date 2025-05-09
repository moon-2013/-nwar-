import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart';
import '../widgets/order_card.dart';
import '../widgets/main_scaffold.dart';

class AdminApprovalPage extends StatefulWidget {
  const AdminApprovalPage({super.key});

  @override
  State<AdminApprovalPage> createState() => _AdminApprovalPageState();
}

class _AdminApprovalPageState extends State<AdminApprovalPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  late TabController _tabController;

  final List<String> approvalStatuses = [
    'approved',
    'pending_add',
    'pending_update',
    'pending_delete'
  ];
  final List<String> tabNames = [
    'الموافق عليها',
    'طلبات الإضافة',
    'طلبات التعديل',
    'طلبات الحذف'
  ];

  final List<String> deliveryStatuses = ['قيد التوصيل', 'واصل', 'راجع'];

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: approvalStatuses.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        fetchOrders();
      }
    });
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    setState(() => isLoading = true);
    final status = approvalStatuses[_tabController.index];
    final res =
        await http.get(Uri.parse('$baseUrl/orders/by_approval/$status'));
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() {
        orders = List<Map<String, dynamic>>.from(data['orders']);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في تحميل الطلبات')),
      );
    }
  }

  Future<void> handleApproval(int orderId, bool approve) async {
    final action = approve ? 'approve' : 'reject';
    final res = await http.post(
      Uri.parse('$baseUrl/orders/approval/$orderId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'action': action}),
    );
    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(approve ? 'تمت الموافقة' : 'تم الرفض')),
      );
      fetchOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في تنفيذ العملية')),
      );
    }
  }

  Future<void> updateDeliveryStatus(int orderId, String newStatus) async {
    final res = await http.put(
      Uri.parse('$baseUrl/orders/$orderId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'delivery_status': newStatus}),
    );
    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديث حالة التوصيل')),
      );
      fetchOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في تحديث الحالة')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'إدارة الطلبات',
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: tabNames.map((name) => Tab(text: name)).toList(),
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : orders.isEmpty
                    ? Center(child: Text('لا توجد طلبات'))
                    : ListView.builder(
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          return Column(
                            children: [
                              OrderCard(order: order),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'المستخدم: ${order['created_by_username'] ?? 'غير معروف'}',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ),
                              ),
                              if (order['approval_status'] != 'approved')
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          handleApproval(order['id'], true),
                                      icon: Icon(Icons.check),
                                      label: Text('موافقة'),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green),
                                    ),
                                    SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          handleApproval(order['id'], false),
                                      icon: Icon(Icons.close),
                                      label: Text('رفض'),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red),
                                    ),
                                  ],
                                )
                              else if (_tabController.index == 0)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: DropdownButtonFormField<String>(
                                    value: order['delivery_status'],
                                    items: deliveryStatuses
                                        .map((status) => DropdownMenuItem(
                                              value: status,
                                              child: Text(status),
                                            ))
                                        .toList(),
                                    decoration: InputDecoration(
                                      labelText: 'تغيير حالة التوصيل',
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (newStatus) {
                                      if (newStatus != null) {
                                        updateDeliveryStatus(
                                            order['id'], newStatus);
                                      }
                                    },
                                  ),
                                ),
                              SizedBox(height: 8),
                            ],
                          );
                        },
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
