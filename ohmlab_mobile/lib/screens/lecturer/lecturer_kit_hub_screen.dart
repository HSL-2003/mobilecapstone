import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ohm_lab_mobile/services/user_services.dart';
import 'package:ohm_lab_mobile/services/report_services.dart';
import 'lecturer_kit_history_screen.dart';

class LecturerKitHubScreen extends StatelessWidget {
  const LecturerKitHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, 
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text('Kit Management', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: -0.5, color: Color(0xFF1E1E1E))),
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
                  Tab(text: 'Scan Kit'),
                  Tab(text: 'History'),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            _GlobalKitScanner(),
            LecturerKitHistoryScreen(hideAppBar: true),
          ],
        ),
      ),
    );
  }
}

class _GlobalKitScanner extends StatefulWidget {
  const _GlobalKitScanner();

  @override
  State<_GlobalKitScanner> createState() => _GlobalKitScannerState();
}

class _GlobalKitScannerState extends State<_GlobalKitScanner> {
  final ReportService _reportService = ReportService();
  final UserService _userService = UserService();
  final MobileScannerController _scannerController = MobileScannerController();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isLoadingKits = true;
  List<dynamic> _kits = [];

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchKits();
  }

  Future<void> _fetchKits() async {
    try {
      final res = await _userService.searchKits(
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
                _kits = payloadData['pageData'] is List ? payloadData['pageData'] : [];
              } else if (payloadData is List) {
                _kits = payloadData;
              }
            }
            _isLoadingKits = false;
          });
        }
      } else {
        if (mounted) setState(() { _isLoadingKits = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoadingKits = false; });
    }
  }

  void _onQRScanned(BuildContext context, String scannedCode) {
    String kitId = scannedCode;
    if (scannedCode.startsWith('http')) {
      try {
        final uri = Uri.parse(scannedCode);
        kitId = uri.pathSegments.last;
      } catch (_) {}
    }
    _fetchAndShowKitById(context, kitId);
  }

  Future<void> _fetchAndShowKitById(BuildContext context, String id) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFF26F21))),
    );

    try {
      final res = await _userService.getKitById(id);
      Navigator.pop(context);

      if (res.status == 200 || res.status == 201) {
        final data = res.data;
        final kit = (data is Map && data.containsKey('data')) ? data['data'] : data;
        if (mounted) _showKitDetailDialog(context, kit);
      } else {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message ?? 'Kit information not found.'), backgroundColor: Colors.red));
      }
    } catch (e) {
      Navigator.pop(context);
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API connection error for Kit.'), backgroundColor: Colors.red));
    }
  }

  Future<void> _pickAndScanImage() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final BarcodeCapture? capture = await _scannerController.analyzeImage(image.path);
    if (capture != null && capture.barcodes.isNotEmpty) {
      final String? code = capture.barcodes.first.rawValue;
      if (code != null && mounted) _onQRScanned(context, code);
    } else if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR code not found in image!'), backgroundColor: Colors.red));
    }
  }

  void _simulateScan() {
    if (_kits.isNotEmpty) {
      final first = _kits.first;
      final String id = (first['kitId'] ?? first['id'])?.toString() ?? '';
      if (id.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Simulating scan for first kit...'), duration: Duration(seconds: 1)));
        _fetchAndShowKitById(context, id);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No kits available to simulate scan.')));
    }
  }

  void _showKitDetailDialog(BuildContext context, Map<String, dynamic> kit) {
    final String kitId = (kit['kitId'] ?? kit['id'] ?? '-').toString();
    final String kitName = kit['kitName'] ?? kit['name'] ?? 'Unknown';
    final String kitCode = kit['kitCode']?.toString() ?? '-';
    final String status = kit['status']?.toString() ?? 'N/A';
    final String desc = kit['description']?.toString() ?? '';
    final String? qrBase64 = kit['kitQr']?.toString();

    Color statusColor = Colors.grey;
    if (status.toLowerCase() == 'available') statusColor = Colors.green;
    if (status.toLowerCase() == 'in use' || status.toLowerCase() == 'inuse') statusColor = Colors.orange;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.inventory_2, size: 36, color: Color(0xFFF26F21)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(kitName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF1E1E1E))),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow(Icons.fingerprint, 'Kit ID', kitId),
              _buildDetailRow(Icons.qr_code, 'Kit Code', kitCode),
              if (desc.isNotEmpty && desc != 'string') _buildDetailRow(Icons.info_outline, 'Description', desc),
              
              if (qrBase64 != null && qrBase64.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('Kit QR Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E1E1E))),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 4))],
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Builder(
                      builder: (_) {
                        try {
                          final bytes = base64Decode(qrBase64);
                          return Image.memory(bytes, width: 200, height: 200, fit: BoxFit.contain);
                        } catch (_) {
                          return const Icon(Icons.broken_image, size: 100, color: Colors.grey);
                        }
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.handshake, color: Colors.white),
                  label: const Text('Borrow for Team', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showBorrowBottomSheet(context, kitId, kitName);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF26F21),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFFF26F21)),
          const SizedBox(width: 12),
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54, fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(color: Color(0xFF1E1E1E), fontWeight: FontWeight.w500, fontSize: 14))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Global Kit Scanner', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E1E1E), letterSpacing: -0.5)),
        const SizedBox(height: 16),
        Container(
          height: 280,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: const Color(0xFFF26F21).withOpacity(0.2), blurRadius: 25, offset: const Offset(0, 10))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: (capture) {
                  final barcode = capture.barcodes.firstOrNull;
                  if (barcode?.rawValue != null) {
                    _onQRScanned(context, barcode!.rawValue!);
                  }
                },
              ),
              Positioned.fill(
                child: CustomPaint(painter: _QRViewfinderPainter()),
              ),
              Positioned(
                top: 12, right: 12,
                child: Container(
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
                  child: IconButton(
                    icon: const Icon(Icons.photo_library, color: Colors.white),
                     tooltip: 'Upload QR image from gallery',
                    onPressed: _pickAndScanImage,
                  ),
                ),
              ),
              Positioned(
                top: 12, right: 64,
                child: Container(
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
                  child: IconButton(
                    icon: const Icon(Icons.center_focus_strong, color: Colors.white),
                      tooltip: 'Simulate Scan (Test)',
                    onPressed: _simulateScan,
                  ),
                ),
              ),
              const Positioned(
                bottom: 12, left: 0, right: 0,
                child: Center(
                   child: Text('Place QR code inside the frame to scan', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text('All Active Kits', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E1E1E), letterSpacing: -0.5)),
        const SizedBox(height: 16),
        if (_isLoadingKits)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFFF26F21))))
        else if (_kits.isEmpty)
           const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No kit data available.', style: TextStyle(color: Colors.grey))))
        else
           ..._kits.map((kit) {
              final name = kit['kitName'] ?? kit['name'] ?? kit['kitCode'] ?? 'Unknown Kit';
              final desc = kit['description'] ?? '';
              final title = desc.isNotEmpty ? '$name ($desc)' : name;
              final status = kit['status']?.toString() ?? '';
              
              final String kitId = (kit['kitId'] ?? kit['id'])?.toString() ?? '';
              
              return GestureDetector(
                onTap: kitId.isNotEmpty ? () => _fetchAndShowKitById(context, kitId) : null,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.inventory_2, color: Color(0xFFF26F21), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1E1E1E))),
                            if (status.isNotEmpty) 
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('Status: $status', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              )
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.handshake_outlined, color: Color(0xFFF26F21)),
                         tooltip: 'Assign to Team',
                        onPressed: () {
                          if (kitId.isNotEmpty) {
                            _showBorrowBottomSheet(context, kitId, name);
                          } else {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid kit (missing ID).')));
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
           }).toList(),
      ],
    );
  }

  void _showBorrowBottomSheet(BuildContext context, String kitId, String kitName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BorrowKitForm(kitId: kitId, kitName: kitName),
    );
  }
}

