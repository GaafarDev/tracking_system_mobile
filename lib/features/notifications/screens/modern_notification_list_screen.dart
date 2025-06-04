// lib/features/notifications/screens/modern_notification_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/models/app_notification.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_widgets.dart';

class ModernNotificationListScreen extends StatefulWidget {
  const ModernNotificationListScreen({Key? key}) : super(key: key);

  @override
  _ModernNotificationListScreenState createState() =>
      _ModernNotificationListScreenState();
}

class _ModernNotificationListScreenState
    extends State<ModernNotificationListScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  List<AppNotification> _notifications = [];
  String? _errorMessage;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadNotifications();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final notificationService = Provider.of<NotificationService>(
        context,
        listen: false,
      );
      final notifications = await notificationService.getNotifications();

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() {
        _errorMessage = 'Failed to load notifications. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (notification.isRead) return;

    try {
      final notificationService = Provider.of<NotificationService>(
        context,
        listen: false,
      );
      final success = await notificationService.markAsRead(notification.id);

      if (success) {
        setState(() {
          final index = _notifications.indexWhere(
            (n) => n.id == notification.id,
          );
          if (index != -1) {
            final updatedNotification = AppNotification(
              id: notification.id,
              userId: notification.userId,
              title: notification.title,
              message: notification.message,
              type: notification.type,
              isRead: true,
              readAt: DateTime.now(),
              createdAt: notification.createdAt,
              updatedAt: notification.updatedAt,
            );
            _notifications[index] = updatedNotification;
          }
        });

        _showCustomSnackBar('Notification marked as read', AppTheme.success);
      } else {
        _showCustomSnackBar(
          'Failed to mark notification as read',
          AppTheme.danger,
        );
      }
    } catch (e) {
      print('Error marking notification as read: $e');
      _showCustomSnackBar(
        'An error occurred. Please try again later.',
        AppTheme.danger,
      );
    }
  }

  Future<void> _markAllAsRead() async {
    final unreadNotifications = _notifications.where((n) => !n.isRead).toList();

    if (unreadNotifications.isEmpty) {
      _showCustomSnackBar('All notifications are already read', AppTheme.info);
      return;
    }

    for (final notification in unreadNotifications) {
      await _markAsRead(notification);
    }
  }

  void _showCustomSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == AppTheme.success
                  ? Icons.check_circle
                  : color == AppTheme.info
                  ? Icons.info
                  : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: AppTheme.spacingSmall),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        ),
        margin: const EdgeInsets.all(AppTheme.spacingMedium),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: 'Notifications',
        backgroundColor: Colors.transparent,
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusSmall,
                  ),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: const Icon(Icons.done_all, color: Colors.black87),
              ),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Icon(
                Icons.refresh,
                color: _isLoading ? Colors.grey : Colors.black87,
              ),
            ),
            onPressed: _isLoading ? null : _loadNotifications,
          ),
        ],
      ),
      body: Container(
        decoration:
            AppTheme.backgroundGradient != null
                ? const BoxDecoration(gradient: AppTheme.backgroundGradient)
                : null,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadNotifications,
            color: AppTheme.primaryRed,
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryRed),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingLarge),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.danger,
                        AppTheme.danger.withOpacity(0.8),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                Text(
                  'Something went wrong',
                  style: AppTheme.heading3,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingSmall),
                Text(
                  _errorMessage!,
                  style: AppTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingLarge),
                GradientButton(
                  text: 'Try Again',
                  onPressed: _loadNotifications,
                  icon: Icons.refresh,
                  width: 140,
                  height: 44,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingLarge),
                  decoration: BoxDecoration(
                    gradient: AppTheme.goldGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_off,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLarge),
                Text(
                  'No Notifications',
                  style: AppTheme.heading2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingSmall),
                Text(
                  'You\'re all caught up!\nNotifications will appear here when available.',
                  style: AppTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingLarge),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMedium,
                    vertical: AppTheme.spacingSmall,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      AppTheme.borderRadiusLarge,
                    ),
                    border: Border.all(
                      color: AppTheme.success.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppTheme.success,
                        size: 16,
                      ),
                      const SizedBox(width: AppTheme.spacingSmall),
                      Text(
                        'All caught up!',
                        style: TextStyle(
                          color: AppTheme.success,
                          fontWeight: FontWeight.w600,
                        ),
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

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          itemCount: _notifications.length,
          itemBuilder: (context, index) {
            final notification = _notifications[index];
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    index * 0.1,
                    (index * 0.1) + 0.5,
                    curve: Curves.easeOutBack,
                  ),
                ),
              ),
              child: FadeTransition(
                opacity: _animationController,
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
                  child: _buildNotificationCard(notification),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    final dateFormat = DateFormat.yMMMd().add_jm();

    return GlassCard(
      onTap: () => _markAsRead(notification),
      child: Container(
        decoration:
            notification.isRead
                ? null
                : BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusMedium,
                  ),
                  border: Border.all(
                    color: AppTheme.primaryRed.withOpacity(0.3),
                    width: 2,
                  ),
                ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  _buildNotificationIcon(notification.type),
                  const SizedBox(width: AppTheme.spacingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: AppTheme.heading3.copyWith(
                            fontSize: 16,
                            fontWeight:
                                notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(notification.createdAt),
                          style: AppTheme.bodyMedium.copyWith(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!notification.isRead)
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryRed.withOpacity(0.4),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: AppTheme.spacingMedium),

              // Message Content
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                decoration: BoxDecoration(
                  color:
                      notification.isRead
                          ? Colors.grey[50]
                          : AppTheme.primaryRed.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusSmall,
                  ),
                  border:
                      notification.isRead
                          ? null
                          : Border.all(
                            color: AppTheme.primaryRed.withOpacity(0.1),
                          ),
                ),
                child: Text(
                  notification.message,
                  style: AppTheme.bodyLarge.copyWith(
                    height: 1.5,
                    fontWeight:
                        notification.isRead
                            ? FontWeight.normal
                            : FontWeight.w500,
                  ),
                ),
              ),

              // Read Status Footer
              if (notification.isRead && notification.readAt != null) ...[
                const SizedBox(height: AppTheme.spacingSmall),
                Row(
                  children: [
                    Icon(Icons.done, size: 14, color: AppTheme.success),
                    const SizedBox(width: 4),
                    Text(
                      'Read on ${DateFormat.yMMMd().add_jm().format(notification.readAt!)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(String type) {
    IconData iconData;
    Gradient gradient;

    switch (type) {
      case 'schedule':
        iconData = Icons.calendar_today;
        gradient = LinearGradient(
          colors: [AppTheme.success, AppTheme.success.withOpacity(0.8)],
        );
        break;
      case 'weather':
        iconData = Icons.cloud;
        gradient = LinearGradient(
          colors: [AppTheme.info, AppTheme.info.withOpacity(0.8)],
        );
        break;
      case 'sos':
        iconData = Icons.emergency;
        gradient = LinearGradient(
          colors: [AppTheme.danger, AppTheme.danger.withOpacity(0.8)],
        );
        break;
      case 'incident':
        iconData = Icons.warning_amber;
        gradient = LinearGradient(
          colors: [AppTheme.warning, AppTheme.warning.withOpacity(0.8)],
        );
        break;
      default:
        iconData = Icons.notifications;
        gradient = LinearGradient(
          colors: [AppTheme.primaryGold, AppTheme.primaryGold.withOpacity(0.8)],
        );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(iconData, size: 24, color: Colors.white),
    );
  }
}
