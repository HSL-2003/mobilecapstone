import 'package:flutter/material.dart';
import 'package:ohm_lab_mobile/services/user_services.dart';
import 'package:ohm_lab_mobile/services/report_services.dart';
import '../common/common_report_incident_screen.dart';

class LecturerSessionManagementScreen extends StatelessWidget {
  final Map<String, dynamic>? teamData;

  const LecturerSessionManagementScreen({super.key, this.teamData});

  @override
  Widget build(BuildContext context) {
    final title = teamData?['teamName'] ?? teamData?['name'] ?? 'IoT Class SE1601 - Lab 3';

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: -0.5, color: Color(0xFF1E1E1E))),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFFF26F21),
          elevation: 0,
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600],
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFF26F21), Color(0xFFFFA726)]),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: const Color(0xFFF26F21).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                tabs: const [
                  Tab(text: 'Equipment'),
                  Tab(text: 'Groups'),
                  Tab(text: 'Grading'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _EquipmentTab(teamData: teamData),
            _GroupsTab(teamData: teamData),
            _GradingTab(teamData: teamData),
          ],
        ),
      ),
    );
  }
}

class _EquipmentTab extends StatefulWidget {
  final Map<String, dynamic>? teamData;
  const _EquipmentTab({this.teamData});

  @override
  State<_EquipmentTab> createState() => _EquipmentTabState();
}

class _EquipmentTabState extends State<_EquipmentTab> {
  final TextEditingController _qrController = TextEditingController();
  final ReportService _reportService = ReportService();
  final UserService _userService = UserService();
  
  bool _isLoadingEquip = true;
  List<dynamic> _equipments = [];

  @override
  void initState() {
    super.initState();
    _fetchEquipments();
  }

  Future<void> _fetchEquipments() async {
    try {
      final res = await _userService.searchEquipment(
        pageNum: 1,
        pageSize: 100,
        keyword: "",
        status: "",
      );
      if (res.status == 200 || res.status == 201) {
        if (mounted) {
          setState(() {
            if (res.data is Map && res.data.containsKey('data')) {
              final payloadData = res.data['data'];
              if (payloadData is Map && payloadData.containsKey('pageData')) {
                _equipments = payloadData['pageData'] is List ? payloadData['pageData'] : [];
              } else if (payloadData is List) {
                _equipments = payloadData;
              }
            }
            _isLoadingEquip = false;
          });
        }
      } else {
        if (mounted) setState(() { _isLoadingEquip = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoadingEquip = false; });
    }
  }

  Future<void> _verifyQR() async {
    final qr = _qrController.text.trim();
    if (qr.isEmpty) return;
    
    // Đóng bàn phím
    FocusScope.of(context).unfocus();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFF26F21))),
    );

    try {
      final id = widget.teamData?['id']?.toString() ?? widget.teamData?['teamId']?.toString() ?? "0";
      final res = await _reportService.verifyEquipmentQR(id, qr);
      Navigator.pop(context);
      
      if (res.status == 200 || res.status == 201) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xác nhận thiết bị hợp lệ!'), backgroundColor: Colors.green));
         _qrController.clear();
      } else {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message ?? 'Mã thiết bị không hợp lệ'), backgroundColor: Colors.red));
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi kết nối kiểm tra mã QR'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Quét mã thiết bị (QR Check)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E1E1E), letterSpacing: -0.5)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(24), 
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nhập hoặc quét mã thiết bị để xác nhận bộ dụng cụ cho buổi Lab.', style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.5)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qrController,
                      decoration: InputDecoration(
                        hintText: 'Mã QR (VD: OSC-01)',
                        filled: true,
                        fillColor: Colors.grey[50], // Soft fill
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFF26F21))),
                        prefixIcon: const Icon(Icons.qr_code_scanner, color: Color(0xFFF26F21)),
                      ),
                      onFieldSubmitted: (_) => _verifyQR(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFF26F21), Color(0xFFFFA726)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: const Color(0xFFF26F21).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: ElevatedButton(
                      onPressed: _verifyQR,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      child: const Text('Kiểm tra', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text('Pre-Session Checklist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E1E1E), letterSpacing: -0.5)),
        const SizedBox(height: 16),
        if (_isLoadingEquip)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFFF26F21))))
        else if (_equipments.isEmpty)
           const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Không có dữ liệu thiết bị cấp phát.', style: TextStyle(color: Colors.grey))))
        else
           ..._equipments.map((equip) {
              final name = equip['equipmentName'] ?? equip['name'] ?? equip['equipmentCode'] ?? 'Unknown Equipment';
              final qty = equip['quantity'] ?? 1;
              final desc = equip['description'] ?? '';
              final title = desc.isNotEmpty ? '$name ($desc)' : name;
              // Nếu bạn muốn hiển thị Status
              // final status = equip['status'];
              
              return _buildCheckItem('$title x$qty', true); // Tick ngẫu nhiên hoặc lưu trạng thái thực tế
           }).toList(),
        
        const SizedBox(height: 32),
        const Text('Post-Session Action', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E1E1E), letterSpacing: -0.5)),
        const SizedBox(height: 8),
        const Text('Verify all tools are collected and note any damages.', style: TextStyle(color: Colors.black54, fontSize: 13)),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const CommonReportIncidentScreen()));
            },
            icon: const Icon(Icons.report_problem, color: Colors.redAccent),
            label: const Text('Report Damaged Equipment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        )
      ],
    );
  }
  Widget _buildCheckItem(String title, bool isChecked) {
    return CheckboxListTile(
      value: isChecked,
      onChanged: (v) {},
      title: Text(title, style: TextStyle(decoration: isChecked ? TextDecoration.lineThrough : null)),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      activeColor: const Color(0xFFF26F21),
    );
  }
}

