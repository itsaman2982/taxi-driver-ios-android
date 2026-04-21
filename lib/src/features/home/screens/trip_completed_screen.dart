
import 'package:flutter/material.dart';
import 'package:taxi_driver/src/features/home/screens/home_screen.dart';

class TripCompletedScreen extends StatelessWidget {
  final Map<String, dynamic> ride;
  const TripCompletedScreen({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 80),
                    SizedBox(height: 16),
                    Text('Trip Completed!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    const Text('Total Earnings', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text('₹${ride['fare']}', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.green)),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    _summaryRow('Distance', '${ride['distance']} km'),
                    const SizedBox(height: 12),
                    _summaryRow('Duration', '${ride['duration']} min'),
                    const SizedBox(height: 12),
                    _summaryRow('Method', (ride['paymentMethod'] ?? 'Cash').toUpperCase()),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () async {
                  // Immediate feedback
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Returning home...'), duration: Duration(milliseconds: 500)),
                  );
                  
                  // Small delay to ensure backend state syncs before HomeScreen checks
                  await Future.delayed(const Duration(milliseconds: 300));
                  
                  if (!context.mounted) return;
                  
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back to Home', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
