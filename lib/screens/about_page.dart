import 'package:flutter/material.dart';
import '../widgets/main_scaffold.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'حول التطبيق',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
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
            const SizedBox(height: 16),
            const Text(
              'شهادة تأسيس الشركة والرقم الضريبي ورقم الضمان الاجتماعي',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'وثيقة صالحة',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'أسطول الفرات للتجارة العامة والنقل العام ونقل البضائع وخدمات التوصيل محدودة المسؤولية',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const ListTile(
              title: Text('صدر عن'),
              subtitle: Text('وزارة التجارة / دائرة تسجيل الشركات'),
            ),
            const ListTile(
              title: Text('الخدمة'),
              subtitle: Text('تسجيل شركة عراقية'),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                '© 2025 شركة أسطول الفرات',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
