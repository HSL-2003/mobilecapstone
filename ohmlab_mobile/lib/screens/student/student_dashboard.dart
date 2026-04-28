import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ohm_lab_mobile/services/user_services.dart';
import 'package:ohm_lab_mobile/screens/student/student_teams_list_screen.dart';
import 'student_schedule_screen.dart';
import '../common/common_report_incident_screen.dart';
import 'student_lab_instructions_screen.dart';
import '../common/daily_schedule_screen.dart';
import 'student_lab_instructions_screen.dart';
import '../common/daily_schedule_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final UserService _userService = UserService();
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _myClasses = [];
  String? _studentId;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      final userResponse = await _userService.getCurrentUser();
      if (userResponse.status == 200 || userResponse.status == 201) {
        final payload = userResponse.data;
        dynamic userData;
        if (payload is Map && payload.containsKey('data') && payload['data'] != null) {
          userData = payload['data'];
        } else {
          userData = payload;
        }

        final String? fetchedId = userData['id']?.toString() ?? userData['userId']?.toString();
        
        if (fetchedId != null) {
          _studentId = fetchedId;
          final classResponse = await _userService.getStudentClasses(fetchedId);
          if (classResponse.status == 200 || classResponse.status == 201) {
            setState(() {
              if (classResponse.data is List) {
                _myClasses = List<dynamic>.from(classResponse.data);
              } else if (classResponse.data is Map && classResponse.data.containsKey('data')) {
                _myClasses = List<dynamic>.from(classResponse.data['data']);
              } else {
                _myClasses = [classResponse.data];
              }
              _isLoading = false;
            });
          } else {
            setState(() {
              _errorMessage = 'Không thể tải danh sách lớp học.';
              _isLoading = false;
            });
          }
        } else {
           setState(() {
            _errorMessage = 'Không tìm thấy thông tin Sinh viên từ API.';
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
        _errorMessage = 'Lỗi kết nối (Vui lòng đăng xuất & đăng nhập lại).';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF8F9FA),
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
                  const Text('Student Area', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1)),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.bolt, color: Colors.yellowAccent, size: 20),
                        SizedBox(width: 8),
                        Text('Your lab session starts soon.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('My Classes', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E1E1E), letterSpacing: -0.5)),
                  const SizedBox(height: 16),
                  _buildClassesList(),
                  const SizedBox(height: 32),
                  const Text('Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E1E1E), letterSpacing: -0.5)),
                  const SizedBox(height: 16),
                  _buildActionGrid(context),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassesList() {
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
    if (_myClasses.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[200]!)),
        child: const Text('Hiện không có lớp nào.', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: _myClasses.map((cls) {
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
            builder: (_) => StudentTeamsListScreen(
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

  Widget _buildActionGrid(BuildContext context) {
    return Column(
      children: [
        _buildActionCard(context, 'Schedule', Icons.today, const DailyScheduleScreen()),
        const SizedBox(height: 16),
        _buildActionCard(context, 'Timetable', Icons.calendar_view_week, const StudentScheduleScreen()),
        const SizedBox(height: 16),
        _buildActionCard(context, 'Report', Icons.report_problem, const CommonReportIncidentScreen()),
        const SizedBox(height: 16),
        _buildActionCard(context, 'Instructions', Icons.menu_book, const StudentLabInstructionsScreen()),
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
