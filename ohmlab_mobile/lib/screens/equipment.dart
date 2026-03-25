import 'package:flutter/material.dart';

class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({super.key});

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All';
  
  final List<String> _statusOptions = ['All', 'Available', 'InUse', 'Maintenance', 'Damaged'];
  
  final List<Map<String, dynamic>> _equipmentList = [
    {
      'id': 1,
      'name': 'Digital Multimeter',
      'serialNumber': 'DMM-001',
      'status': 'Available',
      'image': 'https://via.placeholder.com/150x100/4CAF50/FFFFFF?text=DMM',
    },
    {
      'id': 2,
      'name': 'Oscilloscope',
      'serialNumber': 'OSC-002',
      'status': 'InUse',
      'image': 'https://via.placeholder.com/150x100/FF9800/FFFFFF?text=OSC',
    },
    {
      'id': 3,
      'name': 'Function Generator',
      'serialNumber': 'FG-003',
      'status': 'Maintenance',
      'image': 'https://via.placeholder.com/150x100/FF5722/FFFFFF?text=FG',
    },
    {
      'id': 4,
      'name': 'Power Supply',
      'serialNumber': 'PS-004',
      'status': 'Available',
      'image': 'https://via.placeholder.com/150x100/4CAF50/FFFFFF?text=PS',
    },
    {
      'id': 5,
      'name': 'Signal Analyzer',
      'serialNumber': 'SA-005',
      'status': 'Damaged',
      'image': 'https://via.placeholder.com/150x100/F44336/FFFFFF?text=SA',
    },
    {
      'id': 6,
      'name': 'Logic Analyzer',
      'serialNumber': 'LA-006',
      'status': 'Available',
      'image': 'https://via.placeholder.com/150x100/4CAF50/FFFFFF?text=LA',
    },
  ];

  List<Map<String, dynamic>> get _filteredEquipment {
    List<Map<String, dynamic>> filtered = _equipmentList;
    
    // Filter by status
    if (_selectedStatus != 'All') {
      filtered = filtered.where((equipment) => equipment['status'] == _selectedStatus).toList();
    }
    
    // Filter by search query
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((equipment) {
        return equipment['name'].toLowerCase().contains(_searchController.text.toLowerCase()) ||
               equipment['serialNumber'].toLowerCase().contains(_searchController.text.toLowerCase());
      }).toList();
    }
    
    return filtered;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Available':
        return Colors.green;
      case 'InUse':
        return Colors.blue;
      case 'Maintenance':
        return Colors.orange;
      case 'Damaged':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment'),
        centerTitle: true,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search equipment...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: const BorderSide(color: Colors.orange),
                    ),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 16),
                // Status Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusOptions.map((status) {
                      final isSelected = _selectedStatus == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(status),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedStatus = status;
                            });
                          },
                          selectedColor: Colors.green.shade100,
                          checkmarkColor: Colors.green,
                          backgroundColor: Colors.grey.shade200,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // Equipment List
          Expanded(
            child: _filteredEquipment.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No equipment found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredEquipment.length,
                    itemBuilder: (context, index) {
                      final equipment = _filteredEquipment[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Equipment Image
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey.shade200,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    equipment['image'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade300,
                                        child: const Icon(
                                          Icons.electrical_services,
                                          size: 40,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Equipment Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      equipment['name'],
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Serial: ${equipment['serialNumber']}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(equipment['status']).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: _getStatusColor(equipment['status']),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        equipment['status'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _getStatusColor(equipment['status']),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
