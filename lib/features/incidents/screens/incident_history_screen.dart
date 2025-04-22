import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/services/incident_service.dart';
import '../../../core/models/incident.dart';
import '../widgets/incident_status_badge.dart';
import 'incident_detail_screen.dart';

class IncidentHistoryScreen extends StatefulWidget {
  const IncidentHistoryScreen({Key? key}) : super(key: key);

  @override
  _IncidentHistoryScreenState createState() => _IncidentHistoryScreenState();
}

class _IncidentHistoryScreenState extends State<IncidentHistoryScreen> {
  bool _isLoading = false;
  List<Incident> _incidents = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadIncidents();
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
      MaterialPageRoute(
        builder: (context) => IncidentDetailScreen(incident: incident),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadIncidents,
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: _loadIncidents, child: _buildContent()),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _incidents.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadIncidents,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_incidents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No incidents reported yet',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _incidents.length,
      itemBuilder: (context, index) {
        final incident = _incidents[index];
        return _buildIncidentCard(incident);
      },
    );
  }

  Widget _buildIncidentCard(Incident incident) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToIncidentDetail(incident),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildIncidentTypeIcon(incident.type),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      incident.displayType,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IncidentStatusBadge(status: incident.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                incident.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateFormat.format(incident.createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  if (incident.photoPath != null)
                    const Icon(Icons.photo, size: 16, color: Colors.blue),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncidentTypeIcon(String type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case 'accident':
        iconData = Icons.car_crash;
        iconColor = Colors.red;
        break;
      case 'breakdown':
        iconData = Icons.build;
        iconColor = Colors.orange;
        break;
      case 'road_obstruction':
        iconData = Icons.warning;
        iconColor = Colors.amber;
        break;
      case 'weather':
        iconData = Icons.cloud;
        iconColor = Colors.blue;
        break;
      default:
        iconData = Icons.error;
        iconColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, size: 24, color: iconColor),
    );
  }
}
