// lib/features/profile/screens/modern_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_widgets.dart';

class ModernProfileScreen extends StatefulWidget {
  const ModernProfileScreen({Key? key}) : super(key: key);

  @override
  _ModernProfileScreenState createState() => _ModernProfileScreenState();
}

class _ModernProfileScreenState extends State<ModernProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final driver = authService.currentDriver;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: 'My Profile',
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration:
            AppTheme.backgroundGradient != null
                ? const BoxDecoration(gradient: AppTheme.backgroundGradient)
                : null,
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _animationController,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.easeOutBack,
                    ),
                  ),
                  child: _buildContent(user, driver),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(user, driver) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      child: Column(
        children: [
          // Profile Header
          _buildProfileHeader(user, driver),

          const SizedBox(height: AppTheme.spacingLarge),

          // Account Information
          _buildAccountInfoCard(user),

          const SizedBox(height: AppTheme.spacingLarge),

          // Driver Information
          if (driver != null) ...[
            _buildDriverInfoCard(driver),
            const SizedBox(height: AppTheme.spacingLarge),
          ],

          // Settings and Actions
          _buildSettingsCard(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(user, driver) {
    return GlassCard(
      child: Column(
        children: [
          // Profile Picture with Status
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.goldGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGold.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    user?.name?.isNotEmpty == true
                        ? user!.name.substring(0, 1).toUpperCase()
                        : 'D',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (driver != null)
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color:
                          driver.isActive ? AppTheme.success : AppTheme.danger,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: (driver.isActive
                                  ? AppTheme.success
                                  : AppTheme.danger)
                              .withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      driver.isActive ? Icons.check : Icons.close,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingLarge),

          // Name and Email
          Text(
            user?.name ?? 'Driver',
            style: AppTheme.heading1.copyWith(fontSize: 24),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppTheme.spacingSmall),

          Text(
            user?.email ?? '',
            style: AppTheme.bodyLarge.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppTheme.spacingMedium),

          // Status Badge
          if (driver != null)
            StatusBadge(
              text: driver.isActive ? 'Active Driver' : 'Inactive',
              color: driver.isActive ? AppTheme.success : AppTheme.danger,
              icon: driver.isActive ? Icons.verified : Icons.pause_circle,
            ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoCard(user) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusMedium,
                  ),
                ),
                child: const Icon(
                  Icons.account_circle,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Text(
                'Account Information',
                style: AppTheme.heading3.copyWith(color: AppTheme.primaryRed),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingLarge),

          _buildInfoRow(
            icon: Icons.person,
            label: 'Full Name',
            value: user?.name ?? 'Not provided',
          ),

          const SizedBox(height: AppTheme.spacingMedium),

          _buildInfoRow(
            icon: Icons.email,
            label: 'Email Address',
            value: user?.email ?? 'Not provided',
          ),

          const SizedBox(height: AppTheme.spacingMedium),

          _buildInfoRow(
            icon: Icons.verified_user,
            label: 'Email Status',
            value: user?.emailVerifiedAt != null ? 'Verified' : 'Not Verified',
            valueColor:
                user?.emailVerifiedAt != null
                    ? AppTheme.success
                    : AppTheme.warning,
          ),

          const SizedBox(height: AppTheme.spacingMedium),

          _buildInfoRow(
            icon: Icons.calendar_today,
            label: 'Member Since',
            value:
                user?.emailVerifiedAt != null
                    ? '${user!.emailVerifiedAt!.day}/${user.emailVerifiedAt!.month}/${user.emailVerifiedAt!.year}'
                    : 'Unknown',
          ),
        ],
      ),
    );
  }

  Widget _buildDriverInfoCard(driver) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusMedium,
                  ),
                ),
                child: const Icon(
                  Icons.local_shipping,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Text(
                'Driver Information',
                style: AppTheme.heading3.copyWith(color: AppTheme.primaryGold),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingLarge),

          _buildInfoRow(
            icon: Icons.badge,
            label: 'License Number',
            value: driver.licenseNumber,
          ),

          const SizedBox(height: AppTheme.spacingMedium),

          _buildInfoRow(
            icon: Icons.phone,
            label: 'Phone Number',
            value: driver.phoneNumber,
          ),

          const SizedBox(height: AppTheme.spacingMedium),

          _buildInfoRow(
            icon: Icons.location_on,
            label: 'Address',
            value: driver.address ?? 'Not provided',
          ),

          const SizedBox(height: AppTheme.spacingMedium),

          _buildInfoRow(
            icon: Icons.circle,
            label: 'Driver Status',
            value:
                driver.status.substring(0, 1).toUpperCase() +
                driver.status.substring(1),
            valueColor: driver.isActive ? AppTheme.success : AppTheme.danger,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.info, AppTheme.info.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusMedium,
                  ),
                ),
                child: const Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Text(
                'Settings & Actions',
                style: AppTheme.heading3.copyWith(color: AppTheme.info),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingLarge),

          // Settings Options
          _buildSettingOption(
            icon: Icons.edit,
            title: 'Edit Profile',
            subtitle: 'Update your personal information',
            onTap: () {
              _showComingSoonDialog('Edit Profile');
            },
          ),

          const SizedBox(height: AppTheme.spacingMedium),

          _buildSettingOption(
            icon: Icons.lock,
            title: 'Change Password',
            subtitle: 'Update your account password',
            onTap: () {
              _showComingSoonDialog('Change Password');
            },
          ),

          const SizedBox(height: AppTheme.spacingMedium),

          _buildSettingOption(
            icon: Icons.notifications,
            title: 'Notification Settings',
            subtitle: 'Manage your notification preferences',
            onTap: () {
              _showComingSoonDialog('Notification Settings');
            },
          ),

          const SizedBox(height: AppTheme.spacingMedium),

          _buildSettingOption(
            icon: Icons.help,
            title: 'Help & Support',
            subtitle: 'Get assistance and contact support',
            onTap: () {
              _showComingSoonDialog('Help & Support');
            },
          ),

          const SizedBox(height: AppTheme.spacingMedium),

          _buildSettingOption(
            icon: Icons.info,
            title: 'About',
            subtitle: 'App version and information',
            onTap: () {
              _showAboutDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: AppTheme.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.bodyMedium.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
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

  Widget _buildSettingOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSmall),
                decoration: BoxDecoration(
                  color: AppTheme.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusSmall,
                  ),
                ),
                child: Icon(icon, color: AppTheme.info, size: 20),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          ),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.info),
              const SizedBox(width: AppTheme.spacingSmall),
              Text('Coming Soon'),
            ],
          ),
          content: Text(
            '$feature feature will be available in a future update.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK', style: TextStyle(color: AppTheme.primaryRed)),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_shipping,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              const Text('About'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Driver Tracking System', style: AppTheme.heading3),
              const SizedBox(height: AppTheme.spacingSmall),
              Text('Version 1.0.0'),
              const SizedBox(height: AppTheme.spacingMedium),
              Text(
                'A comprehensive solution for driver management and tracking.',
                style: AppTheme.bodyMedium,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(color: AppTheme.primaryRed),
              ),
            ),
          ],
        );
      },
    );
  }
}
