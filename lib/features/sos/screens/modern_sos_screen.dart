// lib/features/sos/screens/modern_sos_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/sos_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/models/sos_alert.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_widgets.dart';

class ModernSosScreen extends StatefulWidget {
  const ModernSosScreen({Key? key}) : super(key: key);

  @override
  _ModernSosScreenState createState() => _ModernSosScreenState();
}

class _ModernSosScreenState extends State<ModernSosScreen>
    with TickerProviderStateMixin {
  final _messageController = TextEditingController();
  bool _isLoading = false;
  bool _isCheckingActive = true;
  SosAlert? _activeAlert;
  String? _errorMessage;

  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _checkForActiveAlert();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _checkForActiveAlert() async {
    setState(() {
      _isCheckingActive = true;
      _errorMessage = null;
    });

    try {
      final sosService = Provider.of<SosService>(context, listen: false);
      final activeAlert = await sosService.getActiveSosAlert();

      setState(() {
        _activeAlert = activeAlert;
        _isCheckingActive = false;
      });

      if (_activeAlert?.isActive == true) {
        _pulseController.repeat(reverse: true);
      }
    } catch (e) {
      print('Error checking active SOS alert: $e');
      setState(() {
        _errorMessage = 'Failed to check active alerts. Please try again.';
        _isCheckingActive = false;
      });
    }
  }

  Future<void> _sendSosAlert() async {
    if (_messageController.text.trim().isEmpty) {
      _shakeController.forward().then((_) => _shakeController.reverse());
      _showCustomSnackBar('Please enter a message', AppTheme.warning);
      return;
    }

    // Show immediate feedback
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Show optimistic UI immediately
    _showCustomSnackBar('Sending emergency alert...', AppTheme.info);

    try {
      final sosService = Provider.of<SosService>(context, listen: false);
      final locationService = Provider.of<LocationService>(
        context,
        listen: false,
      );

      // Initialize in parallel
      final futures = await Future.wait([
        locationService.initialize(),
        Future.delayed(Duration.zero), // Placeholder for any other init
      ]);

      final success = await sosService.sendSosAlert(
        _messageController.text.trim(),
      );

      if (success) {
        final alert = sosService.activeAlert;
        setState(() {
          _activeAlert = alert;
          _isLoading = false;
        });

        _pulseController.repeat(reverse: true);
        _showCustomSnackBar('✅ Emergency alert sent!', AppTheme.success);
      } else {
        setState(() {
          _errorMessage = 'Failed to send SOS alert. Please try again.';
          _isLoading = false;
        });
        _showCustomSnackBar('❌ Failed to send alert', AppTheme.danger);
      }
    } catch (e) {
      print('Error sending SOS alert: $e');
      setState(() {
        _errorMessage = 'Network error. Please check connection.';
        _isLoading = false;
      });
      _showCustomSnackBar('❌ Network error', AppTheme.danger);
    }
  }

  Future<void> _cancelSosAlert() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sosService = Provider.of<SosService>(context, listen: false);
      final success = await sosService.cancelSosAlert();

      if (success) {
        setState(() {
          _activeAlert = null;
          _isLoading = false;
        });

        _pulseController.stop();
        _showCustomSnackBar('SOS alert cancelled', AppTheme.info);
      } else {
        setState(() {
          _errorMessage = 'Failed to cancel SOS alert. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error cancelling SOS alert: $e');
      setState(() {
        _errorMessage = 'An error occurred. Please try again later.';
        _isLoading = false;
      });
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
                  : color == AppTheme.warning
                  ? Icons.warning
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
        title: 'Emergency SOS',
        backgroundColor: AppTheme.danger,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFDC3545), Color(0xFFC82333), Color(0xFFB21F2D)],
          ),
        ),
        child: SafeArea(
          child:
              _isCheckingActive
                  ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                  : _activeAlert != null
                  ? _buildActiveAlertView()
                  : _buildSendAlertView(),
        ),
      ),
    );
  }

  Widget _buildSendAlertView() {
    return LoadingOverlay(
      isLoading: _isLoading,
      message: 'Sending SOS Alert...',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          children: [
            const SizedBox(height: AppTheme.spacingXLarge),

            // Emergency Icon with Pulse Animation
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.emergency,
                      size: 60,
                      color: AppTheme.danger,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: AppTheme.spacingXLarge),

            // Title and Description
            const Text(
              'Emergency SOS',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppTheme.spacingMedium),

            Text(
              'Send an emergency alert to notify your emergency contacts and our support team.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppTheme.spacingXLarge),

            // Error Message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusMedium,
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.spacingSmall),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

            // Message Input with Shake Animation
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shakeAnimation.value, 0),
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spacingMedium),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadiusMedium,
                      ),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: TextField(
                      controller: _messageController,
                      maxLines: 4,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        hintText: 'Describe the emergency situation...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey[500]),
                      ),
                      style: AppTheme.bodyLarge,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: AppTheme.spacingXLarge),

            // SOS Button
            Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isLoading ? null : _sendSosAlert,
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusLarge,
                  ),
                  child: Center(
                    child:
                        _isLoading
                            ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: AppTheme.danger,
                                    strokeWidth: 3,
                                  ),
                                ),
                                SizedBox(width: AppTheme.spacingMedium),
                                Text(
                                  'SENDING...',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.danger,
                                  ),
                                ),
                              ],
                            )
                            : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.emergency,
                                  color: AppTheme.danger,
                                  size: 32,
                                ),
                                SizedBox(width: AppTheme.spacingMedium),
                                Text(
                                  'SEND SOS ALERT',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.danger,
                                  ),
                                ),
                              ],
                            ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacingLarge),

            // Warning Text
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  AppTheme.borderRadiusMedium,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    color: Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacingSmall),
                  Expanded(
                    child: Text(
                      'IMPORTANT: Only use this button in case of real emergencies',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveAlertView() {
    if (_activeAlert == null) return Container();

    return LoadingOverlay(
      isLoading: _isLoading,
      message: 'Updating SOS Alert...',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          children: [
            const SizedBox(height: AppTheme.spacingXLarge),

            // Pulsing Alert Icon
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.4),
                          blurRadius: 25,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications_active,
                      size: 60,
                      color: AppTheme.danger,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: AppTheme.spacingXLarge),

            // Status Title
            const Text(
              'SOS Alert Active',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppTheme.spacingMedium),

            // Status Badge
            _buildStatusBadge(_activeAlert!.status),

            const SizedBox(height: AppTheme.spacingXLarge),

            // Alert Details Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacingLarge),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(
                  AppTheme.borderRadiusMedium,
                ),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.message,
                        color: AppTheme.danger,
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.spacingSmall),
                      Text(
                        'Emergency Details',
                        style: AppTheme.heading3.copyWith(
                          color: AppTheme.danger,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMedium),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.spacingMedium),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadiusSmall,
                      ),
                    ),
                    child: Text(
                      _activeAlert!.message ?? 'No details provided',
                      style: AppTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingXLarge),

            // Status-specific content and actions
            if (_activeAlert!.isActive)
              ..._buildActiveAlertContent()
            else if (_activeAlert!.isResponded)
              ..._buildRespondedAlertContent()
            else if (_activeAlert!.isResolved)
              ..._buildResolvedAlertContent(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActiveAlertContent() {
    return [
      Container(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        ),
        child: Column(
          children: [
            const Icon(Icons.help_outline, color: Colors.white, size: 32),
            const SizedBox(height: AppTheme.spacingMedium),
            const Text(
              'Help is on the way',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              'Stay calm and wait for assistance. Our support team has been notified of your emergency.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),

      const SizedBox(height: AppTheme.spacingXLarge),

      // Cancel Button
      Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isLoading ? null : _cancelSosAlert,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            child: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cancel, color: Colors.white, size: 20),
                  SizedBox(width: AppTheme.spacingSmall),
                  Text(
                    'CANCEL SOS ALERT',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      const SizedBox(height: AppTheme.spacingMedium),

      Text(
        'Only cancel if the emergency has been resolved',
        style: TextStyle(
          fontSize: 12,
          color: Colors.white.withOpacity(0.7),
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    ];
  }

  List<Widget> _buildRespondedAlertContent() {
    return [
      Container(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        ),
        child: Column(
          children: [
            const Icon(Icons.support_agent, color: Colors.white, size: 32),
            const SizedBox(height: AppTheme.spacingMedium),
            const Text(
              'Support Team Responded',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              'Our support team has responded to your alert and assistance is on the way.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildResolvedAlertContent() {
    return [
      Container(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        ),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 32),
            const SizedBox(height: AppTheme.spacingMedium),
            const Text(
              'Emergency Resolved',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              'Your emergency has been resolved. Thank you for your patience.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),

      const SizedBox(height: AppTheme.spacingXLarge),

      // New Alert Button
      Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: AppTheme.goldGradient,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGold.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _activeAlert = null;
                _messageController.clear();
              });
              _pulseController.stop();
            },
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            child: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Colors.white, size: 20),
                  SizedBox(width: AppTheme.spacingSmall),
                  Text(
                    'CREATE NEW ALERT',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color iconColor;
    String displayText;
    IconData iconData;

    switch (status) {
      case 'active':
        backgroundColor = Colors.white.withOpacity(0.2);
        iconColor = Colors.white;
        displayText = 'ACTIVE';
        iconData = Icons.error_outline;
        break;
      case 'responded':
        backgroundColor = Colors.orange.withOpacity(0.2);
        iconColor = Colors.orange[100]!;
        displayText = 'SUPPORT RESPONDED';
        iconData = Icons.support_agent;
        break;
      case 'resolved':
        backgroundColor = Colors.green.withOpacity(0.2);
        iconColor = Colors.green[100]!;
        displayText = 'RESOLVED';
        iconData = Icons.check_circle_outline;
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.2);
        iconColor = Colors.grey[100]!;
        displayText = status.toUpperCase();
        iconData = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLarge,
        vertical: AppTheme.spacingMedium,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        border: Border.all(color: iconColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 20, color: iconColor),
          const SizedBox(width: AppTheme.spacingSmall),
          Text(
            displayText,
            style: TextStyle(
              color: iconColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
