import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../main.dart';

class AuthPage extends StatefulWidget {
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;
  bool isOTPStep = false;
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final codeController = TextEditingController();
  final locationController = TextEditingController();
  final gpsController = TextEditingController();
  final descriptionController = TextEditingController();

  String frontIdImage = '';
  String backIdImage = '';

  String role = 'تاجر';
  List<String> roles = ['تاجر', 'الإدارة'];

  final picker = ImagePicker();

  void toggleMode() {
    setState(() {
      isLogin = !isLogin;
      isOTPStep = false;
    });
  }

  Future<void> getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    gpsController.text = '${position.latitude}, ${position.longitude}';
  }

  Future<void> pickImage(Function(String) onImagePicked) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      onImagePicked(base64Image);
    }
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      if (isLogin) {
        final res = await http.post(
          Uri.parse('$baseUrl/login'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'user_or_phone': usernameController.text,
            'password': passwordController.text,
          }),
        );

        final data = json.decode(res.body);
        if (res.statusCode == 200) {
          await prefs.setInt('user_id', data['user_id']);
          await prefs.setString('role', data['role']);
          await prefs.setString('username', data['username']);
          await prefs.setString('phone', data['phone']);
          await prefs.setString('profile_image', data['profile_image'] ?? '');
          await prefs.setString('name', data['name']);
          await prefs.setDouble('balance', data['balance'] ?? 0.0);
          await prefs.setBool('loggedIn', true);
          await prefs.setBool(
              'is_active', data['is_active'] == 1 || data['is_active'] == true);

          final isActive = data['is_active'].toString() == '1' ||
              data['is_active'] == true ||
              data['is_active'] == 1;

          if (isActive) {
            Navigator.pushReplacementNamed(context, '/');
          } else {
            Navigator.pushReplacementNamed(context, '/waiting');
          }
        } else {
          showError(data['message']);
        }
      } else if (!isOTPStep) {
        final res = await http.post(
          Uri.parse('$baseUrl/register'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'name': nameController.text,
            'username': usernameController.text,
            'phone': phoneController.text,
            'password': passwordController.text,
            'role': role,
            'location': locationController.text,
            'gps_location': gpsController.text,
            'front_id_image': frontIdImage,
            'back_id_image': backIdImage,
            'page_description': descriptionController.text,
          }),
        );

        final data = json.decode(res.body);
        if (res.statusCode == 200) {
          setState(() => isOTPStep = true);
        } else {
          showError(data['error'] ?? 'خطأ في الاتصال');
        }
      } else {
        final res = await http.post(
          Uri.parse('$baseUrl/verify'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'phone': phoneController.text,
            'code': codeController.text,
          }),
        );

        final data = json.decode(res.body);
        if (res.statusCode == 200) {
          await prefs.setInt('user_id', data['user_id']);
          await prefs.setString('role', data['role']);
          await prefs.setString('username', data['username']);
          await prefs.setString('phone', data['phone']);
          await prefs.setString('profile_image', data['profile_image'] ?? '');
          await prefs.setString('name', data['name']);
          await prefs.setDouble('balance', data['balance'] ?? 0.0);
          await prefs.setBool('loggedIn', true);

          showError('تم إنشاء الحساب بنجاح، بانتظار تفعيل الإدارة');
          Navigator.pushReplacementNamed(context, '/waiting');
        } else {
          showError(data['message'] ?? 'رمز غير صحيح');
        }
      }
    } catch (e) {
      showError('حدث خطأ أثناء الاتصال بالسيرفر');
      print('❌ Error: $e');
    }
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void forgotPassword() {
    Navigator.pushNamed(context, '/forgot-password');
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    codeController.dispose();
    locationController.dispose();
    gpsController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 30),
              ClipOval(
                child: Container(
                  color: Colors.white, // خلفية بيضاء لو تحب
                  width: 100, // حجم صغير مثل اللوغو
                  height: 100,
                  child: Image.asset(
                    'assets/default_avatar.png',
                    fit: BoxFit.contain, // مهم: حتى ما يقص الصورة
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isLogin
                    ? 'تسجيل الدخول'
                    : isOTPStep
                        ? 'أدخل رمز التحقق'
                        : 'إنشاء حساب',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (!isLogin && !isOTPStep)
                      Column(
                        children: [
                          TextFormField(
                            controller: nameController,
                            decoration:
                                InputDecoration(labelText: 'الاسم الكامل'),
                            validator: (val) =>
                                val!.isEmpty ? 'أدخل الاسم' : null,
                          ),
                          TextFormField(
                            controller: usernameController,
                            decoration:
                                InputDecoration(labelText: 'اسم المستخدم'),
                            validator: (val) =>
                                val!.isEmpty ? 'أدخل اسم المستخدم' : null,
                          ),
                          TextFormField(
                            controller: phoneController,
                            decoration:
                                InputDecoration(labelText: 'رقم الهاتف'),
                            validator: (val) =>
                                val!.isEmpty ? 'أدخل رقم الهاتف' : null,
                          ),
                          TextFormField(
                            controller: locationController,
                            decoration:
                                InputDecoration(labelText: 'الموقع كتابة'),
                            validator: (val) =>
                                val!.isEmpty ? 'أدخل الموقع' : null,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: gpsController,
                                  decoration:
                                      InputDecoration(labelText: 'الموقع GPS'),
                                  readOnly: true,
                                  validator: (val) =>
                                      val!.isEmpty ? 'أدخل GPS' : null,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.my_location),
                                onPressed: getCurrentLocation,
                              ),
                            ],
                          ),
                          TextFormField(
                            controller: descriptionController,
                            decoration:
                                InputDecoration(labelText: 'وصف الصفحة'),
                            maxLines: 3,
                            validator: (val) =>
                                val!.isEmpty ? 'أدخل وصف الصفحة' : null,
                          ),
                          DropdownButtonFormField<String>(
                            value: role,
                            items: roles
                                .map((r) =>
                                    DropdownMenuItem(value: r, child: Text(r)))
                                .toList(),
                            onChanged: (val) => setState(() => role = val!),
                            decoration: InputDecoration(labelText: 'الدور'),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  '📸 ${frontIdImage.isEmpty ? 'صورة أمامية غير مرفوعة' : 'تم التحميل'}'),
                              TextButton(
                                onPressed: () => pickImage((base64) =>
                                    setState(() => frontIdImage = base64)),
                                child: Text('تحميل الأمامية'),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  '📸 ${backIdImage.isEmpty ? 'صورة خلفية غير مرفوعة' : 'تم التحميل'}'),
                              TextButton(
                                onPressed: () => pickImage((base64) =>
                                    setState(() => backIdImage = base64)),
                                child: Text('تحميل الخلفية'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    if (isLogin)
                      Column(
                        children: [
                          TextFormField(
                            controller: usernameController,
                            decoration: InputDecoration(
                                labelText: 'اسم المستخدم أو رقم الهاتف'),
                            validator: (val) => val!.isEmpty ? 'مطلوب' : null,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: forgotPassword,
                              child: Text('نسيت كلمة المرور؟'),
                            ),
                          ),
                        ],
                      ),
                    if (!isOTPStep)
                      TextFormField(
                        controller: passwordController,
                        decoration: InputDecoration(labelText: 'كلمة المرور'),
                        obscureText: true,
                        validator: (val) =>
                            val!.isEmpty ? 'أدخل كلمة المرور' : null,
                      ),
                    if (isOTPStep)
                      TextFormField(
                        controller: codeController,
                        decoration: InputDecoration(labelText: 'رمز التحقق'),
                        keyboardType: TextInputType.number,
                        validator: (val) => val!.isEmpty ? 'أدخل الرمز' : null,
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: submit,
                      child: Text(isLogin
                          ? 'تسجيل الدخول'
                          : isOTPStep
                              ? 'تحقق'
                              : 'إنشاء حساب'),
                      style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 48)),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: toggleMode,
                      child: Text(
                          isLogin ? 'إنشاء حساب جديد' : 'العودة لتسجيل الدخول'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