class _QRViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF26F21)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    const cornerSize = 30.0;
    const padding = 60.0;
    final rect = Rect.fromLTRB(padding, padding, size.width - padding, size.height - padding);

    // Top Left
    canvas.drawPath(Path()..moveTo(rect.left, rect.top + cornerSize)..lineTo(rect.left, rect.top)..lineTo(rect.left + cornerSize, rect.top), paint);
    // Top Right
    canvas.drawPath(Path()..moveTo(rect.right - cornerSize, rect.top)..lineTo(rect.right, rect.top)..lineTo(rect.right, rect.top + cornerSize), paint);
    // Bottom Left
    canvas.drawPath(Path()..moveTo(rect.left, rect.bottom - cornerSize)..lineTo(rect.left, rect.bottom)..lineTo(rect.left + cornerSize, rect.bottom), paint);
    // Bottom Right
    canvas.drawPath(Path()..moveTo(rect.right - cornerSize, rect.bottom)..lineTo(rect.right, rect.bottom)..lineTo(rect.right, rect.bottom - cornerSize), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BorrowKitForm extends StatefulWidget {
  final String kitId;
  final String kitName;

  const _BorrowKitForm({required this.kitId, required this.kitName});

  @override
  State<_BorrowKitForm> createState() => _BorrowKitFormState();
}

class _BorrowKitFormState extends State<_BorrowKitForm> {
  final UserService _userService = UserService();
  
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  
  List<dynamic> _teamsList = [];
  bool _isLoadingTeams = true;
  String? _selectedTeamId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = 'Borrow ' + widget.kitName;
    _fetchLecturerTeams();
  }

  Future<void> _fetchLecturerTeams() async {
    try {
      final userResponse = await _userService.getCurrentUser();
      if (userResponse.status == 200 || userResponse.status == 201) {
        final payload = userResponse.data;
        dynamic userData = (payload is Map && payload.containsKey('data') && payload['data'] != null)
            ? payload['data']
            : payload;
        
        // Prioritize lecturerId UUID over the general user account id
        final String? lecturerId = userData['lecturerId']?.toString() ?? userData['id']?.toString() ?? userData['userId']?.toString();
        
        if (lecturerId != null) {
          final teamsRes = await _userService.getLecturerTeams(lecturerId);
          if (teamsRes.status == 200 || teamsRes.status == 201) {
            final tPayload = teamsRes.data;
            List<dynamic> loadedTeams = [];
            if (tPayload is Map && tPayload.containsKey('data')) {
              loadedTeams = tPayload['data'] is List ? tPayload['data'] : [];
            } else if (tPayload is List) {
              loadedTeams = tPayload;
            }
            if (mounted) {
              setState(() {
                _teamsList = loadedTeams;
                _isLoadingTeams = false;
              });
            }
            return;
          }
        }
      }
      if (mounted) {
        setState(() => _isLoadingTeams = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingTeams = false);
      }
    }
  }

  Future<void> _submit() async {
    final nameText = _nameController.text.trim();
    
    if (_selectedTeamId == null || nameText.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a Team and enter Kit Name!')));
      return;
    }

    final int? tId = int.tryParse(_selectedTeamId!);
    if (tId == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Team selected!')));
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      final payload = {
        "teamId": tId,
        "kitId": widget.kitId,
        "teamKitName": nameText,
        "teamKitDescription": _descController.text.trim(),
      };

      final res = await _userService.borrowKit(payload);
      
      setState(() => _isSaving = false);
      
      if (res.status == 200 || res.status == 201) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kit assigned to Team successfully!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${res.message ?? "Cannot assign Kit."}'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Server connection error.'), backgroundColor: Colors.red));
      }
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
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assign Kit: ${widget.kitName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E1E1E))),
            const SizedBox(height: 24),
            _buildField('Kit Name (For Team) *', _nameController),
            
            if (_isLoadingTeams)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Center(child: CircularProgressIndicator(color: Color(0xFFF26F21))),
              )
            else if (_teamsList.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text('No teams found. Please create a team first.', style: TextStyle(color: Colors.red)),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DropdownButtonFormField<String>(
                  value: _selectedTeamId,
                  hint: const Text('Select Team *'),
                  decoration: InputDecoration(
                    labelText: 'Team *',
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFF26F21))),
                  ),
                  items: _teamsList.map((t) {
                    final String tId = (t['teamId'] ?? t['id'] ?? '').toString();
                    final String tName = t['teamName'] ?? t['name'] ?? 'Unknown Team';
                    final String className = t['className'] ?? '';
                    final String displayStr = className.isNotEmpty ? '$tName ($className)' : tName;
                    return DropdownMenuItem<String>(
                      value: tId,
                      child: Text(displayStr),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedTeamId = val;
                    });
                  },
                ),
              ),

            _buildField('Additional Notes', _descController, maxLines: 2),
            
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
                  : const Text('Assign Kit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
