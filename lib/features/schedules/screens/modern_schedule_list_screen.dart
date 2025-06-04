// lib/features/schedules/screens/modern_schedule_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/services/schedule_service.dart';
import '../../../core/models/schedule.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_widgets.dart';
import 'modern_schedule_detail_screen.dart';

class ModernScheduleListScreen extends StatefulWidget {
  const ModernScheduleListScreen({Key? key}) : super(key: key);

  @override
  _ModernScheduleListScreenState createState() =>
      _ModernScheduleListScreenState();
}

class _ModernScheduleListScreenState extends State<ModernScheduleListScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  List<Schedule> _schedules = [];
  String? _errorMessage;
  late TabController _tabController;
  late AnimationController _animationController;

  final List<String> _days = [
    'All',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _days.length, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Select today's tab by default
    final today = DateTime.now().weekday;
    if (today >= 1 && today <= 7) {
      _tabController.index = today;
    }

    _loadSchedules();
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSchedules() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final scheduleService = Provider.of<ScheduleService>(
        context,
        listen: false,
      );
      final schedules = await scheduleService.getSchedules();

      setState(() {
        _schedules = schedules;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading schedules: $e');
      setState(() {
        _errorMessage = 'Failed to load schedules. Please try again.';
        _isLoading = false;
      });
    }
  }

  List<Schedule> _getFilteredSchedules(String day) {
    if (day == 'All') {
      return _schedules;
    }
    return _schedules
        .where(
          (schedule) => schedule.dayOfWeek.toLowerCase() == day.toLowerCase(),
        )
        .toList();
  }

  void _navigateToScheduleDetail(Schedule schedule) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                ModernScheduleDetailScreen(schedule: schedule),
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
        title: 'My Schedules',
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
            onPressed: _isLoading ? null : _loadSchedules,
          ),
        ],
      ),
      body: Container(
        decoration:
            AppTheme.backgroundGradient != null
                ? const BoxDecoration(gradient: AppTheme.backgroundGradient)
                : null,
        child: Column(
          children: [
            // Custom Tab Bar
            Container(
              margin: const EdgeInsets.only(
                top: kToolbarHeight + 60,
                left: AppTheme.spacingMedium,
                right: AppTheme.spacingMedium,
              ),
              child: GlassCard(
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicator: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(
                      AppTheme.borderRadiusSmall,
                    ),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.black54,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 14,
                  ),
                  tabs:
                      _days
                          .map(
                            (day) => Tab(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(day),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
            ),

            // Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadSchedules,
                color: AppTheme.primaryRed,
                child: TabBarView(
                  controller: _tabController,
                  children:
                      _days.map((day) => _buildScheduleList(day)).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleList(String day) {
    if (_isLoading && _schedules.isEmpty) {
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
                Icon(Icons.error_outline, size: 48, color: AppTheme.danger),
                const SizedBox(height: AppTheme.spacingMedium),
                Text(
                  _errorMessage!,
                  style: AppTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                GradientButton(
                  text: 'Retry',
                  onPressed: _loadSchedules,
                  width: 120,
                  height: 40,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final filteredSchedules = _getFilteredSchedules(day);

    if (filteredSchedules.isEmpty) {
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
                    Icons.calendar_today,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                Text(
                  day == 'All'
                      ? 'No schedules assigned yet'
                      : 'No schedules for $day',
                  style: AppTheme.heading3,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingSmall),
                Text(
                  'Your schedules will appear here once assigned.',
                  style: AppTheme.bodyMedium,
                  textAlign: TextAlign.center,
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
          itemCount: filteredSchedules.length,
          itemBuilder: (context, index) {
            final schedule = filteredSchedules[index];
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
                  child: _buildScheduleCard(schedule),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildScheduleCard(Schedule schedule) {
    final isToday = schedule.isToday;

    return GlassCard(
      onTap: () => _navigateToScheduleDetail(schedule),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMedium,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: isToday ? AppTheme.primaryGradient : null,
                      color: isToday ? null : Colors.grey[100],
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadiusLarge,
                      ),
                    ),
                    child: Text(
                      schedule.displayDay,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isToday ? Colors.white : Colors.grey[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (isToday) ...[
                    const SizedBox(width: AppTheme.spacingSmall),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingSmall,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppTheme.goldGradient,
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadiusSmall,
                        ),
                      ),
                      child: const Text(
                        'TODAY',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              StatusBadge(
                text: schedule.isActive ? 'Active' : 'Inactive',
                color: schedule.isActive ? AppTheme.success : AppTheme.danger,
                icon: schedule.isActive ? Icons.check_circle : Icons.cancel,
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingMedium),

          // Route Information
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSmall),
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusSmall,
                  ),
                ),
                child: const Icon(Icons.route, color: Colors.white, size: 20),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.route?.name ?? 'Route #${schedule.routeId}',
                      style: AppTheme.heading3.copyWith(fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (schedule.route?.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        schedule.route!.description!,
                        style: AppTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingMedium),

          // Time and Details Row
          Row(
            children: [
              Expanded(
                child: _buildInfoChip(
                  icon: Icons.schedule,
                  label: schedule.timeRange,
                  color: AppTheme.info,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              if (schedule.vehicle != null)
                Expanded(
                  child: _buildInfoChip(
                    icon: Icons.directions_car,
                    label: schedule.vehicle!.plateNumber,
                    color: AppTheme.primaryGold,
                  ),
                ),
            ],
          ),

          if (schedule.route?.stopCount != null &&
              schedule.route!.stopCount > 0) ...[
            const SizedBox(height: AppTheme.spacingSmall),
            _buildInfoChip(
              icon: Icons.place,
              label: '${schedule.route!.stopCount} stops',
              color: Colors.grey[600]!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSmall,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
