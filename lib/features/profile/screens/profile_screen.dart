import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../auth/screens/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final driver = authService.currentDriver;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header with user info
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      user?.name?.isNotEmpty == true
                          ? user!.name.substring(0, 1).toUpperCase()
                          : 'D',
                      style: TextStyle(
                        fontSize: 40,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? 'Driver',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Driver info
            if (driver != null) ...[
              const Text(
                'Driver Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              _buildInfoItem(
                icon: Icons.badge,
                label: 'License Number',
                value: driver.licenseNumber,
              ),

              const Divider(),

              _buildInfoItem(
                icon: Icons.phone,
                label: 'Phone Number',
                value: driver.phoneNumber,
              ),

              const Divider(),

              _buildInfoItem(
                icon: Icons.location_on,
                label: 'Address',
                value: driver.address ?? 'Not provided',
              ),

              const Divider(),

              _buildInfoItem(
                icon: Icons.verified_user,
                label: 'Status',
                value:
                    driver.status.substring(0, 1).toUpperCase() +
                    driver.status.substring(1),
                valueColor: driver.isActive ? Colors.green : Colors.red,
              ),

              const SizedBox(height: 32),
            ],

            // Actions section
            const Text(
              'Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Logout button
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => _handleLogout(context),
              ),
            ),

            const SizedBox(height: 16),

            // App info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'Tracking System Mobile',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Logout'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.logout();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}
