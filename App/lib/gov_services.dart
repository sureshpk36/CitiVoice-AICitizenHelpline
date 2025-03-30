import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'gov_bot.dart';

class GovernmentServicesScreen extends StatelessWidget {
  const GovernmentServicesScreen({Key? key}) : super(key: key);

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.only(top: 12.0, bottom: 24.0),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFF3E5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back_ios_new,
                              color: Color(0xFF9C27B0)),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Government Services',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9C27B0),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Service Categories
                GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    _buildServiceCard(
                      title: 'Certificates',
                      icon: Icons.description,
                      gradient: LinearGradient(
                        colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      url: 'https://www.digilocker.gov.in',
                    ),
                    _buildServiceCard(
                      title: 'ID Cards',
                      icon: Icons.credit_card,
                      gradient: LinearGradient(
                        colors: [Color(0xFF673AB7), Color(0xFF512DA8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      url: 'https://validation.mha.gov.in/master_entry.aspx',
                    ),
                    _buildServiceCard(
                      title: 'Public Utilities',
                      icon: Icons.electrical_services,
                      gradient: LinearGradient(
                        colors: [Color(0xFF3F51B5), Color(0xFF303F9F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      url: 'https://chennai.nic.in/public-utilities/',
                    ),
                    _buildServiceCard(
                      title: 'Tax Services',
                      icon: Icons.account_balance,
                      gradient: LinearGradient(
                        colors: [Color(0xFF9575CD), Color(0xFF7E57C2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      url: 'https://www.incometax.gov.in/iec/foportal/',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Digital Assistant Button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF9C27B0).withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // Navigate to the grievance screen when tapped
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GovChatScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.support_agent, color: Colors.white),
                            const SizedBox(width: 12),
                            Text(
                              'Ask Digital Assistant',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Popular Services Section
                const SizedBox(height: 24),
                _buildSectionTitle('Popular Services'),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    _showServiceStatusDialog(
                      context,
                      'Birth Certificate',
                      'application_status',
                    );
                  },
                  child: _buildPopularServiceCard(
                    title: 'Birth Certificate',
                    description: 'Apply for new or duplicate birth certificate',
                    icon: Icons.child_care,
                    duration: '7-10 days',
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    _showServiceStatusDialog(
                      context,
                      'Voter ID Card',
                      'voter_id_status',
                    );
                  },
                  child: _buildPopularServiceCard(
                    title: 'Voter ID Card',
                    description:
                        'Register for new voter ID or update existing one',
                    icon: Icons.how_to_vote,
                    duration: '15-20 days',
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    _showServiceStatusDialog(
                      context,
                      'Property Registration',
                      'property_registration_status',
                    );
                  },
                  child: _buildPopularServiceCard(
                    title: 'Property Registration',
                    description: 'Register property or land documents',
                    icon: Icons.home,
                    duration: '30 days',
                  ),
                ),

                // Nearby Offices Section
                // Nearby Offices Section
                const SizedBox(height: 24),
                _buildSectionTitle('Nearby Government Offices'),
                const SizedBox(height: 16),
                ClipRRect(
                  // Use ClipRRect instead of setting clipBehavior on BoxDecoration
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 200,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter:
                            LatLng(13.0827, 80.2707), // Chennai coordinates
                        initialZoom: 13.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c'],
                          userAgentPackageName: 'com.example.app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              width: 80.0,
                              height: 80.0,
                              point: LatLng(13.0827, 80.2707),
                              child: const Icon(
                                Icons.location_on,
                                color: Color(0xFF9C27B0),
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Upcoming Appointments
                const SizedBox(height: 24),
                _buildSectionTitle('Your Appointments'),
                const SizedBox(height: 16),
                _buildAppointmentCard(
                  context,
                  office: 'Municipal Office',
                  purpose: 'Property Tax Payment',
                  date: 'March 15, 2025',
                  time: '10:30 AM',
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required String title,
    required IconData icon,
    required Gradient gradient,
    required String url,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _launchURL(url),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 36, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showServiceStatusDialog(
    BuildContext context,
    String serviceName,
    String serviceType,
  ) {
    // Sample status data - in a real app, this would come from an API
    Widget content;

    if (serviceType == 'application_status') {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusTracker([
            'Application',
            'Document',
            'Processing',
            'Certificate',
            'Delivery',
          ], 2),
          const SizedBox(height: 16),
          _buildStatusDetail('Application Number', 'BC202503150012'),
          _buildStatusDetail('Date of Submission', 'March 5, 2025'),
          _buildStatusDetail('Current Status', 'Document Verification'),
          _buildStatusDetail('Expected Completion', 'March 13, 2025'),
          _buildStatusDetail(
              'Action Required', 'Submit original hospital record'),
        ],
      );
    } else if (serviceType == 'voter_id_status') {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusTracker([
            'Submission',
            'Field Veri.',
            'Update',
            'Card Printing',
            'Delivery',
          ], 1),
          const SizedBox(height: 16),
          _buildStatusDetail('Application Number', 'VID202502280034'),
          _buildStatusDetail('Date of Submission', 'February 28, 2025'),
          _buildStatusDetail('Current Status', 'Field Verification'),
          _buildStatusDetail('Expected Completion', 'March 20, 2025'),
          _buildStatusDetail(
              'Verification Officer', 'Mr. Rajan Kumar (9876543210)'),
        ],
      );
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusTracker([
            'Document',
            'Verification',
            'Payment',
            'Registration',
            'Issuance',
          ], 3),
          const SizedBox(height: 16),
          _buildStatusDetail('Registration ID', 'PR202502150067'),
          _buildStatusDetail('Property Location', '123, Anna Nagar, Chennai'),
          _buildStatusDetail('Current Status', 'Payment of Fees'),
          _buildStatusDetail('Pending Payment', '₹25,000'),
          _buildStatusDetail('Payment Deadline', 'March 18, 2025'),
          _buildStatusDetail(
              'Next Steps', 'Visit municipal office for payment'),
        ],
      );
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '$serviceName Status',
          style: TextStyle(
            color: Color(0xFF9C27B0),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(child: content),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: Color(0xFF9C27B0)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF9C27B0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Track Updates'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTracker(List<String> steps, int currentStep) {
    return Container(
      height: 80,
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index % 2 == 0) {
            // This is a step circle
            final stepIndex = index ~/ 2;
            final isCompleted = stepIndex < currentStep;
            final isCurrent = stepIndex == currentStep;

            return Expanded(
              child: Column(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Color(0xFF9C27B0)
                          : isCurrent
                              ? Color(0xFFF3E5F5)
                              : Colors.grey.shade300,
                      shape: BoxShape.circle,
                      border: isCurrent
                          ? Border.all(color: Color(0xFF9C27B0), width: 2)
                          : null,
                    ),
                    child: isCompleted
                        ? Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    steps[stepIndex],
                    style: TextStyle(
                      fontSize: 12,
                      color: isCompleted || isCurrent
                          ? Colors.black87
                          : Colors.grey,
                      fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          } else {
            // This is a connecting line
            final beforeStepIndex = index ~/ 2;
            final isCompleted = beforeStepIndex < currentStep;

            return Expanded(
              child: Divider(
                color: isCompleted ? Color(0xFF9C27B0) : Colors.grey.shade300,
                thickness: 2,
              ),
            );
          }
        }),
      ),
    );
  }

  Widget _buildStatusDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildPopularServiceCard({
    required String title,
    required String description,
    required IconData icon,
    required String duration,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 30,
                color: Color(0xFF9C27B0),
              ),
            ),
            const SizedBox(width: 16),
            // Information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.black54),
                      const SizedBox(width: 4),
                      Text(
                        'Processing time: $duration',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Action Button
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(
    BuildContext context, {
    required String office,
    required String purpose,
    required String date,
    required String time,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  office,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFFF3E5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Confirmed',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9C27B0),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              purpose,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.black54),
                const SizedBox(width: 8),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.black54),
                const SizedBox(width: 8),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    text: 'Reschedule',
                    icon: Icons.update,
                    onPressed: () {
                      _showRescheduleDialog(context);
                    },
                    isPrimary: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    text: 'Directions',
                    icon: Icons.directions,
                    onPressed: () {
                      _launchURL('https://maps.app.goo.gl/J9c1QD27iXRo6oC48');
                    },
                    isPrimary: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRescheduleDialog(BuildContext context) {
    final TextEditingController reasonController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(Duration(days: 1));
    String selectedTime = '10:00 AM';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              'Reschedule Appointment',
              style: TextStyle(
                color: Color(0xFF9C27B0),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Please provide a reason for rescheduling:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: reasonController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Enter your reason here',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Color(0xFF9C27B0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select new date:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 30)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: Color(0xFF9C27B0),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (pickedDate != null) {
                        setState(() {
                          selectedDate = pickedDate;
                        });
                      }
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                            style: TextStyle(fontSize: 16),
                          ),
                          Icon(Icons.calendar_today, color: Color(0xFF9C27B0)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select new time:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedTime,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Color(0xFF9C27B0)),
                      ),
                    ),
                    items: [
                      '9:00 AM',
                      '10:00 AM',
                      '11:00 AM',
                      '12:00 PM',
                      '2:00 PM',
                      '3:00 PM',
                      '4:00 PM',
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedTime = newValue;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // In a real app, you would save the rescheduling request
                  Navigator.pop(context);
                  // Show confirmation
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Appointment rescheduled successfully'),
                      backgroundColor: Color(0xFF9C27B0),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF9C27B0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Confirm'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isPrimary ? Color(0xFF9C27B0) : Colors.white,
        border: isPrimary ? null : Border.all(color: Color(0xFF9C27B0)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isPrimary ? Colors.white : Color(0xFF9C27B0),
                ),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isPrimary ? Colors.white : Color(0xFF9C27B0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
