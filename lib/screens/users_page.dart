import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // لإضافة Timer
import '../main.dart';
import '../widgets/main_scaffold.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> with TickerProviderStateMixin {
  List<dynamic> users = [];
  List<dynamic> activeUsers = [];
  List<dynamic> inactiveUsers = [];
  bool isLoading = true;
  bool isSearching = false;
  String searchQuery = '';

  final searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() => isLoading = true);
    try {
      String url = '$baseUrl/users';
      if (searchQuery.trim().isNotEmpty) {
        url += '?query=${Uri.encodeComponent(searchQuery.trim())}';
      }
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final fetchedUsers = json.decode(response.body)['users'];
        setState(() {
          users = fetchedUsers;
          activeUsers = users.where((u) => u['is_active'] == 1).toList();
          inactiveUsers = users.where((u) => u['is_active'] == 0).toList();
          isLoading = false;
        });
      } else {
        showError('فشل في جلب المستخدمين');
        setState(() => isLoading = false);
      }
    } catch (e) {
      showError('حدث خطأ أثناء الاتصال بالسيرفر');
      setState(() => isLoading = false);
    }
  }

  void onSearchChanged(String value) {
    searchQuery = value;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      fetchUsers();
    });
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget buildUserList(List<dynamic> usersList) {
    if (usersList.isEmpty) {
      return const Center(child: Text('لا يوجد مستخدمين في هذه القائمة'));
    }
    return RefreshIndicator(
      onRefresh: fetchUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: usersList.length,
        itemBuilder: (context, index) {
          final user = usersList[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(user['name'].toString().substring(0, 1)),
              ),
              title: Text(user['name']),
              subtitle: Text('${user['role']} | ${user['phone']}'),
              trailing: Icon(
                user['is_active'] == 1 ? Icons.check_circle : Icons.cancel,
                color: user['is_active'] == 1 ? Colors.green : Colors.red,
              ),
              onTap: () async {
                final result = await Navigator.pushNamed(
                  context,
                  '/user_details',
                  arguments: {'user_id': user['id']},
                );
                if (result == true) {
                  fetchUsers(); // إعادة تحميل المستخدمين عند الرجوع
                }
              },
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: MainScaffold(
        title: 'المستخدمين',
        isSearching: isSearching,
        onSearchChanged: (value) {
          searchQuery = value;
        },
        onSearchToggle: () {
          setState(() {
            isSearching = !isSearching;
            if (!isSearching) {
              searchController.clear();
              searchQuery = '';
              fetchUsers();
            }
          });
        },
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              fetchUsers();
            },
          ),
        ],
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: 'ابحث في جميع الحقول',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                ),
                onChanged: onSearchChanged,
              ),
            ),
            const TabBar(
              tabs: [
                Tab(text: 'النشطين'),
                Tab(text: 'غير النشطين'),
              ],
              indicatorColor: Colors.red,
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      children: [
                        buildUserList(activeUsers),
                        buildUserList(inactiveUsers),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
