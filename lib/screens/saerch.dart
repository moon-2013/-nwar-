import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../widgets/order_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> orders = [];
  bool isLoading = false;
  String searchQuery = '';
  String? selectedStatus;
  int currentPage = 1;
  bool isFetchingMore = false;

  final List<String> statuses = [
    'الكل',
    'قيد المراجعة',
    'قيد الاستلام',
    'تم الاستلام',
    'قيد التجهيز',
    'جار التوصيل',
    'تم التسليم',
    'تم القبض',
    'تم المحاسبة',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    fetchOrders();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !isFetchingMore) {
      setState(() => isFetchingMore = true);
      currentPage++;
      fetchOrders(page: currentPage).then((_) {
        setState(() => isFetchingMore = false);
      });
    }
  }

  Future<void> fetchOrders({int page = 1}) async {
    setState(() => isLoading = page == 1);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 1;

      final url = Uri.parse(
        '$baseUrl/search_orders?user_id=$userId&page=$page&query=${searchQuery.trim()}${(selectedStatus != null && selectedStatus != 'الكل') ? '&status=$selectedStatus' : ''}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          if (page == 1) {
            orders = List<Map<String, dynamic>>.from(data['orders']);
          } else {
            orders.addAll(List<Map<String, dynamic>>.from(data['orders']));
          }
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('البحث عن الطلبات'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'بحث بالكلمة',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                      fetchOrders();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: selectedStatus,
                  hint: const Text('الحالة'),
                  items: statuses
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value;
                    });
                    fetchOrders();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : orders.isEmpty
                    ? const Center(child: Text('لا توجد طلبات'))
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: orders.length + (isFetchingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == orders.length) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          final order = orders[index];
                          return OrderCard(order: order);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
