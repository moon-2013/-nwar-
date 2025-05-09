import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final phoneController = TextEditingController();
  final codeController = TextEditingController();
  final newPasswordController = TextEditingController();

  bool isOTPSent = false;

  Future<void> sendOTP() async {
    final response = await http.post(
      Uri.parse('$baseUrl/forgot_password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phoneController.text}),
    );
    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      setState(() => isOTPSent = true);
      showMessage('تم إرسال رمز التحقق');
    } else {
      showMessage(data['message'] ?? 'فشل إرسال الرمز');
    }
  }

  Future<void> resetPassword() async {
    final response = await http.post(
      Uri.parse('$baseUrl/reset_password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': phoneController.text,
        'code': codeController.text,
        'new_password': newPasswordController.text,
      }),
    );
    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      showMessage('تم تغيير كلمة المرور بنجاح');
      Navigator.pop(context);
    } else {
      showMessage(data['message'] ?? 'فشل تغيير كلمة المرور');
    }
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    phoneController.dispose();
    codeController.dispose();
    newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('نسيت كلمة المرور')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(labelText: 'رقم الهاتف'),
                validator: (val) => val!.isEmpty ? 'أدخل رقم الهاتف' : null,
              ),
              if (isOTPSent) ...[
                TextFormField(
                  controller: codeController,
                  decoration: InputDecoration(labelText: 'رمز التحقق'),
                  validator: (val) => val!.isEmpty ? 'أدخل الرمز' : null,
                ),
                TextFormField(
                  controller: newPasswordController,
                  decoration: InputDecoration(labelText: 'كلمة المرور الجديدة'),
                  obscureText: true,
                  validator: (val) => val!.isEmpty ? 'أدخل كلمة المرور' : null,
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    isOTPSent ? resetPassword() : sendOTP();
                  }
                },
                child: Text(isOTPSent ? 'تغيير كلمة المرور' : 'إرسال الرمز'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
