// lib/features/schedules/screens/modern_schedule_detail_screen.dart
import 'package:flutter/material.dart' hide Route;
import 'package:provider/provider.dart';
import '../../../core/models/schedule.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_widgets.dart';

class ModernScheduleDetailScreen extends StatefulWidget {
  final Schedule schedule;

  const ModernScheduleDetailScreen({Key? key, required this.schedule})
    : super(key: key);

  @override
  _ModernScheduleDetailScreenState createState() =>
      _ModernScheduleDetailScreenState();
}

class _ModernScheduleDetailScreenState extends State<ModernScheduleDetailScreen>
    with TickerProviderStateMixin {
  bool _showMap = false;
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
    final schedule = widget.schedule;
    final route = schedule.route;
    final vehicle = schedule.vehicle;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: 'Schedule Details',
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
                  child: _buildContent(schedule, route, vehicle),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Schedule schedule, Route? route, Vehicle? vehicle) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          _buildHeaderCard(schedule),

          const SizedBox(height: AppTheme.spacingLarge),

          // Route Information
          _buildRouteCard(schedule, route),

          const SizedBox(height: AppTheme.spacingLarge),

          // Vehicle Information
          _buildVehicleCard(vehicle),

          const SizedBox(height: AppTheme.spacingLarge),

          // Route Stops
          if (route?.stops != null && route!.stops!.isNotEmpty)
            _buildStopsCard(route),

          const SizedBox(height: AppTheme.spacingLarge),

          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(Schedule schedule) {
    return GlassCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMedium,
                  vertical: AppTheme.spacingSmall,
                ),
                decoration: BoxDecoration(
                  gradient:
                      schedule.isToday
                          ? AppTheme.primaryGradient
                          : AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusLarge,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today, color: Colors.white, size: 16),
                    const SizedBox(width: AppTheme.spacingSmall),
                    Text(
                      schedule.displayDay,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                text: schedule.isActive ? 'Active' : 'Inactive',
                color: schedule.isActive ? AppTheme.success : AppTheme.danger,
                icon: schedule.isActive ? Icons.check_circle : Icons.cancel,
              ),
            ],
          ),

          if (schedule.isToday) ...[
            const SizedBox(height: AppTheme.spacingMedium),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              decoration: BoxDecoration(
                gradient: AppTheme.goldGradient,
                borderRadius: BorderRadius.circular(
                  AppTheme.borderRadiusMedium,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.today, color: Colors.white, size: 20),
                  const SizedBox(width: AppTheme.spacingSmall),
                  Text(
                    'Today\'s Schedule',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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

  Widget _buildRouteCard(Schedule schedule, Route? route) {
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
                child: const Icon(Icons.route, color: Colors.white, size: 24),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Route Information',
                      style: AppTheme.heading3.copyWith(
                        color: AppTheme.primaryRed,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      route?.name ?? 'Route #${schedule.routeId}',
                      style: AppTheme.heading2.copyWith(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (route?.description != null) ...[
            const SizedBox(height: AppTheme.spacingMedium),
            Text(route!.description!, style: AppTheme.bodyLarge),
          ],

          const SizedBox(height: AppTheme.spacingLarge),

          // Time Information
          Row(
            children: [
              Expanded(
                child: _buildTimeCard(
                  'Departure',
                  schedule.departureTime,
                  Icons.departure_board,
                  AppTheme.info,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Expanded(
                child: _buildTimeCard(
                  'Arrival',
                  schedule.arrivalTime,
                  Icons.flag,
                  AppTheme.success,
                ),
              ),
            ],
          ),

          if (route != null) ...[
            const SizedBox(height: AppTheme.spacingMedium),
            Row(
              children: [
                if (route.distanceKm != null)
                  Expanded(
                    child: _buildInfoItem(
                      Icons.straighten,
                      'Distance',
                      '${route.distanceKm!.toStringAsFixed(1)} km',
                      AppTheme.primaryGold,
                    ),
                  ),
                if (route.distanceKm != null &&
                    route.estimatedDurationMinutes != null)
                  const SizedBox(width: AppTheme.spacingMedium),
                if (route.estimatedDurationMinutes != null)
                  Expanded(
                    child: _buildInfoItem(
                      Icons.timer,
                      'Duration',
                      route.formattedDuration,
                      AppTheme.warning,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeCard(String label, String time, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppTheme.spacingSmall),
          Text(label, style: AppTheme.bodyMedium.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(
            time,
            style: AppTheme.heading3.copyWith(color: color, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Vehicle? vehicle) {
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
                  Icons.directions_car,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Text(
                'Vehicle Information',
                style: AppTheme.heading3.copyWith(color: AppTheme.primaryGold),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingLarge),

          if (vehicle != null) ...[
            Text(
              vehicle.displayName,
              style: AppTheme.heading2.copyWith(fontSize: 18),
            ),
            const SizedBox(height: AppTheme.spacingMedium),

            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.category,
                    'Type',
                    vehicle.type.substring(0, 1).toUpperCase() +
                        vehicle.type.substring(1),
                    AppTheme.info,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMedium),
                Expanded(
                  child: _buildInfoItem(
                    Icons.people,
                    'Capacity',
                    '${vehicle.capacity} seats',
                    AppTheme.success,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingMedium),

            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.confirmation_number,
                    'Plate Number',
                    vehicle.plateNumber,
                    AppTheme.primaryRed,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMedium),
                Expanded(
                  child: _buildInfoItem(
                    Icons.circle,
                    'Status',
                    vehicle.status.substring(0, 1).toUpperCase() +
                        vehicle.status.substring(1),
                    vehicle.isActive ? AppTheme.success : AppTheme.danger,
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingLarge),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(
                  AppTheme.borderRadiusMedium,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[600]),
                  const SizedBox(width: AppTheme.spacingMedium),
                  Text(
                    'Vehicle information not available',
                    style: AppTheme.bodyLarge.copyWith(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
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

  Widget _buildStopsCard(Route route) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      Icons.place,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMedium),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Route Stops',
                        style: AppTheme.heading3.copyWith(
                          color: AppTheme.primaryRed,
                        ),
                      ),
                      Text(
                        '${route.stops!.length} stops',
                        style: AppTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
              GradientButton(
                text: _showMap ? 'List' : 'Map',
                onPressed: () {
                  setState(() {
                    _showMap = !_showMap;
                  });
                },
                icon: _showMap ? Icons.list : Icons.map,
                width: 80,
                height: 36,
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingLarge),

          _showMap ? _buildRouteMap(route) : _buildStopsList(route),
        ],
      ),
    );
  }

  Widget _buildRouteMap(Route route) {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGold.withOpacity(0.1),
            AppTheme.primaryRed.withOpacity(0.1),
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
    );
  }

  Widget _buildStopsList(Route route) {
    return Column(
      children:
          route.stops!.asMap().entries.map((entry) {
            final index = entry.key;
            final stop = entry.value;
            final isFirst = index == 0;
            final isLast = index == route.stops!.length - 1;

            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient:
                                isFirst
                                    ? AppTheme.primaryGradient
                                    : isLast
                                    ? const LinearGradient(
                                      colors: [
                                        AppTheme.success,
                                        AppTheme.success,
                                      ],
                                    )
                                    : AppTheme.goldGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (isFirst
                                        ? AppTheme.primaryRed
                                        : isLast
                                        ? AppTheme.success
                                        : AppTheme.primaryGold)
                                    .withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Center(
                            child:
                                isFirst
                                    ? const Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                    : isLast
                                    ? const Icon(
                                      Icons.flag,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                    : Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppTheme.primaryGold.withOpacity(0.8),
                                  AppTheme.primaryGold.withOpacity(0.3),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: AppTheme.spacingMedium),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(AppTheme.spacingMedium),
                        decoration: BoxDecoration(
                          color: (isFirst
                                  ? AppTheme.primaryRed
                                  : isLast
                                  ? AppTheme.success
                                  : AppTheme.primaryGold)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadiusMedium,
                          ),
                          border: Border.all(
                            color: (isFirst
                                    ? AppTheme.primaryRed
                                    : isLast
                                    ? AppTheme.success
                                    : AppTheme.primaryGold)
                                .withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isFirst
                                      ? Icons.departure_board
                                      : isLast
                                      ? Icons.flag_outlined
                                      : Icons.location_on,
                                  size: 16,
                                  color:
                                      isFirst
                                          ? AppTheme.primaryRed
                                          : isLast
                                          ? AppTheme.success
                                          : AppTheme.primaryGold,
                                ),
                                const SizedBox(width: AppTheme.spacingSmall),
                                Expanded(
                                  child: Text(
                                    stop['name'] ??
                                        '${isFirst
                                            ? 'Start'
                                            : isLast
                                            ? 'End'
                                            : 'Stop'} ${index + 1}',
                                    style: AppTheme.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color:
                                          isFirst
                                              ? AppTheme.primaryRed
                                              : isLast
                                              ? AppTheme.success
                                              : AppTheme.primaryGold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (stop['lat'] != null && stop['lng'] != null) ...[
                              const SizedBox(height: AppTheme.spacingSmall),
                              Text(
                                'Lat: ${stop['lat']}, Lng: ${stop['lng']}',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: Colors.grey[600],
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (!isLast) const SizedBox(height: AppTheme.spacingSmall),
              ],
            );
          }).toList(),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GradientButton(
                text: 'Start Navigation',
                onPressed: () {
                  _showCustomSnackBar(
                    'Navigation feature coming soon',
                    AppTheme.info,
                  );
                },
                icon: Icons.navigation,
                gradient: AppTheme.primaryGradient,
                height: 56,
              ),
            ),
            const SizedBox(width: AppTheme.spacingMedium),
            Expanded(
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.warning),
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusMedium,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _showCustomSnackBar(
                        'Report issue feature coming soon',
                        AppTheme.warning,
                      );
                    },
                    borderRadius: BorderRadius.circular(
                      AppTheme.borderRadiusMedium,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.report_problem, color: AppTheme.warning),
                        const SizedBox(width: AppTheme.spacingSmall),
                        Text(
                          'Report Issue',
                          style: TextStyle(
                            color: AppTheme.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppTheme.spacingSmall),
          Text(
            label,
            style: AppTheme.bodyMedium.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showCustomSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == AppTheme.info ? Icons.info : Icons.warning,
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
}
