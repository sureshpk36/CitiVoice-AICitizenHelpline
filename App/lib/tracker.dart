import 'package:flutter/material.dart';

class GrievanceTrackerScreen extends StatefulWidget {
  const GrievanceTrackerScreen({Key? key}) : super(key: key);

  @override
  State<GrievanceTrackerScreen> createState() => _GrievanceTrackerScreenState();
}

class _GrievanceTrackerScreenState extends State<GrievanceTrackerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Grievance Tracker',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Search Bar with Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.blue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Enter complaint ID...',
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                      // Added search button
                      ElevatedButton(
                        onPressed: () {
                          _searchComplaints();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Search'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Status Cards
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatusItem(
                          Icons.access_time, Colors.amber, 'Pending', '12'),
                      _buildStatusItem(
                          Icons.info, Colors.blue, 'In Progress', '5'),
                      _buildStatusItem(
                          Icons.check_circle, Colors.green, 'Resolved', '28'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Recent Complaints',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Complaints List
              Expanded(
                child: ListView(
                  children: [
                    _buildComplaintItem(
                      context,
                      'GR-2024-001',
                      'Water Supply Disruption',
                      'No water supply in Ward 7 for the past 3 days',
                      Colors.amber,
                      0.4,
                      _complaintDetails1,
                    ),
                    const SizedBox(height: 16),
                    _buildComplaintItem(
                      context,
                      'GR-2024-002',
                      'Birth Certificate Delay',
                      'Application pending for more than 45 days with no updates',
                      Colors.blue,
                      0.7,
                      _complaintDetails2,
                    ),
                    const SizedBox(height: 16),
                    _buildComplaintItem(
                      context,
                      'GR-2024-003',
                      'Property Tax Assessment',
                      'Incorrect property valuation resulting in excessive taxation',
                      Colors.green,
                      1.0,
                      _complaintDetails3,
                    ),
                  ],
                ),
              ),
              // Bottom Home Indicator
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  width: 100,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show search results
  void _searchComplaints() {
    if (_searchQuery.isNotEmpty) {
      // Show a dialog with search results
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Search Results'),
          content: SizedBox(
            width: double.maxFinite,
            child: _searchQuery.toLowerCase().contains('gr-2024-001')
                ? _buildSearchResultItem(
                    'GR-2024-001',
                    'Water Supply Disruption',
                    'No water supply in Ward 7 for the past 3 days',
                    Colors.amber,
                    0.4,
                  )
                : _searchQuery.toLowerCase().contains('gr-2024-002')
                    ? _buildSearchResultItem(
                        'GR-2024-002',
                        'Birth Certificate Delay',
                        'Application pending for more than 45 days with no updates',
                        Colors.blue,
                        0.7,
                      )
                    : _searchQuery.toLowerCase().contains('gr-2024-003')
                        ? _buildSearchResultItem(
                            'GR-2024-003',
                            'Property Tax Assessment',
                            'Incorrect property valuation resulting in excessive taxation',
                            Colors.green,
                            1.0,
                          )
                        : const Text('No matching complaints found.'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a complaint ID to search'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Detailed information for GR-2024-001 (Municipal Issue)
  void _complaintDetails1(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _DetailScreen(
          id: 'GR-2024-001',
          title: 'Water Supply Disruption',
          status: 'Pending',
          statusColor: Colors.amber,
          progress: 0.4,
          description: 'No water supply in Ward 7 for the past 3 days',
          detailedInfo: [
            {'label': 'Complainant', 'value': 'RM Association, Ward 7'},
            {'label': 'Area Affected', 'value': 'Greenview Colony, Ward 7'},
            {'label': 'Issue Reported', 'value': 'March 8, 2024'},
            {'label': 'Resolution', 'value': 'March 12, 2024'},
            {'label': 'Households Affected', 'value': 'Approximately 320'},
            {'label': 'Department', 'value': 'Municipal Water Works'},
          ],
          timeline: [
            {
              'date': 'Mar 8, 2024',
              'event': 'Complaint registered',
              'status': 'completed'
            },
            {
              'date': 'Mar 9, 2024',
              'event': 'Initial assessment',
              'status': 'completed'
            },
            {
              'date': 'Mar 10, 2024',
              'event': 'Technical team dispatched',
              'status': 'completed'
            },
            {
              'date': 'Mar 11, 2024',
              'event': 'Main pipeline issue identified',
              'status': 'current'
            },
            {
              'date': 'Scheduled Mar 12',
              'event': 'Repair work',
              'status': 'pending'
            },
            {
              'date': 'Estimated Mar 13',
              'event': 'Supply restoration',
              'status': 'pending'
            },
          ],
        ),
      ),
    );
  }

  // Detailed information for GR-2024-002 (Government Document)
  void _complaintDetails2(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _DetailScreen(
          id: 'GR-2024-002',
          title: 'Birth Certificate Delay',
          status: 'In Progress',
          statusColor: Colors.blue,
          progress: 0.7,
          description:
              'Application pending for more than 45 days with no updates',
          detailedInfo: [
            {'label': 'Applicant Name', 'value': 'Priya Sharma'},
            {'label': 'Application ID', 'value': 'BC-2024-7845'},
            {'label': 'Date Applied', 'value': 'January 25, 2024'},
            {'label': 'Standard TAT', 'value': '30 days'},
            {'label': 'Current Status', 'value': 'Verification Pending'},
            {
              'label': 'Responsible Office',
              'value': 'Vital Statistics Department'
            },
          ],
          timeline: [
            {
              'date': 'Jan 25, 2024',
              'event': 'Application submitted online',
              'status': 'completed'
            },
            {
              'date': 'Feb 5, 2024',
              'event': 'Documents received',
              'status': 'completed'
            },
            {
              'date': 'Feb 20, 2024',
              'event': 'Initial processing',
              'status': 'completed'
            },
            {
              'date': 'Mar 10, 2024',
              'event': 'Hospital records verification',
              'status': 'current'
            },
            {
              'date': 'Scheduled Mar 14',
              'event': 'Certificate generation',
              'status': 'pending'
            },
            {
              'date': 'Estimated Mar 18',
              'event': 'Certificate dispatch',
              'status': 'pending'
            },
          ],
        ),
      ),
    );
  }

  // Detailed information for GR-2024-003 (Legal Issue)
  void _complaintDetails3(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _DetailScreen(
          id: 'GR-2024-003',
          title: 'Property Tax Assessment',
          status: 'Resolved',
          statusColor: Colors.green,
          progress: 1.0,
          description:
              'Incorrect property valuation resulting in excessive taxation',
          detailedInfo: [
            {'label': 'Property Owner', 'value': 'Rajesh Kumar'},
            {'label': 'Property ID', 'value': 'PTR-875-44Z'},
            {
              'label': 'Address',
              'value': '45, Lake View Apartments, Sector 18'
            },
            {'label': 'Incorrect Assessment', 'value': '₹45,800'},
            {'label': 'Corrected Assessment', 'value': '₹27,300'},
            {'label': 'Resolution Date', 'value': 'March 9, 2024'},
          ],
          timeline: [
            {
              'date': 'Feb 15, 2024',
              'event': 'Appeal filed',
              'status': 'completed'
            },
            {
              'date': 'Feb 18, 2024',
              'event': 'Documentation submitted',
              'status': 'completed'
            },
            {
              'date': 'Feb 25, 2024',
              'event': 'Review initiated',
              'status': 'completed'
            },
            {
              'date': 'Mar 2, 2024',
              'event': 'Property inspection conducted',
              'status': 'completed'
            },
            {
              'date': 'Mar 7, 2024',
              'event': 'Assessment corrected',
              'status': 'completed'
            },
            {
              'date': 'Mar 9, 2024',
              'event': 'Revised tax notice issued',
              'status': 'completed'
            },
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(
      IconData icon, Color color, String label, String count) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          count,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultItem(
    String id,
    String title,
    String description,
    Color statusColor,
    double progressValue,
  ) {
    IconData statusIcon;
    if (statusColor == Colors.amber) {
      statusIcon = Icons.access_time;
    } else if (statusColor == Colors.blue) {
      statusIcon = Icons.info;
    } else {
      statusIcon = Icons.check_circle;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 18),
            const SizedBox(width: 8),
            Text(
              id,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progressValue,
            minHeight: 6,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            if (id == 'GR-2024-001') {
              _complaintDetails1(context);
            } else if (id == 'GR-2024-002') {
              _complaintDetails2(context);
            } else if (id == 'GR-2024-003') {
              _complaintDetails3(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: statusColor,
            minimumSize: const Size(double.infinity, 40),
          ),
          child: const Text('View Details'),
        ),
      ],
    );
  }

  Widget _buildComplaintItem(
    BuildContext context,
    String id,
    String title,
    String description,
    Color statusColor,
    double progressValue,
    Function(BuildContext) onTap,
  ) {
    IconData statusIcon;
    if (statusColor == Colors.amber) {
      statusIcon = Icons.access_time;
    } else if (statusColor == Colors.blue) {
      statusIcon = Icons.info;
    } else {
      statusIcon = Icons.check_circle;
    }

    return InkWell(
      onTap: () => onTap(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
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
                  Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        id,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progressValue,
                  minHeight: 6,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Detail screen that shows when a complaint is clicked
class _DetailScreen extends StatelessWidget {
  final String id;
  final String title;
  final String status;
  final Color statusColor;
  final double progress;
  final String description;
  final List<Map<String, String>> detailedInfo;
  final List<Map<String, String>> timeline;

  const _DetailScreen({
    required this.id,
    required this.title,
    required this.status,
    required this.statusColor,
    required this.progress,
    required this.description,
    required this.detailedInfo,
    required this.timeline,
  });

  @override
  Widget build(BuildContext context) {
    IconData statusIcon;
    if (statusColor == Colors.amber) {
      statusIcon = Icons.access_time;
    } else if (statusColor == Colors.blue) {
      statusIcon = Icons.info;
    } else {
      statusIcon = Icons.check_circle;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(id),
        backgroundColor: statusColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(statusIcon, color: statusColor),
                        const SizedBox(width: 8),
                        Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: Colors.grey[200],
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(statusColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Detailed information section
              const Text(
                'Detailed Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: detailedInfo.map((info) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 140,
                            child: Text(
                              info['label']!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              info['value']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Timeline section
              const Text(
                'Timeline',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: timeline.asMap().entries.map((entry) {
                    final int idx = entry.key;
                    final Map<String, String> item = entry.value;
                    final bool isLast = idx == timeline.length - 1;

                    Color dotColor;
                    if (item['status'] == 'completed') {
                      dotColor = Colors.green;
                    } else if (item['status'] == 'current') {
                      dotColor = Colors.blue;
                    } else {
                      dotColor = Colors.grey;
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          child: Column(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: dotColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              if (!isLast)
                                Container(
                                  width: 2,
                                  height: 50,
                                  color: Colors.grey[300],
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.only(left: 8.0, bottom: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['date']!,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['event']!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: item['status'] == 'pending'
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Back to List'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Show contact support dialog
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Contact Support'),
                            content: const Text(
                                'Would you like to contact support about this issue?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Support team has been notified'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: statusColor,
                                ),
                                child: const Text('Contact'),
                              ),
                            ],
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: statusColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Contact Support'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
