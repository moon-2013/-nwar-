import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // للوصول إلى AppColors

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String name = 'شركة اسطول الفرات';
  String role = 'تاجر';
  String? profileImage;
  double balance = 0.0;
  int? userId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('name') ?? 'شركة اسطول الفرات';
      role = prefs.getString('role') ?? 'تاجر';
      profileImage = prefs.getString('profile_image');
      balance = prefs.getDouble('balance') ?? 0.0;
      userId = prefs.getInt('user_id');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.drawerStart, AppColors.drawerEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Directionality(
          // ⭐ أضفنا Directionality هنا
          textDirection: TextDirection.rtl,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: Colors.transparent),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipOval(
                      child: Container(
                        color: Colors.white, // خلفية بيضاء لو تحب
                        width: 75, // حجم صغير مثل اللوغو
                        height: 75,
                        child: Image.asset(
                          'assets/default_avatar.png',
                          fit: BoxFit.contain, // مهم: حتى ما يقص الصورة
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      name,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    Text(
                      'الدور: $role',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
              if (role == 'تاجر') ..._traderItems(context),
              if (role == 'الإدارة') ..._adminItems(context),
              const Divider(color: Colors.white),
              _drawerItem(context, Icons.logout, 'تسجيل الخروج', '/auth'),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _traderItems(BuildContext context) {
    return [
      _drawerItem(context, Icons.home, 'الرئيسية', '/home'),
      _drawerItem(context, Icons.shopping_cart, 'الطلبات', '/orders'),
      _drawerItem(context, Icons.notifications, 'الإشعارات', '/notifications'),
      _drawerItem(context, Icons.person, 'الملف الشخصي', '/user_details',
          userId: userId),
      _drawerItem(context, Icons.settings, 'الإعدادات', '/settings'),
      _drawerItem(context, Icons.info, 'حول التطبيق', '/about'),
    ];
  }

  List<Widget> _adminItems(BuildContext context) {
    return [
      _drawerItem(context, Icons.dashboard, 'لوحة التحكم', '/merchant'),
      _drawerItem(context, Icons.group, 'إدارة المستخدمين', '/manage_users'),
      _drawerItem(
          context, Icons.check_circle, 'ادارة الطلبات', '/admin_approval'),
      _drawerItem(context, Icons.receipt_long, 'السندات', '/bonds'),
      _drawerItem(context, Icons.person, 'الملف الشخصي', '/user_details',
          userId: userId),
      _drawerItem(context, Icons.settings, 'الإعدادات', '/settings'),
      _drawerItem(context, Icons.info, 'حول التطبيق', '/about'),
    ];
  }

  Widget _drawerItem(
      BuildContext context, IconData icon, String title, String route,
      {int? userId}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
        textAlign: TextAlign.right, // ⭐ تأكد من محاذاة النص يمينًا
      ),
      onTap: () {
        if (route == '/user_details' && userId != null) {
          Navigator.pushReplacementNamed(context, route,
              arguments: {'user_id': userId});
        } else {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }
}
