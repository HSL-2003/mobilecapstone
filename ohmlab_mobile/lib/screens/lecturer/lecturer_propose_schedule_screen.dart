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
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateScheduleBottomSheet,
        backgroundColor: const Color(0xFFF26F21),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showCreateScheduleBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateScheduleForm(
        teacherId: widget.lecturerId,
        onCreated: () {
          _fetchSchedules(); // Refresh the list
        },
      ),
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
        final String title = schedule['registrationScheduleName']?.toString() ?? schedule['title']?.toString() ?? schedule['scheduleName']?.toString() ?? 'Lịch Đăng Ký #${index + 1}';
        
        // Parse date gracefully (backend returns ISO format)
        String rawDate = schedule['registrationScheduleDate']?.toString() ?? schedule['date']?.toString() ?? 'N/A';
        String formattedDate = rawDate;
        if (rawDate != 'N/A') {
          try {
            final parsedDate = DateTime.parse(rawDate).toLocal();
            formattedDate = '${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}';
          } catch (e) {
            formattedDate = rawDate; // Fallback to raw if parsing fails
          }
        }
        
        final String status = schedule['status']?.toString() ?? 'Đã đăng ký';
        final String desc = schedule['registrationScheduleDescription']?.toString() ?? schedule['description']?.toString() ?? '';
        final String roomId = schedule['roomId']?.toString() ?? '';
        final String slotId = schedule['slotId']?.toString() ?? '';
        
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
              _buildInfoRow(Icons.calendar_today_outlined, 'Ngày', formattedDate),
              if (roomId.isNotEmpty && roomId != '0') ...[
                const SizedBox(height: 12),
                _buildInfoRow(Icons.meeting_room_outlined, 'Phòng', roomId),
              ],
              if (slotId.isNotEmpty && slotId != '0') ...[
                const SizedBox(height: 12),
                _buildInfoRow(Icons.access_time_outlined, 'Slot', slotId),
              ],
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildInfoRow(Icons.description_outlined, 'Mô tả', desc),
              ],
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

class _CreateScheduleForm extends StatefulWidget {
  final String teacherId;
  final VoidCallback onCreated;

  const _CreateScheduleForm({required this.teacherId, required this.onCreated});

  @override
  State<_CreateScheduleForm> createState() => _CreateScheduleFormState();
}

class _CreateScheduleFormState extends State<_CreateScheduleForm> {
  final UserService _userService = UserService();
  
  final _nameController = TextEditingController();
  final _classIdController = TextEditingController();
  final _roomIdController = TextEditingController();
  final _labIdController = TextEditingController();
  final _slotIdController = TextEditingController();
  final _descController = TextEditingController();
  
  DateTime? _selectedDate;
  bool _isSaving = false;

  Future<void> _submit() async {
    if (_nameController.text.isEmpty || 
        _classIdController.text.isEmpty ||
        _roomIdController.text.isEmpty ||
        _labIdController.text.isEmpty ||
        _slotIdController.text.isEmpty ||
        _selectedDate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đủ các trường bắt buộc!')));
      }
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      final payload = {
        "registrationScheduleName": _nameController.text.trim(),
        "teacherId": widget.teacherId,
        "classId": int.tryParse(_classIdController.text) ?? 0,
        "roomId": int.tryParse(_roomIdController.text) ?? 0,
        "labId": int.tryParse(_labIdController.text) ?? 0,
        "slotId": int.tryParse(_slotIdController.text) ?? 0,
        "registrationScheduleDate": _selectedDate!.toUtc().toIso8601String(),
        "registrationScheduleDescription": _descController.text.trim()
      };

      final res = await _userService.createRegistrationSchedule(payload);
      
      setState(() => _isSaving = false);
      
      if (res.status == 200 || res.status == 201) {
        if (mounted) {
          Navigator.pop(context); // Close bottom sheet
          widget.onCreated();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo lịch đăng ký thành công!')));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${res.message ?? "Không thể tạo lịch."}')));
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi kết nối máy chủ.')));
      }
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFFF26F21),
            colorScheme: const ColorScheme.light(primary: Color(0xFFF26F21)),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Widget _buildField(String label, TextEditingController controller, {bool isNumber = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFF26F21))),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24, // Keyboard padding
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tạo lịch đăng ký mới', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1E1E1E))),
            const SizedBox(height: 24),
            _buildField('Tên lịch đăng ký *', _nameController),
            Row(
              children: [
                Expanded(child: _buildField('Class ID *', _classIdController, isNumber: true)),
                const SizedBox(width: 16),
                Expanded(child: _buildField('Room ID *', _roomIdController, isNumber: true)),
              ],
            ),
            Row(
              children: [
                Expanded(child: _buildField('Lab ID *', _labIdController, isNumber: true)),
                const SizedBox(width: 16),
                Expanded(child: _buildField('Slot ID *', _slotIdController, isNumber: true)),
              ],
            ),
            
            // Date Picker Field
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.grey[600]),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _selectedDate == null 
                          ? 'Chọn ngày *' 
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                        style: TextStyle(color: _selectedDate == null ? Colors.grey[600] : Colors.black, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            _buildField('Mô tả', _descController, maxLines: 3),
            
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF26F21),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  disabledBackgroundColor: Colors.grey[300]
                ),
                child: _isSaving 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Lưu thông tin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
