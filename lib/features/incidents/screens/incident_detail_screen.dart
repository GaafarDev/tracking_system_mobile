import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/incident.dart';
import '../widgets/incident_status_badge.dart';

class IncidentDetailScreen extends StatelessWidget {
  final Incident incident;

  const IncidentDetailScreen({Key? key, required this.incident})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMMM d, yyyy • h:mm a');

    return Scaffold(
      appBar: AppBar(title: Text('Incident #${incident.id}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    incident.displayType,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IncidentStatusBadge(status: incident.status),
              ],
            ),

            const SizedBox(height: 8),

            // Date and time
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  dateFormat.format(incident.createdAt),
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Photo if available
            if (incident.photoPath != null) _buildImageSection(context),

            const SizedBox(height: 24),

            // Description section
            _buildSectionHeader(context, 'Description'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(incident.description),
            ),

            const SizedBox(height: 24),

            // Location section
            _buildSectionHeader(context, 'Location'),
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
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Latitude: ${incident.latitude.toStringAsFixed(6)}',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.transparent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Longitude: ${incident.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Resolution section if resolved
            if (incident.resolvedAt != null) ...[
              _buildSectionHeader(context, 'Resolution'),
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
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Resolved on ${DateFormat('MMMM d, yyyy').format(incident.resolvedAt!)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (incident.resolutionNotes?.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Text(incident.resolutionNotes!),
                    ],
                  ],
                ),
              ),
            ],
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

  Widget _buildImageSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Photo'),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            // In a real app, you would build the full URL to the image
            'https://your-backend-url.com/storage/${incident.photoPath}',
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Show a placeholder on error
              return Container(
                width: double.infinity,
                height: 200,
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                return child;
              }
              return Container(
                width: double.infinity,
                height: 200,
                color: Colors.grey[200],
                child: Center(
                  child: CircularProgressIndicator(
                    value:
                        loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