class _GroupsTab extends StatefulWidget {
  final Map<String, dynamic>? teamData;
  const _GroupsTab({this.teamData});

  @override
  State<_GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends State<_GroupsTab> {
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _students = [];
  List<dynamic> _originalStudents = []; // Lưu lại danh sách gốc

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUser() async {
    final searchTxt = _searchController.text.trim();
    if (searchTxt.isEmpty) {
      // Nếu bỏ trống, khôi phục lại danh sách gốc
      setState(() { _students = List.from(_originalStudents); });
      return;
    }

    final query = searchTxt.toLowerCase();

    // 1. Tìm kiếm Offline theo Tên, Mã SV hoặc ID
    final filtered = _originalStudents.where((student) {
       final name = (student['fullName'] ?? student['username'] ?? student['userFullName'] ?? student['name'] ?? '').toString().toLowerCase();
       final code = (student['userCode'] ?? student['mssv'] ?? student['userNumberCode'] ?? student['userRollNumber'] ?? '').toString().toLowerCase();
       final stringId = student['id']?.toString().toLowerCase() ?? '';
       
       return name.contains(query) || code.contains(query) || stringId.contains(query);
    }).toList();

    if (filtered.isNotEmpty) {
      setState(() { _students = filtered; });
      return;
    }

    // 2. Fallback: Nếu không tìm thấy offline và là một số, thì thử gọi Server API getTeamUserById
    final int? searchId = int.tryParse(searchTxt);
    if (searchId != null) {
      FocusScope.of(context).unfocus();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFF26F21))),
      );

      try {
        final res = await _userService.getTeamUserById(searchId);
        Navigator.pop(context);

        if (res.status == 200 || res.status == 201) {
          if (mounted) {
             setState(() {
                if (res.data is Map && res.data.containsKey('data')) {
                   _students = res.data['data'] != null ? [res.data['data']] : [];
                } else if (res.data != null) {
                   _students = [res.data];
                } else {
                   _students = [];
                }
             });
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message ?? 'Không tìm thấy thành viên!'), backgroundColor: Colors.red));
          setState(() { _students = []; });
        }
      } catch (e) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi kết nối tra cứu API'), backgroundColor: Colors.red));
        setState(() { _students = []; });
      }
    } else {
       // Không phải số và cũng ko tìm thấy tên offline
       setState(() { _students = []; });
    }
  }

  Future<void> _fetchUsers() async {
    final teamIdRaw = widget.teamData?['teamId'] ?? widget.teamData?['id'];
    if (teamIdRaw == null) {
      if (mounted) setState(() { _isLoading = false; _errorMessage = 'Không có thông tin '; });
      return;
    }

    final int? teamId = int.tryParse(teamIdRaw.toString());
    if (teamId == null) {
      if (mounted) setState(() { _isLoading = false; _errorMessage = 'ID không hợp lệ'; });
      return;
    }

    try {
      final res = await _userService.getTeamUsers(teamId);
      if (res.status == 200 || res.status == 201) {
        if (mounted) {
           setState(() {
              if (res.data is Map && res.data.containsKey('data')) {
                 _originalStudents = res.data['data'] is List ? res.data['data'] : [res.data['data']];
              } else if (res.data is List) {
                 _originalStudents = res.data;
              }
              _students = List.from(_originalStudents);
              _isLoading = false;
           });
        }
      } else {
        if (mounted) setState(() { _isLoading = false; _errorMessage = 'Lỗi lấy sinh viên: ${res.message ?? res.status}'; });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _errorMessage = 'Lỗi kết nối API'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Search bar
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm theo Tên, Mã SV hoặc ID...',
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFF26F21))),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      _searchUser();
                    },
                  )
                ),
                onFieldSubmitted: (_) => _searchUser(),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFF26F21), Color(0xFFFFA726)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: const Color(0xFFF26F21).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: ElevatedButton(
                onPressed: _searchUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                ),
                child: const Icon(Icons.search, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(40.0),
            child: Center(child: CircularProgressIndicator(color: Color(0xFFF26F21))),
          )
        else if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red[100]!)),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500))),
              ],
            ),
          )
        else if (_students.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Text('Không có dữ liệu thành viên phù hợp.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: true,
                title: const Text('Danh sách Sinh Viên', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Text('Sĩ số: ${_students.length}', style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold, fontSize: 13)),
                children: _students.map((student) {
                   final name = student['fullName'] ?? student['username'] ?? student['userFullName'] ?? student['name'] ?? 'Unknown Student';
                   final code = student['userCode'] ?? student['mssv'] ?? student['userNumberCode'] ?? student['userRollNumber'] ?? '';
                   
                   return ListTile(
                     contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                     leading: CircleAvatar(backgroundColor: Colors.grey[100], child: const Icon(Icons.person, color: Colors.grey)),
                     title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                     subtitle: code.isNotEmpty ? Text(code, style: TextStyle(color: Colors.grey[500])) : null,
                     trailing: Checkbox(value: true, onChanged: (v){}, activeColor: const Color(0xFFF26F21)),
                   );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }
}

class _GradingTab extends StatefulWidget {
  final Map<String, dynamic>? teamData;
  const _GradingTab({this.teamData});

  @override
  State<_GradingTab> createState() => _GradingTabState();
}

class _GradingTabState extends State<_GradingTab> {
  final UserService _userService = UserService();
  final TextEditingController _gradeCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  int _teamId = 0;
  int _labId = 0;
  int _classId = 0;

  @override
  void initState() {
    super.initState();
    _initDataAndFetch();
  }

  Future<void> _initDataAndFetch() async {
    if (widget.teamData != null) {
      final tIdRaw = widget.teamData!['teamId'] ?? widget.teamData!['id'];
      final lIdRaw = widget.teamData!['labId'] ?? widget.teamData!['labId'] ?? 0;
      final cIdRaw = widget.teamData!['classId'] ?? widget.teamData!['subjectId'] ?? 0;

      // Cố gắng parse int
      _teamId = int.tryParse(tIdRaw.toString()) ?? 0;
      _labId = int.tryParse(lIdRaw.toString()) ?? 0;
      _classId = int.tryParse(cIdRaw.toString()) ?? 0;
    }

    if (_teamId == 0) {
      if (mounted) setState(() {
        _isLoading = false;
        _errorMessage = "Missing or invalid Team ID.";
      });
      return;
    }

    // Try fetching existing grade
    try {
      final res = await _userService.getGrade(_labId, _teamId);
      if (res.status == 200 || res.status == 201) {
        if (res.data != null && res.data is Map) {
          final payload = res.data.containsKey('data') ? res.data['data'] : res.data;
          if (payload is Map && payload.isNotEmpty) {
            _gradeCtrl.text = payload['grade']?.toString() ?? '';
            _descCtrl.text = payload['gradeDescription']?.toString() ?? '';
             // Cập nhật lại classId / labId từ response nếu có
             if (payload['classId'] != null) _classId = int.tryParse(payload['classId'].toString()) ?? _classId;
          }
        }
      }
    } catch (e) {
      // Ignored: probably no grade or network error. Continue to show empty form.
      debugPrint("Warning: Fetching grade failed: $e");
    }

    if (mounted) setState(() { _isLoading = false; });
  }

  Future<void> _saveGrade() async {
    if (_teamId == 0) return;
    
    final gradeText = _gradeCtrl.text.trim();
    if (gradeText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a grade first!'), backgroundColor: Colors.red));
      return;
    }

    final double? gradeVal = double.tryParse(gradeText);
    if (gradeVal == null || gradeVal < 0 || gradeVal > 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Grade must be a number between 0 and 10!'), backgroundColor: Colors.red));
      return;
    }

    setState(() { _isSaving = true; });

    final payload = {
      "classId": _classId,
      "grade": gradeVal,
      "gradeDescription": _descCtrl.text.trim(),
      "gradeStatus": "Graded"
    };

    try {
      final res = await _userService.submitGrade(_labId, _teamId, payload);
      if (res.status == 200 || res.status == 201) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Grade saved successfully!'), backgroundColor: Colors.green));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message ?? 'Failed to save grade.'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error connecting to server.'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() { _isSaving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFF26F21)));
    }
    
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)));
    }

    final String teamName = widget.teamData?['teamName'] ?? widget.teamData?['name'] ?? 'Team $_teamId';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Submit Evaluation & Grade', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E1E1E), letterSpacing: -0.5)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.auto_stories, color: Color(0xFFF26F21), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(teamName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _gradeCtrl,
                      decoration: InputDecoration(
                        labelText: 'Grade (0-10)',
                        filled: true,
                        fillColor: Colors.grey[50], // Soft fill
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFF26F21))),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFF26F21), Color(0xFFFFA726)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: const Color(0xFFF26F21).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveGrade,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      child: _isSaving 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save Grade', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Evaluation Feedback',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: Colors.grey[50], // Soft fill
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFF26F21))),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}
