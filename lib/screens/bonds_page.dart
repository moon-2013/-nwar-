import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../main.dart';
import '../widgets/main_scaffold.dart';

class BondsPage extends StatefulWidget {
  const BondsPage({super.key});

  @override
  State<BondsPage> createState() => _BondsPageState();
}

class _BondsPageState extends State<BondsPage> {
  List<dynamic> bonds = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBonds();
  }

  Future<void> fetchBonds() async {
    final response = await http.get(Uri.parse('$baseUrl/transactions'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        bonds = data['transactions'];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تحميل السندات')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'السندات',
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : bonds.isEmpty
              ? const Center(child: Text('لا توجد سندات'))
              : ListView.builder(
                  itemCount: bonds.length,
                  itemBuilder: (context, index) {
                    final bond = bonds[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: Icon(
                          bond['type'] == 'add'
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color:
                              bond['type'] == 'add' ? Colors.green : Colors.red,
                        ),
                        title: Text(
                          '${bond['user_name']} (${bond['user_phone']})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(bond['description']),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${bond['amount']} د.ع'),
                            Text(
                              bond['created_at'],
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
