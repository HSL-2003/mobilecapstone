import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ohm_lab_mobile/services/user_services.dart';

class SecurityCheckInScreen extends StatefulWidget {
  const SecurityCheckInScreen({super.key});

  @override
  State<SecurityCheckInScreen> createState() => _SecurityCheckInScreenState();
}

class _SecurityCheckInScreenState extends State<SecurityCheckInScreen> {
  final UserService _userService = UserService();
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _schedules = [];

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      // Lấy tất cả lịch có status Approved (chờ bảo vệ check-in)
      final res = await _userService.getAllRegistrationSchedules(status: 'Approved');
      if (res.status == 200 || res.status == 201) {
        final payload = res.data;
        List<dynamic> all = [];
        if (payload is List) {
          all = payload;
        } else if (payload is Map && payload.containsKey('data')) {
          all = payload['data'] is List ? payload['data'] : [];
        }
        setState(() {
          _schedules = all;
          _isLoading = false;
        });
      } else {
        setState(() { 
          if (res.status == 403) {
            _errorMessage = 'Security account is not authorized to view the schedule list (Error 403). Please contact Admin.';
          } else {
            _errorMessage = 'Failed to load schedule list: ${res.message ?? res.status}'; 
          }
          _isLoading = false; 
        });
      }
    } catch (e) {
      String errorText = 'A system error occurred.';
      if (e.toString().contains('403')) {
        errorText = 'Account is not authorized to view the schedule (Error 403). Please contact Backend.';
      } else {
        errorText = 'Connection error: ${e.toString()}';
      }
      setState(() { _errorMessage = errorText; _isLoading = false; });
    }
  }

  Future<void> _doCheckIn(Map<String, dynamic> schedule) async {
    final int? scheduleId = int.tryParse((schedule['registrationScheduleId'] ?? schedule['id'] ?? '').toString());
    final int? roomId = int.tryParse((schedule['roomId'] ?? schedule['room']?['id'] ?? '').toString());

    if (scheduleId == null || roomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule or Room ID not found.'), backgroundColor: Colors.red),
      );
      return;
    }

    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Check-in', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Room: ${schedule['roomName'] ?? schedule['room']?['roomName'] ?? 'N/A'}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Lecturer: ${schedule['lecturerName'] ?? schedule['teacherName'] ?? 'N/A'}'),
            const SizedBox(height: 12),
            const Text('Confirm key has been handed over to the lecturer?',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF26F21),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Check-in', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFF26F21))),
    );

    try {
      final res = await _userService.securityCheckIn(scheduleId, roomId);
      Navigator.pop(context); // dismiss loading

      if (res.status == 200 || res.status == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Check-in successful! Schedule is now InProgress.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        _loadSchedules(); // Refresh list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Check-in error: ${res.message ?? res.status}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      Navigator.pop(context); // dismiss loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              title: const Text('Lab Check-in',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
              backgroundColor: const Color(0xFFF26F21).withOpacity(0.95),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              systemOverlayStyle: const SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadSchedules,
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF26F21)))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadSchedules,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF26F21)),
                          child: const Text('Retry', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                )
              : _schedules.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_available, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          const Text('No schedules pending Check-in.',
                              style: TextStyle(color: Colors.grey, fontSize: 16)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 90, left: 20, right: 20, bottom: 24),
                      itemCount: _schedules.length,
                      itemBuilder: (context, index) {
                        final s = _schedules[index];
                        final String roomName = s['roomName'] ?? s['room']?['roomName'] ?? 'Phòng N/A';
                        final String teacher = s['lecturerName'] ?? s['teacherName'] ?? s['teacherFullName'] ?? 'N/A';
                        final String date = s['registrationScheduleDate'] ?? s['date'] ?? 'N/A';
                        final String startTime = s['slotStartTime'] ?? s['startTime'] ?? '';
                        final String endTime = s['slotEndTime'] ?? s['endTime'] ?? '';
                        final String status = s['registrationScheduleStatus'] ?? s['status'] ?? 'N/A';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF26F21).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.meeting_room, color: Color(0xFFF26F21), size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(roomName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF1E1E1E))),
                                          Text(teacher, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(status,
                                          style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
                                    const SizedBox(width: 8),
                                    Text(date, style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500)),
                                    const SizedBox(width: 16),
                                    Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                                    const SizedBox(width: 8),
                                    Text('$startTime - $endTime', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _doCheckIn(s),
                                    icon: const Icon(Icons.key, size: 18),
                                    label: const Text('Check-in (Key Handover)',
                                        style: TextStyle(fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF26F21),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
