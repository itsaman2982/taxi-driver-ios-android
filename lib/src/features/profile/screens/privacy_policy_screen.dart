import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          children: [
            Text(
              'Privacy Policy',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            Text(
              'Last updated: September 15, 2024',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Overview Grid
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildQuickItem(Icons.storage, 'Data Collection', 'Location, trips, device info'),
                      const SizedBox(width: 12),
                      _buildQuickItem(Icons.settings, 'Usage', 'Service delivery, safety'),
                    ],
                  ),
                  const SizedBox(height: 12),
                   Row(
                    children: [
                      _buildQuickItem(Icons.lock, 'Protection', 'Encrypted & secure'),
                      const SizedBox(width: 12),
                      _buildQuickItem(Icons.person, 'Your Rights', 'Access, delete, control'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTab('Data Collection', true),
                  _buildTab('Usage', false),
                  _buildTab('Security', false),
                  _buildTab('Your Rights', false),
                  _buildTab('Third Party', false),
                ],
              ),
            ),
             const SizedBox(height: 24),

             // Intro Text
             Text(
               'This Privacy Policy explains how we collect, use, and protect your personal information when you use our driver platform.',
               style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.5),
             ),
             const SizedBox(height: 24),

             // 1. Information We Collect
             _buildSectionHeader(Icons.storage, 'Information We Collect'),
             const SizedBox(height: 12),
             _buildInfoCard('Personal Information', [
               'Full name and contact details',
               'Driver\'s license and vehicle information',
               'Banking and payment information',
               'Background check results'
             ]),
             const SizedBox(height: 12),
             _buildInfoCard('Location Data', [
               'Real-time GPS location during trips',
               'Route and navigation data',
               'Pickup and drop-off locations'
             ]),

             const SizedBox(height: 24),

             // 2. How We Use Your Data
             _buildSectionHeader(Icons.settings, 'How We Use Your Data'),
             const SizedBox(height: 12),
             _buildProcessStep(Colors.blue, 'Service Delivery', 'To connect you with passengers and facilitate ride requests'),
             _buildProcessStep(Colors.green, 'Safety & Security', 'To verify your identity and ensure platform safety'),
             _buildProcessStep(Colors.orange, 'Payment Processing', 'To calculate earnings and process payments'),
             _buildProcessStep(Colors.purple, 'Communication', 'To send important updates and notifications'),

             const SizedBox(height: 24),

             // 3. Data Security
             _buildSectionHeader(Icons.shield, 'Data Security'),
             const SizedBox(height: 12),
             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: const Color(0xFFECFDF5),
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: const Color(0xFFD1FAE5)),
               ),
               child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.lock, color: Color(0xFF047857), size: 18),
                    SizedBox(width: 8),
                    Text('Encryption & Protection', style: TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold)),
                  ]),
                  SizedBox(height: 8),
                  Text('All sensitive data is encrypted both in transit and at rest using industry-standard encryption protocols.', style: TextStyle(color: Color(0xFF065F46), fontSize: 12)),
                ],
              ),
             ),

              const SizedBox(height: 24),

             // 4. Contact Us
             Container(
               padding: const EdgeInsets.all(20),
               decoration: BoxDecoration(
                 color: const Color(0xFFEFF6FF),
                 borderRadius: BorderRadius.circular(16),
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   const Row(
                     children: [
                       Icon(Icons.email, color: Color(0xFF1E40AF)),
                       SizedBox(width: 12),
                       Text('Contact Us', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A8A))),
                     ],
                   ),
                   const SizedBox(height: 12),
                   Text(
                     'If you have any questions about this Privacy Policy or your data rights, please contact us:',
                     style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
                   ),
                   const SizedBox(height: 16),
                   _buildContactItem(Icons.email, 'privacy@driverapp.com'),
                   const SizedBox(height: 8),
                   _buildContactItem(Icons.phone, '+91 1800-123-4567'),
                   const SizedBox(height: 20),
                   SizedBox(
                     width: double.infinity,
                     height: 45,
                     child: ElevatedButton(
                       onPressed: () {},
                       style: ElevatedButton.styleFrom(
                         backgroundColor: const Color(0xFF2563EB),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                       ),
                       child: const Text('Contact Privacy Team', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                     ),
                   )
                 ],
               ),
             ),
             const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickItem(IconData icon, String title, String subtitle) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 10, height: 1.2)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTab(String text, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? Colors.black : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

   Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.black),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildInfoCard(String title, List<String> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: Colors.grey)),
                Expanded(child: Text(item, style: TextStyle(color: Colors.grey.shade700, fontSize: 13))),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildProcessStep(Color color, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Container(
             margin: const EdgeInsets.only(top: 4),
             width: 8,
             height: 8,
             decoration: BoxDecoration(color: color, shape: BoxShape.circle),
           ),
           const SizedBox(width: 12),
           Expanded(
             child: RichText(
               text: TextSpan(
                 style: const TextStyle(fontSize: 13, color: Colors.black),
                 children: [
                   TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                   TextSpan(text: desc, style: TextStyle(color: Colors.grey.shade700)),
                 ],
               ),
             ),
           )
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blue.shade800),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.w500, fontSize: 13)),
      ],
    );
  }
}
