import 'package:flutter/material.dart';
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
  List<dynamic> _myClasses = [];

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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

        final String? fetchedId = userData['id']?.toString() ?? userData['userId']?.toString() ?? userData['lecturerId']?.toString();
        
        if (fetchedId != null) {
          final response = widget.role == 'student' 
              ? await _userService.getStudentClasses(fetchedId) 
              : await _userService.getLecturerClasses(fetchedId);
              
          if (response.status == 200 || response.status == 201) {
            final classPayload = response.data;
            if (mounted) {
              setState(() {
                if (classPayload is Map && classPayload.containsKey('data')) {
                  _myClasses = classPayload['data'] ?? [];
                } else if (classPayload is List) {
                  _myClasses = classPayload;
                } else {
                  _myClasses = [classPayload];
                }
                
                // Xếp theo semesterName
                _myClasses.sort((a, b) {
                  final String semA = (a['semesterName'] ?? '').toString();
                  final String semB = (b['semesterName'] ?? '').toString();
                  return semA.compareTo(semB);
                });
                
                _isLoading = false;
              });
            }
          } else {
            if (mounted) {
              setState(() {
                _errorMessage = 'Failed to load class list.';
                _isLoading = false;
              });
            }
          }
        } else {
          if (mounted) {
            setState(() {
              _errorMessage = 'Information not found ID từ API.';
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Invalid login session.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Server connection error.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: widget.hideAppBar ? null : AppBar(
        title: const Text('My Classes', style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFF26F21),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey[200], height: 1.0),
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF26F21)))
          : _errorMessage != null
            ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
            : RefreshIndicator(
                onRefresh: _fetchClasses,
                color: const Color(0xFFF26F21),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('My Classes', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E1E1E), letterSpacing: -0.5)),
                      const SizedBox(height: 16),
                      if (_myClasses.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[200]!)),
                          child: const Text('No classes currently available.', style: TextStyle(color: Colors.grey)),
                        )
                      else
                        ..._myClasses.map((cls) {
                          final rawId = cls['classId'] ?? cls['id'] ?? cls['ID'];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildClassCard(context, cls, rawId),
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildClassCard(BuildContext context, dynamic clsData, dynamic rawId) {
    // Ép kiểu an toàn cho cls
    final Map<String, dynamic> cls = clsData is Map ? Map<String, dynamic>.from(clsData) : {};
    
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
        if (widget.role == 'student') {
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
        } else {
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
}
