import 'package:flutter/material.dart';

class RatePassengerScreen extends StatefulWidget {
  const RatePassengerScreen({super.key});

  @override
  State<RatePassengerScreen> createState() => _RatePassengerScreenState();
}

class _RatePassengerScreenState extends State<RatePassengerScreen> {
  int _rating = 4;
  final Set<String> _selectedTags = {};

  final List<String> _positiveTags = [
    'Friendly',
    'Punctual',
    'Clear Directions',
    'Respectful',
    'Good Conversation',
    'Clean & Tidy'
  ];

  final List<String> _negativeTags = [
    'Unruly',
    'Made a Mess',
    'Waited Too Long',
    'Wrong Pickup Location',
    'Rude Behavior',
    'No Show'
  ];

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Light grey background
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
              'Rate Passenger',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            Text(
              'Share your experience',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. Ride Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                   const Text('How was your ride with', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                   const SizedBox(height: 16),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       const CircleAvatar(
                         radius: 28,
                         backgroundImage: NetworkImage('https://via.placeholder.com/150'), // Placeholder
                       ),
                       const SizedBox(width: 16),
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           const Text('Texa M.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                           Text('Passenger ID: #P4829', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                         ],
                       ),
                     ],
                   ),
                   const SizedBox(height: 20),
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                     decoration: BoxDecoration(
                       color: const Color(0xFFF8F9FA),
                       borderRadius: BorderRadius.circular(12),
                     ),
                     child: const Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text('Trip completed', style: TextStyle(color: Colors.grey, fontSize: 12)),
                             SizedBox(height: 4),
                             Text('Duration', style: TextStyle(color: Colors.grey, fontSize: 12)),
                           ],
                         ),
                         Column(
                           crossAxisAlignment: CrossAxisAlignment.end,
                           children: [
                             Text('₹245', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                             SizedBox(height: 4),
                             Text('18 min', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                           ],
                         ),
                       ],
                     ),
                   ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),

            // 2. Star Rating
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text('Rate this passenger', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                          size: 40,
                          color: const Color(0xFFFFA000), // Amber
                        ),
                        onPressed: () => setState(() => _rating = index + 1),
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text('Tap to rate', style: TextStyle(color: Colors.grey.shade400, fontSize: 12, decoration: TextDecoration.underline)),
                ],
              ),
            ),
            
            const SizedBox(height: 20),

            // 3. Quick Feedback
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text('Quick feedback', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                   const SizedBox(height: 16),
                   
                   // Positive Section
                   const Row(
                     children: [
                       Icon(Icons.thumb_up, color: Color(0xFF10B981), size: 16),
                       SizedBox(width: 8),
                       Text('Positive', style: TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.bold, fontSize: 13)),
                     ],
                   ),
                   const SizedBox(height: 12),
                   Wrap(
                     spacing: 8,
                     runSpacing: 8,
                     children: _positiveTags.map((tag) => _buildFeedbackChip(tag, true)).toList(),
                   ),
                   
                   const SizedBox(height: 20),

                   // Negative Section
                   const Row(
                     children: [
                       Icon(Icons.thumb_down, color: Color(0xFFEF4444), size: 16),
                       SizedBox(width: 8),
                       Text('Needs Improvement', style: TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.bold, fontSize: 13)),
                     ],
                   ),
                   const SizedBox(height: 12),
                   Wrap(
                     spacing: 8,
                     runSpacing: 8,
                     children: _negativeTags.map((tag) => _buildFeedbackChip(tag, false)).toList(),
                   ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),

            // 4. Additional Comments
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Additional comments (optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextField(
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Share any additional feedback about your experience with this passenger...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.lock, size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 8),
                      Text('Your feedback helps improve the community experience', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),

            // Bottom Buttons
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.send, color: Colors.white, size: 18),
                label: const Text('Submit Rating', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Skip for now', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackChip(String label, bool isPositive) {
    bool isSelected = _selectedTags.contains(label);
    
    // Choose colors based on type
    Color activeBgColor = isPositive ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2);
    Color activeBorderColor = isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    Color activeTextColor = isPositive ? const Color(0xFF065F46) : const Color(0xFF991B1B);
    
    return InkWell(
      onTap: () => _toggleTag(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBgColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeBorderColor : Colors.grey.shade200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? activeTextColor : activeBorderColor.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
