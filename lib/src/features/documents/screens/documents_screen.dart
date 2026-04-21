import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taxi_driver/src/core/api/api_service.dart';
import 'package:taxi_driver/src/core/providers/driver_provider.dart';

enum DocumentStatus { approved, pending, expired, verified, rejected }

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _documents = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    final driverId = driverProvider.driver?['_id'] ?? driverProvider.driver?['id'];

    if (driverId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Driver ID not found. Please log in again.';
      });
      return;
    }

    try {
      final response = await ApiService().get('driver-registration/application/$driverId');
      if (response['success'] == true) {
        final data = response['data'];
        final docs = List<Map<String, dynamic>>.from(data['documents'] ?? []);
        setState(() {
          _documents = docs;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load documents';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading documents: $e';
        _isLoading = false;
      });
    }
  }

  DocumentStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return DocumentStatus.approved;
      case 'verified': return DocumentStatus.verified;
      case 'rejected': return DocumentStatus.rejected;
      case 'expired': return DocumentStatus.expired;
      default: return DocumentStatus.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Documents',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchDocuments();
            },
          )
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _error != null 
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Alert Banner if needed
                      if (_documents.any((d) => d['status'] == 'rejected' || d['status'] == 'expired'))
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.white),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Action Required: Some documents are rejected or expired.',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              )
                            ],
                          ),
                        ),

                      // 2. Documents List
                      const Text('Uploaded Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      
                      if (_documents.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No documents uploaded yet.'),
                        ),

                      ..._documents.map((doc) {
                        return _buildDocCard(
                          title: doc['type']?.toString().toUpperCase() ?? 'DOCUMENT',
                          status: _parseStatus(doc['status'] ?? 'pending'),
                          details: 'Uploaded: ${doc['uploadedAt']?.toString().split('T')[0] ?? 'N/A'}',
                          icon: Icons.description,
                        );
                      }).toList(),

                      const SizedBox(height: 24),

                      // 5. Add New Document Button
                        SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text(
                            'Add New Document',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDocCard({
    required String title,
    required DocumentStatus status,
    required String details,
    required IconData icon,
    String? bannerMessage,
    bool hasUploadAction = false,
    bool hasUpdateAction = false,
  }) {
    Color statusColor;
    String statusText;
    
    switch (status) {
      case DocumentStatus.approved:
        statusColor = const Color(0xFF10B981); // Green
        statusText = 'Approved';
        break;
      case DocumentStatus.verified:
        statusColor = const Color(0xFF10B981); // Green
        statusText = 'Verified';
        break;
      case DocumentStatus.pending:
        statusColor = const Color(0xFFF59E0B); // Amber
        statusText = 'Pending Review';
        break;
      case DocumentStatus.expired:
        statusColor = const Color(0xFFEF4444); // Red
        statusText = 'Expired';
        break;
      case DocumentStatus.rejected:
        statusColor = const Color(0xFFEF4444); // Red
        statusText = 'Rejected';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                           Icon(Icons.remove_red_eye, size: 18, color: Colors.grey.shade400),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      Text(details, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
