import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../widgets/order_card.dart';
import '../widgets/main_scaffold.dart';

class DeliveriesScreen extends StatefulWidget {
  const DeliveriesScreen({super.key});

  @override
  State<DeliveriesScreen> createState() => _DeliveriesScreenState();
}

class _DeliveriesScreenState extends State<DeliveriesScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  bool isSearching = false;
  String searchQuery = '';
  String? selectedStatusFilter;

  final searchController = TextEditingController();

  final List<String> tabs = ['الكل', 'الطلبات الحالية', 'الواصل', 'الراجع'];
  final Map<String, String> tabToDeliveryStatus = {
    'الطلبات الحالية': 'قيد التوصيل',
    'الواصل': 'واصل',
    'الراجع': 'راجع',
  };

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        fetchOrders();
      }
    });
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 1;
      final role = prefs.getString('role') ?? '';

      String tabName = tabs[_tabController.index];
      String tabStatusParam = tabName != 'الكل'
          ? '&tab_status=${tabToDeliveryStatus[tabName]}'
          : '';

      String statusFilterParam = selectedStatusFilter != null
          ? '&tab_status=$selectedStatusFilter'
          : '';

      String userParam = role == 'الإدارة' ? '' : 'user_id=$userId&';

      String url =
          '$baseUrl/orders?${userParam}${tabStatusParam}${statusFilterParam}&query=${searchQuery.trim()}';

      final res = await http.get(Uri.parse(url));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (!mounted) return;
        setState(() {
          orders = List<Map<String, dynamic>>.from(data['orders']);
          isLoading = false;
        });
      } else {
        showError('فشل في جلب الطلبات');
      }
    } catch (e) {
      showError('حدث خطأ أثناء الاتصال بالسيرفر');
    }
  }

  void showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void showFilterDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('اختر حالة الفلترة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...tabToDeliveryStatus.values.map((status) {
              return RadioListTile<String>(
                value: status,
                groupValue: selectedStatusFilter,
                title: Text(status),
                onChanged: (value) {
                  setState(() {
                    selectedStatusFilter = value;
                    Navigator.pop(context);
                    fetchOrders();
                  });
                },
              );
            }),
            RadioListTile<String>(
              value: '',
              groupValue: selectedStatusFilter,
              title: const Text('مسح الفلتر'),
              onChanged: (_) {
                setState(() {
                  selectedStatusFilter = null;
                  Navigator.pop(context);
                  fetchOrders();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'الطلبات',
      isSearching: isSearching,
      onSearchChanged: (value) {
        searchQuery = value;
        fetchOrders();
      },
      onSearchToggle: () {
        setState(() {
          isSearching = !isSearching;
          if (!isSearching) {
            searchController.clear();
            searchQuery = '';
            fetchOrders();
          }
        });
      },
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: showFilterDialog,
        ),
      ],
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: tabs.map((tab) => Tab(text: tab)).toList(),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : buildOrdersList(),
          ),
        ],
      ),
    );
  }

  Widget buildOrdersList() {
    if (orders.isEmpty) {
      return const Center(child: Text('لا توجد طلبات'));
    }
    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return OrderCard(order: order);
      },
    );
  }
}
