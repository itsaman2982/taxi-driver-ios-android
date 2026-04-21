import 'package:flutter/material.dart';

class DriverHandbookScreen extends StatelessWidget {
  const DriverHandbookScreen({super.key});

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
        title: Column(
          children: [
            const Text(
              'Driver Handbook',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'Version 2.1 - October 2025',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.download, color: Colors.white, size: 20),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search handbook...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),

            // Table of Contents
            const Text(
              'Table of Contents',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),

            _buildHandbookItem(
              icon: Icons.settings,
              title: 'Operational Procedures',
              sections: '12 sections',
            ),
            const SizedBox(height: 12),
            _buildHandbookItem(
              icon: Icons.shield,
              title: 'Safety Guidelines',
              sections: '8 sections',
            ),
            const SizedBox(height: 12),
            _buildHandbookItem(
              icon: Icons.people,
              title: 'Code of Conduct',
              sections: '6 sections',
            ),
            const SizedBox(height: 12),
            _buildHandbookItem(
              icon: Icons.currency_rupee,
              title: 'Earning Rules',
              sections: '5 sections',
            ),
            const SizedBox(height: 12),
            _buildHandbookItem(
              icon: Icons.directions_car,
              title: 'Vehicle Requirements',
              sections: '4 sections',
            ),
            const SizedBox(height: 12),
            _buildHandbookItem(
              icon: Icons.support_agent,
              title: 'Customer Service',
              sections: '7 sections',
            ),
            const SizedBox(height: 12),
            _buildHandbookItem(
              icon: Icons.warning,
              title: 'Emergency Procedures',
              sections: '9 sections',
            ),
            const SizedBox(height: 12),
            _buildHandbookItem(
              icon: Icons.gavel,
              title: 'Legal Compliance',
              sections: '3 sections',
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHandbookItem({
    required IconData icon,
    required String title,
    required String sections,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 24, color: Colors.black87),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sections,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}
