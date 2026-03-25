import 'package:flutter/material.dart';

class IncidentReportsScreen extends StatefulWidget {
  const IncidentReportsScreen({super.key});

  @override
  State<IncidentReportsScreen> createState() => _IncidentReportsScreenState();
}

class _IncidentReportsScreenState extends State<IncidentReportsScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Danh sách report mẫu
  List<Map<String, String>> reports = [
    {
      'title': 'Broken Oscilloscope',
      'date': '2025-10-08',
      'status': 'Resolved',
    },
    {
      'title': 'Power Outage in Lab 3',
      'date': '2025-10-05',
      'status': 'Pending',
    },
    {'title': 'Damaged Cable', 'date': '2025-10-02', 'status': 'Resolved'},
  ];

  String searchText = '';

  @override
  Widget build(BuildContext context) {
    // Lọc danh sách theo search text
    final filteredReports = reports
        .where(
          (r) => r['title']!.toLowerCase().contains(searchText.toLowerCase()),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Reports'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Ô tìm kiếm
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search reports...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() => searchText = value);
              },
            ),
            const SizedBox(height: 16),

            // Danh sách reports
            Expanded(
              child: filteredReports.isEmpty
                  ? const Center(
                      child: Text(
                        'No incident reports found.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredReports.length,
                      itemBuilder: (context, index) {
                        final report = filteredReports[index];
                        final isResolved =
                            report['status']!.toLowerCase() == 'resolved';
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(
                              report['title']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Date: ${report['date']}'),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      isResolved
                                          ? Icons.check_circle
                                          : Icons.pending,
                                      color: isResolved
                                          ? Colors.green
                                          : Colors.orangeAccent,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      report['status']!,
                                      style: TextStyle(
                                        color: isResolved
                                            ? Colors.green
                                            : Colors.orangeAccent,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // TODO: mở chi tiết report sau này
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () {
          // TODO: mở form thêm report
        },
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }
}
