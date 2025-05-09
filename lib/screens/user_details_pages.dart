import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../widgets/app_drawer.dart';
import '../main.dart';
import '../widgets/main_scaffold.dart';

class UserProfilePage extends StatefulWidget {
  final int userId;

  const UserProfilePage({super.key, required this.userId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  Map<String, dynamic> user = {};
  bool isEditing = false;
  bool isAdmin = false;
  String currentUserRole = '';

  late TextEditingController nameController;
  late TextEditingController usernameController;
  late TextEditingController phoneController;
  late TextEditingController locationController;
  late TextEditingController descriptionController;
  late TextEditingController passwordController;
  late TextEditingController balanceChangeController;

  @override
  void initState() {
    super.initState();
    balanceChangeController = TextEditingController();
    fetchCurrentUserRole();
    fetchUserData();
  }

  Future<void> fetchCurrentUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserRole = prefs.getString('role') ?? '';
    });
  }

  Future<void> fetchUserData() async {
    final response =
        await http.get(Uri.parse('$baseUrl/users/${widget.userId}'));
    if (response.statusCode == 200) {
      user = json.decode(response.body);
      setState(() {
        isAdmin = user['role'] == 'الإدارة';
        nameController = TextEditingController(text: user['name'] ?? '');
        usernameController =
            TextEditingController(text: user['username'] ?? '');
        phoneController = TextEditingController(text: user['phone'] ?? '');
        locationController =
            TextEditingController(text: user['location'] ?? '');
        descriptionController =
            TextEditingController(text: user['description'] ?? '');
        passwordController =
            TextEditingController(text: user['password'] ?? '');
      });
    } else {
      showMessage('فشل في تحميل البيانات', error: true);
    }
  }

  Future<void> pickImage(String type) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        user['${type}_image'] = pickedFile.path;
      });
    }
  }

  Future<void> saveChanges() async {
    final response = await http.put(
      Uri.parse('$baseUrl/users'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'id': user['id'] ?? widget.userId,
        'name': nameController.text,
        'username': usernameController.text,
        'phone': phoneController.text,
        'location': locationController.text,
        'description': descriptionController.text,
        'password': passwordController.text,
      }),
    );
    if (response.statusCode == 200) {
      await fetchUserData();
      setState(() => isEditing = false);
      showMessage('تم حفظ التعديلات بنجاح');
    } else {
      showMessage('فشل في حفظ التعديلات', error: true);
    }
  }

  Future<void> updateActivation() async {
    final response = await http.put(
      Uri.parse('$baseUrl/users'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'id': user['id'] ?? widget.userId,
        'is_active': user['is_active'] == 1 ? 0 : 1,
      }),
    );
    if (response.statusCode == 200) {
      await fetchUserData();
      showMessage(user['is_active'] == 1 ? 'تم التفعيل' : 'تم إلغاء التفعيل');
    } else {
      showMessage('فشل في تحديث الحالة', error: true);
    }
  }

  Future<void> changeBalance(bool isAdding) async {
    final amount = double.tryParse(balanceChangeController.text);
    if (amount == null) {
      showMessage('أدخل قيمة صحيحة', error: true);
      return;
    }
    final response = await http.put(
      Uri.parse('$baseUrl/users'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'id': user['id'] ?? widget.userId,
        'balance_change': isAdding ? amount : -amount,
      }),
    );
    if (response.statusCode == 200) {
      await fetchUserData();
      balanceChangeController.clear();
      showMessage(isAdding ? 'تمت إضافة الرصيد' : 'تم خصم الرصيد');

      // هنا التحديث الصحيح
      balanceNotifier.value = (user['balance'] as num).toDouble();
    } else {
      showMessage('فشل في تعديل الرصيد', error: true);
    }
  }

  Future<void> deleteAccount() async {
    final response = await http
        .delete(Uri.parse('$baseUrl/users/${user['id'] ?? widget.userId}'));
    if (response.statusCode == 200) {
      showMessage('تم حذف الحساب بنجاح');
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getInt('user_id');
      if (user['id'] == currentUserId) {
        await prefs.clear();
        Navigator.pop(context, true);
        Navigator.pushReplacementNamed(context, '/auth');
      } else {
        Navigator.pop(context, true);
        Navigator.pushReplacementNamed(context, '/manage_users');
      }
    } else {
      showMessage('فشل في حذف الحساب', error: true);
    }
  }

  void showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: error ? Colors.red : Colors.green),
    );
  }

  Widget buildInfoField(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: controller,
        readOnly: !isEditing,
        maxLines: maxLines,
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }

  Widget circleImage(String? url) {
    return InkWell(
      onTap: isEditing ? () => pickImage('profile') : null,
      child: CircleAvatar(
        radius: 60,
        backgroundImage: url != null && url.isNotEmpty
            ? NetworkImage(url)
            : const AssetImage('assets/default_avatar.png') as ImageProvider,
      ),
    );
  }

  Widget networkImage(String? url, String label) {
    return InkWell(
      onTap: isEditing ? () => pickImage(label) : null,
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Container(
            width: 120,
            height: 120,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8)),
            child: url != null && url.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(url, fit: BoxFit.cover))
                : const Icon(Icons.image_not_supported, size: 50),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user.isEmpty || currentUserRole.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isActive = user['is_active'] == 1;

    return MainScaffold(
      title: 'ملف المستخدم',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  circleImage(user['profile_image']),
                  const SizedBox(height: 16),
                  networkImage(user['front_id_image'], 'بطاقة أمامية'),
                  const SizedBox(height: 16),
                  networkImage(user['back_id_image'], 'بطاقة خلفية'),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ListView(
                children: [
                  buildInfoField(
                      'ID', TextEditingController(text: '${user['id']}')),
                  buildInfoField('الاسم', nameController),
                  buildInfoField('اسم المستخدم', usernameController),
                  buildInfoField('رقم الهاتف', phoneController),
                  buildInfoField(
                      'الدور', TextEditingController(text: user['role'] ?? '')),
                  buildInfoField('الرصيد',
                      TextEditingController(text: '${user['balance']} دينار')),
                  buildInfoField('الموقع', locationController),
                  buildInfoField('GPS',
                      TextEditingController(text: user['gps_location'] ?? '')),
                  buildInfoField('الوصف', descriptionController, maxLines: 3),
                  buildInfoField('كلمة المرور', passwordController),
                  buildInfoField(
                      'الحالة',
                      TextEditingController(
                          text: isActive ? 'نشط' : 'غير نشط')),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isEditing
                        ? saveChanges
                        : () => setState(() => isEditing = true),
                    child: Text(isEditing ? 'حفظ' : 'تعديل'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: deleteAccount,
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('حذف الحساب'),
                  ),
                  if (currentUserRole == 'الإدارة') ...[
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: updateActivation,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      child: Text(isActive ? 'إلغاء التفعيل' : 'تفعيل'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: balanceChangeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'المبلغ', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => changeBalance(true),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue),
                      child: const Text('إضافة رصيد'),
                    ),
                    ElevatedButton(
                      onPressed: () => changeBalance(false),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange),
                      child: const Text('خصم رصيد'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/account_summary',
                          arguments: user['id'],
                        );
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple),
                      child: const Text('كشف الحساب'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
