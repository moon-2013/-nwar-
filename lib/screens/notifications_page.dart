import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../main.dart';

import '../widgets/main_scaffold.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
    // جلب الإشعارات بشكل دوري كل 10 ثوانٍ
    Future.delayed(const Duration(seconds: 10), fetchNotifications);
  }

  Future<void> fetchNotifications() async {
    try {
      final response =
          await http.get(Uri.parse('http://127.0.0.1:5000/get_notifications'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          notifications =
              List<Map<String, dynamic>>.from(data['notifications']);
          isLoading = false;
        });
      } else {
        showError('فشل في جلب الإشعارات');
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
    return MainScaffold(
      title: '  الاشعارات  ',
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(
                          int.parse(notification['color'] ?? '0xFF000000')),
                      child: Icon(
                        IconData(int.parse(notification['icon'] ?? '0xe3af'),
                            fontFamily: 'MaterialIcons'),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      notification['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(notification['message'] ?? ''),
                  ),
                );
              },
            ),
    );
  }
}
