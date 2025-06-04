// lib/features/incidents/screens/modern_report_incident_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/incident_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_widgets.dart';

class ModernReportIncidentScreen extends StatefulWidget {
  const ModernReportIncidentScreen({Key? key}) : super(key: key);

  @override
  _ModernReportIncidentScreenState createState() =>
      _ModernReportIncidentScreenState();
}

class _ModernReportIncidentScreenState extends State<ModernReportIncidentScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String _selectedIncidentType = 'accident';
  bool _isSubmitting = false;
  File? _photoFile;
  String _loadingMessage = 'Submitting report...';

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  final List<Map<String, dynamic>> _incidentTypes = [
    {
      'value': 'accident',
      'label': 'Vehicle Accident',
      'icon': Icons.car_crash,
      'color': AppTheme.danger,
    },
    {
      'value': 'breakdown',
      'label': 'Vehicle Breakdown',
      'icon': Icons.build_circle,
      'color': AppTheme.warning,
    },
    {
      'value': 'road_obstruction',
      'label': 'Road Obstruction',
      'icon': Icons.warning_amber,
      'color': Colors.orange,
    },
    {
      'value': 'weather',
      'label': 'Weather Issue',
      'icon': Icons.cloud,
      'color': AppTheme.info,
    },
    {
      'value': 'other',
      'label': 'Other',
      'icon': Icons.more_horiz,
      'color': Colors.grey,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();

      // Show options for camera or gallery
      final source = await _showImageSourceDialog();
      if (source == null) return;

      final XFile? image = await picker.pickImage(
        source: source,
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
      _showCustomSnackBar('Failed to capture image', AppTheme.danger);
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          ),
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
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
          _showCustomSnackBar(
            _photoFile != null
                ? 'Incident reported! Photo uploaded in background.'
                : 'Incident reported successfully',
            AppTheme.success,
          );
          Navigator.of(context).pop();
        } else {
          _showCustomSnackBar(
            'Failed to report incident. Please try again.',
            AppTheme.danger,
          );
        }
      } catch (e) {
        print('Error submitting incident: $e');
        _showCustomSnackBar(
          'An error occurred. Please try again.',
          AppTheme.danger,
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showCustomSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == AppTheme.success ? Icons.check_circle : Icons.error,
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
        title: 'Report Incident',
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration:
            AppTheme.backgroundGradient != null
                ? const BoxDecoration(gradient: AppTheme.backgroundGradient)
                : null,
        child: LoadingOverlay(
          isLoading: _isSubmitting,
          message: _loadingMessage,
          child: SafeArea(
            child: AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _slideAnimation.value * 50),
                  child: Opacity(
                    opacity: 1 - _slideAnimation.value,
                    child: _buildContent(),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            GlassCard(
              child: Column(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 48,
                    color: AppTheme.warning,
                  ),
                  const SizedBox(height: AppTheme.spacingMedium),
                  Text(
                    'Report an Incident',
                    style: AppTheme.heading2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  Text(
                    'Help us keep everyone safe by reporting incidents quickly and accurately.',
                    style: AppTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingLarge),

            // Incident Type Selection
            Text('Incident Type', style: AppTheme.heading3),
            const SizedBox(height: AppTheme.spacingMedium),

            _buildIncidentTypeSelector(),

            const SizedBox(height: AppTheme.spacingLarge),

            // Description Field
            Text('Description', style: AppTheme.heading3),
            const SizedBox(height: AppTheme.spacingMedium),

            _buildDescriptionField(),

            const SizedBox(height: AppTheme.spacingLarge),

            // Photo Section
            Text('Add Photo (Optional)', style: AppTheme.heading3),
            const SizedBox(height: AppTheme.spacingMedium),

            _buildPhotoSection(),

            const SizedBox(height: AppTheme.spacingXLarge),

            // Submit Button
            GradientButton(
              text: 'SUBMIT REPORT',
              onPressed: _submitIncident,
              isLoading: _isSubmitting,
              icon: Icons.send_rounded,
              width: double.infinity,
              height: 56,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentTypeSelector() {
    return GlassCard(
      child: Column(
        children:
            _incidentTypes.map((type) {
              final isSelected = _selectedIncidentType == type['value'];

              return Container(
                margin: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap:
                        _isSubmitting
                            ? null
                            : () {
                              setState(() {
                                _selectedIncidentType = type['value'];
                              });
                            },
                    borderRadius: BorderRadius.circular(
                      AppTheme.borderRadiusMedium,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spacingMedium),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadiusMedium,
                        ),
                        border: Border.all(
                          color:
                              isSelected
                                  ? type['color']
                                  : Colors.grey.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                        color:
                            isSelected
                                ? type['color'].withOpacity(0.1)
                                : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: type['color'].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                AppTheme.borderRadiusSmall,
                              ),
                            ),
                            child: Icon(
                              type['icon'],
                              color: type['color'],
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingMedium),
                          Expanded(
                            child: Text(
                              type['label'],
                              style: AppTheme.bodyLarge.copyWith(
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                color: isSelected ? type['color'] : null,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: type['color'],
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return GlassCard(
      child: TextFormField(
        controller: _descriptionController,
        maxLines: 5,
        enabled: !_isSubmitting,
        decoration: InputDecoration(
          hintText: 'Provide detailed information about the incident...',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintStyle: TextStyle(color: Colors.grey[500]),
        ),
        style: AppTheme.bodyLarge,
        validator: Validators.requiredValidator,
      ),
    );
  }

  Widget _buildPhotoSection() {
    return GlassCard(
      child: _photoFile != null ? _buildPhotoPreview() : _buildAddPhotoButton(),
    );
  }

  Widget _buildPhotoPreview() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          child: Image.file(
            _photoFile!,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _pickImage,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Change Photo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryRed,
                  side: BorderSide(color: AppTheme.primaryRed),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingSmall),
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    _isSubmitting
                        ? null
                        : () {
                          setState(() {
                            _photoFile = null;
                          });
                        },
                icon: const Icon(Icons.delete),
                label: const Text('Remove'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  side: BorderSide(color: AppTheme.danger),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddPhotoButton() {
    return InkWell(
      onTap: _isSubmitting ? null : _pickImage,
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.withOpacity(0.3),
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, size: 48, color: Colors.grey[600]),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              'Add Photo',
              style: AppTheme.bodyLarge.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to capture or select',
              style: AppTheme.bodyMedium.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
