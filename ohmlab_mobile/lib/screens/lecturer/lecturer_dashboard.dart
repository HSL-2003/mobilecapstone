import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'lecturer_propose_schedule_screen.dart';
import 'lecturer_session_management_screen.dart';
import 'lecturer_equipment_history_screen.dart';
import '../common/daily_schedule_screen.dart';
import '../common/common_report_incident_screen.dart';
import '../common/common_report_history_screen.dart';
import 'package:ohm_lab_mobile/services/user_services.dart';
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
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF8F9FA), // Soft background
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5, fontSize: 24, color: Colors.white)),
              backgroundColor: Colors.white.withOpacity(0.1),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              systemOverlayStyle: SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gorgeous Header Background
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 100, bottom: 40, left: 24, right: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF26F21), Color(0xFFFFA726)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Welcome back,', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Lecturer Area', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1)),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Your lab sessions are ready.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Content Body
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('My Classes', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E1E1E), letterSpacing: -0.5)),
                  const SizedBox(height: 16),
                  _buildTeamsList(),
                  
                  const SizedBox(height: 32),
                  const Text('Pending Tasks', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E1E1E), letterSpacing: -0.5)),
                  const SizedBox(height: 16),
                  // Horizontal Carousel for Tasks
                  SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      children: [
                        _buildCarouselTaskCard(context, 'Grade Reports', Icons.fact_check, const LecturerSessionManagementScreen()),
                        const SizedBox(width: 16),
                        _buildCarouselTaskCard(context, 'Propose Sched.', Icons.calendar_today, const LecturerProposeScheduleScreen()),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  const Text('Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E1E1E), letterSpacing: -0.5)),
                  const SizedBox(height: 16),
                  _buildActionGrid(context),
                  
                  const SizedBox(height: 48), // Bottom padding
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamsList() {
    if (_isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFFF26F21))));
    }
    if (_errorMessage != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.red[100]!)),
        child: Text(_errorMessage!, style: TextStyle(color: Colors.red[800])),
      );
    }
    if (_myTeams.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[200]!)),
        child: const Text('Hiện không có lớp nào được phân công.', style: TextStyle(color: Colors.grey)),
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
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildActionCard(
            context, 
            teamName, 
            Icons.class_outlined,
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

  Widget _buildCarouselTaskCard(BuildContext context, String title, IconData icon, Widget destination) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
      },
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: const Color(0xFFF26F21).withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFF26F21).withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: const Color(0xFFF26F21), size: 24),
            ),
            const Spacer(),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E1E1E), letterSpacing: -0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    return Column(
      children: [
        _buildActionCard(context, 'Schedule', Icons.schedule, const DailyScheduleScreen()),
        const SizedBox(height: 16),
        _buildActionCard(context, 'Equipment', Icons.qr_code_scanner, const LecturerSessionManagementScreen()),
        const SizedBox(height: 16),
        _buildActionCard(context, 'Report', Icons.report_problem, const CommonReportIncidentScreen()),
        const SizedBox(height: 32),
        
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(width: 4, height: 20, decoration: BoxDecoration(color: const Color(0xFFF26F21), borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            const Text('History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E1E1E), letterSpacing: -0.5)),
          ],
        ),
        const SizedBox(height: 16),
        _buildActionCard(context, 'Report History', Icons.history, const CommonReportHistoryScreen()),
        const SizedBox(height: 16),
        _buildActionCard(context, 'Equipment History', Icons.assignment, const LecturerEquipmentHistoryScreen()),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, Widget? destination) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        if (destination != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
        }
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4)),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: const Color(0xFFF26F21), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E1E1E))),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }
}
