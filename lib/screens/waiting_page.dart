import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart';

class WaitingPage extends StatefulWidget {
  @override
  State<WaitingPage> createState() => _WaitingPageState();
}

class _WaitingPageState extends State<WaitingPage> {
  bool isChecking = false;

  Future<void> checkStatus() async {
    setState(() => isChecking = true);
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    try {
      final res = await http.get(Uri.parse('$baseUrl/users'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final users = data['users'] as List;
        final user =
            users.firstWhere((u) => u['id'] == userId, orElse: () => null);

        if (user != null && user['is_active'] == 1) {
          await prefs.setBool('loggedIn', true);
          Navigator.pushReplacementNamed(context, '/');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('الحساب ما زال غير نشط')),
          );
        }
      } else {
        throw Exception('فشل في جلب حالة الحساب');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ أثناء التحقق: $e')),
      );
    } finally {
      setState(() => isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/auth');
          },
        ),
        title: Text('بانتظار التفعيل'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'حسابك بانتظار التفعيل من الإدارة.\nيرجى المحاولة لاحقاً.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: isChecking ? null : checkStatus,
                icon: Icon(Icons.refresh),
                label: Text('التحقق من التفعيل'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                ),
              ),
              if (isChecking)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
