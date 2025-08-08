import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config.dart';
import '../models/user.dart';
import '../utils/analytics_utils.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  final User currentUser;
  
  const AnalyticsDashboardScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _eventStats = {};
  Map<String, dynamic> _userStats = {};
  List<FlSpot> _monthlyEventData = [];
  List<FlSpot> _monthlyRegistrationData = [];
  List<PieChartSectionData> _eventStatusData = [];
  List<PieChartSectionData> _userRoleData = [];
  List<BarChartGroupData> _attendanceData = [];
  List<Map<String, dynamic>> _organizerPerformance = [];
  List<Map<String, dynamic>> _recentActivity = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load all analytics data concurrently
      final results = await Future.wait([
        AnalyticsUtils.getEventStatistics(),
        AnalyticsUtils.getUserStatistics(),
        AnalyticsUtils.getMonthlyEventData(),
        AnalyticsUtils.getMonthlyRegistrationTrend(),
        AnalyticsUtils.getEventStatusDistribution(),
        AnalyticsUtils.getUserRoleDistribution(),
        AnalyticsUtils.getAttendanceData(),
        AnalyticsUtils.getOrganizerPerformance(),
        AnalyticsUtils.getRecentActivity(),
      ]);

      setState(() {
        _eventStats = results[0] as Map<String, dynamic>;
        _userStats = results[1] as Map<String, dynamic>;
        _monthlyEventData = results[2] as List<FlSpot>;
        _monthlyRegistrationData = results[3] as List<FlSpot>;
        _eventStatusData = results[4] as List<PieChartSectionData>;
        _userRoleData = results[5] as List<PieChartSectionData>;
        _attendanceData = results[6] as List<BarChartGroupData>;
        _organizerPerformance = results[7] as List<Map<String, dynamic>>;
        _recentActivity = results[8] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: Config.primaryColor,
        foregroundColor: Config.secondaryColor,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Config.secondaryColor,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Events'),
            Tab(text: 'Users'),
            Tab(text: 'Performance'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildEventsTab(),
                _buildUsersTab(),
                _buildPerformanceTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key Metrics Cards
          _buildKeyMetricsCards(),
          const SizedBox(height: 24),
          
          // Charts Row
          Row(
            children: [
              Expanded(
                child: _buildMonthlyEventsChart(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMonthlyRegistrationsChart(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Recent Activity
          _buildRecentActivitySection(),
        ],
      ),
    );
  }

  Widget _buildKeyMetricsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Key Metrics',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildMetricCard('Total Events', _eventStats['totalEvents']?.toString() ?? '0', Icons.event, Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('Total Users', _userStats['totalUsers']?.toString() ?? '0', Icons.people, Colors.green)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMetricCard('Total Registrations', _eventStats['totalRegistrations']?.toString() ?? '0', Icons.how_to_reg, Colors.orange)),
            const SizedBox(width: 12),
                         Expanded(child: _buildMetricCard('Attendance Rate', AnalyticsUtils.formatPercentage(_eventStats['attendanceRate'] ?? 0), Icons.check_circle, Colors.purple)),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyEventsChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Events',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                          if (value.toInt() >= 1 && value.toInt() <= 12) {
                            return Text(months[value.toInt() - 1], style: const TextStyle(fontSize: 10));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _monthlyEventData,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyRegistrationsChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Registrations',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                          if (value.toInt() >= 1 && value.toInt() <= 12) {
                            return Text(months[value.toInt() - 1], style: const TextStyle(fontSize: 10));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _monthlyRegistrationData,
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_recentActivity.isEmpty)
              const Center(
                child: Text('No recent activity', style: TextStyle(color: Colors.grey)),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentActivity.length,
                itemBuilder: (context, index) {
                  final activity = _recentActivity[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: activity['color'],
                      child: Icon(activity['icon'], color: Colors.white, size: 20),
                    ),
                    title: Text(activity['title'], style: const TextStyle(fontSize: 14)),
                    subtitle: Text(activity['description'], style: const TextStyle(fontSize: 12)),
                    trailing: Text(
                      _formatDate(activity['date']),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Statistics
          _buildEventStatistics(),
          const SizedBox(height: 24),
          
          // Event Status Distribution
          _buildEventStatusChart(),
          const SizedBox(height: 24),
          
          // Attendance Data
          _buildAttendanceChart(),
        ],
      ),
    );
  }

  Widget _buildEventStatistics() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Event Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatItem('Upcoming', _eventStats['upcomingEvents'] ?? 0, Colors.blue)),
                Expanded(child: _buildStatItem('Ongoing', _eventStats['ongoingEvents'] ?? 0, Colors.green)),
                Expanded(child: _buildStatItem('Completed', _eventStats['completedEvents'] ?? 0, Colors.orange)),
                Expanded(child: _buildStatItem('Cancelled', _eventStats['cancelledEvents'] ?? 0, Colors.red)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              value.toString(),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPercentageItem(String label, double value, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${value.toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEventStatusChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Event Status Distribution',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _eventStatusData,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Events - Registrations vs Attendance',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _attendanceData.isNotEmpty 
                      ? _attendanceData.map((group) => group.barRods.map((rod) => rod.toY).reduce((a, b) => a > b ? a : b)).reduce((a, b) => a > b ? a : b) + 5
                      : 10,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('E${value.toInt() + 1}', style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  barGroups: _attendanceData,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Registrations', Colors.blue),
                const SizedBox(width: 24),
                _buildLegendItem('Attendance', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildUsersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Statistics
          _buildUserStatistics(),
          const SizedBox(height: 24),
          
          // User Role Distribution
          _buildUserRoleChart(),
        ],
      ),
    );
  }

  Widget _buildUserStatistics() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatItem('Active', _userStats['activeUsers'] ?? 0, Colors.green)),
                Expanded(child: _buildStatItem('Blocked', _userStats['blockedUsers'] ?? 0, Colors.red)),
                Expanded(child: _buildStatItem('Admin', _userStats['adminUsers'] ?? 0, Colors.purple)),
                Expanded(child: _buildStatItem('Organizer', _userStats['organizerUsers'] ?? 0, Colors.blue)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatItem('Regular Users', _userStats['regularUsers'] ?? 0, Colors.orange)),
                                 Expanded(child: _buildPercentageItem('Active Rate', _userStats['activeRate'] ?? 0, Colors.teal)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserRoleChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Role Distribution',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _userRoleData,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Organizer Performance
          _buildOrganizerPerformance(),
        ],
      ),
    );
  }

  Widget _buildOrganizerPerformance() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Organizer Performance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_organizerPerformance.isEmpty)
              const Center(
                child: Text('No organizer data available', style: TextStyle(color: Colors.grey)),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _organizerPerformance.length,
                itemBuilder: (context, index) {
                  final organizer = _organizerPerformance[index];
                  final events = organizer['events'] ?? 0;
                  final registrations = organizer['registrations'] ?? 0;
                  final attendances = organizer['attendances'] ?? 0;
                  final attendanceRate = registrations > 0 ? (attendances / registrations * 100) : 0;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(organizer['name'] ?? 'Unknown'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Events: $events | Registrations: $registrations | Attendance: $attendances'),
                          Text('Attendance Rate: ${AnalyticsUtils.formatPercentage(attendanceRate)}'),
                        ],
                      ),
                      trailing: CircleAvatar(
                        backgroundColor: _getPerformanceColor(attendanceRate),
                        child: Text(
                          '${attendanceRate.toStringAsFixed(0)}%',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Color _getPerformanceColor(double rate) {
    if (rate >= 80) return Colors.green;
    if (rate >= 60) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}