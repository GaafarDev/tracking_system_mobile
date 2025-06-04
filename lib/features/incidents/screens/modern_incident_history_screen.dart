// lib/features/incidents/screens/modern_incident_history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/services/incident_service.dart';
import '../../../core/models/incident.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_widgets.dart';
import 'modern_incident_detail_screen.dart';

class ModernIncidentHistoryScreen extends StatefulWidget {
  const ModernIncidentHistoryScreen({Key? key}) : super(key: key);

  @override
  _ModernIncidentHistoryScreenState createState() =>
      _ModernIncidentHistoryScreenState();
}

class _ModernIncidentHistoryScreenState
    extends State<ModernIncidentHistoryScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  List<Incident> _incidents = [];
  String? _errorMessage;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadIncidents();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadIncidents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final incidentService = Provider.of<IncidentService>(
        context,
        listen: false,
      );
      final incidents = await incidentService.getIncidentHistory();

      setState(() {
        _incidents = incidents;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading incidents: $e');
      setState(() {
        _errorMessage = 'Failed to load incidents. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _navigateToIncidentDetail(Incident incident) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                ModernIncidentDetailScreen(incident: incident),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: 'Incident History',
        backgroundColor: Colors.transparent,
        actions: [
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
            onPressed: _isLoading ? null : _loadIncidents,
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
            onRefresh: _loadIncidents,
            color: AppTheme.primaryRed,
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _incidents.isEmpty) {
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
                  'Oops! Something went wrong',
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
                  onPressed: _loadIncidents,
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

    if (_incidents.isEmpty) {
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
                    Icons.history,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLarge),
                Text(
                  'No Incidents Yet',
                  style: AppTheme.heading2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingSmall),
                Text(
                  'Your incident reports will appear here.\nStay safe on the road!',
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
                        'All good so far!',
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
          itemCount: _incidents.length,
          itemBuilder: (context, index) {
            final incident = _incidents[index];
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
                  child: _buildIncidentCard(incident),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildIncidentCard(Incident incident) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    return GlassCard(
      onTap: () => _navigateToIncidentDetail(incident),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              _buildIncidentTypeIcon(incident.type),
              const SizedBox(width: AppTheme.spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      incident.displayType,
                      style: AppTheme.heading3.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Incident #${incident.id}',
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              _buildIncidentStatusBadge(incident.status),
            ],
          ),

          const SizedBox(height: AppTheme.spacingMedium),

          // Description
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            ),
            child: Text(
              incident.description,
              style: AppTheme.bodyLarge,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: AppTheme.spacingMedium),

          // Footer Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(incident.createdAt),
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (incident.photoPath != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingSmall,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadiusSmall,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.photo, size: 12, color: AppTheme.info),
                          const SizedBox(width: 4),
                          Text(
                            'Photo',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.info,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSmall),
                  ],
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),

          // Resolution info if resolved
          if (incident.isResolved && incident.resolvedAt != null) ...[
            const SizedBox(height: AppTheme.spacingMedium),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  AppTheme.borderRadiusMedium,
                ),
                border: Border.all(color: AppTheme.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppTheme.success, size: 16),
                  const SizedBox(width: AppTheme.spacingSmall),
                  Text(
                    'Resolved on ${DateFormat('MMM d, yyyy').format(incident.resolvedAt!)}',
                    style: TextStyle(
                      color: AppTheme.success,
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

  Widget _buildIncidentTypeIcon(String type) {
    IconData iconData;
    Gradient gradient;

    switch (type) {
      case 'accident':
        iconData = Icons.car_crash;
        gradient = LinearGradient(
          colors: [AppTheme.danger, AppTheme.danger.withOpacity(0.8)],
        );
        break;
      case 'breakdown':
        iconData = Icons.build_circle;
        gradient = LinearGradient(
          colors: [AppTheme.warning, AppTheme.warning.withOpacity(0.8)],
        );
        break;
      case 'road_obstruction':
        iconData = Icons.warning_amber;
        gradient = LinearGradient(
          colors: [Colors.orange, Colors.orange.withOpacity(0.8)],
        );
        break;
      case 'weather':
        iconData = Icons.cloud;
        gradient = LinearGradient(
          colors: [AppTheme.info, AppTheme.info.withOpacity(0.8)],
        );
        break;
      default:
        iconData = Icons.error;
        gradient = LinearGradient(
          colors: [Colors.grey, Colors.grey.withOpacity(0.8)],
        );
    }

    return Container(
      width: 56,
      height: 56,
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
      child: Icon(iconData, size: 28, color: Colors.white),
    );
  }

  Widget _buildIncidentStatusBadge(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case 'reported':
        color = AppTheme.danger;
        icon = Icons.report_problem;
        break;
      case 'in_progress':
        color = AppTheme.warning;
        icon = Icons.pending;
        break;
      case 'resolved':
        color = AppTheme.info;
        icon = Icons.task_alt;
        break;
      case 'closed':
        color = AppTheme.success;
        icon = Icons.check_circle;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return StatusBadge(
      text: status
          .split('_')
          .map((word) => word.substring(0, 1).toUpperCase() + word.substring(1))
          .join(' '),
      color: color,
      icon: icon,
    );
  }
}
