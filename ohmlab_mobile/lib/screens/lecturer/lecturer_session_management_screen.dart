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
        appBar: AppBar(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, letterSpacing: -0.5)),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFFF26F21),
          elevation: 0,
          bottom: const TabBar(
            labelColor: Color(0xFFF26F21),
            unselectedLabelColor: Colors.black54,
            indicatorColor: Color(0xFFF26F21),
            tabs: [
              Tab(text: 'Equipment'),
              Tab(text: 'Groups'),
              Tab(text: 'Grading'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const _EquipmentTab(),
            _GroupsTab(teamData: teamData),
            const _GradingTab(),
          ],
        ),
      ),
    );
  }
}

class _EquipmentTab extends StatefulWidget {
  const _EquipmentTab();

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
      final userData = await _userService.getCurrentUserLocal();
      final lecturerId = userData?['id']?.toString() ?? userData?['lecturerId']?.toString() ?? userData?['userId']?.toString();
      if (lecturerId == null) {
        if (mounted) setState(() { _isLoadingEquip = false; });
        return;
      }

      final res = await _userService.searchTeamEquipmentByLecturerId(lecturerId: lecturerId);
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
      // Tạm dùng ID lớp là 1 chuỗi fix, thực tế sẽ truyền từ màn hình ngoài vào
      final res = await _reportService.verifyEquipmentQR("SE1601_LAB3", qr);
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
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Quét mã thiết bị (QR Check)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nhập hoặc quét mã thiết bị để xác nhận bộ dụng cụ cho buổi Lab.', style: TextStyle(color: Colors.black54, fontSize: 13)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qrController,
                      decoration: InputDecoration(
                        hintText: 'Mã QR (VD: OSC-01)',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        prefixIcon: const Icon(Icons.qr_code_scanner, color: Color(0xFFF26F21)),
                      ),
                      onFieldSubmitted: (_) => _verifyQR(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _verifyQR,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[800],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      elevation: 0,
                    ),
                    child: const Text('Kiểm tra', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('Pre-Session Checklist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
        
        const SizedBox(height: 24),
        const Text('Post-Session Action', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Verify all tools are collected and note any damages.'),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const CommonReportIncidentScreen()));
            },
            icon: const Icon(Icons.report_problem),
            label: const Text('Report Damaged Equipment'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
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
      padding: const EdgeInsets.all(20),
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
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
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
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _searchUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF26F21),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                elevation: 0,
              ),
              child: const Text('Search', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(40.0),
            child: Center(child: CircularProgressIndicator(color: Color(0xFFF26F21))),
          )
        else if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
              ],
            ),
          )
        else if (_students.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text('Không có dữ liệu thành viên phù hợp.', style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              initiallyExpanded: true,
              title: const Text('Danh sách Sinh Viên', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Sĩ số: ${_students.length}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
            children: _students.map((student) {
               final name = student['fullName'] ?? student['username'] ?? student['userFullName'] ?? student['name'] ?? 'Unknown Student';
               final code = student['userCode'] ?? student['mssv'] ?? student['userNumberCode'] ?? student['userRollNumber'] ?? '';
               
               return ListTile(
                 leading: const Icon(Icons.person),
                 title: Text(name),
                 subtitle: code.isNotEmpty ? Text(code) : null,
                 trailing: Checkbox(value: true, onChanged: (v){}, activeColor: const Color(0xFFF26F21)),
               );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _GradingTab extends StatelessWidget {
  const _GradingTab();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Submit Grades & Feedback', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildGradingForm('Group 1'),
        const Divider(height: 48),
        _buildGradingForm('Group 2'),
      ],
    );
  }
  Widget _buildGradingForm(String groupName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(groupName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Grade (0-10)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF26F21), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24)),
              child: const Text('Save Grade'),
            )
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Feedback (Optional)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }
}
