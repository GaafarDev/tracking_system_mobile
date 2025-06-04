// lib/features/incidents/screens/modern_incident_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/incident.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_widgets.dart';

class ModernIncidentDetailScreen extends StatefulWidget {
  final Incident incident;

  const ModernIncidentDetailScreen({Key? key, required this.incident})
    : super(key: key);

  @override
  _ModernIncidentDetailScreenState createState() =>
      _ModernIncidentDetailScreenState();
}

class _ModernIncidentDetailScreenState extends State<ModernIncidentDetailScreen>
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
    final incident = widget.incident;
    final dateFormat = DateFormat('MMMM d, yyyy • h:mm a');

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: 'Incident #${incident.id}',
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
                  child: _buildContent(incident, dateFormat),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Incident incident, DateFormat dateFormat) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          _buildHeaderCard(incident, dateFormat),

          const SizedBox(height: AppTheme.spacingLarge),

          // Photo Section
          if (incident.photoPath != null) ...[
            _buildPhotoSection(incident),
            const SizedBox(height: AppTheme.spacingLarge),
          ],

          // Description Section
          _buildDescriptionCard(incident),

          const SizedBox(height: AppTheme.spacingLarge),

          // Location Section
          _buildLocationCard(incident),

          const SizedBox(height: AppTheme.spacingLarge),

          // Resolution Section
          if (incident.isResolved) _buildResolutionCard(incident),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(Incident incident, DateFormat dateFormat) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    _buildIncidentTypeIcon(incident.type),
                    const SizedBox(width: AppTheme.spacingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            incident.displayType,
                            style: AppTheme.heading2.copyWith(fontSize: 20),
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
                  ],
                ),
              ),
              _buildIncidentStatusBadge(incident.status),
            ],
          ),

          const SizedBox(height: AppTheme.spacingMedium),

          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 20, color: AppTheme.primaryGold),
                const SizedBox(width: AppTheme.spacingSmall),
                Text(
                  'Reported on ${dateFormat.format(incident.createdAt)}',
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(Incident incident) {
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
                  Icons.photo_camera,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Text(
                'Incident Photo',
                style: AppTheme.heading3.copyWith(color: AppTheme.primaryGold),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingMedium),

          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            child: Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(
                  AppTheme.borderRadiusMedium,
                ),
              ),
              child: Image.network(
                // In a real app, you would build the full URL to the image
                'https://your-backend-url.com/storage/${incident.photoPath}',
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: AppTheme.spacingMedium),
                        Text(
                          'Photo not available',
                          style: AppTheme.bodyMedium.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[100],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            value:
                                loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                            color: AppTheme.primaryGold,
                          ),
                          const SizedBox(height: AppTheme.spacingMedium),
                          Text('Loading photo...', style: AppTheme.bodyMedium),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(Incident incident) {
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
                  Icons.description,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Text(
                'Description',
                style: AppTheme.heading3.copyWith(color: AppTheme.primaryRed),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingMedium),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              incident.description,
              style: AppTheme.bodyLarge.copyWith(height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(Incident incident) {
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
                  Icons.location_on,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Text(
                'Location Details',
                style: AppTheme.heading3.copyWith(color: AppTheme.info),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingMedium),

          Row(
            children: [
              Expanded(
                child: _buildLocationInfoCard(
                  'Latitude',
                  incident.latitude.toStringAsFixed(6),
                  Icons.my_location,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Expanded(
                child: _buildLocationInfoCard(
                  'Longitude',
                  incident.longitude.toStringAsFixed(6),
                  Icons.location_on,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingMedium),

          // Map placeholder
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.info.withOpacity(0.1),
                  AppTheme.primaryGold.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingLarge),
                  decoration: BoxDecoration(
                    gradient: AppTheme.goldGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.map, size: 40, color: Colors.white),
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                Text('Interactive Map', style: AppTheme.heading3),
                const SizedBox(height: AppTheme.spacingSmall),
                Text(
                  'Map integration coming soon',
                  style: AppTheme.bodyMedium.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppTheme.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppTheme.info.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.info, size: 24),
          const SizedBox(height: AppTheme.spacingSmall),
          Text(
            label,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.info),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              color: AppTheme.info,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionCard(Incident incident) {
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
                    colors: [
                      AppTheme.success,
                      AppTheme.success.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusMedium,
                  ),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Text(
                'Resolution',
                style: AppTheme.heading3.copyWith(color: AppTheme.success),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingMedium),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              border: Border.all(color: AppTheme.success.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.event_available,
                      color: AppTheme.success,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.spacingSmall),
                    Text(
                      'Resolved on ${DateFormat('MMMM d, yyyy').format(incident.resolvedAt!)}',
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),

                if (incident.resolutionNotes?.isNotEmpty == true) ...[
                  const SizedBox(height: AppTheme.spacingMedium),
                  const Divider(color: Colors.grey),
                  const SizedBox(height: AppTheme.spacingMedium),
                  Text(
                    'Resolution Notes:',
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.success,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  Text(
                    incident.resolutionNotes!,
                    style: AppTheme.bodyLarge.copyWith(height: 1.6),
                  ),
                ],
              ],
            ),
          ),
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
