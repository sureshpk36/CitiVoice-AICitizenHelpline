import 'package:flutter/material.dart';
import 'grievance_screen.dart'; // Import the grievance screen
import 'law_screen.dart'; // Import the law screen
import 'med_assistance.dart'; // Import the law screen
import 'gov_services.dart';
import 'sos_screen.dart';
import 'tracker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Service App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isEnglish = true;

  // List of pages with isEnglish parameter passed to HomePage
  List<Widget> get _pages => [
        HomePage(isEnglish: _isEnglish),
        const AlertsPage(),
        const HistoryPage(),
        const ProfilePage(),
      ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF2196F3), // Vibrant blue
              Color(0xFF1565C0), // Darker blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row with logo, greeting, and language icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(screenWidth * 0.01),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                          child: ClipOval(
                            child: Icon(
                              Icons.person,
                              color: Color(0xFF1565C0),
                              size: screenWidth * 0.08,
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEnglish ? 'Hello, Suresh' : 'வணக்கம், சுரேஷ்',
                              style: TextStyle(
                                fontSize: screenWidth * 0.05,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              _isEnglish
                                  ? 'Welcome back'
                                  : 'மீண்டும் வரவேற்கிறோம்',
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _isEnglish = !_isEnglish;
                          });
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(_isEnglish
                                  ? 'Language Changed'
                                  : 'மொழி மாற்றப்பட்டது'),
                              content: Text(
                                _isEnglish
                                    ? 'Language changed to English'
                                    : 'மொழி தமிழாக மாற்றப்பட்டது',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(_isEnglish ? 'OK' : 'சரி'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.language,
                          color: Colors.white,
                          size: screenWidth * 0.06,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.02),

                // Removed search bar

                // Help text
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
                  child: Text(
                    _isEnglish
                        ? 'How can we help you today?'
                        : 'இன்று நாங்கள் உங்களுக்கு எவ்வாறு உதவ முடியும்?',
                    style: TextStyle(
                      fontSize: screenWidth * 0.075,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.01),

                // Display the corresponding page based on current index
                Expanded(
                  child: _pages[_currentIndex],
                ),

                // Bottom navigation bar
                Container(
                  margin: EdgeInsets.only(top: screenHeight * 0.02),
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.015,
                    horizontal: screenWidth * 0.04,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      NavItem(
                        icon: Icons.home,
                        label: _isEnglish ? 'Home' : 'முகப்பு',
                        isActive: _currentIndex == 0,
                        screenWidth: screenWidth,
                        onTap: () => setState(() => _currentIndex = 0),
                      ),
                      NavItem(
                        icon: Icons.notifications,
                        label: _isEnglish ? 'Alerts' : 'எச்சரிக்கைகள்',
                        isActive: _currentIndex == 1,
                        screenWidth: screenWidth,
                        onTap: () => setState(() => _currentIndex = 1),
                      ),
                      NavItem(
                        icon: Icons.history,
                        label: _isEnglish ? 'History' : 'வரலாறு',
                        isActive: _currentIndex == 2,
                        screenWidth: screenWidth,
                        onTap: () => setState(() => _currentIndex = 2),
                      ),
                      NavItem(
                        icon: Icons.person,
                        label: _isEnglish ? 'Profile' : 'சுயவிவரம்',
                        isActive: _currentIndex == 3,
                        screenWidth: screenWidth,
                        onTap: () => setState(() => _currentIndex = 3),
                      ),
                    ],
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

// Home Page with the services grid - Updated to receive isEnglish parameter
class HomePage extends StatelessWidget {
  final bool isEnglish;

  const HomePage({super.key, required this.isEnglish});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: constraints.maxWidth * 0.04,
          crossAxisSpacing: constraints.maxWidth * 0.04,
          childAspectRatio: 1.0,
          children: [
            HomeGridItem(
              icon: Icons.local_hospital,
              title: isEnglish ? 'Medical\nAssistance' : 'மருத்துவ\nஉதவி',
              gradientColors: [
                Color(0xFF4CAF50),
                Color(0xFF388E3C),
              ],
              iconColor: Colors.white,
              onTap: () {
                // Navigate to the grievance screen when tapped
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MedicalAssistancePage(),
                  ),
                );
              },
            ),
            HomeGridItem(
              icon: Icons.warning_rounded,
              title: isEnglish ? 'Emergency\nSOS' : 'அவசர\nஉதவி',
              gradientColors: [
                Color(0xFFF44336),
                Color(0xFFD32F2F),
              ],
              iconColor: Colors.white,
              onTap: () {
                // Navigate to the grievance screen when tapped
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EmergencySosScreen(),
                  ),
                );
              },
            ),
            HomeGridItem(
              icon: Icons.gavel,
              title: isEnglish ? 'Legal Help' : 'சட்ட உதவி',
              gradientColors: [
                Color(0xFF03A9F4),
                Color(0xFF0288D1),
              ],
              iconColor: Colors.white,
              onTap: () {
                // Navigate to the law screen when tapped
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LegalAssistancePage(),
                  ),
                );
              },
            ),
            HomeGridItem(
              icon: Icons.assignment,
              title: isEnglish ? 'File a\nGrievance' : 'குறைகளைப்\nபதிவு செய்',
              gradientColors: [
                Color(0xFFFF9800),
                Color(0xFFF57C00),
              ],
              iconColor: Colors.white,
              onTap: () {
                // Navigate to the grievance screen when tapped
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EnhancedGrievanceScreen(),
                  ),
                );
              },
            ),
            HomeGridItem(
              icon: Icons.account_balance,
              title: isEnglish ? 'Government\nServices' : 'அரசு\nசேவைகள்',
              gradientColors: [
                Color(0xFF9C27B0),
                Color(0xFF7B1FA2),
              ],
              iconColor: Colors.white,
              onTap: () {
                // Navigate to the grievance screen when tapped
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GovernmentServicesScreen(),
                  ),
                );
              },
            ),
            HomeGridItem(
              icon: Icons.search_rounded,
              title: isEnglish ? 'Track\nComplaint' : 'புகார்\nதடமறிதல்',
              gradientColors: [
                Color(0xFF009688),
                Color(0xFF00796B),
              ],
              iconColor: Colors.white,
              onTap: () {
                // Navigate to the grievance screen when tapped
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GrievanceTrackerScreen(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

// Simple Alerts Page
class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: const [
          AlertItem(
            title: "Grievance Update",
            message: "Your grievance #GR1234 has been processed",
            time: "2 hours ago",
            icon: Icons.announcement,
            color: Colors.blue,
          ),
          AlertItem(
            title: "Appointment Reminder",
            message: "Medical consultation scheduled for tomorrow",
            time: "5 hours ago",
            icon: Icons.calendar_today,
            color: Colors.green,
          ),
          AlertItem(
            title: "Emergency Alert",
            message: "Heavy rainfall expected in your area",
            time: "1 day ago",
            icon: Icons.warning,
            color: Colors.orange,
          ),
          AlertItem(
            title: "Document Ready",
            message: "Your requested certificate is ready for download",
            time: "2 days ago",
            icon: Icons.description,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }
}

// Simple History Page
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: const [
          HistoryItem(
            title: "Medical Assistance",
            details: "Requested ambulance service",
            date: "March 8, 2025",
            status: "Completed",
            statusColor: Colors.green,
          ),
          HistoryItem(
            title: "Legal Consultation",
            details: "Property dispute guidance",
            date: "March 5, 2025",
            status: "In Progress",
            statusColor: Colors.blue,
          ),
          HistoryItem(
            title: "Grievance Filed",
            details: "Water supply issue in neighborhood",
            date: "February 28, 2025",
            status: "Under Review",
            statusColor: Colors.orange,
          ),
          HistoryItem(
            title: "Document Request",
            details: "Birth certificate application",
            date: "February 20, 2025",
            status: "Completed",
            statusColor: Colors.green,
          ),
        ],
      ),
    );
  }
}

