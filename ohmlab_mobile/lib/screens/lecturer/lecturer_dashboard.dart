import 'package:flutter/material.dart';
import 'lecturer_propose_schedule_screen.dart';
import 'lecturer_session_management_screen.dart';
import 'lecturer_equipment_history_screen.dart';
import '../common/daily_schedule_screen.dart';
import '../common/common_report_incident_screen.dart';
import '../common/common_report_history_screen.dart';
import 'package:ohm_lab_mobile/services/user_services.dart';

class LecturerDashboard extends StatefulWidget {
  const LecturerDashboard({super.key});

  @override
  State<LecturerDashboard> createState() => _LecturerDashboardState();
}

class _LecturerDashboardState extends State<LecturerDashboard> {
  final UserService _userService = UserService();
  bool _isLoading = true;
  List<dynamic> _myTeams = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    try {
      // 1. Lấy thông tin user hiện tại từ API
      final userResponse = await _userService.getCurrentUser();
      if (userResponse.status == 200 || userResponse.status == 201) {
        final payload = userResponse.data;
        dynamic userData;
        if (payload is Map && payload.containsKey('data') && payload['data'] != null) {
          userData = payload['data'];
        } else {
          userData = payload;
        }

        // Tìm ID giảng viên 
        final String? lecturerId = userData['id']?.toString() ?? userData['lecturerId']?.toString() ?? userData['userId']?.toString();
        
        if (lecturerId != null) {
          // 2. Gọi API lấy danh sách Team dựa theo lecturerId
          final teamResponse = await _userService.getLecturerTeams(lecturerId);
          if (teamResponse.status == 200 || teamResponse.status == 201) {
            setState(() {
              if (teamResponse.data is List) {
                _myTeams = List<dynamic>.from(teamResponse.data);
              } else if (teamResponse.data is Map && teamResponse.data.containsKey('data')) {
                _myTeams = List<dynamic>.from(teamResponse.data['data']);
              } else {
                _myTeams = [teamResponse.data]; // Tránh crash
              }
              _isLoading = false;
            });
          } else {
            setState(() {
              _errorMessage = 'Không thể tải danh sách lớp.';
              _isLoading = false;
            });
          }
        } else {
           setState(() {
            _errorMessage = 'Không tìm thấy thông tin lecturerId từ API.';
            _isLoading = false;
          });
        }
      } else {
         setState(() {
          _errorMessage = 'Phiên đăng nhập không hợp lệ (Lỗi API: ${userResponse.message ?? userResponse.status}).';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kết nối phần lấy ID (Vui lòng đăng xuất & đăng nhập lại).';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Lecturer Dashboard', style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFF26F21),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey[200], height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('My Classes (Assigned Teams)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 16),
              _buildTeamsList(),
              const SizedBox(height: 32),
              const Text('Pending Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 16),
              _buildTaskCard(context, 'Grade Lab 3 Reports', 'IoT Class SE1601', const LecturerSessionManagementScreen()),
              const SizedBox(height: 12),
              _buildTaskCard(context, 'Propose Schedule', 'Embedded Systems', const LecturerProposeScheduleScreen()),
              const SizedBox(height: 32),
              const Text('Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 16),
              _buildActionGrid(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamsList() {
    if (_isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
    }
    if (_errorMessage != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red[200]!)),
        child: Text(_errorMessage!, style: TextStyle(color: Colors.red[800])),
      );
    }
    if (_myTeams.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[200]!)),
        child: const Text('Hiện không có lớp/nhóm nào được phân công.', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: _myTeams.map((team) {
        // Tùy chỉnh việc lấy các field theo cấu trúc trả về thật của DB (ở đây đang mock các key phổ biến)
        final String teamName = team['teamName'] ?? team['name'] ?? 'Unknown Group'; // Hoặc 'subjectCode'
        final String details = (team['subjectName'] ?? team['description'] ?? 'Lecturer Team').toString();
        
        // Cố gắng parse ID từ bất kỳ field nào có thể là id
        final rawId = team['id'] ?? team['teamId'] ?? team['ID'] ?? team['TeamID'];
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildActionCard(
            context, 
            teamName, 
            details, 
            LecturerSessionManagementScreen(
              teamData: {
                "id": rawId,
                "teamId": rawId, 
                "teamName": teamName,
                ...((team is Map) ? Map<String, dynamic>.from(team) : {})
              }
            )
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTaskCard(BuildContext context, String title, String subtitle, Widget destination) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    return Column(
      children: [
        _buildActionCard(context, 'Today\'s Schedule', 'View all lab slots and classes for today', const DailyScheduleScreen()),
        const SizedBox(height: 12),
        _buildActionCard(context, 'My Classes', 'View the list of assigned classes', null),
        const SizedBox(height: 12),
        _buildActionCard(context, 'Equipment Check', 'Verify lab tools availability', const LecturerSessionManagementScreen()),
        const SizedBox(height: 12),
        _buildActionCard(context, 'Report Incident', 'Log issues related to equipment', const CommonReportIncidentScreen()),
        const SizedBox(height: 12),
        _buildActionCard(context, 'Timetable', 'View scheduled practicals', null),
        const SizedBox(height: 32),
        const Text('History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 16),
        _buildActionCard(context, 'Report History', 'View history of submitted reports', const CommonReportHistoryScreen()),
        const SizedBox(height: 12),
        _buildActionCard(context, 'Equipment History', 'View history of lab equipment usage', const LecturerEquipmentHistoryScreen()),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle, Widget? destination) {
    return InkWell(
      onTap: () {
        if (destination != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
        }
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
