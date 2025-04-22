import 'package:flutter/material.dart';

class ReportIncidentScreen extends StatefulWidget {
  @override
  _ReportIncidentScreenState createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String _selectedIncidentType = 'Accident';
  bool _isSubmitting = false;

  final List<String> _incidentTypes = [
    'Accident',
    'Vehicle Breakdown',
    'Road Obstruction',
    'Weather Issue',
    'Other',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitIncident() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      // Simulate API call
      await Future.delayed(Duration(seconds: 2));

      // TODO: Implement actual incident reporting API call

      setState(() {
        _isSubmitting = false;
      });

      // Show success message and go back
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Incident reported successfully')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Report Incident')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Incident Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),

              // Incident type dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Incident Type',
                  border: OutlineInputBorder(),
                ),
                value: _selectedIncidentType,
                items:
                    _incidentTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedIncidentType = newValue;
                    });
                  }
                },
              ),
              SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  hintText: 'Provide details about the incident',
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Add photo button
              OutlinedButton.icon(
                icon: Icon(Icons.photo_camera),
                label: Text('Add Photo'),
                onPressed: () {
                  // TODO: Implement photo upload functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Photo upload not implemented yet')),
                  );
                },
              ),
              SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitIncident,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child:
                      _isSubmitting
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('SUBMIT REPORT'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
