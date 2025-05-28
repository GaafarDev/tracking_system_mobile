import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/incident_service.dart';
import '../../../core/utils/validators.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({Key? key}) : super(key: key);

  @override
  _ReportIncidentScreenState createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String _selectedIncidentType = 'accident';
  bool _isSubmitting = false;
  File? _photoFile;
  String _loadingMessage = 'Submitting report...';

  final List<Map<String, dynamic>> _incidentTypes = [
    {'value': 'accident', 'label': 'Accident'},
    {'value': 'breakdown', 'label': 'Vehicle Breakdown'},
    {'value': 'road_obstruction', 'label': 'Road Obstruction'},
    {'value': 'weather', 'label': 'Weather Issue'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _photoFile = File(image.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to capture image')));
    }
  }

  Future<void> _submitIncident() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
        _loadingMessage = 'Getting location...';
      });

      try {
        final incidentService = Provider.of<IncidentService>(
          context,
          listen: false,
        );

        // Update progress message
        setState(() {
          _loadingMessage =
              _photoFile != null
                  ? 'Uploading report with photo...'
                  : 'Submitting report...';
        });

        final success = await incidentService.reportIncident(
          type: _selectedIncidentType,
          description: _descriptionController.text.trim(),
          photo: _photoFile,
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _photoFile != null
                    ? 'Incident reported! Photo uploaded in background.'
                    : 'Incident reported successfully',
              ),
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to report incident. Please try again.'),
            ),
          );
        }
      } catch (e) {
        print('Error submitting incident: $e');
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Incident')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Incident Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),

              // Incident type dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Incident Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                value: _selectedIncidentType,
                items:
                    _incidentTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type['value'],
                        child: Text(type['label']),
                      );
                    }).toList(),
                onChanged:
                    _isSubmitting
                        ? null
                        : (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedIncidentType = newValue;
                            });
                          }
                        },
                validator: Validators.requiredValidator,
              ),
              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  hintText: 'Provide details about the incident',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 5,
                validator: Validators.requiredValidator,
                enabled: !_isSubmitting,
              ),
              const SizedBox(height: 24),

              // Photo selection
              Text(
                'Add Photo (Optional)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),

              // Photo preview or add photo button
              if (_photoFile != null) ...[
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: FileImage(_photoFile!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed:
                              _isSubmitting
                                  ? null
                                  : () {
                                    setState(() {
                                      _photoFile = null;
                                    });
                                  },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Change Photo'),
                  onPressed: _isSubmitting ? null : _pickImage,
                ),
              ] else ...[
                OutlinedButton.icon(
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Take Photo'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: _isSubmitting ? null : _pickImage,
                ),
              ],

              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitIncident,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child:
                      _isSubmitting
                          ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _loadingMessage,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                          : const Text('SUBMIT REPORT'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
