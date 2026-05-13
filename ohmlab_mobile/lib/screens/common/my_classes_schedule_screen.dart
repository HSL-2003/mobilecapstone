import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ohm_lab_mobile/services/user_services.dart';
import 'package:ohm_lab_mobile/screens/student/student_teams_list_screen.dart';
import 'package:ohm_lab_mobile/screens/lecturer/lecturer_teams_list_screen.dart';

class MyClassesScheduleScreen extends StatefulWidget {
  final String role; // 'student' or 'lecturer'
  final bool hideAppBar;

  const MyClassesScheduleScreen({super.key, required this.role, this.hideAppBar = false});

  @override
  State<MyClassesScheduleScreen> createState() => _MyClassesScheduleScreenState();
}

class _MyClassesScheduleScreenState extends State<MyClassesScheduleScreen> {
  final UserService _userService = UserService();
  bool _isLoading = true;
  String? _errorMessage;
  
  List<dynamic> _classes = [];
  List<dynamic> _schedules = [];
  
  List<String> _semesters = [];
  String? _selectedSemester;
  
  DateTime _currentWeekStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).subtract(Duration(days: DateTime.now().weekday - 1));

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userResponse = await _userService.getCurrentUser();
      if (userResponse.status != 200 && userResponse.status != 201) {
        throw Exception('Invalid login session.');
      }

      final payload = userResponse.data;
      dynamic userData = (payload is Map && payload.containsKey('data')) ? payload['data'] : payload;
      final String? fetchedId = userData['id']?.toString() ?? userData['userId']?.toString() ?? userData['lecturerId']?.toString();
      
      if (fetchedId == null) throw Exception('User ID not found.');

      // 1. Lấy danh sách Classes để có thông tin Semester
      final classResponse = widget.role == 'student' 
          ? await _userService.getStudentClasses(fetchedId) 
          : await _userService.getLecturerClasses(fetchedId);
          
      if (classResponse.status == 200 || classResponse.status == 201) {
        final classPayload = classResponse.data;
        if (classPayload is Map && classPayload.containsKey('data')) {
          _classes = classPayload['data'] ?? [];
        } else if (classPayload is List) {
          _classes = classPayload;
        } else {
          _classes = [classPayload];
        }
      }

      // Lọc ra các Semester duy nhất
      Set<String> sems = {};
      for (var c in _classes) {
        if (c['semesterName'] != null && c['semesterName'].toString().isNotEmpty) {
          sems.add(c['semesterName'].toString());
        }
      }
      _semesters = sems.toList()..sort();
      if (_semesters.isNotEmpty && _selectedSemester == null) {
        _selectedSemester = _semesters.first;
      }

      // 2. Lấy danh sách RegistrationSchedules (Lịch thực hành chi tiết)
      List<dynamic> rawSchedules = [];
      if (widget.role == 'lecturer') {
        final schedRes = await _userService.getRegistrationSchedulesByTeacherId(fetchedId);
        if (schedRes.status == 200 || schedRes.status == 201) {
          final data = schedRes.data;
          rawSchedules = data is List ? data : (data is Map && data.containsKey('data') ? data['data'] : []);
        }
      } else {
        final schedRes = await _userService.getRegistrationSchedulesByStudentId(fetchedId);
        if (schedRes.status == 200 || schedRes.status == 201) {
          final data = schedRes.data;
          rawSchedules = data is List ? data : (data is Map && data.containsKey('data') ? data['data'] : []);
        }
      }

      // Filter: Chỉ hiển thị lịch có trạng thái là Accept
      _schedules = rawSchedules.where((s) {
        final status = (s['registraionScheduleStatus'] ?? s['registrationScheduleStatus'] ?? s['status'] ?? '').toString().toLowerCase();
        return status.contains('accept');
      }).toList();

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _changeWeek(int offsetDays) {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(Duration(days: offsetDays));
    });
  }

  List<dynamic> _getSchedulesForDay(DateTime day) {
    // Dùng chung logic lọc _schedules cho cả Lecturer và Student vì cả hai đều có lịch chi tiết
    return _schedules.where((s) {
      // 1. Kiểm tra Semester (thông qua classId)
      String classId = (s['classId'] ?? s['class']?['classId']).toString();
      var mappedClass = _classes.firstWhere(
        (c) => (c['classId'] ?? c['id']).toString() == classId, 
        orElse: () => null
      );
      
      String? scheduleSemester = mappedClass?['semesterName'];
      if (_selectedSemester != null && scheduleSemester != _selectedSemester) {
        return false;
      }

      // 2. Kiểm tra Ngày
      String? dateStr = s['registraionScheduleDate'] ?? s['registrationScheduleDate'] ?? s['date'];
      if (dateStr == null) return false;
      
      try {
        DateTime sDate = DateTime.parse(dateStr);
        return sDate.year == day.year && sDate.month == day.month && sDate.day == day.day;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF26F21), // Orange background for top area
      appBar: widget.hideAppBar ? null : AppBar(
        title: const Text('Weekly timetable', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: const Color(0xFFF26F21),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF26F21)))
          : _errorMessage != null
            ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
            : Column(
                children: [
                  _buildSemesterSelector(),
                  _buildWeekNavigator(),
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: 7,
                        itemBuilder: (context, index) {
                          DateTime day = _currentWeekStart.add(Duration(days: index));
                          List<dynamic> daySchedules = _getSchedulesForDay(day);
                          return _buildDayRow(day, daySchedules);
                        },
                      ),
                    ),
                  )
                ],
              ),
    );
  }

  Widget _buildSemesterSelector() {
    if (_semesters.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: const Color(0xFFF26F21),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _semesters.map((sem) {
            bool isSelected = _selectedSemester == sem;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => setState(() => _selectedSemester = sem),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? Icons.eco : Icons.settings, 
                        size: 16, 
                        color: isSelected ? const Color(0xFFF26F21) : Colors.white
                      ),
                      const SizedBox(width: 8),
                      Text(
                        sem.toUpperCase(),
                        style: TextStyle(
                          color: isSelected ? const Color(0xFFF26F21) : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildWeekNavigator() {
    DateTime weekEnd = _currentWeekStart.add(const Duration(days: 6));
    String formattedStart = DateFormat('dd/MM/yyyy').format(_currentWeekStart);
    String formattedEnd = DateFormat('dd/MM/yyyy').format(weekEnd);
    
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Text('Current week: $formattedStart – $formattedEnd', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_left, color: Color(0xFF1E1E1E)),
                onPressed: () => _changeWeek(-7),
              ),
              Text(
                DateFormat('MMMM yyyy').format(_currentWeekStart),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E1E1E)),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_right, color: Color(0xFF1E1E1E)),
                onPressed: () => _changeWeek(7),
              ),
            ],
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
        ],
      ),
    );
  }

  Widget _buildDayRow(DateTime day, List<dynamic> schedules) {
    String dayNumber = DateFormat('d/M').format(day);
    String dayName = DateFormat('E').format(day); // Mon, Tue...
    
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF5F5F5), width: 1)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Column: Date & Day
            Container(
              width: 70,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: Color(0xFFF5F5F5), width: 1)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(dayNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E2130))),
                  const SizedBox(height: 4),
                  Text(dayName, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ],
              ),
            ),
            
            // Right Column: Schedules
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                child: schedules.isEmpty 
                    ? const SizedBox(height: 60) // Empty space
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: schedules.map((s) => _buildScheduleCard(s)).toList(),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard(dynamic s) {
    final String className = s['className'] ?? s['class']?['className'] ?? s['name'] ?? 'Unknown';
    final String roomName = s['roomName'] ?? s['room']?['roomName'] ?? s['subjectName'] ?? 'No specific room';
    final String startTime = s['slotStartTime'] ?? s['startTime'] ?? '';
    final String endTime = s['slotEndTime'] ?? s['endTime'] ?? '';
    final String status = s['registraionScheduleStatus'] ?? s['registrationScheduleStatus'] ?? s['status'] ?? '';
    final rawId = s['classId'] ?? s['class']?['classId'] ?? s['id'] ?? s['ID'];

    return InkWell(
      onTap: () {
        if (rawId == null) return;
        final scheduleId = s['registraionScheduleId'] ?? s['registrationScheduleId'] ?? rawId;
        
        if (widget.role == 'student') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => StudentTeamsListScreen(classData: {"classId": rawId, "className": className, "registraionScheduleId": scheduleId})));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => LecturerTeamsListScreen(classData: {"classId": rawId, "className": className, "registraionScheduleId": scheduleId})));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4FF), // Soft blue background for scheduled class
          border: Border.all(color: Colors.blue.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(className, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E))),
                Text('$startTime - $endTime', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.meeting_room, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(roomName, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                if (status.isNotEmpty) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(status, style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                  )
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }
}
