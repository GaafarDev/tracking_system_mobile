import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/sos_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/models/sos_alert.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({Key? key}) : super(key: key);

  @override
  _SosScreenState createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  final _messageController = TextEditingController();
  bool _isLoading = false;
  bool _isCheckingActive = true;
  SosAlert? _activeAlert;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkForActiveAlert();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _checkForActiveAlert() async {
    setState(() {
      _isCheckingActive = true;
      _errorMessage = null;
    });

    try {
      final sosService = Provider.of<SosService>(context, listen: false);
      final activeAlert = await sosService.getActiveSosAlert();

      setState(() {
        _activeAlert = activeAlert;
        _isCheckingActive = false;
      });
    } catch (e) {
      print('Error checking active SOS alert: $e');
      setState(() {
        _errorMessage = 'Failed to check active alerts. Please try again.';
        _isCheckingActive = false;
      });
    }
  }

  Future<void> _sendSosAlert() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a message')));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sosService = Provider.of<SosService>(context, listen: false);
      final locationService = Provider.of<LocationService>(
        context,
        listen: false,
      );

      // Make sure we have location permissions
      await locationService.initialize();

      final success = await sosService.sendSosAlert(
        _messageController.text.trim(),
      );

      if (success) {
        final alert = sosService.activeAlert;
        setState(() {
          _activeAlert = alert;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SOS alert sent successfully')),
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to send SOS alert. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error sending SOS alert: $e');
      setState(() {
        _errorMessage = 'An error occurred. Please try again later.';
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelSosAlert() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sosService = Provider.of<SosService>(context, listen: false);
      final success = await sosService.cancelSosAlert();

      if (success) {
        setState(() {
          _activeAlert = null;
          _isLoading = false;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('SOS alert cancelled')));
      } else {
        setState(() {
          _errorMessage = 'Failed to cancel SOS alert. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error cancelling SOS alert: $e');
      setState(() {
        _errorMessage = 'An error occurred. Please try again later.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency SOS'),
        backgroundColor: Colors.red,
      ),
      body:
          _isCheckingActive
              ? const Center(child: CircularProgressIndicator())
              : _activeAlert != null
              ? _buildActiveAlertView()
              : _buildSendAlertView(),
    );
  }

  Widget _buildSendAlertView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber, size: 80, color: Colors.red[700]),
          const SizedBox(height: 24),
          Text(
            'Send Emergency SOS Alert',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Use this only in case of emergencies. Support team will be notified immediately.',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red[700]),
              ),
            ),

          TextField(
            controller: _messageController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Describe the emergency',
              hintText: 'Please provide details about the emergency',
              border: OutlineInputBorder(),
            ),
            enabled: !_isLoading,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _sendSosAlert,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : const Text(
                        'SEND SOS ALERT',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'IMPORTANT: Only use this button in case of real emergencies',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveAlertView() {
    if (_activeAlert == null) return Container();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[100],
              borderRadius: BorderRadius.circular(100),
            ),
            child: Icon(
              Icons.notifications_active,
              size: 64,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'SOS Alert Active',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _buildStatusBadge(_activeAlert!.status),
          const SizedBox(height: 24),
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
                  'Emergency details:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(_activeAlert!.message ?? 'No details provided'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (_activeAlert!.isActive) ...[
            const Text(
              'Help is on the way. Stay calm and wait for assistance.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _cancelSosAlert,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Text(
                          'CANCEL SOS ALERT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Only cancel if the emergency has been resolved',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ] else if (_activeAlert!.isResponded) ...[
            const Text(
              'Support team has responded to your alert and is on the way.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ] else if (_activeAlert!.isResolved) ...[
            const Text(
              'Your emergency has been resolved. Thank you for your patience.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _activeAlert = null;
                  });
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text(
                  'START NEW ALERT',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    String displayText;
    IconData iconData;

    switch (status) {
      case 'active':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[700]!;
        displayText = 'Active';
        iconData = Icons.error_outline;
        break;
      case 'responded':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[700]!;
        displayText = 'Support Responded';
        iconData = Icons.assignment_turned_in;
        break;
      case 'resolved':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[700]!;
        displayText = 'Resolved';
        iconData = Icons.check_circle_outline;
        break;
      default:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[700]!;
        displayText =
            status.substring(0, 1).toUpperCase() + status.substring(1);
        iconData = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 16, color: textColor),
          const SizedBox(width: 8),
          Text(
            displayText,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
