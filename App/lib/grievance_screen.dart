import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'grievance_bot.dart';

class EnhancedGrievanceScreen extends StatelessWidget {
  const EnhancedGrievanceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6A11CB),
              Color(0xFF2575FC),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with glassy effect
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.white),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      const Text(
                        'File a Grievance',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 4,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.account_balance,
                              size: 28, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Progress indicator with animation
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 0.25 - 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF00DBDE),
                              Color(0xFFFC00FF),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFFC00FF).withOpacity(0.5),
                              blurRadius: 8,
                              offset: Offset(0, 0),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 35),

                // Section title with gradient
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.category_outlined, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Select Complaint Type',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Card grid with animations and depth
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.2,
                  children: [
                    complaintCard(
                      'Public Services',
                      Icons.apartment,
                      [Color(0xFFFFA62E), Color(0xFFEA4D2C)],
                      'https://pgportal.gov.in/Registration',
                      context,
                    ),
                    complaintCard(
                      'Gov. Documents',
                      Icons.description,
                      [Color(0xFF0061FF), Color(0xFF60EFFF)],
                      'https://darpg.gov.in/relatedlinks/documents-and-reports-0',
                      context,
                    ),
                    complaintCard(
                      'Legal Issues',
                      Icons.gavel,
                      [Color(0xFF7F00FF), Color(0xFFE100FF)],
                      'https://pgportal.gov.in/',
                      context,
                    ),
                    complaintCard(
                      'Health Emergency',
                      Icons.health_and_safety,
                      [Color(0xFFF5515F), Color(0xFFA1051D)],
                      'https://ehospital.gov.in/ehospitalsso/signin.jsp',
                      context,
                    ),
                    complaintCard(
                      'Municipal Issues',
                      Icons.location_city,
                      [Color(0xFF00B09B), Color(0xFF96C93D)],
                      'https://tnurbanepay.tn.gov.in/LandingPage.aspx#',
                      context,
                    ),
                    complaintCard(
                      'Others',
                      Icons.more_horiz,
                      [Color(0xFF00C9FF), Color(0xFF92FE9D)],
                      'https://docs.google.com/forms/d/e/1FAIpQLScPjhZdRHWGZHaFIxO7zaRHw4qZ5Df4P7Hrc8siFbUi5cNxYQ/viewform?usp=dialog',
                      context,
                    ),
                  ],
                ),

                const SizedBox(height: 35),

                // File upload section with animated bord

                // AI Assistant floating button
                Container(
                  margin: EdgeInsets.only(bottom: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 70,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFFF0080),
                                Color(0xFF7928CA),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(35),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFFFF0080).withOpacity(0.5),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(35),
                              onTap: () {
                                // Navigate to the grievance screen when tapped
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GrievanceChatScreen(),
                                  ),
                                );
                              },
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.smart_toy_outlined,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Ask AI Assistant',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
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

  Widget complaintCard(String title, IconData icon, List<Color> gradientColors,
      String url, BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final Uri _url = Uri.parse(url);
        if (await canLaunchUrl(_url)) {
          await launchUrl(_url);
        } else {
          throw 'Could not launch $url';
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 2,
                    color: Colors.black26,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
