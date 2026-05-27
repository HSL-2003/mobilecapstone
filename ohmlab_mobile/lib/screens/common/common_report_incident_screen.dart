import 'dart:io';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ohm_lab_mobile/services/report_services.dart';
import 'package:ohm_lab_mobile/services/user_services.dart';
import 'package:ohm_lab_mobile/services/api_service.dart';
import 'package:intl/intl.dart';

class CommonReportIncidentScreen extends StatefulWidget {
  final bool hideAppBar;
  const CommonReportIncidentScreen({super.key, this.hideAppBar = false});

  @override
  State<CommonReportIncidentScreen> createState() => _CommonReportIncidentScreenState();
}

class _CommonReportIncidentScreenState extends State<CommonReportIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ReportService _reportService = ReportService();
  final UserService _userService = UserService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoadingSchedules = true;
  List<dynamic> _todaySchedules = [];
  int? _selectedScheduleId;
  String? _selectedScheduleDisplay;

  bool _isLoadingEquipments = true;
  List<dynamic> _equipments = [];
  String? _selectedEquipmentId;
  String? _selectedEquipmentDisplay;
  String _equipmentSearchQuery = '';

  List<String> _imageUrls = [];
  bool _isUploading = false;
  bool _isSubmitting = false;

  final String _cloudName = 'drsvwco0f';
  final String _uploadPreset = 'unsigned_reports';

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
    _fetchEquipments();
  }

  Future<void> _fetchEquipments() async {
    try {
      final res = await _reportService.searchEquipments();
      if (res.status == 200 || res.status == 201) {
        final payload = res.data;
        dynamic dataObj = (payload is Map && payload.containsKey('data')) ? payload['data'] : payload;
        dynamic pageData = (dataObj is Map && dataObj.containsKey('pageData')) ? dataObj['pageData'] : dataObj;
        
        List<dynamic> all = List.from(pageData is List ? pageData : []);
        
        if (mounted) {
          setState(() {
            _equipments = all;
            _isLoadingEquipments = false;
          });
          if (all.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Equipment list from API is empty.'), backgroundColor: Colors.orange),
            );
          }
        }
      } else {
        throw Exception('API Error:  - ');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingEquipments = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading equipment: '), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _fetchSchedules() async {
    try {
      final userResponse = await _userService.getCurrentUser();
      String? finalId;
      if (userResponse.status == 200 || userResponse.status == 201) {
        final payload = userResponse.data;
        dynamic userData = (payload is Map && payload.containsKey('data')) ? payload['data'] : payload;
        finalId = userData['id']?.toString() ?? userData['userId']?.toString() ?? userData['lecturerId']?.toString() ?? userData['studentId']?.toString();
      }

      // Fallback to local storage if API failed or ID is null
      if (finalId == null) {
        final localUser = await _userService.getCurrentUserLocal();
        if (localUser != null) {
          finalId = localUser['id']?.toString() ?? localUser['userId']?.toString() ?? localUser['lecturerId']?.toString();
        }
      }

      if (finalId != null) {
        ApiResponse res = await _userService.getRegistrationSchedulesByTeacherId(finalId);

        if (res.status == 200 || res.status == 201) {
          final data = res.data;
          List<dynamic> all = List.from(data is List ? data : (data is Map && data.containsKey('data') ? data['data'] : []));
          
          if (all.isEmpty && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('API returned empty list for ID: '), backgroundColor: Colors.orange),
            );
          }

          // Sort schedules by date descending (newest first)
          all.sort((a, b) {
            final dateA = a['registraionScheduleDate'] ?? a['registrationScheduleDate'] ?? a['date'] ?? '';
            final dateB = b['registraionScheduleDate'] ?? b['registrationScheduleDate'] ?? b['date'] ?? '';
            return dateB.toString().compareTo(dateA.toString());
          });

          setState(() {
            _todaySchedules = all;
            _isLoadingSchedules = false;
          });
          return;
        } else {
          throw Exception('API Call Error:  - ');
        }
      } else {
        throw Exception('Lecturer ID not found in login data!');
      }
      if (mounted) {
        setState(() => _isLoadingSchedules = false);
      }
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() => _isLoadingSchedules = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading schedules: '), backgroundColor: Colors.red),
        );
        debugPrint('Fetch schedules error: $e\n$stackTrace');
      }
    }
  }

  Future<String?> _uploadToCloudinary(File imageFile) async {
    try {
      final dio = Dio();
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imageFile.path, filename: 'report_${DateTime.now().millisecondsSinceEpoch}.jpg'),
        'upload_preset': _uploadPreset,
        'folder': 'equipment_reports',
      });

      final response = await dio.post(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
        data: formData,
        options: Options(receiveTimeout: const Duration(seconds: 30)),
      );

      if (response.statusCode == 200) {
        return response.data['secure_url'] as String?;
      }
    } on DioException catch (e) {
      debugPrint('Cloudinary upload DioError: ${e.response?.data}');
      throw Exception('Cloudinary Error: ${e.response?.data['error']?['message'] ?? e.message}');
    } catch (e) {
      debugPrint('Cloudinary upload error: $e');
      throw Exception('Error uploading image: ');
    }
    return null;
  }

  void _showEquipmentSelectorSheet() {
    _equipmentSearchQuery = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final filtered = _equipments.where((e) {
              final String name = (e['equipmentName'] ?? '').toString().toLowerCase();
              final String code = (e['equipmentCode'] ?? '').toString().toLowerCase();
              final q = _equipmentSearchQuery.toLowerCase();
              return name.contains(q) || code.contains(q);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Equipment',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1E1E1E)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: TextField(
                      autofocus: false,
                      decoration: InputDecoration(
                        hintText: 'Search equipment name or code...',
                        prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                        suffixIcon: _equipmentSearchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                                onPressed: () {
                                  setModalState(() => _equipmentSearchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFF26F21))),
                      ),
                      onChanged: (val) {
                        setModalState(() => _equipmentSearchQuery = val);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                Text(
                                  'No equipment matches "${_equipmentSearchQuery}"',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final e = filtered[index];
                              final String id = e['equipmentId']?.toString() ?? '';
                              final String name = e['equipmentName'] ?? 'Unknown';
                              final String code = e['equipmentCode'] ?? '';
                              final isSelected = _selectedEquipmentId == id;

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFF26F21).withOpacity(0.06) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFFF26F21).withOpacity(0.2) : Colors.transparent,
                                  ),
                                ),
                                child: ListTile(
                                  title: Text(
                                    name,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? const Color(0xFFF26F21) : const Color(0xFF1E1E1E),
                                    ),
                                  ),
                                  subtitle: Text(
                                    code,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? const Color(0xFFF26F21).withOpacity(0.8) : Colors.grey[500],
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFFF26F21))
                                      : null,
                                  onTap: () {
                                    this.setState(() {
                                      _selectedEquipmentId = id;
                                      _selectedEquipmentDisplay = '$code - $name';
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _takePhoto() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Select Incident Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              const Text('Take or choose a photo of the damaged equipment', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.pop(ctx, ImageSource.camera),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(color: const Color(0xFFF26F21).withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF26F21).withOpacity(0.2))),
                        child: const Column(children: [Icon(Icons.camera_alt, color: Color(0xFFF26F21), size: 32), SizedBox(height: 8), Text('Camera', style: TextStyle(color: Color(0xFFF26F21), fontWeight: FontWeight.bold))]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue.withOpacity(0.2))),
                        child: const Column(children: [Icon(Icons.photo_library, color: Colors.blue, size: 32), SizedBox(height: 8), Text('Gallery', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))]),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    if (source == ImageSource.gallery) {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(imageQuality: 75, maxWidth: 1920);
      if (pickedFiles.isEmpty) return;

      setState(() => _isUploading = true);

      try {
        for (var file in pickedFiles) {
          final String? url = await _uploadToCloudinary(File(file.path));
          if (url != null) {
            setState(() => _imageUrls.add(url));
          }
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      } finally {
        setState(() => _isUploading = false);
      }
    } else {
      final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 75, maxWidth: 1920);
      if (pickedFile == null) return;

      setState(() => _isUploading = true);

      try {
        final String? url = await _uploadToCloudinary(File(pickedFile.path));
        if (url != null) {
          setState(() => _imageUrls.add(url));
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed. Check Cloudinary preset.'), backgroundColor: Colors.red));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedScheduleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a session.'), backgroundColor: Colors.red));
      return;
    }
    if (_selectedEquipmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select the equipment.'), backgroundColor: Colors.red));
      return;
    }
    if (_imageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please capture or choose at least one incident photo.'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await _reportService.createReport(
        registraionScheduleId: _selectedScheduleId!,
        equipmentId: _selectedEquipmentId!,
        urlImg: _imageUrls.join(','),
        reportTitle: _titleController.text.trim(),
        reportDescription: _descriptionController.text.trim(),
      );

      if (response.status == 200 || response.status == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incident reported successfully!'), backgroundColor: Colors.green));
          Navigator.pop(context);
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.message ?? 'An error occurred while reporting.'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot connect to server.'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
              title: const Text('Report Incident', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5, fontSize: 24, color: Colors.white)),
              backgroundColor: Colors.white.withOpacity(0.1),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              systemOverlayStyle: SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(top: widget.hideAppBar ? 24 : 100, bottom: 40, left: 24, right: 24),
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
                       const Text('Report Equipment', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -1.0)),
                       const SizedBox(height: 12),
                       Container(
                         padding: const EdgeInsets.all(16),
                         decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                         child: const Row(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Icon(Icons.info_outline, color: Colors.white, size: 20),
                             SizedBox(width: 8),
                             Expanded(child: Text('Please provide the equipment code and actual photos so the technical department can resolve it promptly.', style: TextStyle(color: Colors.white, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500))),
                           ],
                         ),
                       ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Schedule Selection
                          const Text('Lab Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          if (_isLoadingSchedules)
                            const LinearProgressIndicator(color: Color(0xFFF26F21))
                          else if (_todaySchedules.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red[100]!)),
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.red),
                                  SizedBox(width: 12),
                                  Expanded(child: Text('You do not have any registered lab schedules.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500))),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFEEEEEE)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  isExpanded: true,
                                  value: _selectedScheduleId,
                                  hint: Text('Select Lab Schedule...', style: TextStyle(color: Colors.grey[600])),
                                  items: _todaySchedules.map((s) {
                                    final id = int.tryParse((s['registraionScheduleId'] ?? s['registrationScheduleId'] ?? s['id']).toString());
                                    final String className = s['className'] ?? s['class']?['className'] ?? 'Class';
                                    final String slotName = s['slotName'] ?? s['slot']?['slotName'] ?? 'Slot';
                                    final String labName = s['labName'] ?? s['lab']?['labName'] ?? 'Lab';
                                    final String dateStr = s['registraionScheduleDate'] ?? s['registrationScheduleDate'] ?? s['date'] ?? '';
                                    
                                    // Format the date to make the dropdown readable
                                    String displayDate = dateStr;
                                    try {
                                      if (dateStr.isNotEmpty) {
                                        displayDate = DateFormat('dd/MM/yyyy').format(DateTime.parse(dateStr));
                                      }
                                    } catch(e) {}
                                    
                                    final String display = '$displayDate: $slotName - $className ($labName)';
                                    
                                    return DropdownMenuItem<int>(
                                      value: id,
                                      child: Text(display),
                                    );
                                  }).toList(),
                                  onChanged: (val) => setState(() => _selectedScheduleId = val),
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),
                          
                          // 2. Equipment ID
                          const Text('Equipment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          if (_isLoadingEquipments)
                            const LinearProgressIndicator(color: Color(0xFFF26F21))
                          else if (_equipments.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red[100]!)),
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.red),
                                  SizedBox(width: 12),
                                  Expanded(child: Text('Could not load equipment list.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500))),
                                ],
                              ),
                            )
                           else
                            InkWell(
                              onTap: _showEquipmentSelectorSheet,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFEEEEEE)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _selectedEquipmentDisplay ?? 'Select equipment...',
                                        style: TextStyle(
                                          color: _selectedEquipmentId != null ? const Color(0xFF1E1E1E) : Colors.grey[600],
                                          fontSize: 15,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[600]),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),

                          // 3. Report Title
                          const Text('Incident Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              hintText: 'e.g., Screen won''t turn on',
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFF26F21))),
                            ),
                            validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter a title' : null,
                          ),
                          const SizedBox(height: 24),

                          // 4. Report Description
                          const Text('Detailed Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Describe the details of the problem...',
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFF26F21))),
                            ),
                            validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter a description' : null,
                          ),
                          const SizedBox(height: 32),

                           // 5. Image Upload
                          const Text('Current Status Images', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          if (_imageUrls.isNotEmpty) ...[
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemCount: _imageUrls.length + 1,
                              itemBuilder: (context, index) {
                                if (index == _imageUrls.length) {
                                  // "Add" button inside the grid
                                  return InkWell(
                                    onTap: _takePhoto,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.05),
                                        border: Border.all(color: Colors.blue.withOpacity(0.3), style: BorderStyle.solid, width: 1.5),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_a_photo, size: 24, color: Colors.blue[600]),
                                          const SizedBox(height: 4),
                                          const Text('Add More', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                final url = _imageUrls[index];
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        url,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Container(
                                            color: Colors.grey[100],
                                            child: const Center(
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF26F21)),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: InkWell(
                                        onTap: () => setState(() => _imageUrls.removeAt(index)),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ] else ...[
                            InkWell(
                              onTap: _takePhoto,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: double.infinity,
                                height: 140,
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.05),
                                  border: Border.all(color: Colors.blue.withOpacity(0.3), style: BorderStyle.solid, width: 1.5),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo, size: 40, color: Colors.blue[600]),
                                    const SizedBox(height: 12),
                                    Text('Tap to take/select photos', style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 40),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: (_isSubmitting || _isUploading) ? null : _submitReport,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF26F21),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                                disabledBackgroundColor: Colors.grey[300],
                              ),
                              child: Text(
                                _isSubmitting ? 'SUBMITTING...' : 'SUBMIT REPORT', 
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.0)
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFFF26F21)),
                    SizedBox(height: 16),
                    Text('Uploading image...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
