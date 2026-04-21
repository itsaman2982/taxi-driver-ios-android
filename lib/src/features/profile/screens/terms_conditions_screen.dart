import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

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
              'Terms & Conditions',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Last updated: March 15, 2025',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
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
            // Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTab('Service Agreement', true),
                  _buildTab('Driver Terms', false),
                  _buildTab('Payment Policy', false),
                  _buildTab('FAQs', false),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Important Terms Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF), // Light Blue
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info, color: Color(0xFF2563EB), size: 20),
                      SizedBox(width: 8),
                      Text('Important Terms', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'These terms cover your use of the driver platform. Please read them carefully as they constitute a binding legal agreement. By using our services, you agree to be bound by these terms.',
                    style: TextStyle(color: Colors.blue.shade900, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle(Icons.handshake, 'Service Agreement'),
            const SizedBox(height: 16),
            
            // 1.1 Platform Service
            const Text('1.1 Platform Service', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              'Our platform connects you (independent provider) with passengers seeking transportation services. We provide the technology platform, while you provide the transportation services.',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 8),
            _buildBulletPoint('Connect with riders efficiently'),
            _buildBulletPoint('Real-time routing and navigation'),
            _buildBulletPoint('Secure payment processing'),
            _buildBulletPoint('Quality assurance and safety tools'),
            const SizedBox(height: 24),

             // 1.2 Independent Contractor Relationship
            const Text('1.2 Independent Contractor Relationship', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              'You acknowledge that you are an independent contractor, not an employee. You have full control over your schedule, vehicle, and method of work within platform standards.',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),

            // 1.3 Eligibility Requirements
            const Text('1.3 Eligibility Requirements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Text('To use our services, you must:', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
            const SizedBox(height: 8),
            _buildBulletPoint('Be at least 21 years old'),
            _buildBulletPoint('Hold a valid driver\'s license'),
            _buildBulletPoint('Pass a background and driving record check'),
            _buildBulletPoint('Provide valid vehicle registration and insurance'),
            _buildBulletPoint('Comply with all applicable laws and regulations'),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 32),

            _buildSectionTitle(Icons.person, 'Driver Responsibilities'),
            const SizedBox(height: 16),

            // 2.1 Vehicle Standards
            const Text('2.1 Vehicle Standards', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
             _buildBulletPoint('Maintain vehicle in safe, clean, and roadworthy condition'),
             _buildBulletPoint('Undergo annual inspections as required by law'),
             _buildBulletPoint('No personal items cluttering passenger space'),
            const SizedBox(height: 24),

            // 2.2 Professional Conduct
             const Text('2.2 Professional Conduct', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
             const SizedBox(height: 8),
             _buildBulletPoint('Professional dress code and hygiene'),
             _buildBulletPoint('Polite and helpful communication'),
             _buildBulletPoint('No discrimination against any passenger'),
             _buildBulletPoint('Respect passenger privacy and data'),
            const SizedBox(height: 24),

            // 2.3 Prohibited Activities (Red Box)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2), // Light Red/Pink
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFE4E6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning, color: Color(0xFFE11D48), size: 18),
                      SizedBox(width: 8),
                      Text('Prohibited Activities', style: TextStyle(color: Color(0xFF9F1239), fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildRedBullet('Driving under the influence of drugs or alcohol'),
                  _buildRedBullet('Carrying weapons of any kind'),
                  _buildRedBullet('Accepting street hails (off-app trips)'),
                  _buildRedBullet('Asking for cash payments (unless cash trip)'),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 32),

            _buildSectionTitle(Icons.account_balance_wallet, 'Payment & Commissions'),
            const SizedBox(height: 16),
            
            // 3.1 Commission Structure
            const Text('3.1 Commission Structure', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
             Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA), 
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildPaymentRow('Base Fare', 'Platform Commission varies'),
                  const Divider(height: 16),
                  _buildPaymentRow('Service Fee', '15% (Fixed per ride)'),
                  const Divider(height: 16),
                  _buildPaymentRow('Driver Earnings', '85% (Direct to You)'),
                ],
              ),
            ),
             const SizedBox(height: 24),

             // 3.2 Payment Terms
             const Text('3.2 Payment Terms', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
             const SizedBox(height: 8),
             _buildBulletPoint('Weekly automatic transfers to your registered bank account'),
             _buildBulletPoint('Instant cash-out available for eligible trips charges apply'),
             _buildBulletPoint('We are not responsible for delays by your bank'),
             const SizedBox(height: 24),

             // 3.3 Cancellation Fees
             const Text('3.3 Cancellation Fees', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
             const SizedBox(height: 8),
             Text(
               'Cancellation fees apply if a rider cancels after 2 minutes or is a no-show. You receive 100% of the cancellation fee.',
               style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.5),
             ),
             
             const SizedBox(height: 32),
             const Divider(),
             const SizedBox(height: 32),

             _buildSectionTitle(Icons.smartphone, 'App Usage'),
             const SizedBox(height: 16),
             
             // 4.1 License Grant
             const Text('4.1 License Use', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
             const SizedBox(height: 8),
             _buildBulletPoint('Use the app only for legitimate service delivery'),
             _buildBulletPoint('No reverse engineering or data scraping'),
             _buildBulletPoint('Use only approved devices and software versions'),
             const SizedBox(height: 24),
             
             // 4.2 Prohibited Uses
             Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF), // Light Blue tint
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    const Row(
                    children: [
                      Icon(Icons.block, color: Color(0xFF2563EB), size: 18),
                      SizedBox(width: 8),
                      Text('Prohibited Uses', style: TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildBlueBullet('Attempting to defraud the system or promotions'),
                  _buildBlueBullet('Sharing accounts with other drivers'),
                  _buildBlueBullet('Using GPS spoofing tools'),
                  _buildBlueBullet('Harassing or stalking users'),
                 ],
               ),
             ),
             
             const SizedBox(height: 32),
             const Divider(),
             const SizedBox(height: 32),

             _buildSectionTitle(Icons.gavel, 'Dispute Resolution'),
             const SizedBox(height: 16),
             
             // 5.1 Communication Process
             const Text('5.1 Communication Process', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
             const SizedBox(height: 12),
             _buildNumberedItem('1', 'Submit Request', 'Report disputes via the app within 24 hours of the trip.'),
             _buildNumberedItem('2', 'Investigation', 'Our team reviews trip data, GPS logs, and communications.'),
             _buildNumberedItem('3', 'Resolution', 'Final decision communicated via email within 3 business days.'),
             
             const SizedBox(height: 24),
             
             const Text('5.2 Limitation of Liability', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
             const SizedBox(height: 8),
             Text(
               'We are not liable for indirect, incidental, or  damages arising from your use of the platform. Your sole remedy is to stop using the service.',
               style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.5),
             ),

             const SizedBox(height: 32),
             const Divider(),
             const SizedBox(height: 32),

             _buildSectionTitle(Icons.cancel_presentation, 'Termination'),
             const SizedBox(height: 16),

             const Text('6.1 Voluntary Termination', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
             const SizedBox(height: 8),
             Text(
               'You may terminate this agreement at any time by deleting your account and ceasing use of the app.',
               style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.5),
             ),
             const SizedBox(height: 24),
             
             const Text('6.2 Involuntary Termination', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
             const SizedBox(height: 8),
             Text('We may terminate your access immediately for:', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w500, fontSize: 13)),
             const SizedBox(height: 8),
             _buildRedBullet('Violation of Terms or Safety Guidelines'),
             _buildRedBullet('Fraudulent activity or document falsification'),
             _buildRedBullet('Rating falling below minimum threshold (4.2 stars)'),
             _buildRedBullet('Gross misconduct or criminal behavior'),

             const SizedBox(height: 32),

            // Legal Footer
             Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF), // Light Blue
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Legal Queries', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                  const SizedBox(height: 4),
                  const Text('For specific legal questions regarding Terms & Conditions:', style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 12)),
                  const SizedBox(height: 12),
                  _buildContactRow(Icons.email, 'legal@driverapp.com'),
                  const SizedBox(height: 8),
                  _buildContactRow(Icons.phone, '+91 1800-123-4567'),
                   const SizedBox(height: 8),
                  _buildContactRow(Icons.location_on, '123 Tech Park, Bangalore 560001'),
                  const SizedBox(height: 16),
                   SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Contact Legal Team', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String text, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.black : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 22, color: Colors.black87),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black87)),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4))),
        ],
      ),
    );
  }

  Widget _buildRedBullet(String text) {
     return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFE11D48))),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: Color(0xFF9F1239), fontSize: 13, height: 1.4))),
        ],
      ),
    );
  }
   
   Widget _buildBlueBullet(String text) {
     return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: Color(0xFF1E40AF), fontSize: 13, height: 1.4))),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildNumberedItem(String number, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(number, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.3)),
              ],
            ),
          )
        ],
      ),
    );
  }

   Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF2563EB)),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 13))),
      ],
    );
  }
}
