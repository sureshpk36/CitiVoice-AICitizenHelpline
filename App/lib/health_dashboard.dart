import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class EnhancedHealthDashboard extends StatefulWidget {
  const EnhancedHealthDashboard({Key? key}) : super(key: key);

  @override
  State<EnhancedHealthDashboard> createState() =>
      _EnhancedHealthDashboardState();
}

class _EnhancedHealthDashboardState extends State<EnhancedHealthDashboard> {
  String ipAddress = '192.168.1.100'; // Default IP address
  Timer? _timer;

  // Health metrics data
  double heartRate = 75;
  double spo2 = 98;
  double bodyTemp = 37.2;

  // Trend data
  String heartRateTrend = '+2%';
  String spo2Trend = 'Stable';
  String bodyTempTrend = '-0.1°';

  // Historical data for graphs
  List<double> heartRateHistory = [];
  List<double> spo2History = [];
  List<double> bodyTempHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSavedIPAddress();
    _startDataFetching();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadSavedIPAddress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      ipAddress = prefs.getString('esp8266_ip_address') ?? ipAddress;
    });
  }

  Future<void> _saveIPAddress(String newIP) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('esp8266_ip_address', newIP);
  }

  void _startDataFetching() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _fetchHealthData();
    });
  }

  Future<void> _fetchHealthData() async {
    try {
      final response = await http
          .get(Uri.parse('http://$ipAddress/health_data'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Store previous values for trend calculation
        final prevHeartRate = heartRate;
        final prevSpo2 = spo2;
        final prevBodyTemp = bodyTemp;

        setState(() {
          // Update current values
          heartRate = data['heart_rate'].toDouble();
          spo2 = data['spo2'].toDouble();
          bodyTemp = data['body_temp'].toDouble();

          // Update trends
          heartRateTrend = _calculateTrend(heartRate, prevHeartRate, true);
          spo2Trend = _calculateTrend(spo2, prevSpo2, false);
          bodyTempTrend =
              _calculateTrend(bodyTemp, prevBodyTemp, false, isTempUnit: true);

          // Update history for graph
          _updateHistory();
        });
      }
    } catch (e) {
      debugPrint('Error fetching health data: $e');
    }
  }

  String _calculateTrend(double current, double previous, bool isPercentage,
      {bool isTempUnit = false}) {
    final diff = current - previous;
    if (diff.abs() < 0.1) return 'Stable';

    final prefix = diff > 0 ? '+' : '';

    if (isTempUnit) {
      return '$prefix${diff.toStringAsFixed(1)}°';
    } else if (isPercentage) {
      final percentChange = (diff / previous * 100).toStringAsFixed(1);
      return '$prefix$percentChange%';
    } else {
      return '$prefix${diff.toStringAsFixed(1)}';
    }
  }

  void _updateHistory() {
    // Update historical data for graphs (keep last 6 readings)
    heartRateHistory.add(heartRate);
    spo2History.add(spo2);
    bodyTempHistory.add(bodyTemp);

    if (heartRateHistory.length > 6) {
      heartRateHistory.removeAt(0);
      spo2History.removeAt(0);
      bodyTempHistory.removeAt(0);
    }
  }

  void _showIPAddressDialog() {
    final TextEditingController ipController =
        TextEditingController(text: ipAddress);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('ESP8266 IP Address',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ipController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter IP Address',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF8A4FFF)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFE766FF)),
            ),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF8A4FFF))),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8A4FFF),
            ),
            child: const Text('Connect'),
            onPressed: () {
              setState(() {
                ipAddress = ipController.text;
                _saveIPAddress(ipAddress);
              });
              Navigator.pop(context);
              _fetchHealthData(); // Immediately try to fetch data with new IP
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final date = '${_getMonthName(now.month)} ${now.day}, ${now.year}';

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(date),
                const SizedBox(height: 24),
                _buildConnectionStatus(),
                const SizedBox(height: 16),
                _buildHealthMetricsGrid(),
                const SizedBox(height: 24),
                _buildFusionSyncGraph(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  Widget _buildConnectionStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi,
            color:
                _timer != null && _timer!.isActive ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'ESP8266: $ipAddress',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String date) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hello, Suresh',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5)),
            Text(date,
                style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                    fontWeight: FontWeight.w300)),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.wifi, color: Colors.white),
          onPressed: _showIPAddressDialog,
          tooltip: 'Configure ESP8266 Connection',
        ),
      ],
    );
  }

  Widget _buildHealthMetricsGrid() {
    return Column(
      children: [
        _buildHealthMetricCard(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B6B), Color(0xFFFF4757)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          icon: Icons.favorite,
          label: 'Heart Rate',
          value: '${heartRate.toStringAsFixed(0)} BPM',
          trend: heartRateTrend,
        ),
        const SizedBox(height: 16),
        _buildHealthMetricCard(
          gradient: const LinearGradient(
            colors: [Color(0xFF4ECDC4), Color(0xFF45B7D1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          icon: Icons.air,
          label: 'SpO2',
          value: '${spo2.toStringAsFixed(1)}%',
          trend: spo2Trend,
        ),
        const SizedBox(height: 16),
        _buildHealthMetricCard(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFA07A), Color(0xFFFF6B6B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          icon: Icons.thermostat,
          label: 'Body Temperature',
          value: '${bodyTemp.toStringAsFixed(1)}°C',
          trend: bodyTempTrend,
        ),
      ],
    );
  }

  Widget _buildHealthMetricCard({
    required Gradient gradient,
    required IconData icon,
    required String label,
    required String value,
    required String trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Colors.black26, blurRadius: 15, offset: Offset(0, 10))
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white24,
            radius: 30,
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w300)),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5)),
              ],
            ),
          ),
          Text(trend,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildFusionSyncGraph() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Colors.black38, blurRadius: 20, offset: Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Health Trends',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
              height: 200,
              child: CustomPaint(
                  painter: FusionSyncGraphPainter(
                    heartRateHistory: heartRateHistory,
                    spo2History: spo2History,
                    bodyTempHistory: bodyTempHistory,
                  ),
                  child: Container())),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMetricIndicator(
                  color: const Color(0xFF2563EB),
                  label: 'Heart Rate',
                  value: '${heartRate.toStringAsFixed(0)} BPM'),
              _buildMetricIndicator(
                  color: const Color(0xFF059669),
                  label: 'SpO2',
                  value: '${spo2.toStringAsFixed(1)}%'),
              _buildMetricIndicator(
                  color: const Color(0xFF7C3AED),
                  label: 'Body Temp',
                  value: '${bodyTemp.toStringAsFixed(1)}°C'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricIndicator(
      {required Color color, required String label, required String value}) {
    return Column(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class FusionSyncGraphPainter extends CustomPainter {
  final List<double> heartRateHistory;
  final List<double> spo2History;
  final List<double> bodyTempHistory;

  FusionSyncGraphPainter({
    required this.heartRateHistory,
    required this.spo2History,
    required this.bodyTempHistory,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawAdvancedBackground(canvas, size);
    _drawPrecisionGrid(canvas, size);

    // Only draw graphs if we have data
    if (heartRateHistory.isNotEmpty) {
      final heartRatePaint = _createAdvancedGradientPaint(
          const Color(0xFF2563EB), const Color(0xFF1E40AF), 4.5);
      final spo2Paint = _createAdvancedGradientPaint(
          const Color(0xFF059669), const Color(0xFF064E3B), 4.5);
      final tempPaint = _createAdvancedGradientPaint(
          const Color(0xFF7C3AED), const Color(0xFF5B21B6), 4.5);

      // Convert history data to graph points
      final heartRatePoints =
          _convertDataToPoints(heartRateHistory, size, 40, 120);
      final spo2Points = _convertDataToPoints(spo2History, size, 90, 100);
      final tempPoints = _convertDataToPoints(bodyTempHistory, size, 36, 38);

      canvas.drawPath(
          _createAdvancedSmoothPath(heartRatePoints), heartRatePaint);
      canvas.drawPath(_createAdvancedSmoothPath(spo2Points), spo2Paint);
      canvas.drawPath(_createAdvancedSmoothPath(tempPoints), tempPaint);

      _drawSophisticatedConnectionPoints(
          canvas, heartRatePoints, const Color(0xFF2563EB));
      _drawSophisticatedConnectionPoints(
          canvas, spo2Points, const Color(0xFF059669));
      _drawSophisticatedConnectionPoints(
          canvas, tempPoints, const Color(0xFF7C3AED));
    }
  }

  List<Offset> _convertDataToPoints(
      List<double> data, Size size, double min, double max) {
    if (data.isEmpty) return [];

    final points = <Offset>[];
    final count = data.length;

    for (int i = 0; i < count; i++) {
      // Normalize the x position across the width
      final x = i * (size.width / (count - 1));

      // Normalize the value between 0 and 1, then map to the height
      final normalizedValue = (data[i] - min) / (max - min);
      final clampedValue = normalizedValue.clamp(0.0, 1.0);
      final y = size.height - (clampedValue * size.height);

      points.add(Offset(x, y));
    }

    return points;
  }

  void _drawAdvancedBackground(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF111827), const Color(0xFF1F2937)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Offset.zero & size, backgroundPaint);

    final noisePaint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..style = PaintingStyle.fill;
    final random = math.Random();

    for (int i = 0; i < size.height; i += 2) {
      for (int j = 0; j < size.width; j += 2) {
        if (random.nextDouble() > 0.9) {
          canvas.drawRect(
              Rect.fromLTWH(j.toDouble(), i.toDouble(), 1, 1), noisePaint);
        }
      }
    }
  }

  void _drawPrecisionGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1.0;

    for (int i = 1; i < 6; i++) {
      canvas.drawLine(
          Offset((i / 6) * size.width, 0),
          Offset((i / 6) * size.width, size.height),
          gridPaint..color = Colors.white.withOpacity(0.03 * i));
    }

    for (int i = 1; i < 5; i++) {
      canvas.drawLine(
          Offset(0, (i / 5) * size.height),
          Offset(size.width, (i / 5) * size.height),
          gridPaint..color = Colors.white.withOpacity(0.04 * i));
    }
  }

  Paint _createAdvancedGradientPaint(
      Color startColor, Color endColor, double strokeWidth) {
    return Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [startColor, endColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, 200, 100));
  }

  Path _createAdvancedSmoothPath(List<Offset> points) {
    if (points.isEmpty) return Path();

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      final controlPointDistance = (next.dx - current.dx) / 2.5;
      path.cubicTo(current.dx + controlPointDistance, current.dy,
          next.dx - controlPointDistance, next.dy, next.dx, next.dy);
    }

    return path;
  }

  void _drawSophisticatedConnectionPoints(
      Canvas canvas, List<Offset> points, Color color) {
    for (var point in points) {
      canvas.drawCircle(
          point,
          8,
          Paint()
            ..color = color.withOpacity(0.3)
            ..style = PaintingStyle.fill);
      canvas.drawCircle(
          point,
          4,
          Paint()
            ..color = color
            ..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant FusionSyncGraphPainter oldDelegate) {
    return oldDelegate.heartRateHistory != heartRateHistory ||
        oldDelegate.spo2History != spo2History ||
        oldDelegate.bodyTempHistory != bodyTempHistory;
  }
}
