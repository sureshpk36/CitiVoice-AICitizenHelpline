import 'package:flutter/material.dart';
import 'dart:ui';
import 'law_bot.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalAssistancePage extends StatelessWidget {
  const LegalAssistancePage({Key? key}) : super(key: key);

  // Function to launch URLs
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  // Function to launch phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri uri = Uri.parse('tel:$phoneNumber');
    if (!await launchUrl(uri)) {
      throw 'Could not launch $uri';
    }
  }

  // Function to show content when Get Started is clicked
  void _showGetStartedContent(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Welcome to Legal Services',
            style: TextStyle(
              color: Color(0xFF2E3147),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Our experienced team of legal professionals is here to help you navigate through your legal issues.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'What can we help you with today?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Explore Services',
                style: TextStyle(
                  color: Color(0xFF6C63FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: Stack(
        children: [
          // Top background gradient
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0xFF6C63FF).withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // App Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 5),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(Icons.arrow_back_ios_new,
                                color: Color(0xFF6C63FF)),
                            onPressed: () => Navigator.pop(context),
                            iconSize: 20,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Legal Assistance',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2E3147),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                //
                // Services Section
                //
                //

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Services',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2E3147),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // Services Grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildListDelegate([
                      _buildServiceCard(
                        title: 'Legal Advice',
                        icon: Icons.balance,
                        gradient: LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF5A54D3)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        url: 'https://legaladviceindia.com',
                      ),
                      _buildServiceCard(
                        title: 'Document Help',
                        icon: Icons.description_rounded,
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF6584), Color(0xFFE64D75)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        url: 'https://legaldesk.com',
                      ),
                      _buildServiceCard(
                        title: 'Find Lawyer',
                        icon: Icons.person_search_rounded,
                        gradient: LinearGradient(
                          colors: [Color(0xFF42E695), Color(0xFF3BB78F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        url: 'https://lawrato.com/lawyers',
                      ),
                      _buildServiceCard(
                        title: 'Legal Aid',
                        icon: Icons.business_center_rounded,
                        gradient: LinearGradient(
                          colors: [Color(0xFFFFC75F), Color(0xFFFF9736)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        url: 'https://www.sci.gov.in/legal-aid/',
                      ),
                    ]),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF5A54D3)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF6C63FF).withOpacity(0.3),
                            blurRadius: 15,
                            offset: Offset(0, 8),
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
                                builder: (context) => LawChatScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.smart_toy_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Ask AI Legal Assistant',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Available Lawyers Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 16),
                    child: Text(
                      'Top Lawyers',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2E3147),
                      ),
                    ),
                  ),
                ),

                // Lawyers List
                SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: _buildLawyerCard(
                        name: 'Vitthal',
                        specialty: 'Family Law',
                        rating: 5,
                        location: 'Chennai',
                        experience: '8 years',
                        isAvailable: true,
                        avatarColor: Color(0xFF6C63FF).withOpacity(0.2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: _buildLawyerCard(
                        name: 'Ronak',
                        specialty: 'Corporate Law',
                        rating: 4,
                        location: 'Kochi',
                        experience: '12 years',
                        isAvailable: false,
                        avatarColor: Color(0xFFFF6584).withOpacity(0.2),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ]),
                ),

                // AI Assistant Button
              ],
            ),
          ),
        ],
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
        borderRadius: BorderRadius.circular(20),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _launchURL(url);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
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

  Widget _buildLawyerCard({
    required String name,
    required String specialty,
    required int rating,
    required String location,
    required String experience,
    required bool isAvailable,
    required Color avatarColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            // Profile Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: avatarColor,
              ),
              child: Center(
                child: Text(
                  name.substring(0, 1),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: avatarColor == Color(0xFF6C63FF).withOpacity(0.2)
                        ? Color(0xFF6C63FF)
                        : Color(0xFFFF6584),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            // Information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2E3147),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isAvailable
                              ? Color(0xFFE8FFF1)
                              : Color(0xFFFFEEEE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isAvailable ? 'Available' : 'Busy',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isAvailable
                                ? Color(0xFF42E695)
                                : Color(0xFFFF6584),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    specialty,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6C63FF),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      ...List.generate(
                        5,
                        (index) => Icon(
                          index < rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: Color(0xFFFFC75F),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E3147),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 16, color: Color(0xFF8F92A1)),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8F92A1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Color(0xFF8F92A1),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        experience,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8F92A1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildContactButton(
                          text: 'Call Now',
                          icon: Icons.call_rounded,
                          onPressed: () {
                            // Determine which phone number to call based on lawyer name
                            String phoneNumber =
                                name == 'Vitthal' ? '9782738739' : '8987654321';
                            _makePhoneCall(phoneNumber);
                          },
                          color: Color(0xFF6C63FF),
                          textColor: Colors.white,
                          hasShadow: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildContactButton(
                          text: 'Book',
                          icon: Icons.calendar_today_rounded,
                          onPressed: () {
                            _launchURL(
                                'https://docs.google.com/forms/d/e/1FAIpQLSd2cHWhX0knKThcRiekh1Szf4jRzSiltuGtDOkB59UuUg-NQw/viewform?usp=sharing');
                          },
                          color: Colors.white,
                          textColor: Color(0xFF6C63FF),
                          hasShadow: false,
                          borderColor: Color(0xFF6C63FF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    required Color textColor,
    required bool hasShadow,
    Color? borderColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color,
        border: borderColor != null
            ? Border.all(color: borderColor, width: 1.5)
            : null,
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: textColor,
                ),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
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
