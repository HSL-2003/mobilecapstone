import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ohm_lab_mobile/services/user_services.dart';

class LecturerProposeScheduleScreen extends StatefulWidget {
  final String lecturerId;
  final bool hideAppBar;
  const LecturerProposeScheduleScreen({super.key, required this.lecturerId, this.hideAppBar = false});

  @override
  State<LecturerProposeScheduleScreen> createState() => _LecturerProposeScheduleScreenState();
}

class _LecturerProposeScheduleScreenState extends State<LecturerProposeScheduleScreen> {
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  bool _isSearching = false;
  String? _error;
  List<dynamic> _schedules = [];

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
  }

  Future<void> _fetchSchedules() async {
    if (widget.lecturerId.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Lecturer ID is missing.';
        });
      }
      return;
    }
    try {
      final res = await _userService.getRegistrationSchedulesByTeacherId(widget.lecturerId);
      if (res.status == 200 || res.status == 201) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            final payload = res.data;
            if (payload is Map && payload.containsKey('data')) {
              _schedules = payload['data'] is List ? payload['data'] : [payload['data']];
            } else if (payload is List) {
              _schedules = payload;
            } else {
              _schedules = [payload];
            }
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = res.message ?? 'Failed to load schedules.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'An error occurred: $e';
        });
      }
    }
  }

  Future<void> _searchSchedule() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _isSearching = false);
      _fetchSchedules();
      return;
    }
    
    setState(() {
      _isLoading = true;
      _isSearching = true;
      _error = null;
    });

    try {
      final res = await _userService.getRegistrationScheduleById(query);
      if (res.status == 200 || res.status == 201) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            final payload = res.data;
            if (payload is Map && payload.containsKey('data') && payload['data'] != null) {
              _schedules = [payload['data']];
            } else if (payload != null) {
              _schedules = [payload];
            } else {
              _schedules = [];
            }
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _schedules = [];
            _error = res.message ?? "Không tìm thấy lịch đăng ký với ID này.";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = "Lỗi kết nối máy chủ.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: widget.hideAppBar ? null : PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              title: const Text('Registration Schedules', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5, fontSize: 22, color: Colors.white)),
              backgroundColor: const Color(0xFFF26F21).withOpacity(0.95),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              systemOverlayStyle: const SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Search Box Segment
        Padding(
          padding: EdgeInsets.only(top: widget.hideAppBar ? 24 : 100, left: 24, right: 24, bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm theo ID...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFFF26F21)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward, color: Color(0xFFF26F21)),
                  onPressed: _searchSchedule,
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.white,
              ),
              onSubmitted: (_) => _searchSchedule(),
            ),
          ),
        ),
        
        // Dynamic Content Segment
        Expanded(
          child: _buildListContent(),
        ),
      ],
    );
  }

  Widget _buildListContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFF26F21)));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.orange),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _searchController.clear();
                    _isSearching = false;
                    _error = null;
                  });
                  _fetchSchedules();
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF26F21)),
                child: const Text('Xem tất cả lịch', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }
    if (_schedules.isEmpty) {
      return const Center(
        child: Text("Không có dữ liệu lịch đăng ký.", style: TextStyle(fontSize: 16, color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, left: 24, right: 24, bottom: 24),
      itemCount: _schedules.length,
      itemBuilder: (context, index) {
        final schedule = _schedules[index];
        // Safely extract whatever payload might look like
        final String title = schedule['title']?.toString() ?? schedule['scheduleName']?.toString() ?? 'Schedule #${index + 1}';
        final String date = schedule['date']?.toString() ?? schedule['registrationDate']?.toString() ?? 'N/A';
        final String status = schedule['status']?.toString() ?? 'Pending';
        
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFFFF0E5), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.calendar_month, color: Color(0xFFF26F21), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(title, overflow: TextOverflow.ellipsis, maxLines: 2, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1E1E1E), letterSpacing: -0.5)),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 16),
              _buildInfoRow(Icons.calendar_today_outlined, 'Date', date),
              // we can dump other properties dynamically if needed
              const SizedBox(height: 12),
              if (schedule['description'] != null)
                _buildInfoRow(Icons.description_outlined, 'Desc', schedule['description'].toString()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[500]),
        const SizedBox(width: 12),
        SizedBox(
          width: 60,
          child: Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E1E1E)))),
      ],
    );
  }
}
