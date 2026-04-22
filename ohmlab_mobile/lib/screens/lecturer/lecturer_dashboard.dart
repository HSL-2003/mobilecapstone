import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ohm_lab_mobile/screens/login.dart';
import 'package:ohm_lab_mobile/services/user_services.dart';
import 'package:ohm_lab_mobile/screens/lecturer/lecturer_teams_list_screen.dart';
import 'lecturer_session_management_screen.dart';
import 'lecturer_schedule_hub_screen.dart';
import 'lecturer_report_hub_screen.dart';
import 'lecturer_equipment_hub_screen.dart';

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
  String? _lecturerId;

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
        final String? fetchedLecturerId = userData['id']?.toString() ?? userData['lecturerId']?.toString() ?? userData['userId']?.toString();
        
        if (fetchedLecturerId != null) {
          _lecturerId = fetchedLecturerId;
          // 2. Gọi API lấy danh sách Lớp dựa theo lecturerId
          final classResponse = await _userService.getLecturerClasses(fetchedLecturerId);
          if (classResponse.status == 200 || classResponse.status == 201) {
            setState(() {
              if (classResponse.data is List) {
                _myTeams = List<dynamic>.from(classResponse.data);
              } else if (classResponse.data is Map && classResponse.data.containsKey('data')) {
                _myTeams = List<dynamic>.from(classResponse.data['data']);
              } else {
                _myTeams = [classResponse.data]; // Tránh crash
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
      children: _myTeams.map((cls) {
        final rawId = cls['classId'] ?? cls['id'] ?? cls['ID'];
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildClassCard(context, cls, rawId),
        );
      }).toList(),
    );
  }

  Widget _buildClassCard(BuildContext context, Map<String, dynamic> cls, dynamic rawId) {
    final String className = cls['className'] ?? cls['name'] ?? 'Unknown Class';
    final String subjectName = cls['subjectName'] ?? 'No Subject';
    final String semester = cls['semesterName'] ?? '';
    final String slot = cls['slotName'] ?? '';
    final String dow = cls['scheduleTypeDow'] ?? '';
    final String slotStartTime = cls['slotStartTime'] ?? '';
    final String slotEndTime = cls['slotEndTime'] ?? '';
    
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        Navigator.push(
          context, 
          MaterialPageRoute(
            builder: (_) => LecturerTeamsListScreen(
              classData: {
                "classId": rawId,
                "className": className,
                ...cls,
              }
            )
          )
        );
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    className, 
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF1E1E1E), letterSpacing: -0.5)
                  ),
                ),
                if (semester.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF26F21).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(semester, style: const TextStyle(color: Color(0xFFF26F21), fontWeight: FontWeight.bold, fontSize: 12)),
                  )
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.book_outlined, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(child: Text(subjectName, style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(child: Text(dow, style: TextStyle(color: Colors.grey[600], fontSize: 13))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(child: Text('$slot ($slotStartTime - $slotEndTime)', style: TextStyle(color: Colors.grey[600], fontSize: 13))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselTaskCard(BuildContext context, String title, IconData icon, WidgetBuilder destinationBuilder) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: destinationBuilder));
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
        _buildActionCard(context, 'Schedule', Icons.schedule, LecturerScheduleHubScreen(lecturerId: _lecturerId ?? '')),
        const SizedBox(height: 16),
        _buildActionCard(context, 'Equipment', Icons.qr_code_scanner, const LecturerEquipmentHubScreen()),
        const SizedBox(height: 16),
        _buildActionCard(context, 'Report', Icons.report_problem, const LecturerReportHubScreen()),
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
