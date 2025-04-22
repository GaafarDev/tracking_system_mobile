import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/notification_service.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/incidents/screens/incident_history_screen.dart';
import '../../features/schedules/screens/schedule_list_screen.dart';
import '../../features/notifications/screens/notification_list_screen.dart';
import '../../features/profile/screens/profile_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final notificationService = Provider.of<NotificationService>(context);

    final user = authService.currentUser;
    final driver = authService.currentDriver;

    return Drawer(
      child: Column(
        children: [
          // User header
          UserAccountsDrawerHeader(
            accountName: Text(user?.name ?? 'Driver'),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user?.name?.isNotEmpty == true
                    ? user!.name.substring(0, 1).toUpperCase()
                    : 'D',
                style: TextStyle(
                  fontSize: 24,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
          ),

          // Drawer items
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              // If not on home screen, navigate to it
              if (!(ModalRoute.of(context)?.settings.name == '/home')) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const HomeScreen(),
                    settings: const RouteSettings(name: '/home'),
                  ),
                );
              }
            },
          ),

          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Schedules'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ScheduleListScreen(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Incident History'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const IncidentHistoryScreen(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.notifications),
            title: Row(
              children: [
                const Text('Notifications'),
                if (notificationService.unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      notificationService.unreadCount > 9
                          ? '9+'
                          : notificationService.unreadCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationListScreen(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),

          const Divider(),

          // Status info if driver information is available
          if (driver != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: driver.isActive ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Status: ${driver.status.substring(0, 1).toUpperCase()}${driver.status.substring(1)}',
                    style: TextStyle(
                      color: driver.isActive ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.badge, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'License: ${driver.licenseNumber}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.phone, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    driver.phoneNumber,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),

            const Divider(),
          ],

          // Logout button
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              await authService.logout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),

          // App version at the bottom
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
