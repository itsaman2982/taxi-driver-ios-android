import 'package:flutter/material.dart';

class DataSecurityScreen extends StatelessWidget {
  const DataSecurityScreen({super.key});

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
        title: Column(
          children: [
            const Text(
              'Data & Security',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            Text(
              'Your privacy and security settings',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Hero Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shield, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your data is our top priority',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'We employ industry-leading security measures to protect your personal and financial information.',
                          style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // How We Protect You
             Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'How We Protect You',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey.shade900),
              ),
            ),
            const SizedBox(height: 16),
            _buildProtectionCard(
              Icons.lock,
              'End-to-End Encryption',
              'All your personal and financial data is encrypted during transmission.',
              'Bank-grade security',
            ),
             _buildProtectionCard(
              Icons.credit_card,
              'Secure Payment Processing',
              'We use PCI-DSS compliant payment processors for all transactions.',
              'PCI-DSS Certified',
            ),
             _buildProtectionCard(
              Icons.security,
              'Account Protection',
              'Two-Factor Authentication (2FA) and fraud detection systems protect your account.',
              '24/7 monitoring',
            ),

            const SizedBox(height: 24),

            // Your Security Controls
             Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Your Security Controls',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey.shade900),
              ),
            ),
            const SizedBox(height: 16),
            _buildControlTile(Icons.vpn_key, 'Manage Password', 'Change your account password', true),
            
            // 2FA Toggle
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset:const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                    child: const Icon(Icons.smartphone, size: 20, color: Colors.black87),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Two-Factor Authentication', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('Add an extra layer of security', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
                  const Text('Enabled', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                  const SizedBox(width: 8),
                  Switch(
                    value: true, 
                    onChanged: (v) {},
                    activeThumbColor: Colors.black,
                  )
                ],
              ),
            ),
             _buildControlTile(Icons.history, 'Login Activity', 'View recent login locations', true),

            const SizedBox(height: 24),

            // Data Management
             Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Data Management',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey.shade900),
              ),
            ),
            const SizedBox(height: 16),
            _buildControlTile(Icons.download, 'Download My Data', 'Get a copy of your personal data', true),
            _buildControlTile(Icons.description, 'Privacy Policy', 'Read our complete privacy policy', true),

             const SizedBox(height: 24),

             // Report Security Issue
             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: const Color(0xFFFEF2F2),
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: const Color(0xFFFFE4E6)),
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   const Row(
                     children: [
                       Icon(Icons.warning, color: Colors.red),
                       SizedBox(width: 8),
                       Text('Report a Security Concern', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                     ],
                   ),
                   const SizedBox(height: 8),
                   const Text(
                     'If you suspect unauthorized access or notice suspicious activity, report it immediately.',
                     style: TextStyle(color: Color(0xFF991B1B), fontSize: 12, height: 1.4),
                   ),
                   const SizedBox(height: 12),
                   ElevatedButton.icon(
                      onPressed: () {}, 
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                      icon: const Icon(Icons.shield, color: Colors.white, size: 16),
                      label: const Text('Report Security Issue', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                   ),
                 ],
               ),
             ),

             const SizedBox(height: 24),

             // Security Tips
             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: const Color(0xFFEFF6FF),
                 borderRadius: BorderRadius.circular(12),
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    const Text('Security Tips', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildSecurityTip('Never share your login credentials with anyone'),
                    _buildSecurityTip('Always log out from shared devices'),
                    _buildSecurityTip('Keep your app updated for latest security patches'),
                 ],
               ),
             ),
             const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildProtectionCard(IconData icon, String title, String desc, String badge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset:const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 20, color: Colors.black87),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
            ],
          ),
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.4)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.check_circle, size: 14, color: Colors.green),
              const SizedBox(width: 6),
              Text(badge, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildControlTile(IconData icon, String title, String subtitle, bool showArrow) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
         boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset:const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
           Container(
             padding: const EdgeInsets.all(8),
             decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
             child: Icon(icon, size: 20, color: Colors.black87),
           ),
           const SizedBox(width: 16),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                 Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
               ],
             ),
           ),
           if (showArrow) const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildSecurityTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: Colors.blue.shade900))),
        ],
      ),
    );
  }
}
