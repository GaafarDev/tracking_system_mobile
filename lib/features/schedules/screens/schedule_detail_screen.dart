import 'package:flutter/material.dart' hide Route;
import 'package:provider/provider.dart';
import '../../../core/models/schedule.dart';
import '../../../core/services/location_service.dart';

class ScheduleDetailScreen extends StatefulWidget {
  final Schedule schedule;

  const ScheduleDetailScreen({Key? key, required this.schedule})
    : super(key: key);

  @override
  _ScheduleDetailScreenState createState() => _ScheduleDetailScreenState();
}

class _ScheduleDetailScreenState extends State<ScheduleDetailScreen> {
  bool _showMap = false;

  @override
  Widget build(BuildContext context) {
    final schedule = widget.schedule;
    final route = schedule.route;
    final vehicle = schedule.vehicle;

    return Scaffold(
      appBar: AppBar(title: Text('Schedule #${schedule.id}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status and day
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    schedule.displayDay,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        schedule.isActive ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    schedule.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                          schedule.isActive
                              ? Colors.green[700]
                              : Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Route info section
            _buildSectionHeader(context, 'Route Information'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route?.name ?? 'Route #${schedule.routeId}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (route?.description != null) ...[
                    const SizedBox(height: 8),
                    Text(route!.description!),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildInfoItem(
                        icon: Icons.access_time,
                        label: 'Departure',
                        value: schedule.departureTime,
                      ),
                      const SizedBox(width: 16),
                      _buildInfoItem(
                        icon: Icons.access_time,
                        label: 'Arrival',
                        value: schedule.arrivalTime,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (route?.distanceKm != null) ...[
                        _buildInfoItem(
                          icon: Icons.straight,
                          label: 'Distance',
                          value: '${route!.distanceKm!.toStringAsFixed(1)} km',
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (route?.estimatedDurationMinutes != null) ...[
                        _buildInfoItem(
                          icon: Icons.timelapse,
                          label: 'Duration',
                          value: route!.formattedDuration,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Vehicle info section
            _buildSectionHeader(context, 'Vehicle Information'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  vehicle != null
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle.displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildInfoItem(
                                icon: Icons.category,
                                label: 'Type',
                                value:
                                    vehicle.type.substring(0, 1).toUpperCase() +
                                    vehicle.type.substring(1),
                              ),
                              const SizedBox(width: 16),
                              _buildInfoItem(
                                icon: Icons.people,
                                label: 'Capacity',
                                value: '${vehicle.capacity} seats',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildInfoItem(
                                icon: Icons.pin,
                                label: 'Plate',
                                value: vehicle.plateNumber,
                              ),
                              const SizedBox(width: 16),
                              _buildInfoItem(
                                icon: Icons.circle,
                                label: 'Status',
                                value:
                                    vehicle.status
                                        .substring(0, 1)
                                        .toUpperCase() +
                                    vehicle.status.substring(1),
                                valueColor:
                                    vehicle.isActive
                                        ? Colors.green[700]
                                        : Colors.red[700],
                              ),
                            ],
                          ),
                        ],
                      )
                      : const Text(
                        'Vehicle information not available',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
            ),

            const SizedBox(height: 24),

            // Route stops section
            if (route?.stops != null && route!.stops!.isNotEmpty) ...[
              _buildSectionHeader(context, 'Route Stops'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${route.stops!.length} stops',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          icon: Icon(_showMap ? Icons.list : Icons.map),
                          label: Text(_showMap ? 'Show List' : 'Show Map'),
                          onPressed: () {
                            setState(() {
                              _showMap = !_showMap;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _showMap ? _buildRouteMap(route) : _buildStopsList(route),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.navigation),
                    label: const Text('Start Navigation'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Navigation feature coming soon'),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.report_problem),
                    label: const Text('Report Issue'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      // Navigate to report incident screen
                      // with pre-filled route information
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteMap(Route route) {
    // Placeholder for map view
    // In a real app, you'd use a map widget like Google Maps or MapBox
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text(
          'Map view coming soon',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildStopsList(Route route) {
    return Column(
      children:
          route.stops!.asMap().entries.map((entry) {
            final index = entry.key;
            final stop = entry.value;
            final isLast = index == route.stops!.length - 1;

            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color:
                                index == 0
                                    ? Colors.green
                                    : (isLast ? Colors.red : Colors.blue),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
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
                            height: 30,
                            color: Colors.grey[300],
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stop['name'] ?? 'Stop ${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (stop['lat'] != null && stop['lng'] != null)
                            Text(
                              'Lat: ${stop['lat']}, Lng: ${stop['lng']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          }).toList(),
    );
  }
}
