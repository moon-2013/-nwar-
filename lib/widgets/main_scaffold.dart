import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/app_drawer.dart';
import '../main.dart';

class MainScaffold extends StatefulWidget {
  final String title;
  final Widget child;
  final bool isSearching;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchToggle;
  final List<Widget>? actions;
  final VoidCallback? onBalanceButtonPressed;

  const MainScaffold({
    super.key,
    required this.title,
    required this.child,
    this.isSearching = false,
    this.onSearchChanged,
    this.onSearchToggle,
    this.actions,
    this.onBalanceButtonPressed,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  @override
  void initState() {
    super.initState();
    loadBalanceFromServer();
  }

  Future<void> loadBalanceFromServer() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user_balance?user_id=$userId'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        double newBalance = (data['balance'] as num).toDouble();
        balanceNotifier.value = newBalance;
        prefs.setDouble('balance', newBalance);
      } else {
        print('❌ Failed to load balance: ${response.body}');
      }
    } catch (e) {
      print('❌ Error loading balance: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;

    return Scaffold(
      endDrawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        automaticallyImplyLeading: false,
        title: Row(
          textDirection: TextDirection.rtl,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(width: 10),
            Text(
              widget.title,
              style: const TextStyle(fontSize: 20),
            ),
            const Spacer(),
            if (widget.isSearching)
              SizedBox(
                width: 200,
                child: TextField(
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'بحث...',
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    filled: true,
                    fillColor: Colors.white24,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: widget.onSearchChanged,
                ),
              ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  ValueListenableBuilder<double>(
                    valueListenable: balanceNotifier,
                    builder: (context, value, _) {
                      return Text(
                        '${value.toStringAsFixed(2)} د.ع',
                        style: const TextStyle(color: Colors.black),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.black),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: widget.onBalanceButtonPressed,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: Icon(
                currentRoute == '/orders'
                    ? (widget.isSearching ? Icons.close : Icons.search)
                    : Icons.shopping_cart,
              ),
              onPressed: () {
                if (currentRoute == '/orders') {
                  widget.onSearchToggle?.call();
                } else {
                  Navigator.pushNamed(
                    context,
                    '/orders',
                    arguments: {'openSearch': false},
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.pushNamed(context, '/manage_orders');
              },
            ),
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                Navigator.pushNamed(context, '/notifications');
              },
            ),
          ],
        ),
      ),
      body: widget.child,
    );
  }
}
