// lib/features/home/widgets/modern_app_drawer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_widgets.dart';
import '../screens/modern_home_screen.dart';
import '../../auth/screens/modern_login_screen.dart';
import '../../incidents/screens/modern_incident_history_screen.dart';
import '../../schedules/screens/modern_schedule_list_screen.dart';
import '../../notifications/screens/modern_notification_list_screen.dart';
import '../../profile/screens/modern_profile_screen.dart';

class ModernAppDrawer extends StatelessWidget {
  const ModernAppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final notificationService = Provider.of<NotificationService>(context);
    final user = authService.currentUser;
    final driver = authService.currentDriver;

    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF840016), Color(0xFF6B0012), Color(0xFF450009)],
          ),
        ),
        child: Column(
          children: [
            // Custom Header
            _buildDrawerHeader(user, driver),

            // Navigation Items
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMedium,
                ),
                child: Column(
                  children: [
                    _buildNavItem(
                      context,
                      icon: Icons.home_rounded,
                      title: 'Home',
                      onTap: () => _navigateToHome(context),
                    ),

                    _buildNavItem(
                      context,
                      icon: Icons.calendar_today_rounded,
                      title: 'Schedules',
                      onTap: () => _navigateToSchedules(context),
                    ),

                    _buildNavItem(
                      context,
                      icon: Icons.history_rounded,
                      title: 'Incident History',
                      onTap: () => _navigateToIncidentHistory(context),
                    ),

                    _buildNavItem(
                      context,
                      icon: Icons.notifications_rounded,
                      title: 'Notifications',
                      badge:
                          notificationService.unreadCount > 0
                              ? notificationService.unreadCount.toString()
                              : null,
                      onTap: () => _navigateToNotifications(context),
                    ),

                    _buildNavItem(
                      context,
                      icon: Icons.person_rounded,
                      title: 'Profile',
                      onTap: () => _navigateToProfile(context),
                    ),

                    const SizedBox(height: AppTheme.spacingMedium),

                    // Driver Status Section
                    if (driver != null) _buildDriverStatus(driver),

                    const Spacer(),

                    // Logout Button
                    _buildLogoutButton(context, authService),

                    // App Version
                    const SizedBox(height: AppTheme.spacingMedium),
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLarge),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(user, driver) {
    return Container(
      padding: const EdgeInsets.only(
        top: 60,
        left: AppTheme.spacingLarge,
        right: AppTheme.spacingLarge,
        bottom: AppTheme.spacingLarge,
      ),
      child: Column(
        children: [
          // Profile Picture
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.goldGradient,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGold.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                user?.name?.isNotEmpty == true
                    ? user!.name.substring(0, 1).toUpperCase()
                    : 'D',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacingMedium),

          // User Name
          Text(
            user?.name ?? 'Driver',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppTheme.spacingSmall),

          // User Email
          Text(
            user?.email ?? '',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),

          // Driver Status Badge
          if (driver != null) ...[
            const SizedBox(height: AppTheme.spacingMedium),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMedium,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color:
                    driver.isActive
                        ? AppTheme.success.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                border: Border.all(
                  color: driver.isActive ? AppTheme.success : Colors.grey,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: driver.isActive ? AppTheme.success : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSmall),
                  Text(
                    driver.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: driver.isActive ? AppTheme.success : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            onTap();
          },
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMedium,
              vertical: AppTheme.spacingMedium,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              color: Colors.white.withOpacity(0.1),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: AppTheme.spacingMedium),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.danger,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDriverStatus(driver) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Driver Info',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSmall),

          _buildInfoRow(Icons.badge, 'License: ${driver.licenseNumber}'),

          const SizedBox(height: AppTheme.spacingSmall),

          _buildInfoRow(Icons.phone, driver.phoneNumber),

          if (driver.address != null) ...[
            const SizedBox(height: AppTheme.spacingSmall),
            _buildInfoRow(Icons.location_on, driver.address!),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.7), size: 16),
        const SizedBox(width: AppTheme.spacingSmall),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthService authService) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            Navigator.pop(context);
            await authService.logout();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const ModernLoginScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: Colors.white, size: 20),
              SizedBox(width: AppTheme.spacingSmall),
              Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToHome(BuildContext context) {
    if (!(ModalRoute.of(context)?.settings.name == '/home')) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const ModernHomeScreen(),
          settings: const RouteSettings(name: '/home'),
        ),
      );
    }
  }

  void _navigateToSchedules(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ModernScheduleListScreen()),
    );
  }

  void _navigateToIncidentHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ModernIncidentHistoryScreen(),
      ),
    );
  }

  void _navigateToNotifications(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ModernNotificationListScreen(),
      ),
    );
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ProfileScreen()));
  }
}
