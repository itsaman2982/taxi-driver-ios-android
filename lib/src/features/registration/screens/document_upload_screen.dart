import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:taxi_driver/src/core/providers/registration_provider.dart';
import 'package:taxi_driver/src/features/registration/screens/application_status_screen.dart';

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickDocument(String documentType) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      if (!mounted) return;
      final provider = Provider.of<RegistrationProvider>(context, listen: false);
      provider.setDocument(documentType, File(image.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _takePhoto(String documentType) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image == null) return;
      if (!mounted) return;
      final provider = Provider.of<RegistrationProvider>(context, listen: false);
      provider.setDocument(documentType, File(image.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    }
  }

  void _showDocumentDetailsDialog(String documentType) {
    String docNumber = '';
    String expiryDate = '';
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter ${documentType.replaceAllMapped(RegExp('([A-Z])'), (m) => ' ${m.group(0)!}').capitalize()} Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Document Number'),
                onChanged: (value) => docNumber = value,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(labelText: 'Expiry Date (YYYY-MM-DD)'),
                onChanged: (value) => expiryDate = value,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final provider = Provider.of<RegistrationProvider>(context, listen: false);
                provider.setDocumentDetail(documentType, 'docNumber', docNumber);
                provider.setDocumentDetail(documentType, 'expiryDate', expiryDate);
                Navigator.pop(context);
                _showImageSourceDialog(documentType);
              },
              child: const Text('Save & Upload Photo'),
            ),
          ],
        );
      },
    );
  }

  void _showImageSourceDialog(String documentType) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto(documentType);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickDocument(documentType);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _continueToNext() {
    final provider = Provider.of<RegistrationProvider>(context, listen: false);
    
    // Check required documents
    if (provider.documents['driverLicense'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload driver\'s license')),
      );
      return;
    }
    /* 
    if (provider.documents['vehicleRegistration'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload vehicle registration')),
      );
      return;
    }
    if (provider.documents['insurance'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload insurance certificate')),
      );
      return;
    }
    */
    if (provider.documents['kyc'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload KYC document')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ApplicationStatusScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Step 2 of 3',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
                Text(
                  '66%',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 8,
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                child: LinearProgressIndicator(
                  value: 0.66,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 12 / 255),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.center,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.yellow.withValues(alpha: 12 / 255),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Consumer<RegistrationProvider>(
            builder: (context, provider, child) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.blue.withValues(alpha: 50 / 255),
                              width: 8,
                            ),
                          ),
                          child: const Icon(
                            Icons.description_outlined,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'Document Uploads',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Upload clear photos of your required documents',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 30),

                      _buildDocumentCard(
                        title: "Driver's License",
                        subtitle: "Upload both front and back",
                        isRequired: true,
                        icon: Icons.badge_outlined,
                        documentType: 'driverLicense',
                        uploadedFile: provider.documents['driverLicense'],
                        details: provider.documentDetails['driverLicense'],
                      ),

                      _buildDocumentCard(
                        title: "Vehicle Registration",
                        subtitle: "RC book or registration certificate",
                        isRequired: false,
                        icon: Icons.directions_car_outlined,
                        documentType: 'vehicleRegistration',
                        uploadedFile: provider.documents['vehicleRegistration'],
                        details: provider.documentDetails['vehicleRegistration'],
                      ),

                      _buildDocumentCard(
                        title: "Vehicle Insurance",
                        subtitle: "Valid insurance certificate",
                        isRequired: false,
                        icon: Icons.security_outlined,
                        documentType: 'insurance',
                        uploadedFile: provider.documents['insurance'],
                        details: provider.documentDetails['insurance'],
                      ),

                      _buildKycCard(provider),

                      _buildDocumentCard(
                        title: "PUC Document",
                        subtitle: "Pollution Under Control certificate",
                        isRequired: false,
                        icon: Icons.assignment_outlined,
                        documentType: 'puc',
                        uploadedFile: provider.documents['puc'],
                        details: provider.documentDetails['puc'],
                      ),

                      _buildDocumentCard(
                        title: "Police Verification",
                        subtitle: "Police clearance certificate",
                        isRequired: false,
                        icon: Icons.verified_user_outlined,
                        documentType: 'policeVerification',
                        uploadedFile: provider.documents['policeVerification'],
                      ),

                      const SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 12 / 255),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info_outline, size: 20, color: Colors.black87),
                                SizedBox(width: 8),
                                Text(
                                  'Photo Guidelines',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildGuidelineItem('Take photos in good lighting'),
                            _buildGuidelineItem('Ensure all text is clearly readable'),
                            _buildGuidelineItem('Avoid glare and shadows'),
                            _buildGuidelineItem('Keep documents flat and straight'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      ElevatedButton(
                        onPressed: _continueToNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Continue to Next Step',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, color: Colors.white),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text.rich(
                        TextSpan(
                          text: 'Your documents are encrypted and secure. We comply with all data protection regulations.\n\nBy uploading, you agree to our ',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          children: const [
                            TextSpan(
                              text: 'Terms of Service',
                              style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                            ),
                            TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required String subtitle,
    required bool isRequired,
    required IconData icon,
    required String documentType,
    File? uploadedFile,
    Map<String, String>? details,
  }) {
    final hasDetails = details != null && details['docNumber']!.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: uploadedFile != null ? Colors.green : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 20 / 255),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: uploadedFile != null ? Colors.green.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: uploadedFile != null ? Colors.green : Colors.black87),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      isRequired ? '* Required' : '* Optional',
                      style: TextStyle(
                        color: isRequired ? Colors.red : Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                uploadedFile != null ? Icons.check_circle : Icons.add_circle_outline,
                color: uploadedFile != null ? Colors.green : Colors.grey.shade400,
              ),
            ],
          ),
          if (hasDetails) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                   const Icon(Icons.info_outline, size: 14, color: Colors.blue),
                   const SizedBox(width: 8),
                   Text('No: ${details['docNumber']} | Exp: ${details['expiryDate']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
          if (uploadedFile != null) ...[
            const SizedBox(height: 16),
            Container(
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: FileImage(uploadedFile),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showDocumentDetailsDialog(documentType),
            icon: Icon(uploadedFile != null ? Icons.refresh : Icons.add, size: 16, color: Colors.white),
            label: Text(uploadedFile != null ? 'Replace Document' : 'Upload Document'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKycCard(RegistrationProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: provider.documents['kyc'] != null ? Colors.green : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 20 / 255),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: provider.documents['kyc'] != null ? Colors.green.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person_pin_outlined, color: provider.documents['kyc'] != null ? Colors.green : Colors.black87),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'KYC Document',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Aadhaar Card, PAN Card, or Passport',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '* Required',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                provider.documents['kyc'] != null ? Icons.check_circle : Icons.add_circle_outline,
                color: provider.documents['kyc'] != null ? Colors.green : Colors.grey.shade400,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Select document type:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildChoiceChip('Aadhaar', provider),
              const SizedBox(width: 8),
              _buildChoiceChip('PAN Card', provider),
              const SizedBox(width: 8),
              _buildChoiceChip('Passport', provider),
            ],
          ),
          if (provider.documents['kyc'] != null) ...[
            const SizedBox(height: 16),
            Container(
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: FileImage(provider.documents['kyc']!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showImageSourceDialog('kyc'),
            icon: Icon(provider.documents['kyc'] != null ? Icons.refresh : Icons.add, size: 16, color: Colors.white),
            label: Text(provider.documents['kyc'] != null ? 'Replace KYC' : 'Upload KYC'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String label, RegistrationProvider provider) {
    bool isSelected = provider.selectedKycType == label;
    return GestureDetector(
      onTap: () {
        provider.setKycType(label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.grey.shade600,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildGuidelineItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.check, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