// Updated Profile Page
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final _isEnglish =
        Theme.of(context).textTheme.titleLarge?.color != Colors.orange;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 50,
            backgroundColor: Color(0xFF1565C0),
            child: Icon(
              Icons.person,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              "Suresh Kumar",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              "ID: 89234-CITIZEN",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 30),
          ProfileMenuItem(
            icon: Icons.person_outline,
            title: _isEnglish ? "Personal Information" : "தனிப்பட்ட தகவல்",
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                      _isEnglish ? "Personal Information" : "தனிப்பட்ட தகவல்"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InfoRow(
                          label: _isEnglish ? "Name" : "பெயர்",
                          value: "Suresh Kumar"),
                      const SizedBox(height: 12),
                      InfoRow(
                          label: _isEnglish ? "DOB" : "பிறந்த தேதி",
                          value: "03/06/2005"),
                      const SizedBox(height: 12),
                      InfoRow(label: _isEnglish ? "Age" : "வயது", value: "19"),
                      const SizedBox(height: 12),
                      InfoRow(
                          label: _isEnglish ? "Contact" : "தொடர்பு",
                          value: "987654321"),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(_isEnglish ? "Close" : "மூடு"),
                    ),
                  ],
                ),
              );
            },
          ),
          ProfileMenuItem(
            icon: Icons.lock_outline,
            title: _isEnglish ? "Privacy & Security" : "தனியுரிமை & பாதுகாப்பு",
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(_isEnglish
                      ? "Privacy & Security"
                      : "தனியுரிமை & பாதுகாப்பு"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_isEnglish
                          ? "Your data is protected with industry-standard encryption."
                          : "உங்கள் தரவு தொழில்துறை தரநிலை மறையாக்கத்துடன் பாதுகாக்கப்படுகிறது."),
                      const SizedBox(height: 12),
                      Text(_isEnglish
                          ? "Last password change: 15 days ago"
                          : "கடைசி கடவுச்சொல் மாற்றம்: 15 நாட்களுக்கு முன்பு"),
                      const SizedBox(height: 12),
                      Text(_isEnglish
                          ? "Two-factor authentication: Enabled"
                          : "இரண்டு-காரணி அங்கீகாரம்: செயல்படுத்தப்பட்டது"),
                      const SizedBox(height: 12),
                      Text(_isEnglish
                          ? "Data sharing preferences can be updated in settings."
                          : "தரவு பகிர்வு விருப்பங்களை அமைப்புகளில் புதுப்பிக்கலாம்."),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(_isEnglish ? "Close" : "மூடு"),
                    ),
                  ],
                ),
              );
            },
          ),
          ProfileMenuItem(
            icon: Icons.help_outline,
            title: _isEnglish ? "Help & Support" : "உதவி & ஆதரவு",
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(_isEnglish ? "Help & Support" : "உதவி & ஆதரவு"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_isEnglish
                          ? "24/7 Helpline: 1800-123-4567"
                          : "24/7 உதவி எண்: 1800-123-4567"),
                      const SizedBox(height: 12),
                      Text(_isEnglish
                          ? "Email Support: help@serviceapp.gov.in"
                          : "மின்னஞ்சல் ஆதரவு: help@serviceapp.gov.in"),
                      const SizedBox(height: 12),
                      Text(_isEnglish
                          ? "Visit our help center for FAQs and guides."
                          : "அடிக்கடி கேட்கப்படும் கேள்விகள் மற்றும் வழிகாட்டிகளுக்கு எங்கள் உதவி மையத்தைப் பார்வையிடவும்."),
                      const SizedBox(height: 12),
                      Text(_isEnglish
                          ? "Feedback and suggestions are welcome."
                          : "கருத்துகள் மற்றும் ஆலோசனைகளை வரவேற்கிறோம்."),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(_isEnglish ? "Close" : "மூடு"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Info Row for displaying personal information
class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "$label:",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

// Alert item widget
class AlertItem extends StatelessWidget {
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color color;

  const AlertItem({
    super.key,
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(message),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

// History item widget
class HistoryItem extends StatelessWidget {
  final String title;
  final String details;
  final String date;
  final String status;
  final Color statusColor;

  const HistoryItem({
    super.key,
    required this.title,
    required this.details,
    required this.date,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(details),
            const SizedBox(height: 8),
            Text(
              date,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Profile menu item (updated)
class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Function onTap;
  final bool isLogout;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.isLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color:
          isLogout ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: isLogout ? Colors.red : Color(0xFF1565C0),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isLogout ? Colors.red : Colors.black87,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isLogout ? Colors.red : Colors.grey,
        ),
        onTap: () => onTap(),
      ),
    );
  }
}

class HomeGridItem extends StatelessWidget {
  const HomeGridItem({
    super.key,
    required this.icon,
    required this.title,
    required this.gradientColors,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final List<Color> gradientColors;
  final Color iconColor;
  final Function onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => onTap(),
          child: Padding(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.03),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      EdgeInsets.all(MediaQuery.of(context).size.width * 0.02),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: MediaQuery.of(context).size.width * 0.1,
                    color: iconColor,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.04,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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

class NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final double screenWidth;
  final Function onTap;

  const NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.screenWidth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? Color(0xFF1565C0) : Colors.grey,
            size: screenWidth * 0.06,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Color(0xFF1565C0) : Colors.grey,
              fontSize: screenWidth * 0.03,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
