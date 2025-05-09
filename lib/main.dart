import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth_page.dart';
import 'screens/home_page.dart';
import 'screens/merchant_page.dart';
import 'screens/preparer_page.dart';
import 'screens/orders_page.dart';
import 'widgets/main_scaffold.dart';
import 'screens/saerch.dart';
import 'screens/order_details_page.dart';
import 'screens/manage_orders_page.dart';
import 'screens/notifications_page.dart';
import 'screens/users_page.dart';
import 'screens/user_details_pages.dart'; // عدّلنا الاسم هنا
import 'screens/waiting_page.dart';
import 'screens/ForgotPasswordPage.dart';

import 'screens/admin_approval_page.dart             ';

import 'screens/account_summary_page.dart';

import 'screens/bonds_page.dart';

import 'screens/about_page.dart     ';

const String baseUrl = 'http://127.0.0.1:5000';

ValueNotifier<double> balanceNotifier = ValueNotifier(0.0);

void main() => runApp(const MyApp());

class AppColors {
  static const Color primary = Colors.red;
  static const Color accent = Color(0xFFEDB637);
  static const Color backgroundDark = Color.fromARGB(255, 71, 59, 59);
  static const Color backgroundLight = Colors.white;
  static const Color label = Colors.red;
  static const Color drawerStart = Colors.red;
  static const Color drawerEnd = Colors.black;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'شركة أسطول الفرات',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Tajawal',
        scaffoldBackgroundColor: AppColors.backgroundLight,
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accent,
          background: AppColors.backgroundLight,
        ),
      ),
      routes: {
        '/': (_) => const SessionChecker(),
        '/auth': (_) => AuthPage(),
        '/home': (_) => const HomeScreen(),
        '/merchant': (_) => MerchantPage(userId: 1),
        '/preparer': (_) => const PreparerPage(),
        '/orders': (_) => const DeliveriesScreen(),
        '/notifications': (_) => NotificationsPage(),
        '/search': (_) => const SearchPage(),

        '/bonds': (_) => const BondsPage(),

        '/user_details': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args == null || args is! Map<String, dynamic>) {
            return Scaffold(
              body: Center(child: Text('لا توجد بيانات لهذا المستخدم')),
            );
          }
          return UserProfilePage(userId: args['user_id']);
        },
        '/market': (_) => const PlaceholderScreen(title: 'السوق'),
        '/settings': (_) => const PlaceholderScreen(title: 'الإعدادات'),
        '/about': (_) => const AboutPage(),
        '/order_details': (context) => OrderDetailsPage(),
        '/manage_orders': (_) => const ManageOrdersPage(),
        '/manage_users': (_) => const UsersPage(),
        '/waiting': (_) => WaitingPage(),
        '/forgot-password': (_) => ForgotPasswordPage(),

        '/admin_approval': (_) => AdminApprovalPage(),

        '/account_summary': (context) {
          final userId = ModalRoute.of(context)!.settings.arguments as int;
          return AccountSummaryPage(userId: userId);
        },
        // باقي المسارات..
        //
        //
      },
    );
  }
}

class SessionChecker extends StatefulWidget {
  const SessionChecker({super.key});

  @override
  State<SessionChecker> createState() => _SessionCheckerState();
}

class _SessionCheckerState extends State<SessionChecker> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('loggedIn') ?? false;
    final role = prefs.getString('role');
    final isActive = prefs.getBool('is_active') ?? false;
    final userId = prefs.getInt('user_id');

    if (isLoggedIn && role != null) {
      if (!isActive) {
        Navigator.pushReplacementNamed(context, '/waiting');
      } else if (role == 'تاجر') {
        Navigator.pushReplacementNamed(context, '/home');
      } else if (role == 'الإدارة') {
        Navigator.pushReplacementNamed(context, '/merchant');
      } else if (role == 'مندوب تجهيز') {
        Navigator.pushReplacementNamed(context, '/preparer');
      } else if (role == 'مندوب توصيل') {
        Navigator.pushReplacementNamed(context, '/orders');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class PlaceholderScreen extends StatefulWidget {
  final String title;
  const PlaceholderScreen({required this.title, super.key});

  @override
  State<PlaceholderScreen> createState() => _PlaceholderScreenState();
}

class _PlaceholderScreenState extends State<PlaceholderScreen> {
  double balance = 0.0;

  @override
  void initState() {
    super.initState();
    loadBalance();
  }

  Future<void> loadBalance() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      balance = prefs.getDouble('balance') ?? 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: widget.title,
      child: Center(
        child: Text(
          'صفحة ${widget.title} قيد التطوير',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
